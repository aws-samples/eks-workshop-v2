---
title: ConfigMaps
sidebar_position: 10
---

# ConfigMaps

**ConfigMaps** allow you to decouple configuration artifacts from image content to keep containerized applications portable. They store non-confidential data in key-value pairs and can be consumed by pods as environment variables, command-line arguments, or configuration files.

ConfigMaps provide:
- **Configuration Management:** Store application configuration separately from code
- **Environment Flexibility:** Use different configurations for different environments
- **Runtime Updates:** Update configuration without rebuilding container images
- **Portability:** Keep applications portable across different environments

In this lab, you'll learn about ConfigMaps by creating one for our retail store's UI component and seeing how it connects to backend services.

### Creating ConfigMap

Let's create a ConfigMap for our retail store's UI component. The UI needs to know where to find the backend services:

::yaml{file="manifests/base-application/ui/configMap.yaml" paths="kind,metadata.name,data" title="ui-configmap.yaml"}

1. `kind: ConfigMap`: Tells Kubernetes what type of resource to create
2. `metadata.name`: Unique identifier for this ConfigMap within the namespace
4. `data`: Key-value pairs containing the configuration data

Apply the ConfigMap configuration:
```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/introduction/basics/configmaps/
```

### Exploring ConfigMap

Now let's examine the ConfigMap we just created:

```bash
$ kubectl get configmaps -n ui
NAME               DATA   AGE
kube-root-ca.crt   1      2m51s
ui                 4      2m50s
```

Get detailed information about the ConfigMap:
```bash
$ kubectl describe configmap ui -n ui
Name:         ui
Namespace:    ui
Labels:       <none>
Annotations:  <none>

Data
====
RETAIL_UI_ENDPOINTS_CARTS:
----
http://carts.carts.svc:80

RETAIL_UI_ENDPOINTS_CATALOG:
----
http://catalog.catalog.svc:80

RETAIL_UI_ENDPOINTS_CHECKOUT:
----
http://checkout.checkout.svc:80

RETAIL_UI_ENDPOINTS_ORDERS:
----
http://orders.orders.svc:80


BinaryData
====

Events:  <none>
```

This shows:
- **Data section** - The key-value pairs stored in the ConfigMap
- **Labels** - Metadata tags for organization
- **Annotations** - Additional metadata

### Using ConfigMaps in Pods

Now let's create a pod that uses our ConfigMap. We'll update our UI pod to use the configuration:

::yaml{file="manifests/modules/introduction/basics/configmaps/ui-pod-with-config.yaml" paths="spec.containers.0.envFrom" title="ui-pod-with-config.yaml"}

1. `envFrom.configMapRef`: Loads all key-value pairs from the ConfigMap as environment variables

Apply the updated pod configuration:
```bash hook=ready
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/configmaps/ui-pod-with-config.yaml
```

### Testing the Configuration

Let's verify that our pod can now access the configuration:

```bash
$ kubectl exec -n ui ui-pod -- env | grep RETAIL_UI_ENDPOINTS_CATALOG
RETAIL_UI_ENDPOINTS_CATALOG=http://catalog.catalog.svc:80
```

You can also see all the ConfigMap environment variables:
```bash
$ kubectl exec -n ui ui-pod -- env | grep RETAIL_UI
RETAIL_UI_ENDPOINTS_CATALOG=http://catalog.catalog.svc:80
RETAIL_UI_ENDPOINTS_CARTS=http://carts.carts.svc:80
RETAIL_UI_ENDPOINTS_ORDERS=http://orders.orders.svc:80
RETAIL_UI_ENDPOINTS_CHECKOUT=http://checkout.checkout.svc:80
```

## Key Points to Remember

* ConfigMaps store non-confidential configuration data
* They decouple configuration from container images
* Can be consumed as environment variables or mounted as files
* Allow the same image to work across different environments
* Have a 1MB size limit per ConfigMap
