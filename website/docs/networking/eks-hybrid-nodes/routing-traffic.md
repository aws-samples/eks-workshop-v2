---
title: "Routing Traffic to Hybrid Nodes"
sidebar_position: 10
sidebar_custom_props: { "module": false }
weight: 25 # used by test framework
---

Now that we have our EKS Hybrid Node instance connected to the cluster, we can
deploy a sample workload. In this case, we will use the `nginx` deployment and `Ingress` manifests below. In the deployment, we are using `nodeAffinity` rules to tell the Kubernetes scheduler to _prefer_ cluster nodes
with the `eks.amazonaws.com/compute-type=hybrid` label and value.

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kustomize
namespace/nginx-remote created
service/nginx created
deployment.apps/nginx created
ingress.networking.k8s.io/nginx created
```

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/kustomize/ingress.yaml"}

::yaml{file="manifests/modules/networking/eks-hybrid-nodes/kustomize/deployment.yaml"}

Let’s confirm the pods were scheduled on our hybrid node successfully:

```bash
$ kubectl get pods -n nginx-remote -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName'
NAME                     NODE
nginx-787d665f9b-2bcms   mi-027504c0970455ba5
nginx-787d665f9b-hgrnp   mi-027504c0970455ba5
nginx-787d665f9b-kv4x9   mi-027504c0970455ba5
```

Great! The three `nginx` pods are running on our hybrid node as expected.

:::tip
The provisioning of the Application Load Balancer may take a couple minutes. Before continuing, ensure the load balancer is in an `active` state. Check the status of the load balancer with the following command:

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-nginxrem-nginx`) == `true`]' --query 'LoadBalancers[0].State.Code'
"active"
```

:::

Once the Application Load Balancer is active, we can check the `Address` associated with the Ingress to retrieve the DNS name of the Application Load Balancer:

```bash
$ export ADDRESS=$(kubectl get ingress -n nginx-remote nginx -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}") && echo $ADDRESS
k8s-nginxrem-nginx-03efa1e84c-012345678.us-west-2.elb.amazonaws.com
```

With the DNS name of the Application Load Balancer, we can access our deployment through the command line or by entering the address into a web browser. The ALB will then route the traffic to the appropriate pods based on the Ingress rules.

```bash test=false
$ curl $ADDRESS
Connected to 10.53.0.5 on mi-027504c0970455ba5
```

In the output from curl or the browser, we can see the `10.53.0.X` IP address of the pod receiving the request from the load balancer which is running on our hybrid node with the `mi-` prefix.

Rerun the curl command or refresh your browser a few times and note that the pod IP changes in each request and the node name stays the same, as all pods are scheduled on the same remote node.

```bash test=false
$ curl -s $ADDRESS
Connected to 10.53.0.5 on mi-027504c0970455ba5
$ curl -s $ADDRESS
Connected to 10.53.0.11 on mi-027504c0970455ba5
$ curl -s $ADDRESS
Connected to 10.53.0.84 on mi-027504c0970455ba5
```

We've successfully deployed a workload to our EKS Hybrid Node, configured it to be accessed through an Application Load Balancer, and verified that the traffic is being properly routed to our pods running on the remote node.

Before we move on to explore more usecases with EKS Hybrid Nodes, let's do a little cleanup.

```bash timeout=300 wait=30
$ kubectl delete -k ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kustomize --ignore-not-found=true
```