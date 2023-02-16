# Governance model

## Principles

The EKS workshop will adhere to the following principles:

* The workshop is an open source project: we will allow and encourage contributions from the community at large. 
* Welcoming and respectful: we will respect all contributions from the community and will strive to cultivate a friendly and welcoming atmosphere.
* Transparency: all work on the project will be done in public.
* Merit: ideas and contributions will be accepted on their merits and align with the project’s goals and objectives.

## Steering committee

The steering committee will have at least 1 representative from the following AWS communities: 

* Container Specialist SA
* Technical Account Manager (TAM)
* Professional Services
* TFC at large

Committee members will represent the interests of their cohort at committee meetings and will serve for no longer than 1 year. When their term expires or they leave their post, the cohort they represent will nominate a replacement. The steering committee will then vote to accept or reject the nominee submitted. Steering committee members will be AWS employees. 

The steering committee will be responsible for the overall governance of the project. This includes ongoing management and oversight of the project, adhering to the guiding principles, creating and dissolving working groups as necessary, and deciding which topics are included in the workshop. The work of the steering committee may not always be public.

The steering committee will also be responsible for communicating project wide changes, i.e. changes that can potentially affect all of the working groups, e.g. changes to the style guide, tenets, etc. 

The steering committee will select the chairs and maintainers of each working group. To nominate new chairs/wranglers/maintainers, raise a PR to [steering.md](steering.md). Nominations will require approval from atleast two current steering committee members.

## Working groups

Working groups will be formed for each major topic in the workshop. Each workgroup will have a least 1 chair and at least 1 maintainer. The working groups are be responsible for creating and maintaining the workshop module(s) associated with a particular topic, for example, security, observability, etc. If a chair or maintainer leaves before their terms expires, they are responsible for finding their replacement. 

Each working group will be assigned a steering committee liaison who will serve as their primary point of contact and escalation for the steering committee. The liaison will periodically receive status updates from the working group chairs.

### Working group chairs

Each working group will be led by at least 1 chair who will serve in that role for at least 6 months. The chairs will serve as project managers for the workshop modules in their topic area. Responsibilities include recruiting members from the broader community to develop workshop modules, creating and assigning tasks, setting and maintaining a high quality bar for all releases, and periodically reporting progress/status to the steering committee. 

If working group chairs want make significant changes, impose new processes or conventions, they can present those proposals to the steering committee for approval. If there are doubts about how to proceed, these too, may be escalated to the steering committee for further guidance.

The chair is reponsible for finding maintainers for their working group. If a maintainer leaves the project before their term expires, the chair will work with the maintainer to find a suitable replacement. Finding PR and issue wranglers is also the reponsibility of the chair. 

### Working group maintainers

Maintainers will be responsible for reviewing and merging pull requests into the main branch of the project. There will be at least 1 maintainer for each working group. Maintainers should be technically proficient in the topic(s) that they are responsible for. Like working group chairs, maintainers will serve for at least 6 months.

### Sub-topics

If a topic area encompasses multiple sub-topics and the work to create and maintain modules for those topics exceeds the capacity of the working group, the chair can elect to create a separate working group for those sub-topics. The chair(s) of the main working group will be responsible for defining the structure and composition of the sub working groups.

## Shadowing

AWS employees who wish to chair a working group or become a maintainer will be given the opportunity to shadow the current chair and maintainer. As a shadow, employees will be required to attend all working group meetings and/or schedule recurring meetings to observe how the role is performed. Employees who shadow for at least 2 months will be eligible to become chairs and maintainers when the current term expires.  

## Wranglers

Wranglers will be responsible for resolving, commenting on, and/or triaging issues and PRs submitted to the workshop’s GitHub repository. If the wrangler cannot resolve the issue on their own, they will add labels to it, e.g. topic area, issue type, etc, and assign it to the maintainer for that topic area for further investigation. Wranglers will work across all topic areas and serve for at least 6 months. Wranglers can be from broader community (non-AWS employees).

## Cross-working group collaboration

As mentioned in the workshop tenets, “It should be possible to run any given set of content modules in any order without dependencies on other modules.” This is in place to allow module updates to be released independently of modules overseen by different working groups. If there is a need for cross-working group collaboration, the working groups will coordinate with each other and come to a mutually agreed upon solution. In some cases, it make made sense to form a separate working group for joint work. 
