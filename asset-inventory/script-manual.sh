{
  "command": "cat <<'EOF'
# 1. Export dos recursos de infra
gcloud asset export \\
  --organization=61181892930 \\
  --content-type=resource \\
  --bigquery-table=\"projects/terraform-442218/datasets/asset_inventory/tables/inventory_resources\" \\
  --partition-key=request-time \\
  --output-bigquery-force

# 2. Export das políticas de IAM
gcloud asset export \\
  --organization=61181892930 \\
  --content-type=iam-policy \\
  --bigquery-table=\"projects/terraform-442218/datasets/asset_inventory/tables/inventory_iam_policies\" \\
  --partition-key=request-time \\
  --output-bigquery-force
EOF"
}
Response

# 1. Export dos recursos de infra
gcloud asset export \
  --organization=61181892930 \
  --content-type=resource \
  --bigquery-table="projects/terraform-442218/datasets/asset_inventory/tables/inventory_resources" \
  --partition-key=request-time \
  --output-bigquery-force

# 2. Export das políticas de IAM
gcloud asset export \
  --organization=61181892930 \
  --content-type=iam-policy \
  --bigquery-table="projects/terraform-442218/datasets/asset_inventory/tables/inventory_iam_policies" \
  --partition-key=request-time \
  --output-bigquery-force
