---
title: "Observability with OpenSearch"
sidebar_position: 40
sidebar_custom_props: {"module": true}
---

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=30 hook=install
$ prepare-environment observability/opensearch
```

This will make the following changes to your lab environment:
- Provisiong an OpenSearch domain

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/opensearch/.workshop/terraform).

:::

The steps are: 
1. pull this helm chart - https://artifacthub.io/packages/helm/bitnami/kubernetes-event-exporter, 
2. set up an opensearch instance that's publicly available with a user/pass. 
3. Enter user/pass info with other config info in helm values chart and deploy. 
4. create a pod with an error - wrong image, port, etc. 
5. user logs into opensearch, creates an index, and searches for errors. 
6. finds pod error. 
7. fixes pod spec and watches error disappear. Would this scenario work, and should @alidonmez make any modifications?



In this lab, we'll ...

OpenSearch is ... 

Kubernetes events are ... 

 

In this lab, we'll learn about the following concepts:



We have provisioned an OpenSearch domain. Let's retrieve some information about it that will be used later:


TODO: Add architecture diagram


```bash
$ export OPENSEARCH_HOST=$(aws ssm get-parameter --region $AWS_REGION --name /eksworkshop/$EKS_CLUSTER_NAME/opensearch/host  | jq .Parameter.Value)
$ export OPENSEARCH_USER=$(aws ssm get-parameter --region $AWS_REGION --with-decryption --name /eksworkshop/$EKS_CLUSTER_NAME/opensearch/user  | jq .Parameter.Value)
$ export OPENSEARCH_PASSWORD=$(aws ssm get-parameter --region $AWS_REGION --with-decryption --name /eksworkshop/$EKS_CLUSTER_NAME/opensearch/password  | jq .Parameter.Value)
$ printf "\nOpenSearch dashboard: https://$OPENSEARCH_HOST/_dashboards \nUsername: $OPENSEARCH_USER \nPassword: $OPENSEARCH_PASSWORD\n\n"
```



See OpenSearch indices


1. Create new OpenSearch index for Kubernetes events
1. 



```bash
$ curl -X PUT -H 'Content-Type: application/json' -u $OPENSEARCH_USER:$OPENSEARCH_PASSWORD \
  "https://$OPENSEARCH_HOST/eks-kubernetes-events" -d '{"settings":{"index":{"number_of_replicas":0}}}'

$ curl -u $OPENSEARCH_USER:$OPENSEARCH_PASSWORD "https://$OPENSEARCH_HOST/_cat/indices?v"

```


Your output should look like this: 
```

```




Create dashboard cookie and load 

```bash
$ curl https://$OPENSEARCH_HOST/_dashboards/auth/login \
      -H 'content-type: application/json' \
      -H 'osd-xsrf: osd-fetch' \
      --data-raw '{"username":"'"$OPENSEARCH_USER"'","password":"'"$OPENSEARCH_PASSWORD"'"}' \
      -c dashboards_cookie

$ curl -X POST https://$OPENSEARCH_HOST/_dashboards/api/saved_objects/_import?overwrite=true \
      -H "osd-xsrf: true" --form file=@kubernetes-events-dashboard.ndjson  -b dashboards_cookie

```