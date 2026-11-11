# Bootstrap

These are my notes in case I need to rebuild everything again. I've run throught this _once_ when I migraged from microk8s to k3s. It should be enough of a guide to help you build a cluster from scratch if that's what you're here for.

## Linux nodes
If it breaks again, start here.
1. On master node `curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -s -`
1. Get the token from the master node `cat /var/lib/rancher/k3s/server/node-token`

1. On other nodes `curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.59:6443 K3S_TOKEN=${K3S_TOKEN} sh -s -`
1. On GPU nodes follow the driver install in [cluster-services/nvidia-gpu/README.md](./cluster-services/nvidia-gpu/README.md).
1. On all nodes make a `/stash` directory for local storage provisioning.
1. Check that `/stash` is in the `kube-system/local-path-config` configmap - K3s may change this. It's an issue at the moment but we will look at that later.

All the rest of these steps are on the on master node
1. Install kustomize, on ubuntu that is `curl -L https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.3.0/kustomize_v5.3.0_linux_amd64.tar.gz --output - | tar xzf - kustomize | sudo mv kustomize /usr/local/bin/kustomize`
1. Install helm `curl https://get.helm.sh/helm-v3.14.2-linux-amd64.tar.gz --output - | tar xzf - linux-amd64/helm | sudo mv linux-amd64/helm /usr/local/bin/helm`
1. Install github client `sudo apt-get install gh`
1. Authenticate gh client `/usr/bin/gh auth login` and follow instructions. Use SSH not http.
1. Checkout this repo to the master node `/usr/bin/gh repo clone ryanbeales/personal-k8s-config`
1. Install cert-manager with `/usr/local/bin/kustomize build cluster-services/cert-manager --enable-helm | sudo k3s kubectl apply -f -`
1. Create route53 secret access, see `./cluster-services/letsencrypt/README.md`
1. Add letsencrypt certificate issuer `/usr/local/bin/kustomize build cluster-services/letsencrypt | sudo k3s kubectl apply -f -`
1. Install envoy-gateway and gateways
```bash
/usr/local/bin/kustomize build ingress/envoy-gateway --enable-helm | sudo k3s kubectl apply -f -
/usr/local/bin/kustomize build ingress/gateways | sudo k3s kubectl apply -f -
```
1. Install argocd with kustomize `/usr/local/bin/kustomize build argocd | sudo k3s kubectl apply -f -` - ignore CRD errors, the apps will be picked up after the secret is applied.
1. Follow [argocd/README.md](./argocd/README.md) to create argocd repo secret.
1. At this point the rest of the cluster will then come up as best it can.
1. Create secrets/passwords for applications as needed (e.g., photoprism, `iac-services/crossplane-providers`), this will start these applications correctly.

Notes:
- The crossplane provider config in `iac-services/crossplane-providers` will not apply until other objects have applied first. You may have to remove this and add in the next sync. I'm not a fan of how this all works but we'll leave it in place for now.
- There may be some missing steps. Usually the README in each directory will explain what to do if the project goes wrong.

## Adding windows nodes
I have a gaming PC with a hefty nvidia card in it. I can install K3s via WSL on this PC to make it available to the cluster when I'm not gaming (often, these days).

On the windows PC (these may or may not be in order or complete)
1. Create a .wslconfig in your user directory:
```
[wsl2]
networkingMode=bridged
vmSwitch=WSL Switch
dnsTunneling = false
firewall = false

[network]
generateResolvConf = false
```
1. Install wsl2 `wsl --install` or reinstall (https://gist.github.com/4wk-/889b26043f519259ab60386ca13ba91b), hyper-v and hyper-v manager
1. Create a new External switch in hyper-v manager named `WSL-Switch`, connect it to your network interface
1. Install and Start the Ubuntu instance `wsl --install Ubuntu`
1. Install k3s node as above in the Bootstrap section
1. Install cuda on wsl2 https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
1. Restart the k3s agent `sudo systemctl restart k3s-agent`
1. Verify that the nvidia runtime has been found by k3s: `sudo grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml`

You may need to do this, I lost bout 8 hours of my life just trying to get this to work (is is worth it to get access to a 4090 in my k8s cluster? Maybe...)
```
Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow
New-NetFirewallHyperVRule -Name VXLAN -DisplayName "VXLAN Fix" -Direction Inbound -VMCreatorId '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -Protocol UDP -LocalPorts 8472
```