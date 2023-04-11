---
title: "A/B testing with VPC Lattice"
sidebar_position: 20
---

In this section we will show how to use Amazon VPC Lattice to perform A/B testing gradually shifting traffic from the `checkout` service to the new version we created in the previous section.

# Set up Lattice Service Network

Create the Kubernetes Gateway `eks-workshop-gw`:
   ```bash
   $ kubectl apply -f workspace/modules/networking/vpc-lattice/controller/eks-workshop-gw.yaml
   ```
Verify that `eks-workshop-gw` gateway is created:
   ```bash
   $ kubectl get gateway  
   ```
   ```
   $ NAME              CLASS         ADDRESS   READY   AGE
   $ eks-workshop-gw   aws-lattice                     12min
   ```

Once the gateway is created, find the VPC Lattice service network. Wait until the status is `Reconciled` (this could take about five minutes).
   ```bash
   $ kubectl describe gateway eks-workshop-gw
   ```
   ```
   $ apiVersion: gateway.networking.k8s.io/v1alpha2
   kind: Gateway
   ...
   $ status:
   conditions:
   message: 'aws-gateway-arn: arn:aws:vpc-lattice:us-west-2:<YOUR_ACCOUNT>:servicenetwork/sn-03015ffef38fdc005'
   reason: Reconciled
   status: "True"
   ```
 Now you can see the associated Service Network created in the VPC console under the Lattice resources.
![Checkout Service Network](assets/servicenetwork.png)

# Create Routes to targets
We will show how to preform A/B testing between the two versions using `HTTPRoutes`.

At the time of writing (Apr 2023), the controller requires a port number for `targetPort` . We are working on a better solution, progress is tracked [here](https://github.com/aws/aws-application-networking-k8s/issues/86).

```bash
$ kubectl patch svc checkout -n checkout --patch '{"spec": { "type": "ClusterIP", "ports": [ { "name": "http", "port": 80, "protocol": "TCP", "targetPort": 8080 } ] } }'
```

Create the Kubernetes `HTTPRoute` route that evenly distributes the traffic between `checkout` and `checkoutv2`:
   ```bash
   $ kubectl apply -f workspace/modules/networking/vpc-lattice/routes/checkout-route.yaml
   ```
   ```file
   /networking/vpc-lattice/routes/checkout-route.yaml
   ```

Find out the `HTTPRoute`'s DNS name from `HTTPRoute` status (highlighted here on the `message` line):

```bash
$ kubectl describe httproute checkoutroute -n checkout
```

```bash
$ apiVersion: gateway.networking.k8s.io/v1alpha2
kind: HTTPRoute
    ...
status:
parents:
- conditions:
    - lastTransitionTime: "2023-02-27T14:36:26Z"
    message: 'DNS Name: checkout-checkouroute-05bcd5fb087c79394.7d67968.vpc-lattice-svcs.us-west-2.on.aws'
    reason: Reconciled
    status: "True"
    type: httproute
    controllerName: application-networking.k8s.aws/gateway-api-controller
    parentRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: eks-workshop-gw
```

 Now you can see the associated Service created in the VPC console under the Lattice resources.
![CheckoutRoute Service](assets/checkoutroute.png)

Patch the configmap to point to the new endpoint.

```bash
$ export CHECKOUT_ROUTE_DNS='http://'$(kubectl get httproute checkoutroute -n checkout -o json | jq -r '.status.parents[0].conditions[0].message' | cut  -c 11-)
$ kubectl patch configmap/ui -n ui --type merge -p '{"data":{"ENDPOINTS_CHECKOUT": "'${CHECKOUT_ROUTE_DNS}'"}}'
```

:::tip Now traffic is handled by Amazon VPC Lattice
Now Amazon VPC Lattice automatically redirects the traffic to different backends! This also means that you can take full advantage of all the [features](https://aws.amazon.com/vpc/lattice/features/) of Amazon VPC Lattice.

:::

# Check A/B testing is working

In the real world, A/B testing of new features is normally performed on a percentage of users. 
To simulate this scenario, we will configure the httproutes so that 50% of the traffic is routed to the old version and the other 50% to the new version of the application. 
Completing the checkout procedure multiple times with different objects in the cart should present the users with the 2 version of the applications. 

Again, we need to port-forward and open the preview of your application with `Cloud9`.

```bash
$ kubectl delete --all po -n ui
$ kubectl port-forward svc/ui 8080:80 -n ui
```
Click on the `Preview` button on the top bar and select `Preview Running Application` to preview the UI application on the right:


![Preview your application](assets/preview-app.png)

Now, try to checkout multiple times: you will notice how the new feature will be available around 50% of the times: this is because Amazon VPC Lattice automatically redirects traffic to different versions of `checkout` microservice. This is because now the UI pod points to the Amazon VPC Lattice endpoint we created earlier whith the `HttpRoute`.





