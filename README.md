# practice-k8s-minecraft-server

KubernetesにJava版のマインクラフトサーバーをデプロイします。
マイクロサービスの練習のためにIstioを使用しています。

## 前提

- minikube
- kubernetes
- kubectl
- terraform
- istioctl

## インストール

```sh
minikube start --addons=ingress

cd <project-root>
terraform plan
terraform apply

kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/gateway.yaml
kubectl apply -f kubernetes/minecraft/proxy.yaml
kubectl apply -f kubernetes/minecraft/server.yaml
```

## マインクラフトサーバーに接続

```sh
kubectl get service -n istio-ingress istio-ingressgateway
# 25565に転送されるNodePortを確認
minikube ip
# minikubeに配られたIPアドレスを確認
```

表示されたIPアドレスとポートを使って、マインクラフトのクライアントにマルチプレイヤーサーバーを追加し接続する。

```
ssh -i ~/.minikube/machines/minikube/id_rsa docker@<minikubeのIPアドレス> 25565:127.0.0.1:<NodePort>
# 127.0.0.1:25565で接続できるようにするために、Kubernetesのマシン内にポートフォワード
```

ローカルPCでホストを入力し、接続を開始する。

![](https://raw.githubusercontent.com/UramnOIL/practice-k8s-minecraft-server/main/images/minecraft.png)

![](https://raw.githubusercontent.com/UramnOIL/practice-k8s-minecraft-server/main/images/minecraft_console.png)

## Kialiに接続

Kialiはサービスメッシュの可視化ツールです。

```sh
istioctl dashboard kiali
```

![](https://raw.githubusercontent.com/UramnOIL/practice-k8s-minecraft-server/main/images/kiali.png)

## Prometheus

https://prometheus.io/

監視ツールです。
マインクラフトサーバー内のメトリクスを収集するexport

## kubernetes/minecraft/server.yaml

マインクラフトサーバー用のmanifestです。
Paperを使用しています。

設定はVelocity関連しか変更していません。

## kubernetes/minecraft/proxy.yaml

プロキシサーバー用のmanifestです。
Velocityを使用しています。
