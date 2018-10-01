#! /bin/bash

set -e

path=`dirname $0`

kubernetes_repo="k8s.gcr.io"
kubernetes_version=`docker run -it --rm \
                    -e KUBERNETES_VERSION=${1} \
                    -e KUBERNETES_COMPONENT=kube-apiserver \
                    wise2ck8s/kube-version:v1.12`
dns_version=`docker run -it --rm \
                    -e KUBERNETES_VERSION=${1} \
                    -e KUBERNETES_COMPONENT=coredns \
                    wise2ck8s/kube-version:v1.12`
pause_version="3.1"
echo "" >> ${path}/yat/all.yml.gotmpl
echo "kubernetes_repo: ${kubernetes_repo}" >> ${path}/yat/all.yml.gotmpl
echo "kubernetes_version: ${kubernetes_version}" >> ${path}/yat/all.yml.gotmpl
echo "dns_version: ${dns_version}" >> ${path}/yat/all.yml.gotmpl
echo "pause_version: ${pause_version}" >> ${path}/yat/all.yml.gotmpl

flannel_repo="quay.io/coreos"
flannel_version="v0.10.0"
echo "flannel_repo: ${flannel_repo}" >> ${path}/yat/all.yml.gotmpl
echo "flannel_version: ${flannel_version}-amd64" >> ${path}/yat/all.yml.gotmpl

curl -sS https://raw.githubusercontent.com/coreos/flannel/${flannel_version}/Documentation/kube-flannel.yml \
    | sed -e "s,quay.io/coreos,{{ registry_endpoint }}/{{ registry_project }},g" > ${path}/template/kube-flannel.yml.j2

# Fix the bug coreos/flannel#1044
curl -sSL https://github.com/wise2ck8s/breeze/raw/v1.12/kubernetes-playbook/kube-flannel.yml \
    | sed -e "s,quay.io/coreos,{{ registry_endpoint }}/{{ registry_project }},g" > ${path}/template/kube-flannel.yml.j2
    
dashboard_repo="k8s.gcr.io"
dashboard_version="v1.8.3"
echo "dashboard_repo: ${dashboard_repo}" >> ${path}/yat/all.yml.gotmpl
echo "dashboard_version: ${dashboard_version}" >> ${path}/yat/all.yml.gotmpl

#curl -sS https://raw.githubusercontent.com/kubernetes/dashboard/${dashboard_version}/src/deploy/recommended/kubernetes-dashboard.yaml \
#    | sed -e "s,k8s.gcr.io,{{ registry_endpoint }}/{{ registry_project }},g" > ${path}/template/kubernetes-dashboard.yml.j2

curl -sS https://raw.githubusercontent.com/wise2c-devops/breeze/master/kubernetes-playbook/kubernetes-dashboard-wise2c.yaml.j2 \
    | sed -e "s,k8s.gcr.io,{{ registry_endpoint }}/{{ registry_project }},g" > ${path}/template/kubernetes-dashboard.yml.j2
    
#curl -L -o ${path}/file/cni-plugins-amd64-v0.6.0.tgz https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz

echo "=== pulling kubernetes images ==="
docker pull ${kubernetes_repo}/kube-apiserver:${kubernetes_version}
docker pull ${kubernetes_repo}/kube-controller-manager:${kubernetes_version}
docker pull ${kubernetes_repo}/kube-scheduler:${kubernetes_version}
docker pull ${kubernetes_repo}/kube-proxy:${kubernetes_version}
docker pull ${kubernetes_repo}/pause:${pause_version}
docker pull ${kubernetes_repo}/coredns:${dns_version}
echo "=== pull kubernetes images success ==="
echo "=== saving kubernetes images ==="
mkdir -p ${path}/file
docker save ${kubernetes_repo}/coredns:${dns_version} \
    ${kubernetes_repo}/kube-apiserver:${kubernetes_version} \
    ${kubernetes_repo}/kube-controller-manager:${kubernetes_version} \
    ${kubernetes_repo}/kube-scheduler:${kubernetes_version} \
    ${kubernetes_repo}/kube-proxy:${kubernetes_version} \
    ${kubernetes_repo}/pause:${pause_version} \
    > ${path}/file/k8s.tar
rm ${path}/file/k8s.tar.bz2 -f
bzip2 -z --best ${path}/file/k8s.tar
echo "=== save kubernetes images success ==="

echo "=== pulling flannel image ==="
docker pull ${flannel_repo}/flannel:${flannel_version}-amd64
echo "=== pull flannel image success ==="
echo "=== saving flannel image ==="
docker save ${flannel_repo}/flannel:${flannel_version}-amd64 \
    > ${path}/file/flannel.tar
rm ${path}/file/flannel.tar.bz2 -f
bzip2 -z --best ${path}/file/flannel.tar
echo "=== save flannel image success ==="

echo "=== pulling dashboard image ==="
docker pull ${dashboard_repo}/kubernetes-dashboard-amd64:${dashboard_version}
echo "=== pull dashboard image success ==="
echo "=== saving dashboard image ==="
docker save ${dashboard_repo}/kubernetes-dashboard-amd64:${dashboard_version} \
    > ${path}/file/dashboard.tar
rm ${path}/file/dashboard.tar.bz2 -f
bzip2 -z --best ${path}/file/dashboard.tar
echo "=== save dashboard image success ==="
