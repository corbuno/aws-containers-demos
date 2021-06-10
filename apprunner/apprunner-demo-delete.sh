#!/bin/bash

AWS_REGION=us-east-1
DOCKER_IMG=frontend
SERVICE_NAME=$DOCKER_IMG

# delete App Runner service
AR_SERVICES=$(aws apprunner list-services --query='ServiceSummaryList[].ServiceArn' --output text)
for SERVICE in $( echo "$AR_SERVICES" ); do
    if [[ "$SERVICE" == *"$SERVICE_NAME"* ]]; then
      echo Service $SERVICE is being deleted...
      aws apprunner delete-service --region $AWS_REGION --service-arn $SERVICE
    fi
done
