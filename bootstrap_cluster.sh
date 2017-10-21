#!/bin/bash

if ! gcloud container clusters describe big-data-demo > /dev/null;
then
    gcloud container clusters create --num-nodes=4 --machine-type=n1-standard-2 big-data-demo
    gcloud container clusters get-credentials big-data-demo
fi

# Allow external traffic needed for uploading own jar files
if ! gcloud compute firewall-rules describe file-stageing > /dev/null;
then
    gcloud compute firewall-rules create file-stageing --allow tcp:31000
fi
