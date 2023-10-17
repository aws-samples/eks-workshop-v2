---
title: "View events in Opensearch"
sidebar_position: 20
---





```bash wait=60
$ helm repo add eks https://aws.github.io/eks-charts
$ helm install fluentbit eks/aws-for-fluent-bit --namespace opensearch-exporter \
    --create-namespace \
    -f ~/environment/eks-workshop/modules/observability/opensearch/fluentbit/values.yaml \
    --set="opensearch.host"="$OPENSEARCH_HOST" \
    --set="opensearch.awsRegion"=$AWS_REGION \
    --set="opensearch.httpUser"="$OPENSEARCH_USER" \
    --set="opensearch.httpPasswd"="$OPENSEARCH_PASSWORD" \
    --wait
```






```bash wait=60
$ helm install events-to-opensearch \
    oci://registry-1.docker.io/bitnamicharts/kubernetes-event-exporter \
    --namespace opensearch-exporter --create-namespace \
    -f ~/environment/eks-workshop/modules/observability/opensearch/kube-events/values.yaml \
    --set="config.receivers[0].opensearch.username"=$OPENSEARCH_USER \
    --set="config.receivers[0].opensearch.password"=$OPENSEARCH_PASSWORD \
    --set="config.receivers[0].opensearch.hosts[0]"="https://$OPENSEARCH_HOST" \
    --wait
```







