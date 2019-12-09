#!/bin/bash

TILLER_PORT=44534
export LOCATION=$1
echo 'Set kube context ', $1
kubectl config use-context $1
kubectl config set-context $1 --namespace=default
# Validate it

export HELM_HOST=localhost:$TILLER_PORT

echo "Kill all running tiller instances"
killall -9 tiller

echo 'Start tiller'
tiller -listen localhost:$TILLER_PORT  &
TILLER_PID=$!
sleep 5

echo "Run helm file" ${@:2:99}

helmfile ${@:2:99} | tee helm_run.log

echo 'Kill tiller that we have started'
kill -9 $TILLER_PID