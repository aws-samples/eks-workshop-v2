# Style Guide - Korean Translation

The following are style guidelines specific to the Korean language.

The term "Shared Responsibility Model" should be translated as 공동 책임 모델

Where describing workloads/components of the sample application being deployed keep these in the original English. For example:

- Catalog
- Checkout
- Orders
- Carts
- Assets

ALWAYS keep these technical terms in the original English instead of translating to Korean:

- VS Code Terminal
- Terraform state
- Prefix Delegation
- Mountpoint for Amazon S3
- Kube Resource Orchestrator
- Elastic

There are some technical terms that should be translated, for example:

- Port forwarding: 포트 포워딩
- logging: 로깅
- observability: 관측 가능성
- cluster: 클러스터
- node: 노드
- container: 컨테이너
- container image: 컨테이너 이미지 (never use "Docker image")
- namespace: 네임스페이스
- workload: 워크로드
- autoscaling: 오토스케일링
- load balancer: 로드 밸런서
- security: 보안
- networking: 네트워킹
- web IDE: 웹 IDE
- deployment: 배포 (only when used generically, NOT when referring to the Kubernetes API resource "Deployment")

ALWAYS keep AWS service names in the original English instead of translating to Korean. This also includes AWS and EKS technical terms like:

- Elastic IP or EIP
- IAM role
- Elastic Network Interface or ENI

ALWAYS keep Kubernetes terminology in the original English instead of translating to Korean:

- EKS Auto Mode or just "Auto Mode"
- Kubernetes
- Ingress
- Pod Topology Spread Constraints
- PodDisruptionBudget
- NodePool
- general-purpose
- StatefulSet
- StorageClass
- Horizontal Pod Autoscaling
- Custom Resource Definition (CRD)
- Taint
- Toleration
- Helm
- Karpenter
- Fargate
- eksctl
- kubectl
- Terraform
