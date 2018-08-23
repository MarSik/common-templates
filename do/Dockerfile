#FROM centos/systemd
FROM ubuntu:16.04

ENV KUBEVIRT_VER=v0.8.0-alpha.1
ENV MINIKUBE_VER=v0.28.2
ENV K8S_VER=1.10.7

RUN apt-get update ; apt-get install -y curl
RUN curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v$K8S_VER/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin/
RUN curl -Lo minikube https://storage.googleapis.com/minikube/releases/$MINIKUBE_VER/minikube-linux-amd64 && chmod +x minikube && mv minikube /usr/local/bin/
RUN curl -L https://github.com/openshift/origin/releases/download/v3.10.0/openshift-origin-client-tools-v3.10.0-dd10d17-linux-64bit.tar.gz | tar zx --strip-components=1 openshift-origin-client-tools-v3.10.0-dd10d17-linux-64bit/oc && mv oc /usr/local/bin
RUN curl -Lo virtctl https://github.com/kubevirt/kubevirt/releases/download/$KUBEVIRT_VER/virtctl-$KUBEVIRT_VER-linux-amd64 && chmod +x virtctl && mv virtctl /usr/local/bin/

RUN apt install -y docker.io ebtables ethtool socat sudo

ADD s /s
#ENTRYPOINT ["/s"]
