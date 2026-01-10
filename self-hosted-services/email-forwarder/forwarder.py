import boto3
import json
import os
import email
import time
from email.message import EmailMessage
from email.utils import parseaddr, formataddr

# Configuration
REGION = os.environ.get('AWS_REGION', 'us-west-2')
QUEUE_URL = os.environ.get('SQS_QUEUE_URL')
DESTINATION_EMAIL = os.environ.get('DESTINATION_EMAIL')
FORK_FROM_EMAIL = os.environ.get('FORK_FROM_EMAIL', f"forwarder@ryanbeales.com")

# Backoff configuration
INITIAL_BACKOFF = 1
MAX_BACKOFF = 600

sqs = boto3.client('sqs', region_name=REGION)
s3 = boto3.client('s3', region_name=REGION)
ses = boto3.client('ses', region_name=REGION)

def process_message(message):
    body = json.loads(message['Body'])
    
    # SNS-wrapped SES notification
    if 'Message' in body:
        sns_msg = json.loads(body['Message'])
    else:
        sns_msg = body

    if 'receipt' not in sns_msg or 'mail' not in sns_msg:
        print("Skipping non-SES message")
        return True

    if 'bucketName' not in sns_msg['receipt']['action']:
        print(f"Error: 'bucketName' missing from SES notification. Action type: {sns_msg['receipt']['action'].get('type')}")
        return False

    bucket_name = sns_msg['receipt']['action']['bucketName']
    object_key = sns_msg['receipt']['action']['objectKey']
    original_recipient = sns_msg['mail']['destination'][0]
    original_sender = sns_msg['mail']['commonHeaders']['from'][0]
    subject = sns_msg['mail']['commonHeaders'].get('subject', 'No Subject')

    print(f"Processing email from {original_sender} to {original_recipient}: {subject}")

    # 1. Download email from S3
    response = s3.get_object(Bucket=bucket_name, Key=object_key)
    raw_email = response['Body'].read()

    # 2. Parse and modify email
    # To bypass SPF/DKIM issues, we rewrite the From header
    # and put the original sender in Reply-To.
    msg = email.message_from_bytes(raw_email)
    
    original_from = msg.get('From')
    name, addr = parseaddr(original_from)
    
    # New From header: "Name (original@email.com) via forwarder" <forwarder@ryanbeales.com>
    # This avoids nested angle brackets and keeps the sender context.
    display_name = f"{name} ({addr})" if name else addr
    
    del msg['From']
    msg['From'] = formataddr((f"{display_name} via forwarder", FORK_FROM_EMAIL))
    
    if 'Reply-To' in msg:
        del msg['Reply-To']
    msg['Reply-To'] = original_from
    
    # We also need to remove DKIM-Signature as it's no longer valid after modification
    if 'DKIM-Signature' in msg:
        del msg['DKIM-Signature']

    # 3. Send via SES
    try:
        ses.send_raw_email(
            Source=FORK_FROM_EMAIL,
            Destinations=[DESTINATION_EMAIL],
            RawMessage={'Data': msg.as_bytes()}
        )
        print(f"Successfully forwarded email to {DESTINATION_EMAIL}")
        
        # 4. Cleanup
        s3.delete_object(Bucket=bucket_name, Key=object_key)
        return True
    except Exception as e:
        print(f"Error forwarding email: {e}")
        return False

def main():
    print(f"Email forwarder started. Polling {QUEUE_URL}...")
    current_backoff = INITIAL_BACKOFF
    while True:
        try:
            response = sqs.receive_message(
                QueueUrl=QUEUE_URL,
                MaxNumberOfMessages=1,
                WaitTimeSeconds=20
            )

            if 'Messages' in response:
                for msg in response['Messages']:
                    if process_message(msg):
                        sqs.delete_message(
                            QueueUrl=QUEUE_URL,
                            ReceiptHandle=msg['ReceiptHandle']
                        )
                    else:
                        raise Exception("Message processing failed")
                # Reset backoff ONLY after successful polling and processing
                current_backoff = INITIAL_BACKOFF
            else:
                # No messages, loop again (Long Polling will wait up to 20s)
                pass
        except Exception as e:
            print(f"Error in main loop, backing off for {current_backoff}s: {e}")
            time.sleep(current_backoff)
            current_backoff = min(current_backoff * 2, MAX_BACKOFF)

if __name__ == "__main__":
    main()
