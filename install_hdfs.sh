#!/bin/bash
echo "Install Helm"
helm init --upgrade > /dev/null


# TODO pin it
if [[ ! -d repos/kubernetes-HDFS ]];
then
    echo "Clone Repo"
    git clone https://github.com/apache-spark-on-k8s/kubernetes-HDFS.git repos/kubernetes-HDFS
fi

while [[ $(kubectl -n kube-system get deployment tiller-deploy -o json | jq '.status.availableReplicas') -ne 1 ]];
do
    sleep 1
    echo "Wait for Tiller to come up"
done

if ! kubectl get nodes -o json | jq -j '.items[0].metadata.labels' | grep hdfs-namenode-selector > /dev/null;
then
    # Label node
    kubectl label nodes $(kubectl get nodes -o json | jq -j '.items[0].metadata.name') hdfs-namenode-selector=hdfs-namenode-0
fi

if ! helm status hdfs-namenode > /dev/null;
then
    # Install the namenode
    helm install --wait -n hdfs-namenode --set nameNodeHostPath=/var/tmp/hdfs-name repos/kubernetes-HDFS/charts/hdfs-namenode-k8s
fi

if ! helm status hdfs-datanode > /dev/null;
then
    # Install the data nodes
    helm install --wait -n hdfs-datanode --set dataNodeHostPath="{/var/tmp/hdfs-data}" repos/kubernetes-HDFS/charts/hdfs-datanode-k8s
fi

# Check Status
kubectl exec hdfs-namenode-0 -- hdfs dfsadmin -report
