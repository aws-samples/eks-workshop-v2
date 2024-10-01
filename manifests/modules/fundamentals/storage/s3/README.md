Below are instructions for the S3 Module Lab

Goal: Show customers how Kubernetes pod can access S3 bucket objects and interact with bucket using Mountpoint for S3

(1) Showcase limitations of EKS temporary pod storage
(2) Fill S3 bucket with objects
(3) Show pods having access to S3 objects and be able to write to S3 bucket


# Step 1: Prepare the environment

prepare-environment fundamentals/storage/s3

------------ EKS Limitation -------------------

# Step 2: Show assets deployment in its current state

kubectl describe deployment -n assets

# Step 3: Show deployment images

kubectl exec --stdin deployment/assets \
 -n assets -- bash -c "ls /usr/share/nginx/html/assets/"

# Step 4: Scale up deployment for multiple replicas

kubectl scale -n assets --replicas=2 deployment/assets
kubectl rollout status -n assets deployment/assets --timeout=60s

# Step 5: Put image in first pod

POD_1=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')

kubectl exec --stdin $POD_1 \
 -n assets -- bash -c 'touch /usr/share/nginx/html/assets/watch_band.jpg'

kubectl exec --stdin $POD_1 \
-n assets -- bash -c 'ls /usr/share/nginx/html/assets'

# Step 6: Confirm 'watch_band.jpg' not in second pod, need shared storage!

POD_2=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')

kubectl exec --stdin $POD_2 \
 -n assets -- bash -c 'ls /usr/share/nginx/html/assets'

----------- Setup S3 Bucket ------------------

# Step 7: Create directory for images in local environment

mkdir assets-images

# Step 8: Bring retail store files into environment via 'curl' command

cd assets-images

curl --remote-name-all https://raw.githubusercontent.com/aws-containers/retail-store-sample-app/main/src/assets/public/assets/{chrono_classic.jpg,gentleman.jpg,pocket_watch.jpg,smart_2.jpg,wood_watch.jpg}

ls -l

# Step 9: Copy local files into S3 bucket

cd ..
aws s3 cp assets-images/ s3://$BUCKET_NAME/ --recursive

# Step 10: Use AWS CLI to see files in S3 bucket

aws s3 ls $BUCKET_NAME


----- Configure EKS pods access to S3 bucket files --------

# Step 11: Attach addon to EKS cluster, takes a minute or so

eksctl create addon --name aws-mountpoint-s3-csi-driver --cluster $EKS_CLUSTER_NAME --service-account-role-arn $S3_CSI_ADDON_ROLE --force

# Step 12: Show mountpoint nodes exist

kubectl get daemonset s3-csi-node -n kube-system

# Step 13: Show and explain deployment/s3pvclaim.yaml

Add explanatory comments for mountOptions in PV

Most are needed because of the restrictions on the public.ecr.aws/aws-containers/retail-store-sample-assets:0.4.0 image used in deployment/deployment.yaml

# Step 14: Run deployment/kustomization.yaml to create PV, PVC, and patch deployment

kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/s3/deployment \
  | envsubst | kubectl apply -f-

# Step 15: Wait for rollout to occur

kubectl rollout status --timeout=130s deployment/assets -n assets

# Step 16: View all volume mounts on deployment, note /mountpoint-s3

kubectl get deployment -n assets \
  -o yaml | yq '.items[].spec.template.spec.containers[].volumeMounts'

# Step 17: View PV, PVC, pods, deployment (note static provisioning limitation for S3 CSI Driver)

kubectl get pv
kubectl get pvc -n assets
kubectl get pods -n assets
kubectl describe deployment -n assets

# Step 18: Go into first pod and list files at /mountpoint-s3/

POD_1=$(kubectl -n assets get pods -o jsonpath='{.items[0].metadata.name}')

kubectl exec --stdin $POD_1 \
 -n assets -- bash -c 'ls /mountpoint-s3/'


# Step 19: Add file to the mountpoint-s3 folder in Pod 1

kubectl exec --stdin $POD_1 \
 -n assets -- bash -c 'touch /mountpoint-s3/newproduct_1.jpg'

# Step 20: Go into second pod and list files, notice new file from Pod 1!

POD_2=$(kubectl -n assets get pods -o jsonpath='{.items[1].metadata.name}')

kubectl exec --stdin $POD_2 \
 -n assets -- bash -c 'ls /mountpoint-s3/'

# Step 21: Add file to the mountpoint-s3 folder from Pod 2

kubectl exec --stdin $POD_2 \
 -n assets -- bash -c 'touch /mountpoint-s3/newproduct_2.jpg'


# Step 22: Go to S3 bucket and list contents, notice 2 files from pods are now here

aws s3 ls $BUCKET_NAME