---
title: "Install Jupyterhub"
sidebar_position: 30
---

### Set Up JupyterHub for Model Training

Let's go through the steps to get a JupyterHub instance running for model training and inference.

First we'll add the official JupyterHub Helm chart repository. This contains the pre-packaged JupyterHub that we can install on our Kubernetes cluster:


```bash timeout=600 wait=60
$ helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
$ helm repo update
```

### Configure JupyterHub

Next we need to customize JupyterHub by creating a values.yaml file. This is where we can configure things like users, authentication, resources,  and more.

```file
manifests/modules/aiml/deploy-monitor-genai-model/jupyterhub/jupyterhub-values.yaml
```

### Install JupyterHub

Now, lets install JupyterHub, pointing it at the chart and our config:


```bash timeout=1800 wait=60 hook=check-jupyterhub-install
$ kubectl create namespace jupyterhub
$ kubectl create -f ~/environment/eks-workshop/modules/aiml/deploy-monitor-genai-model/jupyterhub/jupyterhub-configmap.yaml
$ helm upgrade --cleanup-on-fail --install jupyterhub jupyterhub/jupyterhub --namespace jupyterhub --version=3.1.0 --values ~/environment/eks-workshop/modules/aiml/deploy-monitor-genai-model/jupyterhub/jupyterhub-values.yaml
```


### Login and Start Training

Once Kubernetes finishes deploying everything, we can open the external IP of the JupyterHub service in our browser.

Log in with the admin user and password set in values.yaml. Then launch notebooks and start training models on the GPUs configured
