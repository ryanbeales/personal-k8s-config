Manifests for nvidia device plugin and feature discovery ahave been customized from their respective repositories:
https://github.com/NVIDIA/k8s-device-plugin
https://github.com/NVIDIA/gpu-feature-discovery


Install nvidia package repo:
```
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
```

Update apt:
```
sudo apt-get update
```

Install drivers:
```
apt install nvidia-headless-580-server nvidia-container-toolkit cuda-drivers-fabricmanager-580 nvidia-cuda-toolkit nvidia-utils-580-server libnvidia-decode-580-server
```

*** During the install it will build the nvidia kernel module. If you have secure boot enabled it will ask for a password to build the module which you must confirm on boot or else the kernel will load without this module, you cannot do this remotely. https://wiki.ubuntu.com/UEFI/SecureBoot/DKMS - Days lost here: 3 (I grew up in the days of insecure boot, this is new to me...)

Restart host

Confirm nvidia containerruntime has been found:
```
grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml
```

Confirm nvidia module is loaded with `nvidia-smi`. If not, closely examine that secure boot step...

Once the drivers are loaded the nvidia device plugin and nvidia feature discovery will adjust the node resources to show GPU availability (the  number of GPUs depends on the time-slicing-config and physical GPUs):
```
# kubectl get nodes "-o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu"
NAME             GPU
croblociraptor   <none>
crobasaurusrex   4
crobceratops     4
```

Docs:
https://github.com/NVIDIA/k8s-device-plugin
https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-with-apt
https://docs.k3s.io/advanced#nvidia-container-runtime-support

Issues:
- The manifests for nvidia feature discovery and nvidia device plugin are from their respective repos, but have been edited to run in the nvidia runtime created by k3s automagically. These were intially done as a kustomize patch but this didn't work with argocd for some reason without any error message. I'll fix it one day so I'm not storing a full copy that can drift.
- For some reason I have to create the nvidia-gpu namespace to get the cluster role binding and cluster role to apply `kubectl create namespace nvidia-gpu` - I can't figure this one out yet.
- If you see this issue `Auto-detected mode as 'legacy' nvidia-container-cli: initialization error: nvml error: driver/library version mismatch` then run the driver install commands from above and reboot the nodes. This occurs when the container and host driver versions become out of sync. You might also have to remove old versions with a form of `sudo apt purge nvidia-* libnvidia-*`. 