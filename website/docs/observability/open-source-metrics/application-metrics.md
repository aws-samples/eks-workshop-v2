---
title: "Custom Metrics"
sidebar_position: 50
---

Custom metrics are user defined metrics that help track your application KPIs. These metrics help analyze data and derive insights to meet your application needs. Let's look at some custom metrics using AWS Distro for OpenTelemetry and visualize the metrics using grafana.

The custom metrics we want to capture and show in the dashboard for the sample application are:
- number of total orders created
- most popular watch type order, based on number of each watch type ordered
- total cost of each order

The "retail-store-sample-app" has already been instrumented to capture the above mentioned metrics. The OrderMetrics class uses Spring Boot [Micrometer](https://spring.io/blog/2018/03/16/micrometer-spring-boot-2-s-new-application-metrics-collector) a metrics collection facade which collects metrics data from the application with a vendor neutral API. 

Access the ui in your web browser ,following instructions detailed in workshop under [Exposing applications](https://www.eksworkshop.com/docs/fundamentals/exposing/). Once you load the ui page, add a couple of watch orders so we can generate the metrics.

The application code will capture the application metrics outline above. These metrics are exported to Amazon Managed Prometheus. We will use Amazon Managed Grafana to visualize the metrics. 

Use the below script to run load-generator to place watch orders to capture the custom metrics.

```kubectl wait --for=condition=Ready --timeout=180s pods \
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: load-generator
spec:
  containers:
  - name: artillery
    image: artilleryio/artillery:2.0.0-31
    args:
    - "run"
    - "-t"
    - "http://ui.default.svc"
    - "/scripts/scenario.yml"
    volumeMounts:
    - name: scripts
      mountPath: /scripts
  initContainers:
  - name: setup
    image: public.ecr.aws/aws-containers/retail-store-sample-utils:load-gen.0.3.0
    command:
    - bash
    args:
    - -c
    - "cp /artillery/* /scripts"
    volumeMounts:
    - name: scripts
      mountPath: "/scripts"
  volumes:
  - name: scripts
    emptyDir: {}
EOF
```

Open the Grafana dashboard![Grafana dashboard](./assets/business-metrics-dashboard.png)

Go to the dashboard section and click on the dashboard **Order Service Metrics** and let's review the panels wintin the dashboard.

The dashboard displays the panels that represent all the metrics we outlined![Business Metrics](./assets/retailMetrics.png)

You can view / edit each panel to look more closely at the metrics.

This panel displays the toal number of orders placed by the user in the given time range.
![Total Orders Placed](./assets/totalOrders.png)

This panel displays the number of each watch type ordered, displayed as a pie chart.
![Most Popular Watch Ordered](./assets/watchCount.png)

This panel displays the toal price of the order in the given time range.
![Total Order Price](./assets/totalOrderPrice.png)

Once you're satisfied with observing metrics, you can end the load generator with `Ctrl+C` and stop the load generator using the below command.

```bash timeout=180
$ kubectl delete pod load-generator
```

