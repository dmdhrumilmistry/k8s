## Service Account and RBAC

* Service Account (SA) is K8s resource managed by K8s API, it is similar to users but for K8s API (Similar to AWS IAM Roles in AWS environment).

* SA doesn't require certificate and keys for K8s API authentication. Instead, it generates a secret token associated to service account when its resource is created.

* SA Secret token can be used for interacting with K8s API.

* Every namespace generates a default service account

## Creating Service Account and Using It with Pod

###  Lab

* Create a SA `accessor` and use in Pod
* Use SA token to interact with K8s API from inside the Pod

#### Create Service Account and Attach it to Pod
* Create service account

    ```bash
    k apply -f sa.yml

    # cli option:
    # kubectl create serviceaccount accessor
    # kubectl patch serviceaccount accessor -p '{"automountServiceAccountToken": false}'
    ```

* Create pod

    ```bash
    k apply -f pod.yml

    # CLI:
    # kubectl run accessor-pod --image=nginx --serviceaccount=accessor
    ```

#### Get Token from the Pod

* Get Pod shell access in order to interact with k8s API

    ```bash
    k exec -it pod/accessor-pod-automount-allowed -- bash
    ```

* Find token mount directory

    ```bash
    export TOKEN_DIR=$(mount | grep ser | awk '{print $3}')
    
    # /run/secrets/kubernetes.io/serviceaccount
    ```

* List directory

    ```bash
    ls $TOKEN_DIR/
    # ca.crt  namespace  token
    ```

* Get Token

    ```bash
    export TOKEN=$(cat $TOKEN_DIR/token)
    ```

* Get K8s API Host from environment variables. K8s configures several environment variables when pod is created.

    ```bash
    env

    echo $KUBERNETES_SERVICE_HOST
    ```

* Connect to K8s API Server

    ```bash
    curl https://${KUBERNETES_SERVICE_HOST} -k
    
    #{
    #"kind": "Status",
    #"apiVersion": "v1",
    #"metadata": {},
    #"status": "Failure",
    #"message": "forbidden: User \"system:anonymous\" cannot get path \"/#\"",
    #"reason": "Forbidden",
    #"details": {},
    #"code": 403
    #}
    ```

    > K8s API server returns 403 as user is not authenticated (Token is missing in the request)

* Send Request with `Bearer Token` in `Authorization` Header

    ```bash
    curl https://${KUBERNETES_SERVICE_HOST} -k -H "Authorization: Bearer ${TOKEN}"   
    # {
    #  "kind": "Status",
    #  "apiVersion": "v1",
    #  "metadata": {},
    #  "status": "Failure",
    #  "message": "forbidden: User \"system:serviceaccount:default:accessor\" cannot get path \"/\"",
    #  "reason": "Forbidden",
    #  "details": {},
    #  "code": 403
    # }
    ```

### Security: Disable automountServiceAccountToken

* Whenever pod is created default service account token is mounted in its filesystem in order to interact with K8s API.

* But in most of the cases applications hosted doesn't require this token, hence it is preferred to disable attaching token to the pod.

    ```yaml
    -- snip --
    spec:
        serviceAccountName: accessor
        automountServiceAccountToken: falseautomountServiceAccountToken
    -- snip --
    ```
#### Lab

Try accessing token in `pod/accessor-pod-automount-restricted` pod

* Spawn shell for pod

    ```bash
    k exec -it pod/accessor-pod-automount-restricted -- bash
    ```

* Get mount

    ```bash
    export TOKEN_DIR=$(mount | grep ser | awk '{print $3}')
    echo $TOKEN_DIR
    ```

    > We should get empty response here, since no token will be mounted

### Security: Limit SA permission using RBAC

* In order to follow POLP (Principle of Least Privilege), we should restrict SA permissions

* To achieve this we can create a ClusterRole with limited permissions then bind SA & ClusterRole with ClusterRoleBinding.

#### Lab

Let's assume here we want to give `accessor` edit access for the cluster. Use default `edit` clusterRole and create a clusterRoleBinding `accessor-sa-edit` (SA: accessor + ClusterRole:edit).

* Check SA perms to delete secrets

    ```bash
    # k auth can-i verb resource --as system:resource:namespace:name
    k auth can-i delete secrets --as system:serviceaccount:default:accessor # no
    ```

* Create ClusterRole Binding `accessor-sa-edit` for default clusterRole `edit` and SA `accessor`

    ```bash
    k apply -f binding.yml
    
    # CLI:
    # k create clusterrolebinding accessor --clusterrole edit --serviceaccount default:accessor
    ```

* Check permission again

    ```bash
    k auth can-i delete secrets --as system:serviceaccount:default:accessor # yes
    ```

## Resources

* [K8s SA Doc](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)