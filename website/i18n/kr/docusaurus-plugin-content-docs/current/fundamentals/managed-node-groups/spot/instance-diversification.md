---
title: 인스턴스 유형 다양화
sidebar_position: 10
---
[Amazon EC2 스팟 인스턴스](https://aws.amazon.com/ec2/spot/)는 온디맨드 가격에 비해 큰 할인율로 AWS 클라우드에서 사용 가능한 여분의 컴퓨팅 용량을 제공합니다. EC2는 용량이 필요할 때 2분 전 통지로 스팟 인스턴스를 중단할 수 있습니다. 스팟 인스턴스는 다양한 내결함성 및 유연한 애플리케이션에 사용할 수 있습니다. 예를 들어 분석, 컨테이너화된 워크로드, 고성능 컴퓨팅(HPC), 무상태 웹 서버, 렌더링, CI/CD 및 기타 테스트 및 개발 워크로드 등이 있습니다.

스팟 인스턴스를 성공적으로 도입하기 위한 최선의 방법 중 하나는 구성의 일부로** ****스팟 인스턴스 다양화**를 구현하는 것입니다. 스팟 인스턴스 다양화는 확장 시와 스팟 인스턴스 종료 통지를 받을 수 있는 스팟 인스턴스를 교체할 때 여러 스팟 인스턴스 풀에서 용량을 확보하는 데 도움이 됩니다. 스팟 인스턴스 풀은 동일한 인스턴스 유형, 운영 체제 및 가용 영역을 가진 미사용 EC2 인스턴스 집합입니다(예: `us-east-1a`의 Red Hat Enterprise Linux에서 `m5.large`).

### 스팟 인스턴스 다양화를 통한 클러스터 오토스케일러

클러스터 오토스케일러는 리소스 부족으로 인해 클러스터에서 실행할 수 없는 파드가 있을 때(스케일 아웃) 또는 일정 기간 동안 활용도가 낮은 노드가 클러스터에 있을 때(Scale-In) Kubernetes 클러스터의 크기를 자동으로 조정하는 도구입니다.

:::tip
[클러스터 오토스케일러](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)와 함께 스팟 인스턴스를 사용할 때 [고려해야 할 몇 가지 사항](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)이 있습니다. 주요 고려사항 중 하나는 각 오토 스케일링 그룹이 대략 동일한 용량을 제공하는 인스턴스 유형으로 구성되어야 한다는 것입니다. 클러스터 오토스케일러는 ASG의 혼합 인스턴스 정책에서 제공된 첫 번째 오버라이드를 기반으로 오토 스케일링 그룹에서 제공하는 CPU, 메모리 및 GPU 리소스를 결정하려고 시도합니다. 이러한 오버라이드가 발견되면 발견된 첫 번째 인스턴스 유형만 사용됩니다. 자세한 내용은 [혼합 인스턴스 정책 및 스팟 인스턴스 사용](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#Using-Mixed-Instances-Policies-and-Spot-Instances)을 참조하세요.
:::

클러스터 오토스케일러를 사용하여 용량을 동적으로 조정하면서 EKS 및 K8s 클러스터에 스팟 다양화 모범 사례를 적용할 때, 클러스터 오토스케일러의 예상 작동 모드를 준수하는 방식으로 다양화를 구현해야 합니다.

다음 두 가지 전략을 사용하여 스팟 인스턴스 풀을 다양화할 수 있습니다:

* 크기가 다른 여러 노드 그룹을 생성합니다. 예를 들어, 4 vCPU와 16GB RAM 크기의 노드 그룹과 8 vCPU와 32GB RAM 크기의 다른 노드 그룹을 만듭니다.
* 동일한 vCPU 및 메모리 기준을 충족하는 다른 스팟 인스턴스 풀에서 인스턴스 유형과 패밀리의 조합을 선택하여 노드 그룹 내에서 인스턴스 다양화를 구현합니다.

이 워크샵에서는 클러스터 노드 그룹이 2 vCPU와 4GiB 메모리를 가진 인스턴스 유형으로 프로비저닝되어야 한다고 가정하겠습니다.

관련 인스턴스 유형과 패밀리를 선택하는 데 도움이 되도록 [amazon-ec2-instance-selector](https://github.com/aws/amazon-ec2-instance-selector)를 사용할 것입니다.

EC2에는 350개 이상의 다양한 인스턴스 유형이 있어 적절한 인스턴스 유형을 선택하는 과정이 어려울 수 있습니다. 이를 더 쉽게 만들기 위해, CLI 도구인 `amazon-ec2-instance-selector`는 애플리케이션을 실행할 수 있는 호환 가능한 인스턴스 유형을 선택하는 데 도움을 줍니다. 명령줄 인터페이스에 CPU, 메모리, 네트워크 성능 등의 리소스 기준을 전달하면 사용 가능한 일치하는 인스턴스 유형을 반환합니다.

CLI 도구는 IDE에 미리 설치되어 있습니다:

When applying Spot diversification best practices to EKS and K8s clusters while using Cluster Autoscaler to dynamically scale capacity, we must implement diversification in a way that adheres to Cluster Autoscaler expected operational mode.

We can diversify Spot Instance pools using two strategies:

- By creating multiple node groups, each of different sizes. For example, a node group of size 4 vCPUs and 16GB RAM, and another node group of 8 vCPUs and 32GB RAM.
- By Implementing instance diversification within the node groups, by selecting a mix of instance types and families from different Spot Instance pools that meet the same vCPUs and memory criteria.

In this workshop we will assume that our cluster node groups should be provisioned with instance types that have 2 vCPU and 4GiB of memory.

We will use [amazon-ec2-instance-selector](https://github.com/aws/amazon-ec2-instance-selector) to help us select the relevant instance
types and families with sufficient number of vCPUs and RAM.

There are over 350 different instance types available on EC2 which can make the process of selecting appropriate instance types difficult. To make it easier, `amazon-ec2-instance-selector`, a CLI tool, helps you select compatible instance types for your application to run on. The command line interface can be passed resource criteria like cpus, memory, network performance, and much more and then return the available, matching instance types.

The CLI tool has been pre-installed in your IDE:

```bash
$ ec2-instance-selector --version
```

이제 ec2-instance-selector가 설치되었으므로 `ec2-instance-selector --help`를 실행하여 워크로드 요구 사항에 맞는 인스턴스를 선택하는 데 어떻게 사용할 수 있는지 이해할 수 있습니다. 이 워크샵의 목적을 위해 먼저 2 vCPU와 4 GB RAM이라는 우리의 목표를 충족하는 인스턴스 그룹을 얻어야 합니다.

다음 명령을 실행하여 인스턴스 목록을 얻으세요.

```bash
$ ec2-instance-selector --vcpus 2 --memory 4 --gpus 0 --current-generation \
  -a x86_64 --deny-list 't.*' --output table-wide
Instance Type  VCPUs   Mem (GiB)  Hypervisor  Current Gen  Hibernation Support  CPU Arch  Network Performance
-------------  -----   ---------  ----------  -----------  -------------------  --------  -------------------
c5.large       2       4          nitro       true         true                 x86_64    Up to 10 Gigabit
c5a.large      2       4          nitro       true         false                x86_64    Up to 10 Gigabit
c5ad.large     2       4          nitro       true         false                x86_64    Up to 10 Gigabit
c5d.large      2       4          nitro       true         true                 x86_64    Up to 10 Gigabit
c6a.large      2       4          nitro       true         false                x86_64    Up to 12.5 Gigabit
c6i.large      2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit
c6id.large     2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit
c6in.large     2       4          nitro       true         false                x86_64    Up to 25 Gigabit
c7a.large      2       4          nitro       true         false                x86_64    Up to 12.5 Gigabit
c7i.large      2       4          nitro       true         false                x86_64    Up to 12.5 Gigabit

```

다음 섹션에서 노드 그룹을 정의할 때 이 인스턴스들을 사용할 것입니다.

내부적으로 `ec2-instance-selector`는 특정 지역에 대해 [DescribeInstanceTypes](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstanceTypes.html)를 호출하고 명령줄에서 선택한 기준에 따라 인스턴스를 필터링합니다. 우리의 경우 다음 기준을 충족하는 인스턴스를 필터링했습니다:

* GPU가 없는 인스턴스
* x86\_64 아키텍처(A1 또는 m6g 인스턴스와 같은 ARM 인스턴스 제외)
* 2 vCPU와 4 GB RAM을 가진 인스턴스
* 현재 세대 인스턴스(4세대 이상)
* 버스트 가능한 인스턴스 유형을 필터링하기 위해 정규 표현식 `t.*`를 충족하지 않는 인스턴스

We'll use these instances when we define our node group in the next section.

Internally `ec2-instance-selector` is making calls to the [DescribeInstanceTypes](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstanceTypes.html) for the specific region and filtering the instances based on the criteria selected in the command line, in our case we filtered for instances that meet the following criteria:

- Instances with no GPUs
- of x86_64 Architecture (no ARM instances like A1 or m6g instances for example)
- Instances that have 2 vCPUs and 4 GB of RAM
- Instances of current generation (4th gen onwards)
- Instances that don’t meet the regular expression `t.*` to filter out burstable instance types

:::tip
워크로드에 따라 인스턴스 유형을 선택할 때 고려해야 할 다른 제약 사항이 있을 수 있습니다. 예를 들어, **t2**와 **t3** 인스턴스 유형은 [버스트 가능한 인스턴스](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html)이며 CPU 실행 결정성이 필요한 CPU 바운드 워크로드에는 적합하지 않을 수 있습니다. m5**a**와 같은 인스턴스는** **[AMD 인스턴스](https://aws.amazon.com/ec2/amd/)입니다. 워크로드가 수치적 차이에 민감한 경우(예: 금융 위험 계산, 산업 시뮬레이션) 이러한 인스턴스 유형을 혼합하는 것이 적절하지 않을 수 있습니다.
:::
