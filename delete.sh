#!/bin/bash
# reset.sh
kubeadm reset
# 停止相关服务
systemctl stop docker kubelet etcd
#删除所有容器
docker rm -f $(sudo docker ps -qa)
# 删除/var/lib/kubelet/目录，删除前先卸载，否则会删除不干净
for m in $(sudo tac /proc/mounts | sudo awk '{print $2}'|sudo grep /var/lib/kubelet);do
 sudo umount $m||true
done
rm -rf /var/lib/kubelet/
#删除/var/lib/rancher/目录，删除前先卸载
for m in $(sudo tac /proc/mounts | sudo awk '{print $2}'|sudo grep /var/lib/rancher);do
 sudo umount $m||true
done
rm -rf /var/lib/rancher/
#删除/run/kubernetes/ 目录
rm -rf /run/kubernetes/
#删除所有的数据卷
docker volume rm $(sudo docker volume ls -q)
#再次显示所有的容器和数据卷，确保没有残留
docker ps -a
docker volume ls
# 
yum remove -y docker* kubelet kubectl
rm -rf /var/lib/docker
rm -rf /var/lib/etcd
rm -rf /var/lib/kubelet
rm -rf /var/lib/calico
rm -rf /data/etcd
rm -rf /opt/cni
rm -rf /var/etcd/calico-data
rm -rf /usr/local/bin/Documentation
rm -rf /root/.kube
# 这边有个坑，转发规则如果不清除，导致新的网络不通
iptables -F
iptables -X
iptables -L
find / -type f -name docker*
find / -type f -name calico*
find / -type f -name etcd*
