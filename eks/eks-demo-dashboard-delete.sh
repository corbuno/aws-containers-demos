#!/bin/bash

# do not run all at once! demo script
exit 0

# based on https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html

AWS_REGION=us-east-1
EKS_CLUSTER=eks-demo-cluster

# kill proxy
lsof -t -i:8001
kill -9 $(lsof -t -i:8001)
