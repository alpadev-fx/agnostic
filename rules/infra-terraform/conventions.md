---
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "infrastructure/**"
---
# Terraform — Conventions

## Layout
```
infrastructure/
  modules/                 # reusable: networking, db, compute, storage
  environments/
    dev/main.tf
    staging/main.tf
    prod/main.tf
  shared/                  # cross-env: backend config, providers
```

## State
- Remote backend always (S3 + DynamoDB lock, or Terraform Cloud)
- One state file per environment
- Never commit `*.tfstate` to git
- Never run `terraform apply` against shared state without `terraform plan` first

## Naming
- Resources: `<project>-<env>-<service>` (e.g., `ledgerfi-prod-api`)
- Modules: descriptive, no abbreviations (`vpc-public-subnet`, not `vps`)
- Variables: snake_case, with type and description
- Tags: always `Environment`, `Project`, `ManagedBy=terraform`, `CostCenter` if applicable

## Variables
- All vars typed (`type = string`, `type = list(string)`, `type = object({...})`)
- Sensible defaults for non-environment-specific vars
- `validation {}` blocks for constrained values
- Secrets via env vars or secret manager refs — NEVER in `.tfvars` committed

## Modules
- One responsibility per module
- Inputs documented (description on every variable)
- Outputs documented
- Versioned via git tags or registry pin

## Workflow
```bash
terraform fmt -recursive
terraform validate
terraform plan -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
```

## Safety
- `terraform plan` reviewed before every `apply`
- `lifecycle { prevent_destroy = true }` on critical resources (DB, S3 bucket with state)
- `terraform-docs` for module documentation generation
- `tflint` + `tfsec`/`checkov` in CI

## Anti-patterns
- Committing `.tfvars` with secrets
- Running `terraform apply` from a laptop into prod
- `count` for resource configuration (use `for_each` for stable identity)
- Hardcoded ARNs/IDs that change per env
