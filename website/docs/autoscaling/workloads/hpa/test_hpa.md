---
title: "Generate load"
sidebar_position: 20
---

```bash hook=hpa-pod-scaleout hookTimeout=330
$ kubectl run load-generator \
  --image=public.ecr.aws/f2e3b2o6/eks-workshop:loadgen-latest \
  --restart=Never -- -c 10 -q 5 -z 60m http://ui.ui.svc/home
```

Watch the HPA with the following command:

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

Once you're satisfied with the autoscaling behavior, you can stop the simulated load test:

```bash timeout=180
$ kubectl delete pod load-generator
```

As the load generator terminates you will notice that HPA will slowly bring the replica count to min number based on its configuration. 
