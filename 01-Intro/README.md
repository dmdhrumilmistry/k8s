# Intro

## Arch Diagram
![K8s Arch](https://kubernetes.io/images/docs/kubernetes-cluster-architecture.svg)

## Mini K8s Installation

- Install [docker](https://docs.docker.com/engine/install/) 

- Install minikube
```bash
# using brew
brew install minikube

# using binary
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-arm64
sudo install minikube-darwin-arm64 /usr/local/bin/minikube
```

- start cluster
```bash
minikube start --driver docker --cni calico
```

- check status
```bash
minikube status
```

- Install addons
```bash
minikube addons enable metrics-server
minikube addons enable ingress # run minikube tunnel after installation
```

## Most Used Cmds
> `k` == `kubectl`

- get nodes
```bash
kubectl get nodes
```

- apply config from file
```bash
kubectl apply -f {file_path} 
```

- get info
```bash
kubectl get all
kubectl get pod
kubectl get configmap
kubectl get secret
kubectl get svc
```

- get all deployments
```bash
k get deployment --all-namespaces
```

- get pod name using label
```bash
kubectl get pods --namespace default -l "app=build-code" -o jsonpath="{.items[0].metadata.name}" # -l: label
```

- describe cmd
```bash
# describe service
kubectl describe service {service_name}

# describe pods
kubectl describe pod {pod_name}
```

- view logs
```bash
kubectl logs {pod_name}
```

## Access Service 

- Access Service
```bash
minikube service <service-name> --url
```

**OR** 

- get of node
```bash
kubectl get node -o wide

# using minikube
minikube ip
```

## Stop K8s server

- Halt cluster
```bash
minikube stop
```


- delete minikube clusters
```bash
minikube delete --all
```

## Extra Config
* export kubectl alias 

```bash
export "alias k='$HOME/.docker/bin/kubectl'" >> ~/.zshrc_user_config # this file is sourced in ~/.zshrc
source ~/.zshrc
```

## Docs
* https://minikube.sigs.k8s.io/docs/start/

## Lab Resources
* https://github.com/killer-sh/cks-course-environment
* https://killercoda.com/killer-shell-cks

## Exam Link
* https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/

