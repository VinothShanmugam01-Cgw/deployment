#!/bin/bash

NAMESPACE="production"
SA_NAME="jenkins-deployer"

kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

kubectl create serviceaccount ${SA_NAME} -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jenkins-deployer-role
rules:
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["pods", "services", "endpoints", "namespaces", "serviceaccounts"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["roles", "rolebindings"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
EOF

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-deployer-binding
subjects:
  - kind: ServiceAccount
    name: ${SA_NAME}
    namespace: ${NAMESPACE}
roleRef:
  kind: ClusterRole
  name: jenkins-deployer-role
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SA_NAME}-token
  namespace: ${NAMESPACE}
  annotations:
    kubernetes.io/service-account.name: ${SA_NAME}
type: kubernetes.io/service-account-token
EOF

echo ""
echo "Waiting for token to be populated..."
sleep 5

SA_TOKEN=$(kubectl get secret ${SA_NAME}-token -n ${NAMESPACE} -o jsonpath='{.data.token}' | base64 --decode)

echo ""
echo "========================================"
echo "  Add this token to Jenkins credentials "
echo "  Credential ID: k8s-sa-token           "
echo "  Type: Secret text                      "
echo "========================================"
echo ""
echo "${SA_TOKEN}"
echo ""
