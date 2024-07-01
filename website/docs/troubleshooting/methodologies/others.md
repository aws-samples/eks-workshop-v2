---
title: "Other Methods"
sidebar_position: 14
---

This section contains details and references for a number of other problem solving methods. We suggest researching other methods as many of them include useful techniques that can be used, regardless of the primary method chosen. Here is a list of other methods, including a number of proprietary problem solving systems.

### The Scientific method

An ever-evolving and age-old system used by scientists world-wide, the scientific method is a process for experimentation that is used to explore observations and answer questions. Generally, it consists of the following steps:

- Gather information or make an observation
- State the Problem or ask a question
- Form a hypothesis
- Make a prediction
- Test the hypothesis
- Observe Results & Draw conclusions
- Repeat as necessary

The scientific method is almost always an iterative process, with the outcome of one round of hypothesis testing feeding into the next. In this workshop, we assume mutating changes are a last resort when troubleshooting, unless the issue is able to be reproduced in a controlled environment. So we will be focusing on "read only" root cause analysis where possible. For an excellent overview of the scientific method, please see the following pages:

- [Troubleshooting with the Scientific Method ](https://www.inetdaemon.com/tutorials/troubleshooting/scientific_method.shtml)
- [The scientific method ](https://www.khanacademy.org/science/biology/intro-to-biology/science-of-biology/a/the-science-of-biology)

### Ishikawa diagrams

Ishikawa diagrams (also called fishbone diagrams or cause-and-effect diagrams) help you to determine the root cause by identifying possible causes of an issue. We suggest building collaborative diagrams, inviting your team members to ensure all the potential causes are identified. It is also important to note that some causes may have multiple sub-causes, so we also suggest expanding your diagram in a hierarchical manner to encompass all possible causes.

For more information and examples of Ishikawa diagrams, please see the following page:

Fishbone Diagram: A Tool to Organize a Problem’s Cause and Effect

### Trial-and-error

Also called the scattergun approach, trial-and-error is often a last resort, or a method used when panic sets in. Whilst it can be used in controlled environments where it is clear that an issue is caused by or fixed by a lever or configuration, it is far from ideal. Whilst flipping a switch may fix the problem, making mutating changes before understanding root cause is not ideal, as the issue may not be properly fixed, or there could be another factor at play, with the issue being indirectly "fixed" and root cause still not being understood. We often also change too many variables and don't observe enough in between changes.

As an example, say you have a web application running on an EC2 instance. One day, the application stops working and you see failures when trying to access the application. Looking at CloudWatch metrics, CPU Utilization is at 100%. You stop the EC2 instance, change the instance type to one with more vCPUs and start it again. The instance starts, the application is bootstrapped, but you still see the same issue - errors and 100% CPU Utilization. Perhaps it is a problem with the new version of the application, so your team roll back to the previous version. The issue persists. Maybe it is running out of memory and CPU is spiking because it is continually paging, moving data from memory to disk and vice-versa continuously. You change the instance type to one with more memory and this time, everything works!

Whilst you were able to bring the application back to a working state, there was no methodical approach taken to identify the root cause so that a targeted fix could be put in. The application is now running, but until we understand the root cause, we don't know how long until it happens again.
