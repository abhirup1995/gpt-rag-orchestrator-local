# Creates the Cosmos DB database + containers required by gpt-rag-orchestrator.
# Run this from an identity that has write access to the Cosmos DB account
# (e.g. Cosmos DB Built-in Data Contributor / Contributor on the account),
# such as the VDI/admin session.
#
# Usage:
#   .\create-cosmos-db.ps1

$ErrorActionPreference = "Stop"

$accountName = "cosmosdb-7ep-acc-ai-dev-01"
$resourceGroup = "RG-DEV-7EP-AI-Accounting"
$databaseName = "gptrag"

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

Write-Host "Done. Verifying..."
az cosmosdb sql database list --account-name $accountName --resource-group $resourceGroup --query "[].name" -o table
az cosmosdb sql container list --account-name $accountName --resource-group $resourceGroup --database-name $databaseName --query "[].id" -o table
