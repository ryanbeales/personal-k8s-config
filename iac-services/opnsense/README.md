# OPNsense Infrastructure Configuration

This directory contains the Kubernetes/Crossplane configuration for managing the OPNsense home router's static DHCP reservations and SSL/TLS certificates.

## Architecture

1. **DNS**: A Route53 A record is configured via Crossplane (`websites/ryanbeales.com/dns/router.ryanbeales.com.yaml`) pointing `router.ryanbeales.com` to `10.0.0.1`.
2. **Certificates**: A cert-manager Certificate resource requests a TLS certificate for `router.ryanbeales.com` using Route53 DNS-01 verification.
3. **Crossplane Terraform Provider**: A Crossplane `Workspace` executes Terraform HCL using the `browningluke/opnsense` provider to:
   - Import the generated TLS certificate into OPNsense.
   - Configure Kea DHCP subnets and static reservations.

## Prerequisites

Before this configuration can synchronize successfully, you must create a Kubernetes Secret containing the API credentials for your OPNsense firewall.

### Creating the API Credentials Secret

Generate an API Key and Secret in your OPNsense GUI (`System > Access > Users > [Your User] > API keys`), then run the following command to store them in your cluster:

```powershell
kubectl create secret generic opnsense-creds -n crossplane-system --from-literal=api-key="YOUR_API_KEY" --from-literal=api-secret="YOUR_API_SECRET"
```

## Adding DHCP Reservations

To add a new static reservation, edit the `module` block in [workspace.yaml](workspace.yaml) and declare an `opnsense_kea_dhcpv4_reservation` resource:

```hcl
resource "opnsense_kea_dhcpv4_reservation" "my_host" {
  subnet_id   = opnsense_kea_dhcpv4_subnet.lan.id
  ip_address  = "10.0.0.50"
  mac_address = "aa:bb:cc:dd:ee:ff"
  description = "My Hostname"
}
```
