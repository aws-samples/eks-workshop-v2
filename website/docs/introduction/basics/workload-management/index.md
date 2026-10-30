---
title: Workload Management
sidebar_position: 30
---

# Workload Management
While you can create individual pods directly, in production you rarely manage pods manually. Instead, you use **workload controllers** - higher-level Kubernetes resources that create and manage pods according to different application patterns.

Think of workload controllers as smart managers that:
- **Create pods** based on templates you define
- **Monitor pod health** and replace failed instances
- **Handle scaling** up and down based on demand
- **Manage updates** with strategies like rolling deployments
- **Provide specialized behavior** for different application types

## Types of Workload Controllers
Kubernetes provides several workload controllers, each designed for specific use cases:

- **Deployments** manage multiple identical pods for stateless applications. They handle scaling, rolling updates, and automatic replacement of failed pods. Perfect for web applications where any pod can handle any request.
- **ReplicaSets** ensure a specified number of identical pods are running at any time. While you rarely create ReplicaSets directly, they're the building blocks that Deployments use under the hood to manage pods.
- **StatefulSets** provide stable identities and persistent storage for stateful applications. Each pod gets a unique name (like `mysql-0`, `mysql-1`) and its own persistent volume. Essential for databases and clustered applications.
- **DaemonSets** ensure exactly one pod runs on each node (or selected nodes). Great for system-level services like log collectors or monitoring agents that need to run everywhere in your cluster.
- **Jobs** run pods until they complete successfully, then stop. Unlike other controllers, they don't restart completed pods. Ideal for one-time tasks like data migrations or batch processing.
- **CronJobs** create Jobs on a schedule using familiar cron syntax. They're perfect for recurring tasks like backups, report generation, or cleanup operations.

## Understanding the Controller Hierarchy

It's helpful to understand how these controllers relate to each other:

**Deployment → ReplicaSet → Pods**

When you create a Deployment, here's what happens:
1. **Deployment** creates and manages ReplicaSets
2. **ReplicaSet** creates and manages the actual Pods
3. **Pods** run your application containers

This layered approach enables powerful features:
- **Rolling updates**: Deployments create new ReplicaSets while gradually scaling down old ones
- **Rollbacks**: Deployments can switch back to previous ReplicaSet versions
- **Scaling**: Changes to replica count flow through ReplicaSets to Pods

You'll often see ReplicaSets when debugging (like `kubectl get rs`), but you typically manage them indirectly through Deployments.

### Why Use Workload Controllers?

**Managing pods directly:**
- Manual pod replacement when they fail
- No built-in scaling mechanisms  
- Complex update procedures
- No rollback capabilities
- Production management becomes difficult

**Using workload controllers:**
- Automatic pod replacement and healing
- Easy scaling with a single command
- Rolling updates with zero downtime
- Simple rollback to previous versions
- Production-ready management

| Controller | Purpose | Best For |
|------------|---------|----------|
| **Deployments** | Stateless applications | Web apps, APIs, microservices |
| **ReplicaSets** | Maintain pod replicas | Usually managed by Deployments |
| **StatefulSets** | Stateful applications | Databases, message queues |
| **DaemonSets** | Node-level services | Logging agents, monitoring |
| **Jobs** | Run-to-completion tasks | Data migration, batch processing |
| **CronJobs** | Scheduled tasks | Backups, reports, cleanup |

### Choosing the Right Workload Controller

Ask yourself these questions to pick the right controller:

**What type of application am I running?**

- **Web app, API, or microservice?** → Use **Deployment**
  - Pods are interchangeable and stateless
  - Can run multiple identical copies
  - Example: Our retail store UI, catalog service

- **Database or message queue?** → Use **StatefulSet**  
  - Needs persistent storage
  - Requires stable network identity
  - Example: MySQL database, Kafka cluster

- **System service on every node?** → Use **DaemonSet**
  - Monitoring, logging, or networking
  - One pod per node automatically
  - Example: Log collector, node monitoring

- **One-time task or batch job?** → Use **Job**
  - Runs until completion
  - Database migration, data processing
  - Example: Import product catalog

- **Recurring scheduled task?** → Use **CronJob**
  - Runs on a schedule (like cron)
  - Backups, reports, cleanup
  - Example: Daily sales report generation

## Key Points to Remember

* Different workload controllers serve different application patterns
* Deployments are for stateless applications that can have identical replicas
* StatefulSets are for stateful applications that need persistent identity
* DaemonSets ensure pods run on every node for system-level services
* Jobs run tasks to completion, CronJobs run them on schedule
* Choose the right controller based on your application's requirements

## Explore Each Workload Type

Now that you have an overview of workload controllers, dive deeper into each type:

- **[Deployments](./deployments)** - Learn to deploy and manage stateless applications like our retail store UI
- **[StatefulSets](./statefulsets)** - Understand how to run stateful applications like databases with persistent storage
- **[DaemonSets](./daemonsets)** - Explore system-level services that run on every node
- **[Jobs & CronJobs](./jobs)** - Master batch processing and scheduled tasks

