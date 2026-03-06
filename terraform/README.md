### Instructions to apply

add terraform.tfvars files

```shell
github_app_config_username = "<github-username>"
github_app_config_token   = "<github-token>"  # GitHub PAT with repo scope
```

### Install kind

https://kind.sigs.k8s.io/docs/user/quick-start/#installations

### Terraform steps

```shell
terraform init
```

```shell
terraform apply --target=kind_cluster.local
```

```shell
terraform apply --target=null_resource.registry_config
```

```shell
terraform apply --target=null_resource.registry
```

then run

```shell
terraform apply
```

### Access dashboards

**Jenkins** (NodePort 30080 or port-forward):

```shell
kubectl port-forward -n jenkins svc/jenkins 8080:8080
```

Open http://localhost:8080

**ArgoCD** (NodePort 30081 or port-forward):

```shell
kubectl port-forward -n argocd svc/argo-cd-argocd-server 8081:80
```

Open https://localhost:8081 (accept self-signed cert). Username: `admin`

Get ArgoCD admin password:

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Notes:

dont use this in production, has a lot of hacks to make it work in local with kind
