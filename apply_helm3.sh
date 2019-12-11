#!/bin/bash

export LOCATION=$1
export HELMFILE_HELM3='1'
echo 'Set kube context ', $1
kubectl config use-context $1

echo "Last chance. Helm3 will start in 3 sec"
sleep 3

echo "Run helm file" ${@:2:99}

helmfile --log-level error --helm-binary helm3 ${@:2:99} | tee helm_run.log