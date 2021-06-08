#!/bin/bash

DOCKER_IMG=node-web-app
CONTAINER_ID=`docker ps --filter ancestor=$DOCKER_IMG --format {{.ID}}`

echo "Container ID: " $CONTAINER_ID

# Cleanup container
docker container stop $CONTAINER_ID
docker container rm $CONTAINER_ID

# Cleanup image
docker image rm $DOCKER_IMG 
