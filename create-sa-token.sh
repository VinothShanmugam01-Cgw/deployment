#!/bin/bash

NAMESPACE="learning-k8s"
SA_NAME="learning-k8s-sa"

echo "Creating namespace..."
kubectl create namespace ${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating ServiceAccount..."
kubectl create serviceaccount ${SA_NAME} \
  -n ${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating ClusterRole..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: learning-k8s-role
rules:
  - apiGroups: ["apps"]
    resources:
      - deployments
      - replicasets
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - patch
      - delete

  - apiGroups: [""]
    resources:
      - pods
      - services
      - endpoints
      - namespaces
      - serviceaccounts
      - secrets
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - patch
      - delete

  - apiGroups: ["rbac.authorization.k8s.io"]
    resources:
      - roles
      - rolebindings
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - patch
      - delete
EOF

echo "Creating ClusterRoleBinding..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-deployer-binding
subjects:
  - kind: ServiceAccount
    name: ${SA_NAME}
    namespace: ${NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: learning-k8s-role
EOF

echo "Creating long-lived token Secret..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: learning-k8s-token
  namespace: ${NAMESPACE}
  annotations:
    kubernetes.io/service-account.name: ${SA_NAME}
type: kubernetes.io/service-account-token
EOF

echo "Waiting for token to be populated..."
for i in $(seq 1 10); do
    TOKEN=$(kubectl get secret learning-k8s-token \
        -n ${NAMESPACE} \
        -o jsonpath='{.data.token}' 2>/dev/null)
    if [ -n "$TOKEN" ]; then
        break
    fi
    echo "Attempt $i: Token not ready yet. Retrying in 3s..."
    sleep 3
done

echo ""
echo "========================================"
echo "         ServiceAccount Token           "
echo "========================================"
echo ""

kubectl get secret learning-k8s-token \
  -n ${NAMESPACE} \
  -o jsonpath='{.data.token}' | base64 --decode

echo ""
echo ""
echo "========================================"
echo "      Add This Token To Jenkins         "
echo "========================================"
echo ""
echo "  Manage Jenkins"
echo "  └── Credentials"
echo "      └── System"
echo "          └── Global Credentials"
echo "              └── Add Credentials"
echo ""
echo "  Credential Type : Secret Text"
echo "  Credential ID   : k8s-sa-token"
echo "  Description     : Kubernetes Service Account Token"
echo ""
echo "========================================"