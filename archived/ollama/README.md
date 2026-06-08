Run Ollama within K8s so I can use it against a GPU instance

Models are pulled with a lifecycle hook once the container starts. They may not be available right away on the API.
