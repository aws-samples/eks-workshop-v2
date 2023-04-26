---
title: "Traditional A/B testing"
sidebar_position: 15
---


We have modified the `checkout` microservice adding a prefix *"Lattice"* to the shipping options. In this section, we want to test this new feature performing A/B testing. 

Let's deploy a new version of the `checkout` microservice in a new namespace (`checkoutv2`) using `kustomize`.

```bash
$ kubectl apply -k workspace/modules/networking/vpc-lattice/abtesting/
```

We can check how both namespaces contain a version of the application:

```bash
$ kubectl get pods -n checkout
NAME                              READY   STATUS    RESTARTS   AGE
checkout-698856df4d-nsgrm         1/1     Running   0          19m
checkout-redis-6cfd7d8787-ddfxx   1/1     Running   0          19m
$ kubectl get pods -n checkoutv2
NAME                              READY   STATUS    RESTARTS   AGE
checkout-698856df4d-zdhn7         1/1     Running   0          45s
checkout-redis-6cfd7d8787-cmj6g   1/1     Running   0          45s
```

Now we shift the traffic to the new version. To do so, we will manually update the user interface config map to point to our new service: 
```bash
$ CHECKOUT_V2_SVC="http://checkout.checkoutv2.svc:80"
$ kubectl patch configmap/ui -n ui --type merge -p '{"data":{"ENDPOINTS_CHECKOUT": "'${CHECKOUT_V2_SVC}'"}}'
```

**IMPORTANT**: To ensure nothing is cached and we are using the new image, we will re-create the UI pod:

```bash
$ kubectl delete --all pods --namespace=ui
```

Check that the new pod is in a running state:
```bash
$ kubectl get pods -n ui
```

We can now visit the website and confirm that the new feature we introduced is present.

Port-forward the `ui` pod:  

```bash
$ kubectl port-forward svc/ui 8080:80 -n ui
```

and the preview of your application in `Cloud9`. To do so, click on the `Preview` button on the top bar and select `Preview Running Application` to preview the UI application on the right:

![Preview your application](assets/preview-app.png)

Go to the checkout page:
![Checkout](assets/checkout1.png)

And fill in the required information (zip code must be 5 numbers):

![Checkout](assets/checkout2.png)

Checking out items, we can see that a the *"Lattice"* prefix for the shipping options: 

![Preview your application](assets/latticeprefix.png)