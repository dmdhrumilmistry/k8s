- only expose services externally if required
- cluster internal services/dashboards can be accessed using kubectl port forward


## Kubectl Proxy

Can communicate via http only.

![Proxy](/.images/04-k-proxy.png)

## Kubectl Port Forward

can be used for any tcp connection. 
It's similar to ssh port forwarding.

![port forward](/.images/04-Port-forward.png)

## K8s Dashboard Deployment

### New Version Deployment 

- install helm

```bash
brew install helm
```

- Start pods in `kubernetes-dashboard` namespace

```bash
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
```

Output:
```bash
Release "kubernetes-dashboard" does not exist. Installing it now.
NAME: kubernetes-dashboard
LAST DEPLOYED: Thu Jul 25 17:22:57 2024
NAMESPACE: kubernetes-dashboard
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
*************************************************************************************************
*** PLEASE BE PATIENT: Kubernetes Dashboard may need a few minutes to get up and become ready ***
*************************************************************************************************

Congratulations! You have just installed Kubernetes Dashboard in your cluster.

To access Dashboard run:
  kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443

NOTE: In case port-forward command does not work, make sure that kong service name is correct.
      Check the services in Kubernetes Dashboard namespace using:
        kubectl -n kubernetes-dashboard get svc

Dashboard will be available at:
  https://localhost:8443
```


### Old Version/HTTP Deployment

By default dashboard server will be running on 8443 port over TLS/SSL. But if you want to run dashboard without any authentication over HTTP then follow below configurations. It is highly un-recommend to follow below config, it's only meant for learning purpose.

- apply dashboard config

```bash
k apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml
```

- Check pods and services

```bash
k -n kubernetes-dashboard get pods,svc
```

- Update kubernetes-dashboard deployment in kubernetes-dashboard namespace for running kubernetes dashboard on HTTP protocol (Not preffered)

```bash
k -n kubernetes-dashboard edit deploy kubernetes-dashboard
```


```yaml
-- snip --
template:
    metadata:
      creationTimestamp: null
      labels:
        k8s-app: kubernetes-dashboard
    spec:
      containers:
      - args:
		# removed certificate generator configuration from this line
        - --namespace=kubernetes-dashboard
        - --insecure-port=9090 # added this config to use http instead of https
        image: kubernetesui/dashboard:v2.4.0
        imagePullPolicy: Always
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /
            port: 9090 # update this from 8443
            scheme: HTTP # update this from HTTPS
        -- snip --
        ports:
        - containerPort: 9090 # update this from 8443
          protocol: TCP
        resources: {}
-- snip --
```

- Edit service kubernetes-dashboard 

```bash
k -n kubernetes-dashboard svc edit kubernetes-dashboard
```

```yaml
-- snip --
spec:
  clusterIP: 10.106.127.52
  clusterIPs:
  - 10.106.127.52
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - port: 9090 # updated from 8443
    protocol: TCP
    targetPort: 9090 # updated from 8443
  selector:
    k8s-app: kubernetes-dashboard
  sessionAffinity: None
  type: NodePort # changed from ClusterIp. Keep it as it is. for NodePort use vm/worker Ip address.
```

- Expose kubernetes dashboard by port-forward

```bash
k -n kubernetes-dashboard port-forward svc/kubernetes-dashboard 9090:9090
```

> visit `http://localhost:9090` to view k8s dashboard

## Minikube Dashboard

- start dashboard server

```bash
minikube dashboard
```

## HTTPS deployment

- Revert above changes and run below command to access dashboard over https

```bash
k -n kubernetes-dashboard port-forward svc/kubernetes-dashboard 9090:9090
```
## Access Control

Doc Resource: https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md (Follow this as it creates a new service account, below is for practice)

- Assign view only access to `kubernetes-dashboard` service account

```bash
k -n kubernetes-dashboard get sa # get service account: 
k -n kubernetes-dashboard get clusterroles | grep view # get view role
```

- Create Role binding for service account giving view only access.

```bash
k -n kubernetes-dashboard create rolebinding insecure --serviceaccount kubernetes-dashboard:kubernetes-dashboard --clusterrole view # -o yaml --dry-run=client

# use clusterrolebinding if you want to give view permission for overall cluster
 k -n kubernetes-dashboard create clusterrolebinding insecure --serviceaccount kubernetes-dashboard:kubernetes-dashboard --clusterrole view # -o yaml --dry-run=client

# To remove cluster role binding execute below command
# kubectl -n kubernetes-dashboard delete clusterrolebinding kubernetes-dashboard
```

- Create token for `kubernetes-dashboard` service account

```bash
kubectl -n kubernetes-dashboard create token kubernetes-dashboard
```

Resources:
- https://github.com/kubernetes/dashboard/blob/v2.4.0/aio/deploy/recommended.yaml
- Ports: https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0
- https://github.com/kubernetes/dashboard/blob/master/docs/user/accessing-dashboard/README.md
- https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md