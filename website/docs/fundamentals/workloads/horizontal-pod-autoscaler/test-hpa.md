---
title: "Generate load"
sidebar_position: 20
---

To observe HPA scale out in response to the policy we have configured we need to generate some load on our application. We'll do that by calling the home page of the workload with [hey](https://github.com/rakyll/hey).

The command below will run the load generator with:

- 10 workers running concurrently
- Sending 5 queries per second each
- Running for a maximum of 60 minutes

```bash hook=hpa-pod-scaleout hookTimeout=330
$ kubectl run load-generator \
  --image=williamyeh/hey:latest \
  --restart=Never -- -c 10 -q 5 -z 60m http://ui.ui.svc/home
```

Now that we have requests hitting our application we can watch the HPA resource to follow its progress:

```bash test=false
$ kubectl get hpa ui -n ui --watch
NAME   REFERENCE       TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
ui     Deployment/ui   69%/80%   1         4         1          117m
ui     Deployment/ui   99%/80%   1         4         1          117m
ui     Deployment/ui   89%/80%   1         4         2          117m
ui     Deployment/ui   89%/80%   1         4         2          117m
ui     Deployment/ui   84%/80%   1         4         3          118m
ui     Deployment/ui   84%/80%   1         4         3          118m
```

Once you're satisfied with the autoscaling behavior, you can end the watch with `Ctrl+C` and stop the load generator like so:

```bash timeout=180
$ kubectl delete pod load-generator
```

As the load generator terminates, notice that HPA will slowly bring the replica count to min number based on its configuration.
