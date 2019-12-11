#!/bin/bash

export LOCATION=$1

echo 'Set kube context ', $1
kubectl config set-context $1

rm **/Chart.lock
rm **/requirements.lock

for value in $(helmfile list | sed '/NAME/d;' | cut -f 1)
do
    echo 'Migrating' $value
    helm3 2to3 convert $value --tiller-out-cluster --release-storage configmaps
done
