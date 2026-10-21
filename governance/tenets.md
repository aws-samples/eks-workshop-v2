# EKS Workshop Program Tenets

### Customer Obsession

The priorities of content and modes of use of the workshop should be centered around how EKS customers and users interact with the services.

### Service Differentiation

The modules that make up the core EKS workshop should be focused on features that differentiate EKS from open source or other Kubernetes distributions or offerings. The aim of this workshop is not to provide education on general Kubernetes concepts or wider ecosystem projects unless it is how they specifically intersect with the EKS service.

### Open Content

We aim to develop the workshop content in an open environment as much as possible to promote inclusion and collaboration, whether inside or outside Amazon. This encompasses public access to the content as well as contribution.

### Content Flexibility

It should be possible to run any given set of content modules in any order without dependencies on other modules. This allows modules to be selected “a la carte” and prevents cascading issues between content.

### Stability

Workshop content that does not function, negatively affects both the confidence of those delivering customer workshops and the public perception of those using the content on their own time. We strive to produce content in a manner that remains stable and functional, and mechanisms that detect issues as early as possible.

## Fast Path Tenets

### Persona-driven

Fast paths provide an opinionated learning journey tailored to specific roles (e.g., Developer, Platform Engineer, FinOps) rather than a broad feature set. 

### Time-bound

Each fast path must be completable within a two-hour window, including environment setup, hands-on labs, and conclusion. 

### Frictionless flow

Provide an uninterrupted experience using a single prepare-environment script at the start to eliminate mid-workshop infrastructure delays. 

### Strictly opinionated

Select exactly one tool or methodology for any given objective (e.g., choosing ArgoCD over Flux) to prevent redundancy and decision fatigue. 

### Auto Mode by default

Utilize EKS Auto Mode clusters as the standard environment unless specific lab requirements necessitate a custom configuration. 

### Outcome-focused

Target a 200-level depth, prioritizing high-level learning outcomes over deep-dive architectural exploration.
