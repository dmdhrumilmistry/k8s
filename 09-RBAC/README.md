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

## Resources
* [K8s RBAC Docs](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
