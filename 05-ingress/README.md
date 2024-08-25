# Ingress

![Ingress Structure](/.images/05-Ingress.png)

## Ingress Setup

### For proper K8s deployment only

https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal-clusters

- old script installation

  ```bash
  k apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.40.2/deploy/static/provider/baremetal/deploy.yaml

  # new script
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/baremetal/deploy.yaml
  ```

- using helm

  ```bash
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo add stable https://kubernetes-charts.storage.googleapis.com/
  helm repo update
  ```

### For minikube

- enable ingress addon

  ```bash
  minikube addons enable ingress
  ```

- start tunnel

  ```bash
  minikube tunnel
  ```

### Create pods and services

- Create pods

  ```bash
  k run pod1 --image=nginx
  k run pod2 --image=nginx
  ```

- Create services

  ```bash
  k expose pod pod1 --port 80 --name service1
  k expose pod pod2 --port 80 --name service2
  ```

### Create Ingress 

- create ingress file `ingress.yaml`

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: secure-ingress
    annotations:
      nginx.ingress.kubernetes.io/rewrite-target: /
  spec:
    ingressClassName: nginx # newer NGINX-INGRESS needs this
    rules:
    # - host: dmdhrumilmistry.local # uncomment this if you're unable to connect to ingress.
    - http:
        paths:
        - path: /service1
          pathType: ImplementationSpecific
          backend:
            service:
              name: service1
              port:
                number: 80
        
        - path: /service2
          pathType: Prefix
          backend:
            service:
              name: service2
              port:
                number: 80
  ```

- apply changes

  ```bash
  k apply -f ingress.yaml
  ```

- test ingress connection

  ```bash
  curl http://localhost/service1
  curl http://localhost/service2

  curl https://localhost/service1 -k
  curl https://localhost/service2 -k
  ```

## Configuring TLS

- Create key for signing TLS certs

  ```bash
  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 265 -nodes 
  ```

  > ⚠️ Common name is must, everything else can be optional.

- Generate TLS certificate for k8s

  ```bash
  k create secret tls secure-ingress --cert=cert.pem --key=key.pem
  ```

- Check creation

  ```bash
  k get ing,secret
  ```

- Test using curl command

  ```bash
  curl https://dmdhrumilmistry.local/service1 -vk --resolve dmdhrumilmistry.local:443:127.0.0.1 # resolve flag is equivalent to entry in /etc/hosts
  ```

- verify request in logs

  ```bash
  kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx 
  ```

## Troubleshooting

- Clear previous Network Policies

- Reset Nginx Ingress Controller for minikube

  ```bash
  # delete controller
  kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission kubectl delete namespace ingress-nginx

  minikube addons enable ingress
  ```

- Get Ingress controller connection port

  ```bash
  controlplane $ kubectl get svc -A 
  NAMESPACE       NAME                                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
  default         kubernetes                           ClusterIP   10.96.0.1        <none>        443/TCP                      24d
  default         service1                             NodePort    10.108.228.176   <none>        80:32166/TCP                 35m
  default         service2                             ClusterIP   10.106.94.37     <none>        80/TCP                       35m
  ingress-nginx   ingress-nginx-controller             NodePort    10.97.108.113    <none>        80:30178/TCP,443:31428/TCP   38m
  ingress-nginx   ingress-nginx-controller-admission   ClusterIP   10.97.35.170     <none>        443/TCP                      38m
  kube-system     kube-dns                             ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP       24d
  controlplane $ curl http://localhost:30178
  <html>
  <head><title>404 Not Found</title></head>
  <body>
  <center><h1>404 Not Found</h1></center>
  <hr><center>nginx</center>
  </body>
  </html>
  ```

## Resources
- https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/
- https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal-clusters