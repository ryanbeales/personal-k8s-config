Local gitea instance for CI/CD and local package repo. Intent is to mirror github repos and build locally for deployment in the same cluster.

Prereqisite:
Create the admin username and password, and gitea actions secret with this:
```
sudo k3s kubectl create namespace gitea # Created here to store the secret, but will be managed by the helm chart afterwards.
sudo k3s kubectl create secret generic -n gitea gitea-admin-secret --from-literal=password=$(openssl rand -base64 16) --from-literal=username=YOUR_NAME_HERE
sudo k3s kubectl create secret generic -n gitea gitea-actions-secret --from-literal=GITEA_ACTIONS_TOKEN=$(openssl rand -base64 16)
```

Then on the host create the filesystem directory as the persistant volume will not create it itself.
```
mkdir -p /stash/gitea
```

After Gitea has started and you have logged in, you can now connect the runner to the instance.
1. Go to https://gitea.crobasaurusrex.ryanbeales.com/user/settings/actions/runners and get a new registration token
1. Update the gitea-actions-secret with the registration token (you can patch, you can edit, but this is far easier):
```
sudo k3s kubectl delete secret gitea-actions-secret -n gitea
sudo k3s kubectl create secret generic -n gitea gitea-actions-secret --from-literal=GITEA_ACTIONS_TOKEN={REGISTRATION_TOKEN}
```

Restart the runner and it should be picked up by gitea.

## Rootless Runner Setup
The Gitea Actions runners in this deployment are configured to run in "rootless" mode (specifically Docker-in-Docker rootless). This setup requires a few special considerations compared to the default Helm chart configuration:

1.  **Values Configuration:** `values-actions.yaml` is configured with `image.rootless: true` and specifically targets the `-dind-rootless` tags for both `act_runner` and `dind`.
2.  **AppArmor and Seccomp:** To allow nested virtualization/user namespaces on newer OS versions (like Ubuntu 24.04), the `dind` and `act-runner` containers require native Kubernetes 1.30+ `securityContext` settings with `appArmorProfile: type: Unconfined` and `seccompProfile: type: Unconfined`.
3.  **Socket Paths:** Rootless docker places its socket at `/var/run/user/1000/docker.sock` instead of `/var/run/docker.sock`.

These necessary modifications are applied via a Kustomize patch (`patch-runner-rootless.yaml`), which overrides the default StatefulSet created by the Gitea Actions Helm chart to adjust the security contexts, probe paths, and mount points.