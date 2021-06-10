#!/bin/bash

# do not run all at once! demo script
exit 0

AWS_REGION=us-east-1
EKS_CLUSTER=eks-demo-cluster
MY_PWD=PwdForGrafana

# HELM
brew upgrade helm
helm repo add stable https://charts.helm.sh/stable

# PROMETHEUS
kubectl create namespace prometheus
helm install prometheus stable/prometheus \
    --namespace prometheus \
    --set alertmanager.persistentVolume.storageClass="gp2" \
    --set server.persistentVolume.storageClass="gp2"

kubectl get all -n prometheus
kubectl port-forward -n prometheus deploy/prometheus-server 8080:9090 &

# GRAFANA
kubectl create namespace grafana
helm install grafana stable/grafana \
    --namespace grafana \
    --set persistence.storageClassName="gp2" \
    --set persistence.enabled=true \
    --set adminPassword=$MY_PWD \
    --values grafana.yaml \
    --set service.type=LoadBalancer
kubectl get all -n grafana
export GRAFANA_LB=$(kubectl get svc -n grafana grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $GRAFANA_LB
open -a Safari http://$GRAFANA_LB

kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo


