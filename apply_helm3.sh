#!/bin/bash

export LOCATION=$1
export HELMFILE_HELM3='True'
echo 'Set kube context ', $1
kubectl config set-context $1

echo "Last chance. Helm3 will start in 5 sec"
sleep 5

echo "Run helm file" ${@:2:99}

helmfile --helm-binary helm3 ${@:2:99} | tee helm_run.log