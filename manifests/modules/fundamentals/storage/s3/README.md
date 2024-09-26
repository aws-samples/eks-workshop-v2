Below are instructions to go through the S3 Module Lab

Goal: Show that container can access images within S3 bucket and write to it

# Step 1: Prepare the environment

prepare-environment fundamentals/storage/s3

# Step 2: Show assets deployment in its current state

kubectl describe deployment -n assets

# Step 3: Show deployment images

kubectl exec --stdin deployment/assets \
 -n assets -- bash -c "ls /usr/share/nginx/html/assets/"

# Step 4: Scale up deployment for multiple replicas

kubectl scale -n assets --replicas=2 deployment/assets
kubectl rollout status -n assets deployment/assets --timeout=60s

# Step 5: Put image in first pod

POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')
kubectl exec --stdin $POD_NAME \
 -n assets -- bash -c 'touch /usr/share/nginx/html/assets/horse.jpg'

# Step 6: Confirm image not in second pod

POD_NAME=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')
kubectl exec --stdin $POD_NAME \
 -n assets -- bash -c 'ls /usr/share/nginx/html/assets'

----------- Setup S3 Bucket ------------------

# Step: Create directory for images

mkdir assets-images

# Step: Bring retail store files to environment

cd assets-images

curl --remote-name-all https://raw.githubusercontent.com/aws-containers/retail-store-sample-app/main/src/assets/public/assets/{chrono_classic.jpg,gentleman.jpg,pocket_watch.jpg,smart_2.jpg,wood_watch.jpg}

ls -l

# Step: Copy local files into S3 bucket (Permission Error!)

aws s3 cp . s3://$BUCKET_NAME/

# Step : Navigate to S3 bucket and see files

aws s3 ls $BUCKET_NAME


----- Configure Kub --------

# Step 7: Attach addon to EKS cluster

eksctl create addon --name aws-mountpoint-s3-csi-driver --cluster $EKS_CLUSTER_NAME --service-account-role-arn $S3_CSI_ADDON_ROLE --force

# Step 8: Show mountpoint nodes exist

kubectl get daemonset s3-csi-node -n kube-system

# Step 9: Show and explain  PV and PVC file

Add explanatory comments for mountOptions in PV

# Step : Run kustomize to create PV, PVC, and patch deployment

kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/s3/deployment \
  | envsubst | kubectl apply -f-

# Step : Wait for rollout to occur

kubectl rollout status --timeout=130s deployment/assets -n assets

# Step : See volume mounts on deployment

kubectl get deployment -n assets \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'

# Step : Show PV and PVC

kubectl get pv

kubectl describe pvc -n assets

# Step: Go into assets container within first pod and list files at mountpoint-s3

POD_1=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_1 -n assets -c assets -- /bin/sh
id
cd mountpoint-s3
ls -l

# Step: Add file to the mountpoint-s3 folder from Pod 1

touch 'hi_from_pod_1.jpg'
exit

# Step: Go into assets container within second pod and list files at mountpoint-s3, notice extra

POD_2=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')
kubectl exec -it $POD_2 -n assets -c assets -- /bin/sh
id
cd mountpoint-s3
ls -l

# Step: Add file to the mountpoint-s3 folder from Pod 2

touch 'hi_from_pod_2.jpg'
exit

# Step: Go to S3 bucket and list contents, notice 2 extra files

aws s3 ls $BUCKET_NAME


### EXTRA INFORMATION

# Run this to view persistent volumes/storage class

kubectl get pv
kubectl get pvc -n assets
kubectl get pods -n assets
kubectl get deployment -n assets
