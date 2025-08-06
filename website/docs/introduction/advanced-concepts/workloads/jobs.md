---
title: Jobs
sidebar_position: 30
---

# Jobs and CronJobs

Jobs run pods to completion for batch processing, data migration, and one-time tasks. CronJobs schedule Jobs to run at specific times, like traditional cron jobs.

## Job Types Overview

| Type | Purpose | Execution | Examples |
|------|---------|-----------|----------|
| **Job** | One-time batch processing | Run to completion | Data migration, backup, batch processing |
| **CronJob** | Scheduled recurring tasks | Time-based scheduling | Daily backups, report generation, cleanup |

## When to Use Jobs

### Perfect for:
- **Data processing** - ETL jobs, batch analytics, data transformation
- **Maintenance tasks** - Database migrations, cleanup scripts, backups
- **Initialization** - Application setup, database seeding, configuration
- **Batch workloads** - Image processing, report generation, data exports

### Not suitable for:
- **Long-running services** - Use Deployments instead
- **System services** - Use DaemonSets instead
- **Interactive applications** - Use Deployments with Services

## Creating Your First Job

Let's create a simple Job that processes some data:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: data-processor
spec:
  template:
    spec:
      containers:
      - name: processor
        image: busybox
        command: ['sh', '-c', 'echo "Processing data..."; sleep 30; echo "Data processing complete!"']
      restartPolicy: Never
  backoffLimit: 4
EOF
```

## Understanding Job Configuration

### Key Fields
- **template** - Pod specification (like Deployment)
- **restartPolicy** - Must be `Never` or `OnFailure`
- **backoffLimit** - Maximum retry attempts (default: 6)
- **completions** - Number of successful completions needed
- **parallelism** - Number of pods to run in parallel

### Observing Job Execution
```bash
$ kubectl get jobs
NAME             COMPLETIONS   DURATION   AGE
data-processor   1/1           45s        1m

$ kubectl get pods -l job-name=data-processor
NAME                   READY   STATUS      RESTARTS   AGE
data-processor-abc12   0/1     Completed   0          1m
```

### Viewing Job Logs
```bash
$ kubectl logs job/data-processor
Processing data...
Data processing complete!
```

## Job Patterns

### 1. Single Job (Default)
Runs one pod to completion:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: single-job
spec:
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c', 'echo "Single job execution"']
      restartPolicy: Never
```

### 2. Parallel Jobs with Fixed Completion Count
Runs multiple pods, needs specific number of completions:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-job
spec:
  completions: 5      # Need 5 successful completions
  parallelism: 2      # Run 2 pods at a time
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c', 'echo "Worker $(hostname)"; sleep 10']
      restartPolicy: Never
```

### 3. Parallel Jobs with Work Queue
Multiple pods process items from a shared queue:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: queue-job
spec:
  parallelism: 3      # Run 3 workers
  # No completions specified - pods coordinate completion
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c', 'echo "Processing queue item"; sleep 15']
      restartPolicy: Never
```

## Real-World Example: Database Migration

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
spec:
  template:
    spec:
      containers:
      - name: migrator
        image: migrate/migrate
        command:
        - migrate
        - -path
        - /migrations
        - -database
        - postgres://user:password@db:5432/mydb?sslmode=disable
        - up
        env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: host
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        volumeMounts:
        - name: migrations
          mountPath: /migrations
      volumes:
      - name: migrations
        configMap:
          name: migration-scripts
      restartPolicy: Never
  backoffLimit: 3
EOF
```

## CronJobs

CronJobs create Jobs on a schedule using cron syntax.

### Creating a CronJob

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-backup
spec:
  schedule: "0 2 * * *"  # Every day at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: busybox
            command: ['sh', '-c', 'echo "Running daily backup at $(date)"']
          restartPolicy: OnFailure
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
EOF
```

### Cron Schedule Syntax
```
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of the month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of the week (0 - 6) (Sunday to Saturday)
# │ │ │ │ │
# * * * * *
```

Common examples:
- `"0 2 * * *"` - Daily at 2 AM
- `"*/15 * * * *"` - Every 15 minutes
- `"0 0 * * 0"` - Weekly on Sunday at midnight
- `"0 0 1 * *"` - Monthly on the 1st at midnight

### CronJob Configuration

```yaml
spec:
  schedule: "0 2 * * *"
  concurrencyPolicy: Forbid  # Allow, Forbid, or Replace
  suspend: false             # Pause scheduling
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  startingDeadlineSeconds: 300  # Latest start time
```

