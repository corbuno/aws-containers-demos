#!/bin/bash

# do not run all at once! demo script
exit 0

AWS_REGION=us-east-1
DOCKER_IMG=frontend
ECR_REPO=$DOCKER_IMG

# Browse to base image
open https://hub.docker.com/_/rust/

# build image and run container
docker build -t $DOCKER_IMG:01 .
docker images -a

# (optional) run locally
docker run -d -p 49161:8080 --name=$DOCKER_IMG $DOCKER_IMG:01
docker ps -a
open http://localhost:49161

# create repo on ECR
aws ecr create-repository --region=$AWS_REGION --repository-name=$ECR_REPO

# get full repo name from ECR: <account>.dkr.ecr.<region>.amazonaws.com/<repo>:<version>
QUERY=repositories[?repositoryName==\`$ECR_REPO\`].repositoryUri
IMG_URI=$(aws ecr describe-repositories --region=$AWS_REGION --query=$QUERY --output=text):01
echo $IMG_URI

# login to ecr
ECR_URI=`echo $IMG_URI | sed 's|/.*||'`
echo $ECR_URI
aws ecr get-login-password --region=$AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

# tag, login and push to ECR repo
docker tag $DOCKER_IMG:01 $IMG_URI
docker push $IMG_URI
open -a Safari https://$AWS_REGION.console.aws.amazon.com/ecr/repositories?region=$AWS_REGION
