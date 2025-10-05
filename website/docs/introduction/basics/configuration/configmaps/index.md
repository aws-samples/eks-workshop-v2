---
title: ConfigMaps
sidebar_position: 10
sidebar_custom_props: { "module": true }
---

# ConfigMaps

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/basics/configmaps
```

:::

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
```

You should see output like:
```
NAME        DATA   AGE
ui-config   1      30s
```

Get detailed information about the ConfigMap:
```bash
$ kubectl describe configmap ui -n ui
```

This shows:
- **Data section** - The key-value pairs stored in the ConfigMap
- **Labels** - Metadata tags for organization
- **Annotations** - Additional metadata

View the ConfigMap's data in YAML format:
```bash
$ kubectl get configmap ui -n ui -o yaml
```

### Using ConfigMaps in Pods

Now let's create a pod that uses our ConfigMap. We'll update our UI pod to use the configuration:

::yaml{file="manifests/modules/introduction/basics/configmaps/ui-pod-with-config.yaml" paths="spec.containers.0.envFrom" title="ui-pod-with-config.yaml"}

1. `envFrom.configMapRef`: Loads all key-value pairs from the ConfigMap as environment variables

Apply the updated pod configuration:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/configmaps/ui-pod-with-config.yaml
```

### Testing the Configuration

Let's verify that our pod can now access the configuration:

```bash
$ kubectl exec -n ui ui-pod -- env | grep CATALOG_BASE_URL
```

You should see:
```
CATALOG_BASE_URL=http://catalog.catalog.svc.cluster.local
```

## Key Points to Remember

* ConfigMaps store non-confidential configuration data
* They decouple configuration from container images
* Can be consumed as environment variables or mounted as files
* Allow the same image to work across different environments
* Have a 1MB size limit per ConfigMap
