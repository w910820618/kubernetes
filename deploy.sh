#!/bin/bash
#判断docker是否已经被安装
if ! [ -x "$(command -v docker)" ]; then
 #安装依赖包
yum install -y yum-utils device-mapper-persistent-data lvm2
#设置docker源
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
#安装docker
yum install docker-ce-18.09.6 docker-ce-cli-18.09.6 containerd.io
#命令补全
yum -y install bash-completion
source /etc/profile.d/bash_completion.sh
#配置加速器
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
"registry-mirrors": ["https://v16stybc.mirror.aliyuncs.com"],
"exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
#设置docker开机自启
systemctl enable docker
systemctl daemon-reload
#重新启动docker
systemctl restart docker
#验证docker已经安装成功
docker run hello-world
echo "Successfully installed docker-ce"
else
  echo "docker has been installed"
fi

yum install openssl

#关闭
swapoff -a

systemctl stop firewalld

systemctl disable firewalld

#安装k8s
if ! [ -x "$(command -v kubectl)" ]; then
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum clean all
yum -y makecache
yum install -y kubelet-1.14.2 kubeadm-1.14.2 kubectl-1.14.2
systemctl enable kubelet && systemctl start kubelet
echo "source <(kubectl completion bash)" >> ~/.bash_profile
source ~/.bash_profile
url=registry.cn-hangzhou.aliyuncs.com/google_containers
version=v1.14.2
images=(`kubeadm config images list --kubernetes-version=$version|awk -F '/' '{print $2}'`)
for imagename in ${images[@]} ; do
docker pull $url/$imagename
docker tag $url/$imagename k8s.gcr.io/$imagename
docker rmi -f $url/$imagename
done
echo "Successfully installed k8s "
else
	echo "kubectl has been installed"
fi

#安装git
if ! [ -x "$(command -v git)" ]; then
	yum install git
else
	echo "git has been installed"
fi

modprobe br_netfilter
sysctl -p

#判断是master还是node
echo "Is the server master or node :"
read answer

#如何是master
if [[ "$answer" = "master" ]]; then
    echo "your ip:"
    read serverip
    sudo kubeadm init --kubernetes-version=v1.14.2 --apiserver-advertise-address="$serverip" --pod-network-cidr=192.168.0.0/16

    sudo cp /etc/kubernetes/admin.conf $HOME/
    sudo chown $(id -u):$(id -g) $HOME/admin.conf
    export KUBECONFIG=$HOME/admin.conf
   
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml

    kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
    kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml

    kubectl create -f kubernetes-dashboard.yaml

    kubectl create -f admin-token.yaml
fi

#如果是node
if [[ "$answer" = "node" ]]; then
	echo "Master IP:"
    read masterip
    echo "Master token:"
    read token
    echo "ssh:"
    read ssh
    kubeadm join "$masterip":6443 --token "$token" --discovery-token-ca-cert-hash "$ssh"
fi



