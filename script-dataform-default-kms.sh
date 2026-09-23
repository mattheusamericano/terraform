gcloud kms keys add-iam-policy-binding KMS_KEY \
  --keyring=KMS_KEY_RING --location=LOCATION \
  --member="serviceAccount:service-PROJECT_NUMBER@gcp-sa-dataform.iam.gserviceaccount.com" \
  --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"


curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{"defaultKmsKeyName":"projects/PROJECT_ID/locations/LOCATION/keyRings/KMS_KEY_RING/cryptoKeys/KMS_KEY"}' \
  https://dataform.googleapis.com/v1/projects/PROJECT_ID/locations/LOCATION/config