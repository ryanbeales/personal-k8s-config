1. Get access key for Huggingface from https://huggingface.co/settings/tokens

1. Create secret for the access key:
```
sudo k3s kubectl create secret generic hf-token-secret --from-literal=token={secret} -n vllm
```


This has been disabled and removed. It's here as an example. It won't start a small model on my 5060 Ti 16GB, I'll wait until I have access to much larger hardware.