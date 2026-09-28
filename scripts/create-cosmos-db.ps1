# Creates the Cosmos DB database + containers required by gpt-rag-orchestrator.
# Run this from an identity that has write access to the Cosmos DB account
# (e.g. Cosmos DB Built-in Data Contributor / Contributor on the account),
# such as the VDI/admin session.
#
# Usage:
#   .\create-cosmos-db.ps1

$ErrorActionPreference = "Stop"

# cosmosdb-7ep-acc-ai-dev-01 has the EnableTable capability (Table API) and
# cannot host SQL databases/containers -- use the Core (SQL) API account.
$accountName = "cosmosdb-7ep-acc-ai-dev-02"
$resourceGroup = "RG-DEV-7EP-AI-Accounting"
$databaseName = "gptrag"
# Developer's own AAD user object id (used via AzureCliCredential when
# running locally/on the VDI with `az login` -- not the UMI-7EP-ACC-48A-01
# managed identity, which only applies inside Azure Container Apps).
$developerPrincipalId = "98718db9-5e9d-4c63-9462-f4eac680a0ab"

Write-Host "Creating Cosmos SQL database '$databaseName' on account '$accountName'..."
az cosmosdb sql database create `
    --account-name $accountName `
    --resource-group $resourceGroup `
    --name $databaseName `
    --throughput 400

Write-Host "Creating container 'conversations' (partition key /conversation_id)..."
az cosmosdb sql container create `
    --account-name $accountName `
    --resource-group $resourceGroup `
    --database-name $databaseName `
    --name conversations `
    --partition-key-path "/conversation_id"

Write-Host "Creating container 'datasources' (partition key /id)..."
az cosmosdb sql container create `
    --account-name $accountName `
    --resource-group $resourceGroup `
    --database-name $databaseName `
    --name datasources `
    --partition-key-path "/id"

Write-Host "Granting Cosmos DB Built-in Data Contributor to the developer identity..."
az cosmosdb sql role assignment create `
    --account-name $accountName `
    --resource-group $resourceGroup `
    --role-definition-id 00000000-0000-0000-0000-000000000002 `
    --principal-id $developerPrincipalId `
    --scope "/"

Write-Host "Done. Verifying..."
az cosmosdb sql database list --account-name $accountName --resource-group $resourceGroup --query "[].name" -o table
az cosmosdb sql container list --account-name $accountName --resource-group $resourceGroup --database-name $databaseName --query "[].id" -o table
az cosmosdb sql role assignment list --account-name $accountName --resource-group $resourceGroup --query "[].principalId" -o table
