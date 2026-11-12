# Kubernetes Monitoring with Prometheus & Grafana

## Safe installer (updated November 2026)

The script now **refuses to modify a cluster unless its exact kubeconfig context is explicitly confirmed**. It no longer prints or logs the Grafana admin password.

```bash
kubectl config current-context
bash -n monitoring_setup.sh
CONFIRM_CONTEXT="$(kubectl config current-context)" CHART_VERSION="<reviewed-chart-version>" bash monitoring_setup.sh
```

Choose a chart version compatible with your cluster and review its release notes first. Confirm the value returned by `kubectl config current-context` before setting `CONFIRM_CONTEXT`. This is a **lab installer**: source-code publication and static lint checks are not evidence of a successful Kubernetes deployment. See the Actions tab for lint status, and record sanitized workloads, alert delivery, and dashboard evidence after a real run.


A Kubernetes observability lab using **Helm** to install the community `kube-prometheus-stack` chart: Prometheus, Grafana and supporting monitoring components.

> **Status:** The existing installation script is documented here; a successful deployment on a live cluster has not been independently confirmed.

## How it works

```text
monitoring_setup.sh
  ├── kubectl: create namespace monitoring (if absent)
  ├── helm: add/update prometheus-community repository
  ├── helm upgrade --install monitoring prometheus-community/kube-prometheus-stack
  ├── kubectl wait: wait for selected pods
  └── kubectl/port-forward: inspect Grafana and access locally
```

## Prerequisites

- A test Kubernetes cluster with capacity for Prometheus and Grafana
- `kubectl` context pointing to the intended cluster
- Helm 3
- RBAC permissions to create namespace, deploy Helm releases, and access Secrets
- Awareness of monitoring storage and compute costs

## Usage

Inspect the script before running it. It changes the active Kubernetes context.

```bash
kubectl config current-context
kubectl cluster-info
bash -n monitoring_setup.sh
bash monitoring_setup.sh
```

### Verify installation

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
helm status monitoring -n monitoring
kubectl get prometheusrules,servicemonitors -n monitoring
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

Then visit `http://localhost:3000`.

### Credential safety

The supplied shell script **prints the Grafana admin password to stdout** for learning purposes. Avoid using it in shared terminals or captured CI logs. For real deployments, use a managed credential source and rotate the initial admin credentials.

## Troubleshooting

```bash
kubectl get pods -n monitoring -o wide
kubectl describe pods -n monitoring
kubectl get events -n monitoring --sort-by=.lastTimestamp
helm get values monitoring -n monitoring
kubectl logs -n monitoring <pod-name> --tail=100
```

Check chart compatibility, CRD installation, pod resource requests, storage classes, and network accessibility. The script's pod readiness selector may not match every chart component, so inspect individual pod readiness too.

## Known limitations and follow-up work

- Chart version is not pinned, reducing reproducibility.
- The script has no configurable values file or persistent-storage settings.
- No dashboards, alerting rules or Alertmanager routing examples are yet included.
- Prometheus retention, ingress/TLS, RBAC, and network policies need environment-specific configuration.
- **No production deployment or alert delivery is claimed.**

Planned work: version-pinned chart, values files, ServiceMonitor demo, useful alerts, dashboards, automated Helm template checks and measured test evidence.

*Portfolio theme: Kubernetes observability, Helm automation, metrics, dashboards, operations and troubleshooting.*
