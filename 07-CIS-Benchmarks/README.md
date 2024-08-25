# CIS Benchmarks

* CIS: Center for Internet Security
* Download Link: https://learn.cisecurity.org/benchmarks
* CIS Automation Tool: [kube-bench](https://github.com/aquasecurity/kube-bench)

## Using KubeBench for CIS Audit

* Run below command to run kube-bench as job

    ```bash
    k apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml
    ```

* View kube-bench results

    ```bash
    k get pods # view pod logs

    k logs {kube-bench-pod-name}
    ```

## Resources

* https://github.com/aquasecurity/kube-bench?tab=readme-ov-file#quick-start