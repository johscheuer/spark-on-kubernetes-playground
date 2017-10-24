# Introduction

This repository contains some examples for Spark on Kubernetes.

## Prerequisites

- [Helm](https://github.com/kubernetes/helm)
- Kubernetes Cluster(e.g. [GKE](https://cloud.google.com/container-engine))
- Maven

## Start a GKE Cluster

Run `./bootstrap_cluster.sh` to start a GKE cluster with 4 nodes. Also a firewall rule for port 31000 will be created, this is needed to upload own jar files to the file-staging server.

## Install HDFS

Run `./install_hdfs` to install HDFS on your cluster. For futher information look into the repo: https://github.com/apache-spark-on-k8s/kubernetes-HDFS

## Run Spark jobs

### Example job

```bash
cd repos/spark-2.2.0-k8s-0.4.0-bin-2.7.3/

export KUBE_MASTER=$(kubectl cluster-info | grep master | awk  '{print $6}' | tr -cd "[:print:]\n" | sed 's/\[0;33m//g;s/\[0m//g')
bin/spark-submit \
  --deploy-mode cluster \
  --class org.apache.spark.examples.SparkPi \
  --master k8s://$KUBE_MASTER \
  --kubernetes-namespace default \
  --conf spark.executor.instances=5 \
  --conf spark.app.name=spark-pi \
  --conf spark.executor.cores=1 \
  --conf spark.executor.memory=1g \
  --conf spark.kubernetes.driver.docker.image=kubespark/spark-driver:v2.2.0-kubernetes-0.4.0 \
  --conf spark.kubernetes.executor.docker.image=kubespark/spark-executor:v2.2.0-kubernetes-0.4.0 \
  --conf spark.kubernetes.initcontainer.docker.image=kubespark/spark-init:v2.2.0-kubernetes-0.4.0 \
  local:///opt/spark/examples/jars/spark-examples_2.11-2.2.0-k8s-0.4.0.jar
```

### Run example job in namespace

```bash
kubectl create ns spark
# Default test different Namespace
bin/spark-submit \
  --deploy-mode cluster \
  --class org.apache.spark.examples.SparkPi \
  --master k8s://$KUBE_MASTER \
  --kubernetes-namespace spark \
  --conf spark.executor.instances=5 \
  --conf spark.app.name=spark-pi \
  --conf spark.kubernetes.driver.docker.image=kubespark/spark-driver:v2.2.0-kubernetes-0.4.0 \
  --conf spark.kubernetes.executor.docker.image=kubespark/spark-executor:v2.2.0-kubernetes-0.4.0 \
  --conf spark.kubernetes.initcontainer.docker.image=kubespark/spark-init:v2.2.0-kubernetes-0.4.0 \
  local:///opt/spark/examples/jars/spark-examples_2.11-2.2.0-k8s-0.4.0.jar
```

### Run terasort

In this example we make use of the file staging server to upload our own jar file. Terasort is compiled in the `./fetch_spark.sh` script.

```bash
# Assuming you run on GKE:
export STAGING_SERVER=$(gcloud compute instances list | grep -m1 "^gke-big-data-demo" | awk '{print $5}')

bin/spark-submit \
  --verbose \
  --deploy-mode cluster \
  --class com.github.ehiggs.spark.terasort.TeraGen \
  --master k8s://$KUBE_MASTER \
  --kubernetes-namespace default \
  --conf spark.executor.instances=3 \
  --conf spark.app.name=teragen \
  --conf spark.executor.cores=1 \
  --conf spark.executor.memory=1g \
  --conf spark.hadoop.dfs.block.size=268435436 \
  --conf spark.kubernetes.resourceStagingServer.uri=http://$STAGING_SERVER:31000 \
  ../spark-terasort/target/spark-terasort-1.1-SNAPSHOT.jar 10G terasort-in-10G
```

### Running PySpark

```bash
kubectl create ns pyspark

bin/spark-submit \
  --deploy-mode cluster \
  --master k8s://$KUBE_MASTER  \
  --kubernetes-namespace=pyspark \
  --conf spark.executor.instances=5 \
  --conf spark.app.name=spark-pi \
  --conf spark.kubernetes.driver.docker.image=kubespark/spark-driver-py:v2.2.0-kubernetes-0.4.0 \
  --conf spark.kubernetes.executor.docker.image=kubespark/spark-executor-py:v2.2.0-kubernetes-0.4.0 \
  --jars local:///opt/spark/examples/jars/spark-examples_2.11-2.2.0-k8s-0.4.0.jar \
  local:///opt/spark/examples/src/main/python/pi.py 10
```

### Dynamic Shuffeling

Create the dynamic executors

```bash
kubectl apply -f  conf/kubernetes-shuffle-service.yaml
```

```bash
bin/spark-submit \
  --deploy-mode cluster \
  --class org.apache.spark.examples.GroupByTest \
  --master k8s://$KUBE_MASTER  \
  --kubernetes-namespace default \
  --conf spark.app.name=group-by-test \
  --conf spark.kubernetes.driver.docker.image=kubespark/spark-driver:v2.2.0-kubernetes-0.4.0  \
  --conf spark.kubernetes.executor.docker.image=kubespark/spark-executor:v2.2.0-kubernetes-0.4.0 \
  --conf spark.dynamicAllocation.enabled=true \
  --conf spark.shuffle.service.enabled=true \
  --conf spark.kubernetes.shuffle.namespace=default \
  --conf spark.kubernetes.shuffle.labels="app=spark-shuffle-service,spark-version=2.2.0" \
  local:///opt/spark/examples/jars/spark-examples_2.11-2.2.0-k8s-0.4.0.jar 100 4000000 5
```

## TODO

- [ ] more examples
- [ ] perf tests
- [ ] Livy Server
- [ ] Jupyter Server
