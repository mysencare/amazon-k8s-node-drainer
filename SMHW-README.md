# Amazon EKS Node Drainer - SMHW

## Deploy

### QA environment

- Standard worker nodes

```bash
./build_deploy.sh -b satchel-k8s-node-drainer -a satchel-eks-qa -c satchel-eks-qa -s eks-qa-standard-drainer
```

- Sidekiq worker nodes

```bash
./build_deploy.sh -b satchel-k8s-node-drainer -a satchel-eks-qa-sidekiq -c satchel-eks-qa -s eks-qa-sidekiq-drainer
```

### PROD environment

- Standard worker nodes

```bash
./build_deploy.sh -b satchel-k8s-node-drainer -a satchel-eks-prod -c satchel-eks-prod -s eks-prod-standard-drainer
```

- Sidekiq worker nodes

```bash
./build_deploy.sh -b satchel-k8s-node-drainer -a satchel-eks-prod-sidekiq -c satchel-eks-prod -s eks-prod-sidekiq-drainer
```

### Kubernetes Permissions

After deployment there will be an IAM role associated with the lambda that needs to be mapped to a user or group in
the EKS cluster. The build script will create the required Kubernetes `ClusterRole` and `ClusterRoleBinding`.

You may now create the mapping to the IAM role created when deploying the Drainer function.
You can find this role by checking the `DrainerRole` output of the CloudFormation stack created by the `sam deploy`
command above. Run `kubectl edit -n kube-system configmap/aws-auth` and add the following `yaml`:

```yaml
mapRoles: |
# ...
    - rolearn: <DrainerFunction IAM role>
      username: lambda
```
