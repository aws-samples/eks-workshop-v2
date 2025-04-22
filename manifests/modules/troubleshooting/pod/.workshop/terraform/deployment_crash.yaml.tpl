---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${filesystemid}
  directoryPerms: "700"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 20Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: efs-app
  labels:
    app: efs-app
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector: 
    matchLabels:
      app: efs-app
  template:
    metadata:
      labels:
        app: efs-app
    spec:
      containers:
      - name: app
        image: public.ecr.aws/docker/library/centos:latest
        command: ["/bin/sh"]
        args: ["-c", "while true; do echo $(date -u) >> /example/out.txt; sleep 5; done"]
        volumeMounts:
          - name: persistent-storage
            mountPath: /example
      volumes:
      - name: persistent-storage
        persistentVolumeClaim:
          claimName: efs-claim