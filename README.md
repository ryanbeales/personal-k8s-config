<p align="center">
<img src="./image.png" alt="A stylized logo for a technical software repository. A friendly, cybernetic T-Rex dinosaur, wearing tech goggles, is sitting on top of a small, mismatched home server rack cluster. The dinosaur is holding a glowing blue Kubernetes wheel icon. Behind it is a subtle outline of a house with a WiFi signal. The style is clean, modern vector art with a blue, purple, and orange color palette.">
</p>

# personal-k8s-config

Welcome to my home kubernetes configuration!

### Why run Kubernetes at home?

1. Work, 90% of my day job is this so it's just an easy extension to do this at home too, but it is incredibly easy too.
1. I took inspiration from [billimek/k8s-gitops](https://github.com/billimek/k8s-gitops/tree/master/default), however I've not referred to that in a long time now.
1. Seemed like an easy way to manage home assistant and other software.

### Is the the Gold Standard of K8s Config?

Not really. It's always a work in progress and lots of things aren't commented to a standard I would leave in the workplace since this is just my home. It's been _much_ easier to maintain than stand alone systems, and if there is a new application I want to try out I can have it running in about 15 minutes. 

### Manifests vs Helm

Previously I relied heavily on helm charts, particularlly the k8s-at-home  charts, but since that repo was deprecated I just went back to plain manifests.

I find it easier to have the plain manifests than trying to find out what a helm chart does anyway, which needs a heavy reliance on the Dyff github action so I can see what changes are actually being made.

Eventually I'll switch to a custom operator, [KRO](https://kro.run/) or [YokeCD](https://yokecd.github.io/docs/). I have examples of KRO in [cluster-services/kro](./cluster-services/kro) and [cluster-services/kro-templates](./cluster-services/kro-templates). 

# Features

Highlights of what is running here.

## Renovatebot

Renovatebot is used to keep dependancies up to date. It will create a PR for each update and will auto merge if the PR is approved. It makes a majority of the work keeping everything up to date very hands off. When I haven't allowed auto merge on dependancies Renovate will (most of the time) show the changelog for the app so I can scan through for any breaking changes (eg: frigate, home-assistant). Auto merge is enabled for renovate itself, esphome, monitoring charts, envoy-gateway, home-assistant, and argocd, things that are stable release to release with the features I make use of.

To make all this work there is:
- Renovatebot cronjob in [development-services/renovate](./development-services/renovate) which runs daily within the cluster
- Renovate config for this repo in [.github/renovate.json5](./.github/renovate.json5) for specifying how to update dependencies in locations not natively supported by renovate (such as Deployment manifests).
- A github actions workflow to run dyff and show changes between commits, which is configured as a required check for PRs.
- Repository set to allow auto merge on PRs, and renovate configured to use platform commits and platform merge.

I'm pretty active in this repo day to day, but at a minimum the work to keep things up to date is a couple of PRs to scan over once a week.

## Envoy Gateway

[Envoy Gateway](https://gateway.envoyproxy.io/) is used to manage ingress, with the ingress-nginx deprecation I've switched to GatewayAPI which was very painless.

The Envoy Gateway contoller is configured in [ingress/envoy-gateway](./ingress/envoy-gateway), with a GatewayClass. The Gateways themselves are in [ingress/gateways](./ingress/gateways/), TLS termination happens at the gateway with their own wildcard certificates (configured with the gateways). Each app has it's own HTTPRoute.

The Gateways are using a LoadBalancer service to expose ports to the outside world. Within K3s that is done with ServiceLB which will open the ports on all nodes in the cluster.

## Certificates / Let's Encrypt

[Let's Encrypt](https://letsencrypt.org/) is used to manage certificates in the cluster. It is configured as a ClusterIssuer in [cluster-services/letsencrypt](./cluster-services/letsencrypt) for [cert-manager](https://cert-manager.io/) in [cluster-services/cert-manager](./cluster-services/cert-manager). The DNS challenge is used to manage certificates so that there are no exposed ports to the outside world.

## ArgoCD

[ArgoCD](https://argo-cd.readthedocs.io/en/stable/) is used to manage applications in the cluster, configured in [argocd](./argocd). I've enabled the terminal plugin to allow me to execute commands within pods from the argocd interface. Since TLS termination happens at the gateway, argocd is configured to be 'insecure', but it is not.

Argocd uses an ApplicationSet to find applications in this repo, it is configured in [argocd/applicationset](./argocd/applicationset). This allows me to drop a small argocd.yaml file in each application directory I want managed by argocd and it is then picked up by argocd on it's next background repo sync (minutes):
```yaml
argocd:
  name: application-name
  namespace: application-namespace
```

## Nvidia GPUs

I'm running a mix of old Nvidia GPUs in the cluster. I did use the Nvidia GPU operator at one point but this didn't work properly with my setup. Instead I've installed the components it manages separately, which is detailed in [cluster-services/nvidia-gpu](./cluster-services/nvidia-gpu). I'm using a timeslicing config to split each GPU in to 8 virtual GPUs for applications in the cluster. Because each GPU has vastly different performance I use `nodeSelector` to direct applications to the appropriate GPU by node name. Until [DRA](https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/) is available this is the best I can do.

## Crossplane

Crossplane is used to manage infrastructure (some DNS entries mostly), configured in [iac-services/crossplane](./iac-services/crossplane) and [iac-services/crossplane-providers](./iac-services/crossplane-providers). I've tried alternatives (Pulumi, tofu-operator), but crossplane is working and I'm not super invested in trying to make it better. There is a _huge_ barrier of entry to get started with crossplane which does put me off the project, but don't fix what ain't broke.

## Self-Hosted AI

I've added several self-hosted AI services into the cluster to provide local LLM capabilities, both out of interest of running these and also to make use of idle hardware instead of sending money elsewhere. 

- [llama.cpp](https://github.com/ggml-org/llama.cpp) instances in [ai-services](./ai-services) provide the backend for running GGUF models locally across the cluster GPUs, fronted by [LiteLLM](https://www.litellm.ai/) ([ai-services/litellm](./ai-services/litellm)) for unified OpenAI-compatible routing and fallbacks (previously used Ollama and vLLM, now in [archived](./archived)).
- [Hermes Agent](https://github.com/NousResearch/Hermes-Agent) ([ai-services/hermes](./ai-services/hermes)) runs autonomous agentic workflows inside the cluster.
- [SearXNG](https://searxng.org/) ([ai-services/searxng](./ai-services/searxng)) provides a metasearch engine to power web search tools for AI agents.
- [Open-WebUI](https://openwebui.com/) ([ai-services/open-webui](./ai-services/open-webui)) provides the interface for interacting with models.

Home Assistant and Frigate are both configured to route through the LiteLLM instance in the cluster to the local Gemma 4 `llama.cpp` backends (`gemma-4-26B-A4B` on the 5060 Ti 16GB and `gemma-4-E4B` on the 3060 12GB) for Frigate snapshot descriptions and the Home Assistant Voice Assistant conversation agent.

## Antigravity

I've been using the Antigravity IDE to manage this repo recently. There are repository rules and skills in [.agent/AGENTS.md](./.agent/AGENTS.md) and [.agent/skills](./.agent/skills). This is a work in progress but right now it's functioning as an assistant that can complete a majority of the tasks in this repo I ask of it while I do something else.

# Cluster Hardware

The cluster is a mix of old custom-built desktops from old parts from my main desktop computer. As I upgrade it I take the old parts and build another computer for the cluster. This unfortunately means that every upgrade costs _more_ and with DDR5 prices what they are now (TODO: review this in a couple of years) I expect this is what it will remain as. There is also an old laptop that I use as a worker node. Every node has local storage, but the k3s master node also serves as the NFS storage for apps running elsewhere in the cluster.

```mermaid
graph TD
    M["crobasaurusrex<br/>(Master Node)"]
    W1["crobceratops<br/>(Worker Node)"]
    W2["croblodocus<br/>(Worker Node)"]
    W3["crobputer<br/>(Worker Node - WSL2)"]

    M --- Storage[("20TB Storage<br/>(Mirrored Spinning Disk)")]
    M --- G1["Nvidia GeForce RTX 3060 12GB"]
    W1 --- G2["Nvidia GeForce RTX 5060 Ti 16GB"]
    W2 --- G3["Nvidia GeForce GTX 1050Ti 4GB"]
    W3 --- G4["Nvidia GeForce RTX 4090 24GB"]
    M --- W1
    M --- W2
    M --- W3
```

I won't explain the naming convention except that I also acknowledge that it's strange, but I'm stuck with it now (do you know how many dinosaurs end in the same set of letters??).

## Hosts

| Hostname | Role | CPU | RAM | Storage | GPU |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **crobasaurusrex** | Master | AMD Ryzen 9 3900XT (12C/24T) | 32GB | 20TB Mirrored (NFS) | Nvidia GeForce RTX 3060 12GB |
| **crobceratops** | Worker | AMD Ryzen 5 5600X (6C/12T) | 32GB | 1TB Local | Nvidia GeForce RTX 5060 Ti 16GB |
| **croblodocus** | Worker | Intel Core i9-8950HK (6C/12T) | 32GB | 2TB Local | Nvidia GeForce GTX 1050Ti 4GB |
| **crobputer** | Worker | AMD Ryzen 7 5800XT (8C/16T) | 32GB (24GB WSL2) | 1TB Local | Nvidia GeForce RTX 4090 24GB |

### Other hardware

My main desktop (`crobputer`) is joined as a worker node running Windows with k3s in WSL2 (instructions in [BOOTSTRAP.md](./BOOTSTRAP.md)), making its RTX 4090 available for running larger AI workloads when not gaming. In the past I've also had a Raspberry Pi 3 running as a k3s worker node, but I took it out as I have more than enough capacity with these nodes.

## Building the cluster

See [BOOTSTRAP.md](./BOOTSTRAP.md) for notes on how to build the cluster from scratch. 

## Upgrading the cluster

Follow the instructions [here](https://docs.k3s.io/upgrades/manual#upgrade-k3s-using-the-binary) on each node in the cluster.
