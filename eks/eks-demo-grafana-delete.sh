#!/bin/bash

# kill proxy
lsof -t -i:8080
kill -9 $(lsof -t -i:8080)

# cleanup
helm uninstall prometheus --namespace prometheus
helm uninstall grafana --namespace grafana
