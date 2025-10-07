#!/bin/bash

set -e

# Delete the Job
kubectl delete job data-processor -n catalog --ignore-not-found=true

# Delete the CronJob
kubectl delete cronjob catalog-cleanup -n catalog --ignore-not-found=true

# Delete any manually created jobs from CronJob
kubectl delete job manual-cleanup -n catalog --ignore-not-found=true

# Delete any jobs that start with catalog-cleanup (created by CronJob)
kubectl get jobs -n catalog -o name | grep "job/catalog-cleanup" | xargs -r kubectl delete -n catalog --ignore-not-found=true