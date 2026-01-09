<#
Import existing namespaces and PVCs into Terraform module.storage state.
Run this from PowerShell with terraform installed and KUBECONFIG set (if needed).
#>
Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $scriptDir

Write-Output "Initializing Terraform..."
terraform init

Write-Output "Importing namespaces..."
terraform import 'module.storage.kubernetes_namespace.env["dev"]' dev -lock=false -allow-missing-config || $null
terraform import 'module.storage.kubernetes_namespace.env["staging"]' staging -lock=false -allow-missing-config || $null
terraform import 'module.storage.kubernetes_namespace.env["prod"]' prod -lock=false -allow-missing-config || $null

Write-Output "Importing PVCs..."
terraform import 'module.storage.kubernetes_persistent_volume_claim.chat_logs["dev"]' dev/chat-logs-dev -lock=false -allow-missing-config || $null
terraform import 'module.storage.kubernetes_persistent_volume_claim.chat_logs["staging"]' staging/chat-logs-staging -lock=false -allow-missing-config || $null
terraform import 'module.storage.kubernetes_persistent_volume_claim.chat_logs["prod"]' prod/chat-logs-prod -lock=false -allow-missing-config || $null

Pop-Location
Write-Output "Import complete. Run 'terraform plan' to verify."
