#!/bin/bash

set -e

# ------------------------------
# Configurable Variables
# ------------------------------
NAMESPACE="monitoring"
RELEASE_NAME="monitoring"
CHART_REPO="https://prometheus-community.github.io/helm-charts"
CHART_NAME="prometheus-community/kube-prometheus-stack"

# ------------------------------
# Functions
# ------------------------------

create_namespace() {
    echo "🔧 Creating namespace: $NAMESPACE (if not exists)..."
    kubectl get namespace $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE
}

add_helm_repo() {
    echo "📦 Adding Helm repo for Prometheus stack..."
    helm repo add prometheus-community $CHART_REPO
    helm repo update
}

install_stack() {
    echo "🚀 Installing or upgrading Prometheus + Grafana stack..."
    helm upgrade --install $RELEASE_NAME $CHART_NAME \
        --namespace $NAMESPACE \
        --create-namespace
}

wait_for_pods() {
    echo "⏳ Waiting for pods to be ready in '$NAMESPACE'..."
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=$RELEASE_NAME -n $NAMESPACE --timeout=300s
}

show_grafana_info() {
    echo -e "\n🔑 Grafana default credentials:"
    echo "  ➤ Username: admin"
    echo "  ➤ Password: $(kubectl get secret --namespace $NAMESPACE $RELEASE_NAME-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)"
    
    echo -e "\n🌐 To access Grafana:"
    echo "  ➤ Run: kubectl port-forward svc/$RELEASE_NAME-grafana -n $NAMESPACE 3000:80"
    echo "  ➤ Open: http://localhost:3000"
}

# ------------------------------
# Main Execution
# ------------------------------

echo "🚧 Starting Monitoring Stack Setup..."
create_namespace
add_helm_repo
install_stack
wait_for_pods
show_grafana_info
echo "✅ Setup Complete!"

