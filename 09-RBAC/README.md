# Role Based Access Control (RBAC)

* In this approach permissions are provided to users/service accounts(SA) based on their roles. They're only provided necessary permissions as required i.e. whitelisting approach, everything is else is denied by default. Hence, it implements principle of least privilege (POLP).
* Restrict resources to K8s when accessed by users/SA. It works with roles and bindings.
* `kube-apiserver` binary uses `--authorization-mode` argument for using `RBAC` mode.

## K8s Resource Segregation - Namespaced Based Resources

|Name|Command|
|:--:|:------|
|Namespaced Resource|`kubectl api-resources --namespaced=true`|
|Non-Namespaced Resource|`kubectl api-resources --namespaced=false`|

## K8s Permissions - Where are the permissions available?

|Resource Type|Permission Type|Permission Scope Available In|
|:-----------:|:-------------:|:----------------------------|
|NameSpaced|Role|One namespace|
|Non NameSpaced|Cluster Role|All namespaces + non namespaced|

It defines set of permissions such as:
* can edit pods
* can read secrets


### Permissions Binding - Where are the permissions applied?

Binds set for permissions to a role/cluster.

|Bind Type|Applied To|Binding Scope Available In|
|:-------:|:--------:|:-------------------------|
|RoleBinding|Role|One Namespace|
|ClusterRoleBinding|Cluster Role|All namespaces + non namespaced|

Who gets a set of permission
* bind role/cluster role to something

We should use cluster roles with cluster binding carefully as it'll be applied automatically to all old, new and non namespaces.

Permissions applied are additive

### K8s Permission and Permission Binding Permission

|Combination Type|Permission Type|Binding Type|Description|
|:--------------:|:-------------:|:----------:|:----------|
|Role Binding|Role|Role Binding|User has permission in single namespace|
|Cluster Role Binding|Cluster Role|Cluster Role Binding|User has permission in mutiple and non namespaces|
|Role Binding|Cluster Role| Role Binding|User has same permission in multiple namespaces|

## Test Rules

⚠️ Always test RBAC rules to minimize attack surface and follow POLP using below command:

```bash
k auth can-i --list
```

## Lab 1

* Create namespaces `red` and `blue`
* User `jane` can only `get` *secrets* in namespace `red`
* User `jane` can only `get` and `list` *secrets* in namespace `blue`
* Test it using `auth can-i`

## Lab 2

* Create a ClusterRole `deploy-deleter` which allows to delete deployments
* User `jane` can `delete` deployments in all namespaces
* User `jim` can `delete` deployments only in namespace red
* Test using `auth can-i`

### Create Resources

* Create resources associated with this lab

    ```bash
    make apply
    ```

### Test Permissions

#### Lab 1 Tests

* Tests for Red Namespace

    ```bash
    k -n red auth can-i get secrets --as jane # yes
    k -n red auth can-i list secrets --as jane # no
    k -n red auth can-i delete secrets --as jane # no
    ```

* Tests for Blue Namepsace

    ```bash
    k -n blue auth can-i get secrets --as jane # yes
    k -n blue auth can-i list secrets --as jane # yes
    k -n blue auth can-i delete secrets --as jane # no
    ```

#### Automated Tests for Both Labs

```bash
make test
```

### Destroy Resources

* Delete all resources associated with this lab

    ```bash
    make destroy
    ```


### Troubleshoot Permissions

* Check All Bindings

    ```bash
    kubectl get clusterrolebinding -o wide | grep jim
    kubectl get rolebinding -A -o wide | grep jim
    ```

* Verify Role and ClusterRole Permissions:

    ```bash
    kubectl describe clusterrole deploy-deleter
    kubectl describe rolebinding deploy-deleter -n lab2-red
    ```

## Accounts

### Service Account

* Used by k8s resources

### Normal User

* K8s User resource is absent and it is assumed cluster independent service manages normal user such as AWS, GCP, etc.

* User is identified based on the signed certificate and key
    * Certificate is signed by cluster's CA (Certificate Authority)
    * username is stored under CN (Common Name, eg. /CN=jim)


* In oder to create signed certificate and key, we need to create a certificate signing request (CSR) using openssl which in turn is attached to K8s CSR resource making call to API, which later updates the CSR resource and provides signed certificate and key.

    ![CSR Flow](/.images/09-CSR.png)

    > In order to sign certificate, we only need access to CA, but API was introduced in order to streamline the process of managing and securing certificates.

* If user certificate has been leaked then we only have below options to revoke certificate:
    * Remove user/username using RBAC and it can't be used until certificate expires
    * Create new CA and re-issue all certificates


### Lab 3

#### Steps Overview

* Create CSR for user `jane` (using key)
* Sign CSR using k8s API
* Use Cert + Key to connect to K8s API

### Actual Steps

* Create OpenSSL Key

    ```bash
    openssl genrsa -out jane.key 2048
    ```

* Create CSR

    ```bash
    openssl req -new -key jane.key -out jane.csr

    # for CNAME enter username: `jane`
    ```

* Create CSR resource for K8s

    ```yaml
    apiVersion: certificates.k8s.io/v1
    kind: CertificateSigningRequest
    metadata:
    name: jane
    spec:
        request: somebase64encodedcontent # base64 of jane.csr file
        signerName: kubernetes.io/kube-apiserver-client
        expirationSeconds: 86400  # one day
        usages:
            - client auth
    ```

    > update `request`

* Create CSR request to K8s API

    ```bash
    k apply -f csr.yml
    ```

* View CSR request

    ```bash
    k get csr
    # NAME   AGE   SIGNERNAME                            REQUESTOR       # REQUESTEDDURATION   CONDITION
    # jane   46s   kubernetes.io/kube-apiserver-client   minikube-user   24h                 Pending
    ```

* Approve certificate

    ```bash
    k certificate approve jane
    ```

* View certificate from K8s CSR resource

    ```bash
    k get csr jane -o yaml
    ```

    > certificate is stored in `status.certificate`

* Store certificate for authentication

    ```bash
    k get csr jane -o yaml | grep "certificate:" | awk '{print $2}' | base64 -d > jane.crt
    ```

    > certificate will be stored as `jane.crt` which can be used for authentication along with the key.

* Configure `jane` user in k8s config

    ```bash
    k config set-credentials jane --client-key=jane.key --client-certificate=jane.crt
    ```

* View details

    ```bash
    k config view
    ```

* Create and use context for using `jane` user credentials

    ```bash
    k config set-context jane --user=jane --cluster=minikube # for k8s use: kubernetes

    k config use-context jane

    k config get-contexts
    ```

* get secrets from blue namespace using jane

    ```bash
    k get secrets -n blue
    ```

* Check other permissions as per our previous labs

    ```bash
    k auth can-i delete deployment -A # yes
    k auth can-i delete pod -A # no
    ```

* Repeat same for user `jim`


## Resources

* [K8s RBAC Docs](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
* [K8s CSR](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-certificatessigningrequest)
