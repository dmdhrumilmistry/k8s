## Download file and compare its hash value

* Download File

    ```bash
    wget https://dl.k8s.io/v1.27.16/kubernetes-server-linux-amd64.tar.gz -O k8s-server.tar.gz
    ```

* Verify Hash

    ```bash
    echo "cbcb0591a3a84f98cf2c7abe11c5531e7f79850714abdd957be52049afed14031d0ab9c584c2e54775bceedf8833a500148d5d01335474b33cbb8b30b7ce51b3 k8s-server.tar.gz" | sha512sum --check
    ```

    > hashes can be retrieved from release [changelogs.md](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.27.md#server-binaries) file

## Compare Binaries

Kube api server and other kube binaries doesn't have shell installed in their container images. But we can map process id and get binary hash for comparision


## For Minikube

Below section is only meant for minikube k8s cluster

### Get SHA512 Kube API Server Binary From Release

* Get Release Version

    ```bash
    k get -n kube-system pod | grep api

    # kube-apiserver-minikube                    1/1     Running   9 (44h ago)    8d
    ```

* Get K8s deployment version

    ```bash
    k get -n kube-system pod kube-apiserver-minikube -o yaml | grep image

    # Output
    # image: registry.k8s.io/kube-apiserver:v1.28.3
    # imagePullPolicy: IfNotPresent
    # image: registry.k8s.io/kube-apiserver:v1.28.3
    # imageID: docker-pullable://registry.k8s.io/ kube-apiserver@sha256:8db46adefb0f251da210504e2ce268c36a5a7c630667418ea4601f63c9057a2d
    ```

    > K8s api server is using `v1.28.3`

* Download server release `v1.28.3` from [releases](https://github.com/kubernetes/kubernetes/releases/v1.28.3) config.md file for [arm](https://dl.k8s.io/v1.28.12/kubernetes-server-linux-arm64.tar.gz)

    ```bash
    wget https://dl.k8s.io/v1.28.12/kubernetes-server-linux-arm64.tar.gz -O k8s-server.tar.gz
    ```

* Untar downloaded file

    ```bash
    tar -vxf kubernetes-server-linux-arm64.tar.gz
    ```

* Calculate sha512 for `kube-apiserver` binary

    ```bash
    sha512sum kubernetes/server/bin/kube-apiserver 

    # Output
    # 154edeb7deb7e7559a8c63c26bd39e6c67b666515e5607bba55756ea1f06801a77e1ddb1ad6a4049e5156e9cdbb1d742f5b5a78159d4839b1aec9dc8176928e8  kubernetes/server/bin/kube-apiserver
    ```

### Get SHA512 for Kube API Server Binary Running Inside The Container

* Get access to shell inside minikube server

    ```bash
    docker ps 
    docker exec -it <minikube-server-container-id> /bin/bash
    ```

    > on Host machine

* Get container entrypoint binary from docker ps command

    ```bash
    docker ps --no-trunc | grep apiserver
    
    # Output:
    # kube-apiserver
    ```

    > Run this and all below commands inside minikube server container

* Get PID for `kube-apiserver`

    ```bash
    ps aux | awk '{ print $2 $11}' |  grep kube-apiserver
    
    # Output:
    # 2051kube-apiserver
    ```

* Find `kube-apiserver` executable

    ```bash
    find /proc/2051/root/ | grep kube-api

    # Output:
    # /proc/2051/root/usr/local/bin/kube-apiserver
    ```

* Calculate sha512 for `/proc/2051/root/usr/local/bin/kube-apiserver` file

    ```bash
    sha512sum /proc/2051/root/usr/local/bin/kube-apiserver
    
    # Output
    # 154edeb7deb7e7559a8c63c26bd39e6c67b666515e5607bba55756ea1f06801a77e1ddb1ad6a4049e5156e9cdbb1d742f5b5a78159d4839b1aec9dc8176928e8 /proc/2051/root/usr/local/bin/kube-apiserver
    ```