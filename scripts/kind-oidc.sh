#!/usr/bin/env bash
# Makes the kind API server issue service-account tokens for a public OIDC issuer,
# so AWS IAM can trust them (IRSA-style federation outside EKS).
set -euo pipefail
ISSUER="${1:?usage: kind-oidc.sh <issuer-url>}"
NODE=platform-control-plane
MANIFEST=/etc/kubernetes/manifests/kube-apiserver.yaml
DEFAULT_ISSUER=https://kubernetes.default.svc.cluster.local

docker cp "$NODE:$MANIFEST" /tmp/kube-apiserver.yaml
cp /tmp/kube-apiserver.yaml /tmp/kube-apiserver.yaml.bak

if grep -q -- "--service-account-jwks-uri" /tmp/kube-apiserver.yaml; then
  echo "Already configured:"; grep -- "--service-account" /tmp/kube-apiserver.yaml; exit 0
fi

sed -i "s#^\( *\)- --service-account-issuer=${DEFAULT_ISSUER}#\1- --service-account-issuer=${ISSUER}\n\1- --service-account-issuer=${DEFAULT_ISSUER}\n\1- --service-account-jwks-uri=${ISSUER}/openid/v1/jwks#" /tmp/kube-apiserver.yaml

grep -q -- "--service-account-jwks-uri=${ISSUER}" /tmp/kube-apiserver.yaml \
  || { echo "Edit failed; issuer flag not found. Current flags:"; grep -- "--service-account" /tmp/kube-apiserver.yaml; exit 1; }

grep -- "--service-account" /tmp/kube-apiserver.yaml
docker cp /tmp/kube-apiserver.yaml "$NODE:$MANIFEST"
echo "API server restarting..."
sleep 20
until kubectl get --raw /readyz >/dev/null 2>&1; do sleep 5; done
kubectl get --raw /.well-known/openid-configuration | jq '{issuer, jwks_uri}'
