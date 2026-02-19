---
title: Pods
sidebar_position: 20
---

# Pods

**Pods** are the smallest deployable units in Kubernetes. A Pod represents one or more containers that share storage, network, and configuration settings for how they should run together.

Pods provide:
- **Container grouping:** Usually, a pod runs a single container, but it can include multiple tightly coupled containers that need to share data or communicate over localhost.
- **Shared networking:** All containers in a pod share the same IP address
- **Shared storage:** Containers can share volumes within the pod
- **Lifecycle management:** Containers in a pod live and die together
- **Ephemeral nature:** Pods can be created, destroyed, and recreated

In this lab, you'll learn about pods by creating a simple example pod and exploring its properties.

### Creating a Pod

Let's create a simple pod to understand how they work. The manifest defines a simple pod running the retail store UI container.

::yaml{file="manifests/modules/introduction/basics/pods/ui-pod.yaml" paths="kind,metadata.name,metadata.namespace,spec.containers,spec.containers.0.name,spec.containers.0.image,spec.containers.0.ports,spec.containers.0.env,spec.containers.0.resources" title="ui-pod.yaml"}

1. `kind: Pod`: Tells Kubernetes what type of resource to create
2. `metadata.name`: Unique identifier for this pod within the namespace
3. `metadata.namespace`: Which namespace the pod belongs to (ui namespace)
4. `spec.containers`: Array defining what containers run in the pod
5. `spec.containers.0.name`: Name of the first container (ui)
6. `spec.containers.0.image`: Container image from ECR Public registry
7. `spec.containers.0.ports`: Network ports the container exposes
8. `spec.containers.0.env`: Environment variables for the container
9. `spec.containers.0.resources`: CPU and memory allocation settings

Apply the pod configuration:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/pods/ui-pod.yaml
```

Kubernetes will create the pod in the `ui` namespace and start pulling the container image.

Wait for the pod to become ready:
```bash
$ kubectl wait --for=condition=Ready --timeout=60s -n ui pod/ui-pod
```

### Exploring Pod

Now let's examine the pod we just created:

```bash
$ kubectl get pods -n ui
NAME     READY   STATUS    RESTARTS   AGE
ui-pod   1/1     Running   0          30s
```

Get detailed information about the pod:
```bash
$ kubectl describe pod -n ui ui-pod
Name:             ui-pod
Namespace:        ui
Priority:         0
Service Account:  default
Node:             ip-10-42-144-0.us-west-2.compute.internal/10.42.144.0
Start Time:       Sun, 05 Oct 2025 19:28:02 +0000
Labels:           app.kubernetes.io/component=service
                  app.kubernetes.io/name=ui
Annotations:      <none>
Status:           Running
IP:               10.42.146.177
IPs:
  IP:  10.42.146.177
Containers:
  ui:
    Container ID:   containerd://01709a8abac99ce46842dda128752a68e828a485ee47f2094549fc00f9d71953
    Image:          public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1
    Image ID:       public.ecr.aws/aws-containers/retail-store-sample-ui@sha256:63a531dd3716cf9f6a3c7b54d65c39ce4de43cb23a613ac2933f2cb38aff86d7
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sun, 05 Oct 2025 19:28:03 +0000
    Ready:          True
    Restart Count:  0
    Limits:
      memory:  1536Mi
    Requests:
      cpu:     250m
      memory:  1536Mi
    Environment:
      JAVA_OPTS:  -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/urandom
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-68xdw (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-68xdw:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  10s   default-scheduler  Successfully assigned ui/ui-pod to ip-10-42-144-0.us-west-2.compute.internal
  Normal  Pulled     10s   kubelet            Container image "public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1" already present on machine
  Normal  Created    10s   kubelet            Created container: ui
  Normal  Started    10s   kubelet            Started container ui
```

This shows:
- **Container specifications** - Image, ports, environment variables
- **Resource usage** - CPU and memory requests/limits
- **Events** - What happened during pod creation
- **Status** - Current state and health

View the pod's logs:
```bash
$ kubectl logs -n ui ui-pod
Picked up JAVA_TOOL_OPTIONS: 

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.4.4)

2025-10-05T19:28:06.600Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Starting UiApplication v0.0.1-SNAPSHOT using Java 21.0.7 with PID 1 (/app/app.jar started by appuser in /app)
2025-10-05T19:28:06.658Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : The following 1 profile is active: "prod"
2025-10-05T19:28:10.268Z  INFO 1 --- [           main] i.o.i.s.a.OpenTelemetryAutoConfiguration : OpenTelemetry Spring Boot starter has been disabled

2025-10-05T19:28:11.712Z  INFO 1 --- [           main] o.s.b.a.e.w.EndpointLinksResolver        : Exposing 4 endpoints beneath base path '/actuator'
2025-10-05T19:28:14.045Z  INFO 1 --- [           main] o.s.b.w.e.n.NettyWebServer               : Netty started on port 8080 (http)
2025-10-05T19:28:14.075Z  INFO 1 --- [           main] c.a.s.u.UiApplication                    : Started UiApplication in 8.505 seconds (process running for 10.444)
```

> You’ll see the UI container starting up. 

Execute a command inside the pod:
```bash hook=ready
$ kubectl exec -n ui ui-pod -- curl -s localhost:8080/actuator/health | jq
{"status":"UP","groups":["liveness","readiness"]}
```
This should return the status of the application.

### Accessing Pod

You can access the pod from your local machine using port forwarding:
```bash test=false
$ kubectl port-forward -n ui ui-pod 8080:8080
```

:::info
Port forwarding temporarily connects your local port to a port inside the pod, allowing you to access the application directly from your laptop.
:::

In the Workshop IDE, a popup appears to view all forwarded ports. Click to open applicaiton URL in the browser.

Alternatively, open another terminal and test:
```bash test=false
$ curl localhost:8080
```

In the browser, You'll see the Retail store application landing page.

Press `CTRL+C` to break `port-forward` session.

### Deleting Pods

When you no longer need a pod, you can delete it using the `kubectl delete` command. There are several ways to delete pods:

**Method 1: Delete by name**
```bash
$ kubectl delete pod -n ui ui-pod
pod "ui-pod" deleted
```

**Method 2: Delete using the manifest file**
Let's recreate the `ui-pod` and delete using mainfest file.
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/pods/ui-pod.yaml
$ kubectl delete -f ~/environment/eks-workshop/modules/introduction/basics/pods/ui-pod.yaml
pod "ui-pod" deleted
```

After deletion, verify the pod is gone:
```bash
$ kubectl get pods -n ui
No resources found in ui namespace.
```

:::warning
When you delete a pod directly, it's gone forever. The data inside the pod (unless stored in persistent volumes) is lost. In production environments, pods are typically managed by controllers like Deployments that automatically recreate them if needed.
:::

### Pod Lifecycle

Pods have well-defined lifecycle phases that reflect their current state in the cluster.
- **Pending** - Pod is being scheduled and containers are starting
- **Running** - At least one container is running
- **Succeeded** - All containers have completed successfully
- **Failed** - At least one container has failed
- **Unknown** - Pod state cannot be determined

Kubernetes controllers continuously monitor pod states and take action (like restarting failed containers or recreating pods) to maintain desired application health.

## Key Points to Remember

* Pods are the smallest deployable units in Kubernetes
* Usually contain one container, but can contain multiple
* Share network and storage within the pod
* Pods are ephemeral - they come and go
* Typically managed by higher-level controllers like Deployments

:::info
In real-world scenarios, you rarely create pods directly — instead, you use higher-level resources like Deployments, ReplicaSets, or Jobs to manage them.
:::
