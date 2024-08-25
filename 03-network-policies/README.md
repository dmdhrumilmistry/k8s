# Network Policies

They're firewall rules in k8s implemented by calico/weave. It restrict the ingress/egress for a group of pods based on the certain rules and conditions.

If pod has more than one network policy then union of NP is applied. NP order doesn't affect policy result.

## Default Deny Policy and Whitelisting Communication for Frontend to Backend

- It is best practice to implement default deny policy

#### Lab:

!!! Before proceeding make sure your k8s is started with CNI supporting NPs such as calico/weaver. Remove all previously created containers as well.

```bash
minikube start --driver docker --cni calico
```

We'll create 2  pods running nginx, initially they'll be able to communicate with each other. Then we'll allow frontend to connect to backend 

> Frontend (FE) -> FE  Egress -> BE Ingress -> Backend (BE)


> `k` is alias for `kubectl` in below commands

##### Create pods and test connectivity between them 

- Create and expose pods

  ```bash
  kubectl run frontend --image=nginx
  kubectl run backend --image=nginx
  kubectl expose pod backend --port=80
  kubectl expose pod frontend --port=80
  ```

- check pods status

  ```bash
  kubectl get pods,svc
  ```

- check connectivity from frontend to backend

  ```bash
  kubectl exec frontend -- curl backend
  ```

- check connectivity from backend to frontend

  ```bash
  kubectl exec backend -- curl frontend
  ```

##### Create Default Deny NP

- create network policy file

  ```bash
  vim default-deny.yaml
  ```

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: default-deny
    namespace: default
  spec:
    podSelector: {} # can select on basis of namespace/pod
    policyTypes:
    - Ingress
    - Egress
  ```

- apply configuration

  ```bash
  kubectl apply -f default-deny.yaml 

  # delete configuration
  # kubectl delete -f default-deny.yaml
  ```

- test connectivity between pods

  ```bash
  kubectl exec frontend -- curl backend
  kubectl exec backend -- curl frontend
  ```

##### Create Frontend Egress Policy

- Create frontend policy (`frontend.yaml`)

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: frontend
    namespace: default
  spec:
    podSelector:
      matchLabels:
        run: frontend
    policyTypes:
    - Egress
    egress:
    - to:
      - podSelector:
          matchLabels:
              run: backend
  ```

- apply policy

  ```bash
  k apply -f frontend.yaml
  ```

- connect to backend

  ```bash
  k exec frontend -- curl backend
  # it won't be able to backend since egress policy 
  ```

##### Create Backend Ingress Policy

- Create backend policy (`backend.yaml`)

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: backend
    namespace: default
  spec:
    podSelector:
      matchLabels:
        run: backend
    policyTypes:
    - Ingress
    ingress:
    - from:
      - podSelector:
          matchLabels:
              run: frontend
  ```

- apply policy

  ```bash
  k apply -f backend.yaml
  ```

- connect to frontend

  ```bash
  k exec -- curl frontend
  # we won't be able to connect since DNS port is blocked
  ```

- get pod ip to connect using ip

  ```bash
  k get pods -o wide
  ```

- connect using IP

  ```bash
  k exec frontend -- curl 10.244.120.67
  # nginx will return default homepage
  ```

##### DNS Resolution Fix

- DNS policy (`dns.yaml`)

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: default-deny
    namespace: default
  spec:
    podSelector: {}
    policyTypes:
    - Ingress
    - Egress
    egress:
    - to:
      ports:
      - port: 53
        protocol: TCP
      - port: 53
        protocol: UDP
  ```

- apply policy

  ```bash
  k apply -f dns.yaml
  ```

- send request to backend from frontend

  ```bash
  k exec frontend -- curl backend
  ```

## Whitelisting Communication for Backend to Namespaced Database

![Network Policy](/.images/03-NP-BE-DB.png)

##### Create namespace and pod

- Create namespace

  ```bash
  k create ns cassandra
  ```

- edit namespace file and add labels to namespace

  ```bash
  k edit ns cassandra
  ```

  ```yaml
  apiVersion: v1
  kind: Namespace
  metadata:
    creationTimestamp: "2024-07-22T13:26:44Z"
    labels:
      kubernetes.io/metadata.name: cassandra
    name: cassandra
    resourceVersion: "7564"
    uid: 6f70ce09-72d9-4ead-9122-d5ce3bf12a86
    labels: # add this line
      ns: cassandra # add this line
  spec:
    finalizers:
    - kubernetes
  status:
    phase: Active
  ```

