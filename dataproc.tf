gcloud dataproc clusters create dp-01-gepld-prd \
  --region=southamerica-east1 \
  --project=prj-modelagem-gepld-prd \
  --subnet=projects/prj-network-services-prd-cef/regions/southamerica-east1/subnetworks/sub-risco-gepld-prd \
  --no-address \
  --master-machine-type=n2-standard-8 \
  --master-boot-disk-type=hyperdisk-balanced \
  --master-boot-disk-size=100 \
  --num-workers=5 \
  --worker-machine-type=n2-standard-8 \
  --worker-boot-disk-type=hyperdisk-balanced \
  --worker-boot-disk-size=200 \
  --image-version=2.3-debian12 \
  --optional-components=JUPYTER,ICEBERG \
  --enable-component-gateway \
  --properties=spark:spark.dataproc.enhanced.execution.enabled=true,spark:spark.dataproc.enhanced.optimizer.enabled=true \
  --autoscaling-policy=autoscale-policy \
  --service-account=sa-wb-06-gepld-prd@prj-modelagem-gepld-prd.iam.gserviceaccount.com \
  --scopes=https://www.googleapis.com/auth/cloud-platform


id: autoscale-policy
workerConfig:
  minInstances: 2
  maxInstances: 15
secondaryWorkerConfig:
  maxInstances: 0
basicAlgorithm:
  yarnConfig:
    scaleUpFactor: 1.0
    scaleDownFactor: 1.0
    scaleUpMinWorkerFraction: 0.0
    scaleDownMinWorkerFraction: 0.0
    gracefulDecommissionTimeout: 1h

gcloud dataproc autoscaling-policies import autoscale-policy \
  --region=southamerica-east1 \
  --project=prj-modelagem-gepld-prd \
  --source=autoscale-policy.yaml