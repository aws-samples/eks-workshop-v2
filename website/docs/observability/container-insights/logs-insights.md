---
title: "Using CloudWatch Logs Insights to View Container Insights Data"
sidebar_position: 30
weight: 5
---

Container Insights collects metrics by using performance log events with using [embedded metric format](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format.html). The logs are stored in CloudWatch Logs. CloudWatch generates several metrics automatically from the logs which you can view in the CloudWatch console. You can also do a deeper analysis of the performance data that is collected by using CloudWatch Logs Insights queries.

:::note
It may take a few minutes for data to start appearing in CloudWatch
:::

**To use CloudWatch Logs Insights to query your container metric data**

1. Open the CloudWatch console at [https://console.aws.amazon.com/cloudwatch/](https://console.aws.amazon.com/cloudwatch/).

2. In the navigation pane, under **Logs choose Logs Insights.**

    Near the top of the screen is the query editor. When you first open CloudWatch Logs Insights, this box contains a default query that returns the 20 most recent log events.

3. In the search box above the query editor, select one of the Container Insights log groups to query. For the following example queries to work, selecr the log group name that is ending with **performance**.
    
    When you select a log group and run the query, CloudWatch Logs Insights automatically detects fields in the data in the log group and displays them in **Discovered fields** in the right pane. It also displays a bar graph of log events in this log group over time. This bar graph shows the distribution of events in the log group that matches your query and time range, not only the events displayed in the table.
    
4. In the query editor, replace the default query with the following query and choose **Run query.**
    ```````
    STATS avg(node_cpu_utilization) as avg_node_cpu_utilization by NodeName
    | SORT avg_node_cpu_utilization DESC 
    ````````
    ![Query1](/img/container-insights/query1.jpg)

    This query shows a list of nodes, sorted by average node CPU utilization.


5. To try another example, replace that query with another query and choose **Run query.**
    `````
    STATS avg(number_of_container_restarts) as avg_number_of_container_restarts by PodName
    | SORT avg_number_of_container_restarts DESC
    `````
    ![Query2](/img/container-insights/query2.jpg)

    This query displays a list of your pods, sorted by average number of container restarts.
    
6. If you want to try another query, you can use include fields in the list at the right of the screen. For more information about query syntax, see [CloudWatch Logs Insights Query Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html).