- Create new pod

  ```bash
  k -n cassandra run cassandra --image=nginx
  ```

-  get pods

  ```bash
  k -n cassandra get pods -o wide

  # pod ip: 10.244.120.73
  ```

- connect from backend to cassandra pod

  ```bash
  k exec backend -- curl 10.244.120.73

  # won't be able to connect since backend doesn't allow any egress traffic
  ```

- Add label to default namespace as well

  ```yaml
  apiVersion: v1
  kind: Namespace
  metadata:
    creationTimestamp: "2024-07-21T10:20:39Z"
    labels:
      kubernetes.io/metadata.name: default
    name: default
    resourceVersion: "43"
    uid: 1f29434f-3ec7-4464-93cc-aad322dfcaae
    labels:
      ns: default # add default namespace label
  spec:
    finalizers:
    - kubernetes
  status:
    phase: Active
  ```

##### Allow Egress to cassandra namespace from Backend

- Update `backend.yaml`

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: backend
    namespace: default
  spec:
    podSelector:
      matchLabels:
        run: backend
    policyTypes:
    - Ingress
    - Egress # update policy type
    ingress:
    - from:
      - podSelector:
          matchLabels:
              run: frontend
    egress: # add egress block
    - to:
      - namespaceSelector:
          matchLabels:
              ns: cassandra
  ```

- Apply new changes

  ```bash
  k apply -f backend.yaml
  ```

- try connecting from backend to cassandra pod

  ```bash
  k exec backend -- curl 10.244.120.73

  # backend will be able to connect to cassandra since default deny is only applied to default namespace
  ```

##### Apply Default Deny and allow backend ingress

- Use previously configured default deny config allowing DNS traffic and update namespace in it: `default-deny-except-dns-cassandra.yaml`

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: default-deny
    namespace: cassandra
  spec:
    podSelector: {}
    policyTypes:
    - Ingress
    - Egress
    egress:
    - to:
      ports:
      - port: 53
        protocol: TCP
      - port: 53
        protocol: UDP
  ```

- Apply config

  ```bash
  k apply -f default-deny-except-dns-cassandra.yaml
  ```

- try connecting from backend to cassandra again (request should timeout)

  ```bash
  k exec backend -- curl 10.244.120.73

  # request will timeout since ingress for cassandra is not allowed
  ```

- Create new `cassandra.yaml` policy

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata: # update metadata
    name: cassandra
    namespace: cassandra
  spec:
    podSelector: # apply policy to cassandra pod
      matchLabels:
        run: cassandra
    policyTypes:
    - Ingress
    ingress:
    - from:
      - namespaceSelector: # restrict ingress traffic only from default namespace
          matchLabels:
              ns: default
      - podSelector: # restrict ingress traffic only from backend pod
          matchLabels:
              run: backend
      ports: # restrict traffic only on 80 port
        - port: 80
          protocol: TCP
  ```

- Apply policy

  ```bash
  k apply -f cassandra.yaml
  ```

- try connecting from backend to cassandra pod again

  ```bash
  k exec backend -- curl 10.244.120.73

  # this should work
  ```


## Restricted Policies for Frontend and Backend

- frontend.yaml (with restricted port for egress)

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: frontend
    namespace: default
  spec:
    podSelector:
      matchLabels:
        run: frontend
    policyTypes:
    - Egress
    egress:
    - to:
      - podSelector:
          matchLabels:
              run: backend
      ports:
      - protocol: TCP
        port: 80
  ```

- backend.yaml (with restricted ports for ingress and egress)

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: backend
    namespace: default
  spec:
    podSelector:
      matchLabels:
        run: backend
    policyTypes:
    - Ingress
    - Egress
    ingress:
    - from:
      - podSelector:
          matchLabels:
              run: frontend
      ports:
        - port: 80
          protocol: TCP
    egress:
    - to:
      - namespaceSelector:
          matchLabels:
              ns: cassandra
      ports:
        - port: 80
          protocol: TCP
  ```

## Resources

- https://kubernetes.io/docs/concepts/services-networking/network-policies/
- https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/network-policy-v1/
- Github Repo: https://github.com/killer-sh/cks-course-environment/tree/master/course-content/cluster-setup/network-policies