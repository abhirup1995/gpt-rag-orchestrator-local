# Run Locally

This repository retains the complete GPT-RAG orchestrator architecture.
`LOCAL_MODE` changes configuration and startup behavior only; it does not
replace strategies, connectors, telemetry, or deployment assets.

## Local API startup

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e ".[test]"
Copy-Item .env.local.example .env
az login
python -m uvicorn main:app --app-dir src --host 127.0.0.1 --port 9000
```

`LOCAL_MODE=true` continues startup instead of hard-exiting if the initial
Azure App Configuration auth probe fails, reads configuration from
environment variables (`allow_environment_variables=true` makes `.env` values
win over anything pulled from App Configuration), and does not require an
`APP_CONFIG_ENDPOINT` to start. It is intended for API and orchestration-logic
work.

Every real Azure connector (AI Foundry, AI Search, Cosmos DB, Key Vault, SQL)
already falls back from Managed Identity to `AzureCliCredential`, so once
`az login` succeeds the same code path used in production authenticates
locally with no further changes.

## Azure-connected local execution

For a high-fidelity local run, set `APP_CONFIG_ENDPOINT` in `.env` and
authenticate with `az login`. The service then retrieves configuration under
the `orchestrator`, `gpt-rag-orchestrator`, `gpt-rag`, and no-label scopes,
including Key Vault references, with environment variables in `.env` taking
precedence for any key you set locally. Run from a machine that has network
access to the Azure AI Foundry, AI Search, and Cosmos DB resources — there is
no offline/mocked backend; this profile talks to real Azure services.

Use a dev subscription and dev-scoped resources, since this mode issues real
calls to AI Foundry, AI Search, and Cosmos DB.

## Production deployment

This repository deploys the same way as `gpt-rag-orchestrator`: `azd up` /
`azd provision` + `azd deploy`, or the scripts under `scripts/`. `LOCAL_MODE`
is unset in deployed environments, so the startup auth check keeps its
original hard-exit behavior in Azure Container Apps.
