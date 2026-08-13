#!/usr/bin/env bash
# Convenience wrapper around the Terraform deploy.
# Usage: ./deploy.sh <plan|apply|destroy>
set -euo pipefail

ACTION="${1:-plan}"
cd "$(dirname "$0")/terraform"

if [ ! -f terraform.tfvars ]; then
  echo "No terraform.tfvars found."
  echo "Copy terraform.tfvars.example to terraform.tfvars and fill in your project_id and lb_domain first."
  exit 1
fi

terraform init

case "$ACTION" in
  plan)
    terraform plan
    ;;
  apply)
    terraform apply
    ;;
  destroy)
    terraform destroy
    ;;
  *)
    echo "Unknown action: $ACTION (expected plan|apply|destroy)"
    exit 1
    ;;
esac
