---
title: Amazon S3용 마운트포인트
sidebar_position: 20
---
이 섹션을 진행하기 전에, [스토리지](../index.md) 메인 섹션에서 다룬 Kubernetes 스토리지 개념(볼륨, 영구 볼륨(PV), 영구 볼륨 클레임(PVC), 동적 프로비저닝, 임시 스토리지)을 이해하는 것이 중요합니다.

[Mountpoint for Amazon S3 CSI 드라이버](https://github.com/awslabs/mountpoint-s3-csi-driver)를 통해 Kubernetes 애플리케이션이 표준 파일 시스템 인터페이스를 사용하여 Amazon S3 객체에 접근할 수 있습니다. [Mountpoint for Amazon S3](https://github.com/awslabs/mountpoint-s3)를 기반으로 구축된 Mountpoint CSI 드라이버는 Kubernetes 클러스터의 컨테이너가 접근할 수 있는 스토리지 볼륨으로 Amazon S3 버킷을 노출합니다. 이 드라이버는 [CSI](https://github.com/container-storage-interface/spec/blob/master/spec.md) 사양을 구현하여 컨테이너 오케스트레이터(CO)가 스토리지 볼륨을 효과적으로 관리할 수 있게 합니다.

다음 아키텍처 다이어그램은 EKS pod의 영구 스토리지로 Mountpoint for Amazon S3를 어떻게 사용할 것인지 보여줍니다:

![Assets with S3](./assets/assets-s3.webp)

이미지 호스팅 웹 애플리케이션에 필요한 이미지를 위한 스테이징 디렉토리를 생성하는 것부터 시작하겠습니다:

```bash
$ mkdir ~/environment/assets-images/
$ cd ~/environment/assets-images/
$ curl --remote-name-all https://raw.githubusercontent.com/aws-containers/retail-store-sample-app/main/src/assets/public/assets/{chrono_classic.jpg,gentleman.jpg,pocket_watch.jpg,smart_2.jpg,wood_watch.jpg}
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 98157  100 98157    0     0   242k      0 --:--:-- --:--:-- --:--:--  242k
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 58439  100 58439    0     0   214k      0 --:--:-- --:--:-- --:--:--  214k
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 58655  100 58655    0     0   260k      0 --:--:-- --:--:-- --:--:--  260k
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 20795  100 20795    0     0  96273      0 --:--:-- --:--:-- --:--:-- 96273
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 43122  100 43122    0     0   244k      0 --:--:-- --:--:-- --:--:--  243k
$ ls
chrono_classic.jpg  gentleman.jpg  pocket_watch.jpg  smart_2.jpg  wood_watch.jpg
```

다음으로, `aws s3 cp` 명령을 사용하여 이러한 이미지 자산을 S3 버킷에 복사하겠습니다:

```bash
$ cd ~/environment/
$ aws s3 cp ~/environment/assets-images/ s3://$BUCKET_NAME/ --recursive
upload: assets-images/smart_2.jpg to s3://eks-workshop-mountpoint-s320241014192132282600000002/smart_2.jpg
upload: assets-images/wood_watch.jpg to s3://eks-workshop-mountpoint-s320241014192132282600000002/wood_watch.jpg
upload: assets-images/gentleman.jpg to s3://eks-workshop-mountpoint-s320241014192132282600000002/gentleman.jpg
upload: assets-images/pocket_watch.jpg to s3://eks-workshop-mountpoint-s320241014192132282600000002/pocket_watch.jpg
upload: assets-images/chrono_classic.jpg to s3://eks-workshop-mountpoint-s320241014192132282600000002/chrono_classic.jpg
```

`aws s3 ls` 명령을 사용하여 버킷에 업로드된 객체를 확인할 수 있습니다:

```bash
$ aws s3 ls $BUCKET_NAME
2024-10-14 19:29:05      98157 chrono_classic.jpg
2024-10-14 19:29:05      58439 gentleman.jpg
2024-10-14 19:29:05      58655 pocket_watch.jpg
2024-10-14 19:29:05      20795 smart_2.jpg
2024-10-14 19:29:05      43122 wood_watch.jpg
```

이제 Amazon S3 버킷에 초기 객체가 있으므로, pod에 영구적이고 공유된 스토리지를 제공하도록 Mountpoint for Amazon S3 CSI 드라이버를 구성하겠습니다.

EKS 클러스터에 Mountpoint for Amazon S3 CSI 애드온을 설치해보겠습니다. 이 작업은 완료되는 데 몇 분이 소요됩니다:

```bash
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-mountpoint-s3-csi-driver \
  --service-account-role-arn $S3_CSI_ADDON_ROLE
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name aws-mountpoint-s3-csi-driver
```

완료되면 애드온이 EKS 클러스터에 생성한 것을 확인할 수 있습니다:

```bash
$ kubectl get daemonset s3-csi-node -n kube-system
NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
s3-csi-node   3         3         3       3            3           kubernetes.io/os=linux   61s
```
