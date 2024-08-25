# Restricting Access To K8s API

## Request Flow

![Request Flow](/.images/11-Request-Flow.png)

User/SA -> Authentication -> Authorization  -> Access Control -> Resource (Created/Updated/Deleted)

* Authentication (Who are you?)
* Authorization (Are you allowed to perform requested action)
* Access Control (Is access control limit reached?)

> Above 3A are components of K8s API Server

## Important Points to Note

* Requests are always tied to any of the below:
    * An anonymous user
    * A user
    * A service account

* Every request must authenticate or it can be treated as an anonymous user

## Security Considerations

* Never allow anonymous access
* Always close insecure port
* Don't expose API Server to the outside
* Restrict access from nodes to API (Node Restriction)
* Prevent unauthorized access (RBAC)
* Prevent pods from accessing APIs
* Restrict API Server Ports behind firewall using IPs allowlist


## Anonymous Access

From k8s 1.6+, anonymous access is enabled by default
* if authorization mode other than AlwaysAllow
* but ABAC (Attribute Based Access Control) and RBAC (Role Based Access Control) requires explicit authorization for anonymous access

### Lab

Aim of the lab is to understand how to enable/disable K8s API server anonymous accesses

* Get shell access into master node in minkube or k8s.

    > for minikube use `minikube ssh sudo su`

* view kube-apiserver config file

    ```bash
    cat /etc/kubernetes/manifests/kube-apiserver.yaml  | grep "authorization-mode"
    #   - --authorization-mode=Node,RBAC
    ```

    > anonymous user cannot access resource since RBAC is enabled. Api server is running on port `8443` inside minikube docker VM 

* Get k8s API server port

    * For exposing minikube api server using below command

        ```bash
        minikube service kubernetes --url
        # http://127.0.0.1:51657
        export PORT=51657
        ```

        > we'll get service url exposed to our localhost. example: `http://127.0.0.1:51657`

    * **K8s** api will be exposed on port `6443`

        ```bash
        export PORT=6443
        ```

* Send request to API server using K8s server

    ```bash
    curl https://localhost:$PORT -k

    # {
    #   "kind": "Status",
    #   "apiVersion": "v1",
    #   "metadata": {},
    #   "status": "Failure",
    #   "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
    #   "reason": "Forbidden",
    #   "details": {},
    #   "code": 403
    # }
    ```

* In order to disable this behavior set `--anonymous-auth=false` in `/etc/kubernetes/manifests/kube-apiserver.yaml` file

    ```yaml
    -- snip --
    spec:
        containers:
        - command:
            - kube-apiserver
            - --anonymous-auth=false
            - --advertise-address=192.168.49.2
    -- snip --
    ```

* Wait for server to reboot

    ```bash
    kubectl -n kube-system get pod | grep api
    ```

* Send anonymous request to API

    ```bash
    curl https://localhost:$PORT -k
    # {
    #   "kind": "Status",
    #   "apiVersion": "v1",
    #   "metadata": {},
    #   "status": "Failure",
    #   "message": "Unauthorized",
    #   "reason": "Unauthorized",
    #   "code": 401
    # }
    ```

## Restricting HTTP Traffic for K8s API

Sometimes K8s API server could be misconfigured to work on HTTP traffic which doesn't validate authn and authz bypassing security controls. Hence, it should be disabled on prod and it is only meant to be used for debug environments.

CLI Option: `--insecure-port=8080`

### Lab 

Aim of the lab is to use insecure HTTP API and revert it as it was

* Get shell access to master node

* Edit API server and add flag in spec to use insecure port (It'll disable authn and authz)

    ```bash
    vim /etc/kubernetes/manifests/kube-apiserver.yaml
    ```

    ```yaml
    -- snip --
    spec:
        containers:
        - command:
            - kube-apiserver
            - --insecure-port=8080
    -- snip --
    ```

    > make sure, you're not using any option that is supposed to be used along with HTTPS/secure port. 

* Let the K8s API server reboot and make request to API server over http

    ```bash
    curl http://localhost:8080
    ```

