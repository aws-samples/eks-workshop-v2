---
title: "Lab setup"
sidebar_position: 60
---

In this lab, we are going to implement network policies for the sample application deployed in the lab cluster. The sample application component architecture is shown below.

<img src={require('@site/static/img/sample-app-screens/architecture.png').default}/>

Each component in the sample application is implemented in its own namespace. For example, the **'ui'** component is deployed in the **'ui'** namespace, whereas the **'catalog'** web service and **'catalog'** MySQL database are deployed in the **'catalog'** namespace.

Currently, there are no network policies that are defined, and any component in the sample application can communicate with any other component or any external service. For example, the 'ui' component can directly communicate with the 'catalog' database. We can validate this using the below commands:

```bash wait=30 timeout=240
$ UI_POD_1=$(kubectl get pod --selector app.kubernetes.io/name=ui -n ui -o json | jq -r '.items[0].metadata.name')
$ echo $UI_POD_1
ui-XXXX-XXX
$ kubectl exec -it ${UI_POD_1} -n ui -- curl -v telnet://catalog-mysql.catalog:3306 --connect-timeout 5
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
*   Trying XXX.XXX.XXX.XXX:3306...
* Connected to catalog-mysql.catalog (XXX.XXX.XXX.XXX) port 3306 (#0)
...
```
On execution of the curl statement, the output displayed should have the below statement which shows that ui component can directly communicate with the catalog database component.
```
Connected to catalog-mysql.catalog (XXX.XXX.XXX.XXX) port 3306 (#0)
```

Let us start by implementing some network rules so we can better control the follow of traffic for the sample application.