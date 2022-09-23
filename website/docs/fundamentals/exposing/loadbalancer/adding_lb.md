---
title: "Creating the load balancer"
sidebar_position: 20
---

Lets create an additional `Service` that provisions a load balancer with the following kustomization:

```file
exposing/load-balancer/nlb/nlb.yaml
```

This `Service` will create a Network Load Balancer that listens on port 80 and forwards connections to the `ui` Pods on port 8080. An NLB is a layer 4 load balancer that on our case operates at the TCP layer.

```bash timeout=180 hook=add-lb hookTimeout=430
$ kubectl apply -k /workspace/modules/exposing/load-balancer/nlb
```

Lets inspect the `Service` resources for the `ui` application again:

```bash
$ cat <<EOF > /tmp/yourfilehere
These contents will be written to the file.
  This line is indented.
EOF
```

Now we see two separate resources, with the new `ui-nlb` entry being of type `LoadBalancer`. Most importantly note it has an "external IP" value, this the DNS entry that can be used to access our application from outside the Kubernetes cluster.