#!/usr/bin/env bash
# Install/upgrade a monitoring lab stack without exposing credentials.
set -Eeuo pipefail

NAMESPACE="${NAMESPACE:-monitoring}"
RELEASE_NAME="${RELEASE_NAME:-monitoring}"
CHART_REPO="${CHART_REPO:-https://prometheus-community.github.io/helm-charts}"
CHART_NAME="${CHART_NAME:-prometheus-community/kube-prometheus-stack}"
CHART_VERSION="${CHART_VERSION:-}"

for cmd in kubectl helm; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing required command: $cmd" >&2; exit 1; }
done

ACTIVE_CONTEXT="$(kubectl config current-context)"
if [[ -z "${CONFIRM_CONTEXT:-}" || "$CONFIRM_CONTEXT" != "$ACTIVE_CONTEXT" ]]; then
  echo "Refusing to modify Kubernetes context '$ACTIVE_CONTEXT'." >&2
  echo "Review the target and re-run with CONFIRM_CONTEXT='$ACTIVE_CONTEXT'." >&2
  exit 1
fi

echo "Target context: $ACTIVE_CONTEXT | namespace: $NAMESPACE | release: $RELEASE_NAME"
kubectl cluster-info >/dev/null
helm repo add prometheus-community "$CHART_REPO" --force-update
helm repo update prometheus-community

helm_args=(
  upgrade --install "$RELEASE_NAME" "$CHART_NAME"
  --namespace "$NAMESPACE" --create-namespace
  --wait --timeout 10m
)
if [[ -n "$CHART_VERSION" ]]; then
  helm_args+=(--version "$CHART_VERSION")
else
  echo "WARNING: CHART_VERSION is unset; pin a reviewed version for reproducible deployments." >&2
fi

helm "${helm_args[@]}"
echo "Release details:"
helm status "$RELEASE_NAME" --namespace "$NAMESPACE"
echo "Workload status:"
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME"

echo
echo "Grafana: kubectl -n '$NAMESPACE' port-forward svc/'$RELEASE_NAME'-grafana 3000:80"
echo "Open http://localhost:3000 and retrieve login credentials securely from your cluster."
echo "Admin passwords and Kubernetes Secrets are intentionally NOT printed or logged."
