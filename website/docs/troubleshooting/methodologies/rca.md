---
title: "Root Cause Analysis (RCA)"
sidebar_position: 11
---

Root Cause Analysis (RCA) helps in identifying how and why an event or failure happened, allowing for corrective and preventive measures to be put in place.

### Importance of root cause analysis

In the heat of an investigation, it can be tempting to find and implement a quick fix. However, the risk is two-fold:

Further investigation and deep root cause analysis with persistent fix(es) may be deprioritized.
Correcting the immediate cause may eliminate a symptom of a problem, but not the problem itself. As the underlying cause has not been eliminated, the issue may occur again in the future.
RCA generally serves as input to a remediation process whereby corrective actions are taken to prevent the problem from reoccurring.

### Method

The method varies somewhat depending on the flavour used, however most schools of root cause analysis cover the following steps:

1. Identify and describe the problem clearly.
2. Collect data
3. Establish a timeline from the normal situation until the problem occurs.
4. Identify Root Cause
5. Distinguish between the root cause and other causal factors (e.g., using event correlation).
6. Establish a causal graph between the root cause and the problem.
7. Although the word "cause" is singular in RCA, experience shows that generally causes are plural. Therefore, look for multiple causes when carrying out RCA.

### Method

The method varies somewhat depending on the flavour used, however most schools of root cause analysis cover the following steps:

1. Identify and describe the problem clearly.
2. Collect data
3. Establish a timeline from the normal situation until the problem occurs.
4. Identify Root Cause
5. Distinguish between the root cause and other causal factors (e.g., using event correlation).
6. Establish a causal graph between the root cause and the problem.
7. Although the word "cause" is singular in RCA, experience shows that generally causes are plural. Therefore, look for multiple causes when carrying out RCA.

### Correction of Errors

Once root cause has been established and you are no longer seeing impact, use a Correction Of Errors process. This will enable you to:

1. Prevent a reoccurrence.
2. Should preventative measures fail, reduce impact of the next occurrence.
3. Improve observability and investigative ability to determine root cause should something similar happen again.

We suggest using AWS Systems Manager Incident Manager , an incident management console designed to help you mitigate and recover from incidents affecting your AWS-hosted applications. Post-incident analysis guides you through identifying improvements to your incident response, including time to detection and mitigation. An analysis can also help you understand the root cause of the incidents. Incident Manager creates recommended action items to improve your incident response.

### Five whys

Five Whys is a linear, repetitive root cause analysis method used to explore the cause-and-effect relationships underlying a particular problem. The idea is simple - start with the problem and keep asking why until you get to all contributing and root causes, peeling away the layers of symptoms as you progress.

At Amazon, we leverage the five whys technique during our Correction Of Errors process. We have found that whilst "5 Whys" is a helpful mnemonic, teams are encouraged to ask why more than five times as they complete their root cause analysis, especially when considering environmental and systemic factors that may have contributed prior to the immediate incident. A sufficiently deep five whys analysis will likely have multiple root causes or contributing causes, so branching your causal tree is generally expected and encouraged.

The process is as follows:

1. Identify the problem
2. Ask why the problem happened, and record the reason.
3. Decide if the reason is the root cause
4. Could the reason have been prevented?
5. Could the reason have been detected before it happened?
6. If the reason is human error, why was it possible?
7. If the answer you just provided doesn’t identify the root cause of the problem, repeat the process using the reason as the problem. Stop when you are confident that you have found the root causes.

Some key points to remember:

- Five whys should be applied in a blame-free way, where the focus is on finding the "why" rather than blaming "who".
- If you see "human error" as a root cause in the RCA, it may be indicating a lack of check or fail-safe mechanism. Therefore, you should always ask why the human error was possible.
- Consider having entirely separate causal trees for the duration of the event: ("Why did this impact last as long as it did?")

If you use the [AWS System Manager Incident Manager](https://docs.aws.amazon.com/incident-manager/latest/userguide/analysis.html) COE template, then the five whys section is included as part of the Incident questions under the Prevention section.

### Establishing a timeline

Regardless of the method used, establishing a timeline is critical. It allows us to understand the state of the system at the time and the sequence of events leading to the failure. It is perfectly fine to start with known events and fill in the gaps as the investigation continues. We recommend leveraging services like AWS CloudTrail and other auditing systems to ensure the timeline is built from objective data sources, rather than human memory. For any blind spots, anecdote and memory can be useful, but whenever possible - use data and trust, but verify.
