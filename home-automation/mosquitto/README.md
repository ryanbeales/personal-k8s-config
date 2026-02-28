# Mosquitto MQTT Broker

## Managing Users

This mosquitto deployment uses a `ConfigMap` to store the `accounts.conf` file containing the user credentials.

### 1. Generating a Password Hash

You can use the `mosquitto_passwd` utility to generate a new password hash. The easiest way to do this without installing anything locally is via Docker. 
Note: Ensure you use `eclipse-mosquitto:1.6` or an older tag that generates `$6$` SHA512 hashes. New argon2 (`$7$`) hashes fail to decode salt on this cluster.

```bash
docker run --rm --entrypoint sh eclipse-mosquitto:1.6 -c "mosquitto_passwd -c -b /tmp/pw <username> <password> && cat /tmp/pw"
```

For example:
```bash
docker run --rm --entrypoint sh eclipse-mosquitto:1.6 -c "mosquitto_passwd -c -b /tmp/pw workswitcher mysecretpassword && cat /tmp/pw"
```

This will output a line like:
```
workswitcher:$6$0F...
```

### 2. Updating the Configuration

1. Edit the `config.yaml` file in this directory.
2. Locate the `accounts.conf` section within the `data` block.
3. Change the yaml block scalar from `>-` to `|-` (if not already) to properly support multiple lines.
4. Add the newly generated output line on a new line.

Example `config.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mosquitto
  namespace: mosquitto
data:
  accounts.conf: |-
    admin:$6$5w8gXq38OdhCaMy1$0RkpHDAEPAyNOwxU8Y6MdfxTCo7Sx6Hch35AEtUb6L42UrehC4JxEtQiRsaSKWsOZt/YtW98MOjrB3yhLcXrNw==
    newuser:$6$8wJ...
  mosquitto.conf: |-
    # ...
```

## Externally Addressable Endpoints

The broker is exposed via an internal ClusterIP service and an external LoadBalancer service.

### Internal Use (Within Cluster)
- Address: `mosquitto.mosquitto.svc.cluster.local`
- Port: `1883`

### External Use (Outside Cluster on Local Network)
Once the `mosquitto-external` LoadBalancer gets an IP assigned by your network (e.g., via MetalLB), you can address it via:
- Address: `<EXTERNAL_IP>`
- Port: `1883`

To find the external IP, run:
```bash
kubectl get svc -n mosquitto mosquitto-external
```
