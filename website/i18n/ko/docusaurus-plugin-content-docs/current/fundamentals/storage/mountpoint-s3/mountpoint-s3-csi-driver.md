---
title: Mountpoint for Amazon S3
sidebar_position: 20
tmdTranslationSourceHash: 33c66beddd4e3a9034878051b80eaea3
---

이 섹션을 진행하기 전에 메인 [스토리지](../index.md) 섹션에서 다룬 Kubernetes 스토리지 개념(볼륨, 영구 볼륨(PV), 영구 볼륨 클레임(PVC), 동적 프로비저닝 및 임시 스토리지)을 이해하는 것이 중요합니다.

[Mountpoint for Amazon S3 Container Storage Interface (CSI) Driver](https://github.com/awslabs/mountpoint-s3-csi-driver)는 Kubernetes 애플리케이션이 표준 파일 시스템 인터페이스를 통해 Amazon S3 객체에 액세스할 수 있도록 합니다. [Mountpoint for Amazon S3](https://github.com/awslabs/mountpoint-s3)를 기반으로 구축된 Mountpoint CSI 드라이버는 Amazon S3 버킷을 Kubernetes 클러스터의 컨테이너가 원활하게 액세스할 수 있는 스토리지 볼륨으로 노출합니다. 이 드라이버는 [CSI](https://github.com/container-storage-interface/spec/blob/master/spec.md) 사양을 구현하여 컨테이너 오케스트레이터(CO)가 스토리지 볼륨을 효율적으로 관리할 수 있도록 합니다.

다음 아키텍처 다이어그램은 Mountpoint for Amazon S3를 Pod의 영구 스토리지로 사용하는 방법을 보여줍니다:

![Assets with S3](/docs/fundamentals/storage/mountpoint-s3/s3-storage.webp)

이미지 호스팅 웹 애플리케이션에 필요한 이미지를 위한 스테이징 디렉터리를 생성하는 것부터 시작하겠습니다:

```bash
$ mkdir ~/environment/assets-images/
$ wget https://github.com/aws-containers/retail-store-sample-app/releases/download/v1.2.1/sample-images.zip \
  -O /tmp/sample-images.zip
$ unzip /tmp/sample-images.zip -d ~/environment/assets-images/
Archive:  /tmp/sample-images.zip
  inflating: /home/ec2-user/environment/assets-images/1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg
  inflating: /home/ec2-user/environment/assets-images/4f18544b-70a5-4352-8e19-0d070f46745d.jpg
  inflating: /home/ec2-user/environment/assets-images/631a3db5-ac07-492c-a994-8cd56923c112.jpg
  inflating: /home/ec2-user/environment/assets-images/79bce3f3-935f-4912-8c62-0d2f3e059405.jpg
  inflating: /home/ec2-user/environment/assets-images/8757729a-c518-4356-8694-9e795a9b3237.jpg
  inflating: /home/ec2-user/environment/assets-images/87e89b11-d319-446d-b9be-50adcca5224a.jpg
  inflating: /home/ec2-user/environment/assets-images/a1258cd2-176c-4507-ade6-746dab5ad625.jpg
  inflating: /home/ec2-user/environment/assets-images/cc789f85-1476-452a-8100-9e74502198e0.jpg
  inflating: /home/ec2-user/environment/assets-images/d27cf49f-b689-4a75-a249-d373e0330bb5.jpg
  inflating: /home/ec2-user/environment/assets-images/d3104128-1d14-4465-99d3-8ab9267c687b.jpg
  inflating: /home/ec2-user/environment/assets-images/d4edfedb-dbe9-4dd9-aae8-009489394955.jpg
  inflating: /home/ec2-user/environment/assets-images/d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49.jpg
```

다음으로 `aws s3 cp` 명령을 사용하여 이 이미지 자산을 S3 버킷에 복사합니다:

```bash
$ aws s3 cp --recursive ~/environment/assets-images/ s3://$BUCKET_NAME/
upload: assets-images/79bce3f3-935f-4912-8c62-0d2f3e059405.jpg to s3://eks-workshop-mountpoint-s320250709143521722200000002/79bce3f3-935f-4912-8c62-0d2f3e059405.jpg
[...]
```

`aws s3 ls` 명령을 사용하여 버킷의 콘텐츠를 나열하고 업로드된 객체를 확인할 수 있습니다:

```bash
$ aws s3 ls $BUCKET_NAME
2025-07-09 14:43:36     102950 1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg
2025-07-09 14:43:36     118546 4f18544b-70a5-4352-8e19-0d070f46745d.jpg
2025-07-09 14:43:36     147820 631a3db5-ac07-492c-a994-8cd56923c112.jpg
2025-07-09 14:43:36     100117 79bce3f3-935f-4912-8c62-0d2f3e059405.jpg
2025-07-09 14:43:36     106911 8757729a-c518-4356-8694-9e795a9b3237.jpg
2025-07-09 14:43:36     113010 87e89b11-d319-446d-b9be-50adcca5224a.jpg
2025-07-09 14:43:36     171045 a1258cd2-176c-4507-ade6-746dab5ad625.jpg
2025-07-09 14:43:36     170438 cc789f85-1476-452a-8100-9e74502198e0.jpg
2025-07-09 14:43:36      97592 d27cf49f-b689-4a75-a249-d373e0330bb5.jpg
2025-07-09 14:43:36     169246 d3104128-1d14-4465-99d3-8ab9267c687b.jpg
2025-07-09 14:43:36     151884 d4edfedb-dbe9-4dd9-aae8-009489394955.jpg
2025-07-09 14:43:36     134344 d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49.jpg
```

이제 Amazon S3 버킷에 초기 객체가 있으므로 Mountpoint for Amazon S3 CSI 드라이버를 구성하여 Pod에 영구적이고 공유된 스토리지를 제공하겠습니다.

EKS 클러스터에 Mountpoint for Amazon S3 CSI 애드온을 설치하겠습니다. 이 작업은 완료하는 데 몇 분 정도 걸립니다:

```bash
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-mountpoint-s3-csi-driver \
  --service-account-role-arn $S3_CSI_ADDON_ROLE
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name aws-mountpoint-s3-csi-driver
```

완료되면 배포된 DaemonSet을 확인하여 애드온이 EKS 클러스터에 생성한 것을 확인할 수 있습니다:

```bash
$ kubectl get daemonset s3-csi-node -n kube-system
NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
s3-csi-node   3         3         3       3            3           kubernetes.io/os=linux   61s
```

