# LiteLLM

Proxy and routing layer for LLMs and speech/voice services in the cluster.

## Setup & Prerequisites

### 1. Gemini Secret
LiteLLM connects to Google Gemini (e.g. Gemini 3.7 Flash and Gemini 3.8 Flash) using the `GEMINI_API_KEY` environment variable mounted from the `gemini-secret` Kubernetes Secret in the `litellm` namespace.

To create the secret directly:
```bash
kubectl create secret generic gemini-secret -n litellm \
  --from-literal=GEMINI_API_KEY=<YOUR_GEMINI_API_KEY>
```

Or in PowerShell:
```powershell
kubectl create secret generic gemini-secret -n litellm --from-literal=GEMINI_API_KEY="<YOUR_GEMINI_API_KEY>"
```

#### Migrating from an Existing Secret (e.g. Hermes)
If you previously had a secret named `hermes-gemini-secret` in the `hermes` namespace:
```powershell
$apiKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((kubectl get secret hermes-gemini-secret -n hermes -o jsonpath="{.data.GEMINI_API_KEY}")))
kubectl create secret generic gemini-secret -n litellm --from-literal=GEMINI_API_KEY=$apiKey

# Optional: Remove old secret from hermes namespace
kubectl delete secret hermes-gemini-secret -n hermes
```

## Available Models

- **Gemini**: `gemini-3.7-flash` (alias `gemini-3.7`), `gemini-3.8-flash` (alias `gemini-3.8`)
- **Local LLMs**: `qwen3.8-27B`, `gemma-4-12B`, `gemma-4-E4B`
- **Speech-to-Text**: `faster-whisper`
- **Text-to-Speech**: `omnivoice`, `kokoro`
- **Routing Groups**: `agent`, `vision`, `assistant`, `code`, `stt`, `tts`
