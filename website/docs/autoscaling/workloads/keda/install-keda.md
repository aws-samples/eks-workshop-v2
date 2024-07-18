---
title: "Installing KEDA"
sidebar_position: 10
---

First lets install the KEDA Operator using helm:

```bash
$ helm repo add kedacore https://kedacore.github.io/charts
$ helm upgrade --install keda kedacore/keda \
  --version "${KEDA_CHART_VERSION}" \
  --namespace keda \
  --create-namespace \
  --set "podIdentity.aws.irsa.enabled=true" \
  --set "podIdentity.aws.irsa.roleArn=${KEDA_ROLE_ARN}" \
  --wait
Release "keda" does not exist. Installing it now.
NAME: keda
LAST DEPLOYED: [...]
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
:::^.     .::::^:     :::::::::::::::    .:::::::::.                   .^.                  
7???~   .^7????~.     7??????????????.   :?????????77!^.              .7?7.                 
7???~  ^7???7~.       ~!!!!!!!!!!!!!!.   :????!!!!7????7~.           .7???7.                
7???~^7????~.                            :????:    :~7???7.         :7?????7.               
7???7????!.           ::::::::::::.      :????:      .7???!        :7??77???7.              
7????????7:           7???????????~      :????:       :????:      :???7?5????7.             
7????!~????^          !77777777777^      :????:       :????:     ^???7?#P7????7.            
7???~  ^????~                            :????:      :7???!     ^???7J#@J7?????7.           
7???~   :7???!.                          :????:   .:~7???!.    ~???7Y&@#7777????7.          
7???~    .7???7:      !!!!!!!!!!!!!!!    :????7!!77????7^     ~??775@@@GJJYJ?????7.         
7???~     .!????^     7?????????????7.   :?????????7!~:      !????G@@@@@@@@5??????7:        
::::.       :::::     :::::::::::::::    .::::::::..        .::::JGGGB@@@&7:::::::::        
                                                                      ?@@#~                  
                                                                      P@B^                   
                                                                    :&G:                    
                                                                    !5.                     
                                                                    .Kubernetes Event-driven Autoscaling (KEDA) - Application autoscaling made simple.

Get started by deploying Scaled Objects to your cluster:
    - Information about Scaled Objects : https://keda.sh/docs/latest/concepts/
    - Samples: https://github.com/kedacore/samples

Get information about the deployed ScaledObjects:
  kubectl get scaledobject [--namespace <namespace>]

Get details about a deployed ScaledObject:
  kubectl describe scaledobject <scaled-object-name> [--namespace <namespace>]

Get information about the deployed ScaledObjects:
  kubectl get triggerauthentication [--namespace <namespace>]

Get details about a deployed ScaledObject:
  kubectl describe triggerauthentication <trigger-authentication-name> [--namespace <namespace>]

Get an overview of the Horizontal Pod Autoscalers (HPA) that KEDA is using behind the scenes:
  kubectl get hpa [--all-namespaces] [--namespace <namespace>]

Learn more about KEDA:
- Documentation: https://keda.sh/
- Support: https://keda.sh/support/
- File an issue: https://github.com/kedacore/keda/issues/new/choose
```

KEDA will be running as several deployments in the keda namespace:

```bash
$ kubectl get deployment -n keda
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
keda-admission-webhooks           1/1     1            1           105s
keda-operator                     1/1     1            1           105s
keda-operator-metrics-apiserver   1/1     1            1           105s
```

Now we can move on to configuring KEDA to scale our workload.