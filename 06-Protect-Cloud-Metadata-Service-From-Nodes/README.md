# Protect Cloud Metadata and Endpoints from Nodes

- Metadata services for the cloud environment contains sensitive information and credentials for the cloud environment. only specific nodes should be allowed to access metadata services.

- Usually the metadata service IP for the cloud environment is `169.254.169.254`

## Network Policies

|Title|Path|Description|
|:----|:---:|:---------|
|Block Pod's Access to Cloud Metadata Service By Default|[NP Link](./cloud-metadata-deny.yml)|By default blocks requests to Cloud Metadata service and allows requests to other services|
|Allow Pod to Access Cloud Metadata Service using label|[NP Link](./allow-cloud-metadata.yml)|Allows pods with role=metadata-accessor to access metadata service|

## Create Infra

```bash
make deploy
```

## Test Connections

* denytest pod requests should be blocked

```bash
k exec denytest -- curl http://169.254.169.254/latest
```

* allowtest pod requests should be allowed

```bash
k exec allowtest -- curl http://169.254.169.254/latest
```

## Destroy Infra

```bash
make destroy
```