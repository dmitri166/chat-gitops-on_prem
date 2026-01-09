# Import existing Namespaces and PVCs into Terraform

This document describes how to import existing Kubernetes Namespaces and PersistentVolumeClaims (PVCs) into the Terraform `module.storage` we added.

Prerequisites
- `terraform` CLI installed
- Kubeconfig pointing at the cluster where resources exist (set `KUBECONFIG` or ensure default config works)

Options

1) PVCs do NOT exist: run `terraform plan` and `terraform apply` to create namespaces and PVCs.

2) PVCs already exist: import them into Terraform state.

Import steps (recommended)

From the repository root:

```bash
cd infrastructure/terraform
./import_pvcs.sh
# or on Windows PowerShell:
# .\import_pvcs.ps1

terraform plan
```

Verify the plan shows no changes to existing resources that would be destructive.

If everything looks good, keep `create-pvcs.yaml.disabled` archived and do not let ArgoCD apply that manifest.
