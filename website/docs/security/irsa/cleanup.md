---
title: "Cleanup"
sidebar_position: 70
---

Run the following command to reset the EKS cluster:

```bash timeout=300 wait=30
$ reset-environment 
```

The `carts` service will be reconfigured to use the lightweight DynamoDB service deployed as Pod `carts-dynamodb-xxxxxxxxxx-xxxxx` and the `carts-dynamo` config map will be deleted.




