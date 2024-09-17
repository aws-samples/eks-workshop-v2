Below are instructions to go through the S3 Module Lab

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

# Step 7: Attach addon to EKS cluster

eksctl create addon --name aws-mountpoint-s3-csi-driver --cluster $EKS_CLUSTER_NAME --service-account-role-arn $S3_CSI_ADDON_ROLE --force

# Step 8: Show mountpoint nodes exist

kubectl get daemonset s3-csi-node -n kube-system

# Step 9: Create PV and PVC separately

envsubst < ~/environment/eks-workshop/modules/fundamentals/storage/s3/deployment/s3pvclaim.yaml | kubectl apply -f -

# Step 10: Deploy patch to assets deployment to mount S3 bucket and copy files

# Run this to execute deployment.yaml

kubectl patch deployment assets -n assets --patch "$(cat ~/environment/eks-workshop/modules/fundamentals/storage/s3/deployment/deployment.yaml)"

# Run this to execute kustomization.yaml

kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/s3/deployment

# Step : Interact with deployment

# Step : Navigate to S3 bucket and see file

### EXTRA INFORMATION

# Run this to view persistent volumes/storage class

kubectl get pv
kubectl get pvc -n assets
kubectl get pods -n assets
