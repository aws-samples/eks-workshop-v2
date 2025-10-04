---
title: Jobs & CronJobs
sidebar_position: 34
sidebar_custom_props: { "module": true }
---

# Jobs & CronJobs

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/basics/jobs
```

:::

**Jobs** and **CronJobs** are controllers for running **finite or recurring tasks**. Unlike Deployments or StatefulSets that keep pods running continuously, Jobs run tasks to completion, and CronJobs run Jobs on a schedule.

Key benefits:
- **Run to completion** - Pods finish the task and stop
- **Retry failed tasks** - Automatically retry based on backoff policy
- **Parallel execution** - Multiple Pods can run simultaneously
- **Scheduled tasks** - CronJobs run tasks at specific times
- **Track history** - Monitor successful and failed completions

## When to Use Jobs & CronJobs

**Use Jobs for:**
- Database migrations and schema updates
- Data processing and ETL operations
- One-time setup tasks and initialization
- Backup operations and file processing

**Use CronJobs for:**
- Regular backups (daily, weekly)
- Cleanup tasks and log rotation
- Report generation and data synchronization
- Periodic health checks and monitoring

## Deploying a Job

Let's create a database migration job:

::yaml{file="manifests/modules/introduction/basics/jobs/migration-job.yaml" paths="kind,metadata.name,spec.completions,spec.backoffLimit,spec.template.spec.restartPolicy" title="migration-job.yaml"}

1. `kind: Job`: Creates a Job controller
2. `metadata.name`: Name of the job (catalog-migration)
3. `spec.completions`: Number of successful completions needed (1)
4. `spec.backoffLimit`: Maximum retry attempts (3)
5. `spec.template.spec.restartPolicy`: Pods never restart on failure; the Job controller handles retries

Deploy the job:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/jobs/migration-job.yaml
```

## Inspecting Your Job

Check job status:
```bash
$ kubectl get jobs -n catalog
```

You'll see output showing completions and duration:
```
NAME                COMPLETIONS   DURATION   AGE
catalog-migration   1/1           45s        2m
```

View the job's pod:
```bash
$ kubectl get pods -n catalog -l job-name=catalog-migration
```

Check job logs:
```bash
$ kubectl logs -n catalog job/catalog-migration
```

Get detailed job information:
```bash
$ kubectl describe job -n catalog catalog-migration
```

## Deploying a CronJob

Let's create a daily backup CronJob:

::yaml{file="manifests/modules/introduction/basics/jobs/backup-cronjob.yaml" paths="kind,metadata.name,spec.schedule,spec.jobTemplate" title="backup-cronjob.yaml"}

1. `kind: CronJob`: Creates a CronJob controller
2. `metadata.name`: Name of the CronJob (`catalog-backup`)
3. `spec.schedule`: Cron schedule (`0 2 * * *` = daily at 2 AM)
4. `spec.jobTemplate`: Template for jobs that will be created

Deploy the CronJob:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/jobs/backup-cronjob.yaml
```

## Managing CronJobs

View CronJobs:
```bash
$ kubectl get cronjobs -n catalog
```

You'll see the schedule and last run time:
```
NAME             SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
catalog-backup   0 2 * * *   False     0        23h             1d
```

View jobs created by the CronJob:
```bash
$ kubectl get jobs -n catalog -l cronjob=catalog-backup
```

Manually trigger a CronJob:
```bash
$ kubectl create job --from=cronjob/catalog-backup manual-backup -n catalog
```

## Common Cron Schedules

| Schedule | Description |
|----------|-------------|
| `0 2 * * *` | Daily at 2 AM |
| `0 */6 * * *` | Every 6 hours |
| `0 0 * * 0` | Every Sunday at midnight |
| `*/15 * * * *` | Every 15 minutes |
| `0 9 * * 1-5` | Weekdays at 9 AM |

## Parallel Jobs

For processing multiple items simultaneously:

```yaml
spec:
  completions: 10      # Process 10 items total
  parallelism: 3       # Run 3 pods at once
```
- `completions` = total number of successful Pods
- `parallelism` = how many Pods run concurrently

This creates 10 successful completions using 3 parallel pods.

## Jobs vs Other Controllers
| Controller | Purpose | Pods run continuously? | Use Case |
|------------|---------|---------------|----------------|
| Job  | One-off task | No | Batch processing, migrations |
| CronJob  | Scheduled jobs | No | Backups, periodic reports |
| Deployment | Long-running stateless app | Yes | Web apps, APIs |
| StatefulSet | Stateful services | Yes | Databases, queues |

## Key Points to Remember

* Jobs run pods until tasks complete successfully
* CronJobs create Jobs automatically on schedules
* Use `restartPolicy: Never` for Jobs and `OnFailure` for CronJobs
* Set backoff limits to control retry attempts
* Jobs can run multiple pods in parallel for faster processing
* Clean up completed Jobs to avoid resource accumulation
* Jobs and CronJobs are ideal for finite or recurring batch tasks, not long-running services