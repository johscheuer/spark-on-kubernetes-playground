#!/bin/bash

if [[ ! -d repos/spark-2.2.0-k8s-0.4.0-bin-2.7.3 ]];
then
# Fetch latest Kubernetes Spark release
  curl -sLO https://github.com/apache-spark-on-k8s/spark/releases/download/v2.2.0-kubernetes-0.4.0/spark-2.2.0-k8s-0.4.0-bin-with-hadoop-2.7.3.tgz
  tar xfz spark-2.2.0-k8s-0.4.0-bin-with-hadoop-2.7.3.tgz -C repos
  rm spark-2.2.0-k8s-0.4.0-bin-with-hadoop-2.7.3.tgz
fi
# Get Spark terrasort and Terragen
if [[ ! -d repos/spark-terasort ]];
then
  git clone https://github.com/ehiggs/spark-terasort.git repos/spark-terasort
  cd repos/spark-terasort
  mvn install
  cd ..
fi

cd repos/spark-2.2.0-k8s-0.4.0-bin-2.7.3
kubectl apply -f conf/kubernetes-resource-staging-server.yaml

