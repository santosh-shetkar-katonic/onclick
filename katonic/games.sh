#!/bin/bash
kubectl create deployment mario --image=docker.io/pengbai/docker-supermario
kubectl expose deployment mario --port=8080 --type=NodePort

kubectl create deployment car --image=docker.io/playpalash/car-racing:01
kubectl expose deployment car --port=8181 --type=NodePort
