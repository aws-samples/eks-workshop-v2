---
title: Identity Based Routing
sidebar_position: 40
weight: 5
---

In this task, you use Istio to send 100% of the traffic to `ui-v1`. You then set a rule to selectively send traffic to `ui-v2` based on the cookie ID added to the end-user header request by the UI service. 

Most cookies contain a unique identifier called a cookie ID: a string of characters that websites and servers associate with the browser on which the cookie is stored.

In this case, all traffic from a user with a unique *COOKIE ID=XXX* will be routed to the deployment `ui-v2`, but all remaining user traffic goes to `ui-v1`.

To check which version of the UI traffic is routed to, the grep banner at the of the page should display the pod name which includes the deployment version.

The Cookie ID can be found:

Run the following command to re-configure the virtualService reviews you created in the previous task with the following one to enable user-based routing:

```bash
$ kubectl apply -n test -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ui
spec:
  hosts:
  - "*"
  gateways:
  - ui-gateway
  http:
  - match:
    - headers:
        cookie:
          regex: "^(.*?;)?(SESSIONID=XXX)(;.*)?$"
    route:
    - destination:
        host: ui
        subset: v2
  - route:
    - destination:
        host: ui
        subset: v1
EOF
```
Now, let's open the retail store sample using the browser:
```bash
$ echo $ISTIO_IG_HOSTNAME/home
```
Output:
```bash
http://af08b29901d054f489ffb6473b1593a9-510276527.us-east-1.elb.amazonaws.com/home
```

Notice here before logging, that the displayed page shows `reviews-v1` and does not includes the star ratings feature.
![productpage-with-no-user-identity](../assets/productpage-with-no-user-identity.png)

Now, let's see what happens when logging with the *tester* user?

Hit the `Sign In` button, to log in with the `tester` user, with no password:

![tester-login](../assets/tester-login.png)

Once the tester user is in, you will notice that the displayed page include the star ratings feature and show `reviews-v2` as it's expected.

![login-with-tester](../assets/login-with-tester.png)


And if you singed out and signed in back with any user other than *tester* (pick any name you wish). You will see that review stars are not there and it shows reviews-v1. This is because traffic is routed to reviews:v1 for all users except tester.

![not-tester](../assets/not-tester.png)

You have successfully configured Istio to route traffic based on user identity.

**Try it out:** Change the routing rule to direct tester user to v1, and remaining traffic to goes to v2.


