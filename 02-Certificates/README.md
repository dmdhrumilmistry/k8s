## Certificates

### Arch

![cert arch](https://www.dbi-services.com/blog/wp-content/uploads/sites/2/2023/06/certificates-1024x576.png)

* CA 

```bash
cat /etc/kubernetes/pki/ca.crt
```

* API Server certificate
```bash
cat /etc/kubernetes/pki/ca.crt
```

* API Server Client certificate (for communicating with etcd)
```bash
cat /etc/kubernetes/pki/apiserver-etcd-client.crt
```

* API Server Kubelet certificate (for communicating with kubelets)

```bash
cat /etc/kubernetes/pki/apiserver-kubelet-client.crt
```
