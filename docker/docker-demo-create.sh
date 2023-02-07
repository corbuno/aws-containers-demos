#!/bin/bash

# do not run all at once! demo script
exit 0

DOCKER_IMG=node-web-app

# Browse to base image
open https://hub.docker.com/_/node/

# Browse to npm dependency
open https://www.npmjs.com/package/express

# Build image
docker build -t $DOCKER_IMG .
docker images

# inspect
docker inspect $DOCKER_IMG

# find vulnerabilities with Snyk and learn how to fix them
docker scan $DOCKER_IMG

# Run container
docker container run -d -p 49160:8080 $DOCKER_IMG
docker container ps -a --no-trunc

open http://localhost:49160

# get container identifier
CONTAINER_ID=`docker ps --filter ancestor=$DOCKER_IMG --format {{.ID}}`
echo "Container ID: " $CONTAINER_ID

# Port
docker container port $CONTAINER_ID

# Check logs
docker container logs $CONTAINER_ID

# Check processes
docker container exec -it $CONTAINER_ID ps aux

# Enter the container (type "exit" to exit)
docker container exec -it $CONTAINER_ID sh
