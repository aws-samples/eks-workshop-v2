---
title: "Accessing Argo CD"
sidebar_position: 10
weight: 10
---

For the purpose of this lab, Argo CD server UI has been exposed outside of the cluster using Kubernetes Service of `Load Balancer` type. To see how to set up Argo CD in the cluster with Amazon EKS Blueprint for Terraform please refer to this [guide](https://aws-ia.github.io/terraform-aws-eks-blueprints/).
<!--
:::info
If you need to reset Argo CD `admin` password you can use the following commands:

```bash
$ kubectl -n argocd patch secret argocd-secret -p '{"data": {"admin.password": null, "admin.passwordMtime": null}}'
$ kubectl -n argocd rollout restart deployment/argocd-server
$ kubectl -n argocd rollout status deploy/argocd-server
```

:::
 -->
To get the URL from Argo CD service, run the following command:

```bash
$ ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
$ echo "ArgoCD URL: http://$ARGOCD_SERVER"
ArgoCD URL: http://acfac042a61e5467aace45fc66aee1bf-818695545.us-west-2.elb.amazonaws.com
```

The initial username is `admin`. The password is auto-generated. You can get it by running the following command:

```bash
$ ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
$ echo "ArgoCD admin password: $ARGOCD_PWD"
```

Log in to the Argo CD UI using the URL and credentials you just obtained

You will be presented with a screen that looks like this:

![argocd-ui](assets/argocd-ui.png)

Argo CD also provides a powerful CLI tool called `argocd` that can be used to manage applications.

:::info
For the purpose of this lab, `argocd` CLI has been installed for you. You can learn more about installing the CLI tool by following the [instructions](https://argoproj.github.io/argo-cd/cli_installation/).
:::

In order to interact with Argo CD objects using CLI, we need to login to the Argo CD server by running the following commands:

```bash
$ argocd login $(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname') --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) --insecure
'admin:login' logged in successfully
Context 'acfac042a61e5467aace45fc66aee1bf-818695545.us-west-2.elb.amazonaws.com' updated
```
