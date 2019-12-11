#Migrating helmfile managed charts from helm2 to helm3

We have 26 helm charts deployed to 6 kube clusters.
We use [helmfile](https://github.com/roboll/helmfile) to manage all the charts.


Recently Helm3 was released and i was tasked to migrate our helm charts from helm2 to helm3.
Ive created small helmfile solution to test migration.Ill be using it to demonstrate the migration

you can get it at github

    git clone git@github.com:wix-playground/helm3diff.git
    cd helm3diff
    
#### 0. Versions, versions...
   Be very carefull with versions of software you are using, i did few tries and found out that this one is working. 
   
    helm2 version v2.16.1
    helm3 version v3.0.0
    helmfile version v0.94.1
    kube-server version v1.15.6
    helm-diff version  v3.0.0-rc.7
    2to3 version 0.2.1
#### 1. We need to run in parallel on helm2 and helm3
   Its still working clusters so i need to be able to use helm2 and helm3 in parallel.So ive installed helm3 as separate executable in my /usr/local/bin/
    
    wget https://get.helm.sh/helm-v3.0.0-darwin-amd64.tar.gz
    tar -zxvf helm-v3.0.0-darwin-amd64.tar.gz
    sudo mv darwin-amd64/helm /usr/local/bin/helm3
    
   Dont do brew upgrade install it manually
#### 2. We will need plugins. 
   All the data ive found says i need to migrate helm2 configuration to helm3 configuration and it will be fine. Ive tried several times it was not sucessfull.Plugins where not migrated properly
   In my case ive removed all plugins using ```helm plugin remove <plugin_name>``` and ```helm3 plugin remove <plugin_name```
   And than ive installed 2 plugins   ```2to3``` and ```helm-diff``` fro both helm and helm3 seaprately
   
    helm plugin install https://github.com/helm/helm-2to3
    helm plugin install https://github.com/databus23/helm-diff --version v3.0.0-rc.7
    helm3 plugin install https://github.com/helm/helm-2to3
    helm3 plugin install https://github.com/databus23/helm-diff --version v3.0.0-rc.7

   check your plugins installation <br>
   
    ```
    >helm plugin list
    NAME	VERSION   	DESCRIPTION
    2to3	0.2.1     	migrate and cleanup Helm v2 configuration and releases in-place to Helm v3
    diff	3.0.0-rc.7	Preview helm upgrade changes as a diff
    >helm3 plugin list
    NAME	VERSION   	DESCRIPTION
    2to3	0.2.1     	migrate and cleanup Helm v2 configuration and releases in-place to Helm v3
    diff	3.0.0-rc.7	Preview helm upgrade changes as a diff
    ```
##### 3. Move configuration
   We still need to move helm2 configuration to helm3 since it contains information about helm cache
   
    
    helm3 2to3 move config
    
#### 4. Few words about helmfile execution.
   Helm2 used to have tiller service that we have chosen not to install into cluster but use it client side only.
   So ive created little bash script to run it.<br> 
   apply_helm.sh:
    
    
    #!/bin/bash
    
    TILLER_PORT=44534
    export LOCATION=$1
    echo 'Set kube context ', $1
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
    
    
   im using it like that  
    
    ./apply_helm.sh tbd diff
    ./apply_helm.sh tbd sync
    ./apply_helm.sh tbd template
    ./apply_helm.sh tbd delete --purge
    
   where *tbd* is the context of my kubernetes cluster.

#### 5. Deploy some helm2 charts
    >./apply_helm.sh tbd sync
    Switched to context "tbd".
    Context "tbd" modified.
    Kill all running tiller instances
    No matching processes belonging to you were found
    Start tiller
    [main] 2019/12/11 17:23:53 Starting Tiller v2.16.1 (tls=false)
    [main] 2019/12/11 17:23:53 GRPC listening on localhost:44534
    [main] 2019/12/11 17:23:53 Probes listening on :44135
    [main] 2019/12/11 17:23:53 Storage driver is ConfigMap
    [main] 2019/12/11 17:23:53 Max history per release is 0
    Run helm file diff    
    Updating repo
    Hang tight while we grab the latest from your chart repositories...
    ...Successfully got an update from the "incubator" chart repository
    ...Successfully got an update from the "stable" chart repository
    Update Complete.
    
    Building dependency release=simple-cm, chart=simple-cm
    No requirements found in simple-cm/charts.
    
    Comparing release=chaoskube, chart=stable/chaoskube
    Comparing release=simple-cm, chart=simple-cm
    [storage] 2019/12/11 17:24:01 getting last revision of "simple-cm"
    [storage] 2019/12/11 17:24:01 getting release history for "simple-cm"
    [tiller] 2019/12/11 17:24:02 preparing install for simple-cm
    [storage] 2019/12/11 17:24:02 getting release history for "simple-cm"
    [storage] 2019/12/11 17:24:03 getting last revision of "chaoskube"
    [storage] 2019/12/11 17:24:03 getting release history for "chaoskube"
    [tiller] 2019/12/11 17:24:03 preparing install for chaoskube
    [storage] 2019/12/11 17:24:03 getting release history for "chaoskube"
    [tiller] 2019/12/11 17:24:03 rendering simple-cm chart using values
    [tiller] 2019/12/11 17:24:03 performing install for simple-cm
    [tiller] 2019/12/11 17:24:03 dry run for simple-cm
    [tiller] 2019/12/11 17:24:04 rendering chaoskube chart using values
    2019/12/11 17:24:04 info: manifest "chaoskube/templates/servicemonitor.yaml" is empty. Skipping.
    2019/12/11 17:24:04 info: manifest "chaoskube/templates/serviceaccount.yaml" is empty. Skipping.
    2019/12/11 17:24:04 info: manifest "chaoskube/templates/rolebinding.yaml" is empty. Skipping.
    2019/12/11 17:24:04 info: manifest "chaoskube/templates/clusterrolebinding.yaml" is empty. Skipping.
    2019/12/11 17:24:04 info: manifest "chaoskube/templates/clusterrole.yaml" is empty. Skipping.
    2019/12/11 17:24:04 info: manifest "chaoskube/templates/service.yaml" is empty. Skipping.
    2019/12/11 17:24:04 info: manifest "chaoskube/templates/role.yaml" is empty. Skipping.
    [tiller] 2019/12/11 17:24:04 performing install for chaoskube
    [tiller] 2019/12/11 17:24:04 dry run for chaoskube
    ********************
    
        Release was not present in Helm.  Diff will show entire contents as new.
    
    ********************
    sandbox, simple-cm, ConfigMap (v1) has been added:
    + # Source: simple-cm/templates/simple-config-map.yaml
    + apiVersion: v1
    + kind: ConfigMap
    + metadata:
    +   name: simple-cm
    
    + data:
    +   field1: filed1value
    +   field2: somevalue
    
    ********************
    
        Release was not present in Helm.  Diff will show entire contents as new.
    
    ********************
    sandbox, chaoskube, Deployment (apps) has been added:
    -
    + # Source: chaoskube/templates/deployment.yaml
    + apiVersion: apps/v1beta1
    + kind: Deployment
    + metadata:
    +   name: chaoskube
    +   labels:
    +     app.kubernetes.io/name: chaoskube
    +     app.kubernetes.io/managed-by: "Tiller"
    +     app.kubernetes.io/instance: "chaoskube"
    +     helm.sh/chart: chaoskube-3.1.3
    + spec:
    +   replicas: 1
    +   selector:
    +     matchLabels:
    +       app.kubernetes.io/name: chaoskube
    +       app.kubernetes.io/instance: chaoskube
    +   template:
    +     metadata:
    +       labels:
    +         app.kubernetes.io/name: chaoskube
    +         app.kubernetes.io/managed-by: "Tiller"
    +         app.kubernetes.io/instance: "chaoskube"
    +         helm.sh/chart: chaoskube-3.1.3
    +     spec:
    +       containers:
    +         - name: chaoskube
    +           image: quay.io/linki/chaoskube:v0.14.0
    +           args:
    +             - --interval=10m
    +             - --labels=
    +             - --annotations=
    +             - --namespaces=sandbox
    +             - --excluded-weekdays=
    +             - --excluded-times-of-day=
    +             - --excluded-days-of-year=
    +             - --timezone=UTC
    +             - --minimum-age=0s
    +             - --grace-period=-1s
    +             - --metrics-address=
    +           resources:
    +             {}
    +
    +           securityContext:
    +             runAsNonRoot: true
    +             runAsUser: 65534
    +             readOnlyRootFilesystem: true
    +             capabilities:
    +               drop: ["ALL"]
    +       serviceAccountName: "default"
    
    Kill tiller that we have started

#### 6. Check that helm2 still works after plugin manipulations    
    >./apply_helm.sh tbd diff
    Switched to context "tbd".
    Context "tbd" modified.
    Kill all running tiller instances
    No matching processes belonging to you were found
    Start tiller
    [main] 2019/12/11 17:26:45 Starting Tiller v2.16.1 (tls=false)
    [main] 2019/12/11 17:26:45 GRPC listening on localhost:44534
    [main] 2019/12/11 17:26:45 Probes listening on :44135
    [main] 2019/12/11 17:26:45 Storage driver is ConfigMap
    [main] 2019/12/11 17:26:45 Max history per release is 0
    Run helm file diff
    Building dependency release=simple-cm, chart=simple-cm
    No requirements found in simple-cm/charts.
    
    Comparing release=simple-cm, chart=simple-cm
    Comparing release=chaoskube, chart=stable/chaoskube
    [storage] 2019/12/11 17:26:50 getting last revision of "simple-cm"
    [storage] 2019/12/11 17:26:50 getting release history for "simple-cm"
    [tiller] 2019/12/11 17:26:51 preparing update for simple-cm
    [storage] 2019/12/11 17:26:51 getting deployed releases from "simple-cm" history
    [tiller] 2019/12/11 17:26:51 resetting values to the chart's original version
    [storage] 2019/12/11 17:26:51 getting last revision of "simple-cm"
    [storage] 2019/12/11 17:26:51 getting release history for "simple-cm"
    [storage] 2019/12/11 17:26:51 getting last revision of "chaoskube"
    [storage] 2019/12/11 17:26:51 getting release history for "chaoskube"
    [tiller] 2019/12/11 17:26:52 preparing update for chaoskube
    [storage] 2019/12/11 17:26:52 getting deployed releases from "chaoskube" history
    [tiller] 2019/12/11 17:26:52 resetting values to the chart's original version
    [storage] 2019/12/11 17:26:52 getting last revision of "chaoskube"
    [storage] 2019/12/11 17:26:52 getting release history for "chaoskube"
    [tiller] 2019/12/11 17:26:52 rendering simple-cm chart using values
    [tiller] 2019/12/11 17:26:52 performing update for simple-cm
    [tiller] 2019/12/11 17:26:52 dry run for simple-cm
    [tiller] 2019/12/11 17:26:53 rendering chaoskube chart using values
    2019/12/11 17:26:53 info: manifest "chaoskube/templates/clusterrolebinding.yaml" is empty. Skipping.
    2019/12/11 17:26:53 info: manifest "chaoskube/templates/servicemonitor.yaml" is empty. Skipping.
    2019/12/11 17:26:53 info: manifest "chaoskube/templates/service.yaml" is empty. Skipping.
    2019/12/11 17:26:53 info: manifest "chaoskube/templates/role.yaml" is empty. Skipping.
    2019/12/11 17:26:53 info: manifest "chaoskube/templates/serviceaccount.yaml" is empty. Skipping.
    2019/12/11 17:26:53 info: manifest "chaoskube/templates/rolebinding.yaml" is empty. Skipping.
    2019/12/11 17:26:53 info: manifest "chaoskube/templates/clusterrole.yaml" is empty. Skipping.
    [tiller] 2019/12/11 17:26:53 performing update for chaoskube
    [tiller] 2019/12/11 17:26:53 dry run for chaoskube
    Kill tiller that we have started
    ```
    If diff reports differences run ```./apply_helm.sh tbd sync
    
   Its very important to have fully synced charts before migration.
#### 7. Migrate releases from helm2 to helm3
Migration was tricky helm3 complained a lot 
 - about not finding helm 2 releases 
 - about not having tiller
 - and after migration was done lock files where problematic, 
 - and you need to have LOCATION env var. i was forgeting it every time
   
   So this is the script ive ended up with:
   migrate_to_helm3.sh
```
    #!/bin/bash
    
    export LOCATION=$1
    
    echo 'Set kube context ', $1
    kubectl config use-context $1
    
    rm **/Chart.lock
    rm **/requirements.lock
    
    for value in $(helmfile list | sed '/NAME/d;' | cut -f 1)
    do
        echo 'Migrating' $value
        helm3 2to3 convert $value --tiller-out-cluster --release-storage configmaps
    done
```

   Run this script like that
   

    >./migrate_to_helm3.sh tbd
    Set kube context , tbd
    Switched to context "tbd".
    Context "tbd" modified.
    rm: **/Chart.lock: No such file or directory
    rm: **/requirements.lock: No such file or directory
    Migrating simple-cm
    2019/12/11 17:38:07 Release "simple-cm" will be converted from Helm v2 to Helm v3.
    2019/12/11 17:38:07 [Helm 3] Release "simple-cm" will be created.
    2019/12/11 17:38:08 [Helm 3] ReleaseVersion "simple-cm.v1" will be created.
    2019/12/11 17:38:08 [Helm 3] ReleaseVersion "simple-cm.v1" created.
    2019/12/11 17:38:08 [Helm 3] Release "simple-cm" created.
    2019/12/11 17:38:08 Release "simple-cm" was converted successfully from Helm v2 to Helm v3.
    2019/12/11 17:38:08 Note: The v2 release information still remains and should be removed to avoid conflicts with the migrated v3 release.
    2019/12/11 17:38:08 v2 release information should only be removed using `helm 2to3` cleanup and when all releases have been migrated over.
    Migrating chaoskube
    2019/12/11 17:38:08 Release "chaoskube" will be converted from Helm v2 to Helm v3.
    2019/12/11 17:38:08 [Helm 3] Release "chaoskube" will be created.
    2019/12/11 17:38:09 [Helm 3] ReleaseVersion "chaoskube.v1" will be created.
    2019/12/11 17:38:09 [Helm 3] ReleaseVersion "chaoskube.v1" created.
    2019/12/11 17:38:09 [Helm 3] Release "chaoskube" created.
    2019/12/11 17:38:09 Release "chaoskube" was converted successfully from Helm v2 to Helm v3.
    2019/12/11 17:38:09 Note: The v2 release information still remains and should be removed to avoid conflicts with the migrated v3 release.
    2019/12/11 17:38:09 v2 release information should only be removed using `helm 2to3` cleanup and when all releases have been migrated over.
    
#### 8. Lets go to helm3
   I want to be as close to usage of helm2 as i can. So ive created similar file to execute helmfile with helm3
   
   apply_helm3.sh
   
    #!/bin/bash
    export LOCATION=$1
    export HELMFILE_HELM3='1'
    echo 'Set kube context ', $1
    kubectl config use-context $1
    
    echo "Last chance. Helm3 will start in 3 sec"
    sleep 3
    
    echo "Run helm file" ${@:2:99}
    
    helmfile --helm-binary helm3 ${@:2:99} | tee helm_run.log
   So if i want to see diffs with helm3 releases i run
   
    >./apply_helm tbd diff
    Set kube context , tbd
    Switched to context "tbd".
    Last chance. Helm3 will start in 3 sec
    Run helm file diff
    sandbox, chaoskube, Deployment (apps) has changed:
      # Source: chaoskube/templates/deployment.yaml
      apiVersion: apps/v1beta1
      kind: Deployment
      metadata:
        name: chaoskube
        labels:
          app.kubernetes.io/name: chaoskube
    -     app.kubernetes.io/managed-by: "Tiller"
    +     app.kubernetes.io/managed-by: "Helm"
          app.kubernetes.io/instance: "chaoskube"
          helm.sh/chart: chaoskube-3.1.3
      spec:
        replicas: 1
        selector:
          matchLabels:
            app.kubernetes.io/name: chaoskube
            app.kubernetes.io/instance: chaoskube
        template:
          metadata:
            labels:
              app.kubernetes.io/name: chaoskube
    -         app.kubernetes.io/managed-by: "Tiller"
    +         app.kubernetes.io/managed-by: "Helm"
              app.kubernetes.io/instance: "chaoskube"
              helm.sh/chart: chaoskube-3.1.3
          spec:
            containers:
              - name: chaoskube
                image: quay.io/linki/chaoskube:v0.14.0
                args:
                  - --interval=10m
                  - --labels=
                  - --annotations=
                  - --namespaces=sandbox
                  - --excluded-weekdays=
                  - --excluded-times-of-day=
                  - --excluded-days-of-year=
                  - --timezone=UTC
                  - --minimum-age=0s
                  - --grace-period=-1s
                  - --metrics-address=
                resources:
                  {}
    -
                securityContext:
                  runAsNonRoot: true
                  runAsUser: 65534
                  readOnlyRootFilesystem: true
                  capabilities:
                    drop: ["ALL"]
            serviceAccountName: "default"
   Sure enough since we dont have Tiller anymore our charts are managed by Helm
   So change in  ```app.kubernetes.io/managed-by``` label makes sense.<br>
   Lets sync our releases
   
    >./apply_helm tbd sync    
      Set kube context , tbd
    Switched to context "tbd".
    Last chance. Helm3 will start in 3 sec
    Run helm file sync
    Release "simple-cm" has been upgraded. Happy Helming!
    NAME: simple-cm
    LAST DEPLOYED: Wed Dec 11 18:08:00 2019
    NAMESPACE: sandbox
    STATUS: deployed
    REVISION: 2
    TEST SUITE: None
    
    simple-cm	sandbox  	2       	2019-12-11 18:08:00.31019 +0200 IST	deployed	simple-cm-0.1.1	1.0
    
    Release "chaoskube" has been upgraded. Happy Helming!
    NAME: chaoskube
    LAST DEPLOYED: Wed Dec 11 18:08:01 2019
    NAMESPACE: sandbox
    STATUS: deployed
    REVISION: 2
    TEST SUITE: None
    NOTES:
    chaoskube is running and will kill arbitrary pods every 10m.
    
    You can follow the logs to see what chaoskube does:
    
        POD=$(kubectl -n sandbox get pods -l='app.kubernetes.io/instance=chaoskube' --output=jsonpath='{.items[0].metadata.name}')
        kubectl -n sandbox logs -f $POD
    
    You are running in dry-run mode. No pod is actually terminated.
    
    chaoskube	sandbox  	2       	2019-12-11 18:08:01.459229 +0200 IST	deployed	chaoskube-3.1.3	0.14.0
    
#### 9. Check that everything is ok
    
    ./apply_helm3.sh tbd diff
    Set kube context , tbd
    Switched to context "tbd".
    Last chance. Helm3 will start in 3 sec
    Run helm file diff
   No diffs. Everything is ok.
   
    >helm3 list -n sandbox
    NAME     	NAMESPACE	REVISION	UPDATED                             	STATUS  	CHART          	APP VERSION
    chaoskube	sandbox  	2       	2019-12-11 18:08:01.459229 +0200 IST	deployed	chaoskube-3.1.3	0.14.0
    simple-cm	sandbox  	2       	2019-12-11 18:08:00.31019 +0200 IST 	deployed	simple-cm-0.1.1	1.0 
   All cool here too.
   
#### 10. What about cleanup.
   We can remove old helm2 releases from kube cluster using *2to3* helm plugin, but i wanted to hold on to them in case of problems.
    

#### 11. Its not all good
   I still had problem with one of actual charts. [cert-manager](https://github.com/jetstack/cert-manager)
   It would not sync properly at the first time with helm3. I needed to redeploy it.All other charts where migrated without actuall pods restarting.
    

 