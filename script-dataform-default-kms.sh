gcloud kms keys add-iam-policy-binding dtfrmNPRDSYMAES256hsm001 \
  --keyring=dtfrmhsmNPRDring --location=southamerica-east1 \
  --member="serviceAccount:service-394791638914@gcp-sa-dataform.iam.gserviceaccount.com" \
  --role="roles/cloudkms.cryptoKeyEncrypterDecrypter" \
  --project="prj-hsm-services-des"


curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{"defaultKmsKeyName":"projects/prj-hsm-services-des/locations/southamerica-east1/keyRings/dtfrmhsmNPRDring/cryptoKeys/dtfrmNPRDSYMAES256hsm001"}' \
  https://dataform.googleapis.com/v1/projects/prj-decci-des/locations/southamerica-east1/config

  curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{"defaultKmsKeyName":"projects/prj-hsm-services-prd/locations/southamerica-east1/keyRings/dataformrepositoryhsmPRDring/cryptoKeys/dtformPRDSYMAES256hsm001"}' \
  https://dataform.googleapis.com/v1/projects/prj-siapc-prd/locations/southamerica-east1/config

  gcloud kms keys add-iam-policy-binding dtformPRDSYMAES256hsm001 \
  --keyring=dataformrepositoryhsmPRDring --location=southamerica-east1 \
  --member="serviceAccount:service-1058859310639@gcp-sa-dataform.iam.gserviceaccount.com" \
  --role="roles/cloudkms.cryptoKeyEncrypterDecrypter" \
  --project="prj-hsm-services-prd"