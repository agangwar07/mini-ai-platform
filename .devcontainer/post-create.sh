#!/usr/bin/env bash
set -euo pipefail
cd /tmp

curl -fsSLo kind https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-linux-amd64
sudo install -m 0755 kind /usr/local/bin/kind

curl -fsSLo argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 0755 argocd /usr/local/bin/argocd

curl -fsSLo k9s.tar.gz https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz
tar -xzf k9s.tar.gz k9s && sudo install -m 0755 k9s /usr/local/bin/k9s

echo "post-create done"