### Concurrency Policies
- **Allow** - Multiple jobs can run concurrently
- **Forbid** - Skip new job if previous is still running
- **Replace** - Cancel running job and start new one

## Advanced Job Patterns

### Job with Init Container
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: job-with-init
spec:
  template:
    spec:
      initContainers:
      - name: setup
        image: busybox
        command: ['sh', '-c', 'echo "Setting up environment"']
      containers:
      - name: main
        image: busybox
        command: ['sh', '-c', 'echo "Running main task"']
      restartPolicy: Never
```

### Job with Persistent Storage
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: job-with-storage
spec:
  template:
    spec:
      containers:
      - name: processor
        image: busybox
        command: ['sh', '-c', 'echo "Processing data" > /data/result.txt']
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: job-data-pvc
      restartPolicy: Never
```

### Indexed Job (Kubernetes 1.21+)
Process specific items by index:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: indexed-job
spec:
  completions: 5
  parallelism: 2
  completionMode: Indexed
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c', 'echo "Processing item $JOB_COMPLETION_INDEX"']
      restartPolicy: Never
```

## Monitoring Jobs

### Check Job Status
```bash
$ kubectl get jobs
$ kubectl describe job <job-name>
```

### View Job Pods
```bash
$ kubectl get pods -l job-name=<job-name>
```

### Check CronJob Status
```bash
$ kubectl get cronjobs
NAME           SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
daily-backup   0 2 * * *   False     0        <none>          5m
```

### View CronJob History
```bash
$ kubectl get jobs -l cronjob=daily-backup
```

## Troubleshooting Jobs

### Job Not Completing
```bash
$ kubectl describe job <job-name>
# Check events and conditions

$ kubectl logs job/<job-name>
# Check application logs
```

### Pod Failures
```bash
$ kubectl get pods -l job-name=<job-name>
$ kubectl describe pod <pod-name>
$ kubectl logs <pod-name> --previous  # Previous container logs
```

### CronJob Not Running
```bash
$ kubectl describe cronjob <cronjob-name>
# Check schedule and suspend status

$ kubectl get events --field-selector involvedObject.kind=CronJob
```

### Resource Issues
```bash
$ kubectl top nodes
$ kubectl describe node <node-name>
# Check resource availability
```

## Best Practices

### 1. Set Resource Limits
```yaml
spec:
  template:
    spec:
      containers:
      - name: worker
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### 2. Use Appropriate Restart Policy
```yaml
# For Jobs
restartPolicy: Never      # Don't restart failed containers
# OR
restartPolicy: OnFailure  # Restart failed containers
```

### 3. Configure Backoff Limit
```yaml
spec:
  backoffLimit: 3  # Retry failed jobs up to 3 times
```

### 4. Set Active Deadline
```yaml
spec:
  activeDeadlineSeconds: 3600  # Kill job after 1 hour
```

### 5. Clean Up Completed Jobs
```yaml
# For CronJobs
spec:
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1

# Or use TTL for Jobs (Kubernetes 1.21+)
spec:
  ttlSecondsAfterFinished: 86400  # Delete after 24 hours
```

### 6. Handle Secrets Securely
```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: password
```

### 7. Use Init Containers for Setup
```yaml
initContainers:
- name: wait-for-db
  image: busybox
  command: ['sh', '-c', 'until nc -z db 5432; do sleep 1; done']
```

## Real-World Examples

### Daily Database Backup
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: db-backup
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:13
            command:
            - pg_dump
            - -h
            - postgres-service
            - -U
            - postgres
            - mydb
            env:
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

### Log Cleanup Job
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: log-cleanup
spec:
  schedule: "0 0 * * 0"  # Weekly on Sunday
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: cleanup
            image: busybox
            command:
            - find
            - /var/log
            - -name
            - "*.log"
            - -mtime
            - "+7"
            - -delete
            volumeMounts:
            - name: logs
              mountPath: /var/log
          volumes:
          - name: logs
            hostPath:
              path: /var/log
          restartPolicy: OnFailure
```

## Cleanup

Remove the Jobs and CronJobs we created:

```bash
$ kubectl delete job data-processor parallel-job queue-job db-migration
$ kubectl delete cronjob daily-backup
```

## What's Next?

You've now learned about all the major workload types in Kubernetes:
- **Deployments** - Stateless applications
- **StatefulSets** - Stateful applications  
- **DaemonSets** - Node-level services
- **Jobs/CronJobs** - Batch processing

Next, let's explore [Nodes](../nodes) to learn about advanced scheduling and node management.