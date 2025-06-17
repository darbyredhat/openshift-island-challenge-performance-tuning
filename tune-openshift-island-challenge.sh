#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration Variables ---
NAMESPACE="ctfd"
APP_DEPLOYMENT_NAME="ctfd"
DB_DEPLOYMENT_NAME="ctfd-mysql-db"
APP_CONTAINER_NAME="ctfd"
DB_CONTAINER_NAME="ctfd-mysql-db"
DESIRED_REPLICA_COUNT=1 # Current desired replica count for both deployments

echo "Starting CTFd Deployment Optimization Script with Scale Down/Up Strategy..."
echo "--------------------------------------------------------"

# --- PRE-TASKS: SCALE DOWN DEPLOYMENTS FOR PATCHING ---
echo "--- PRE-TASKS: SCALING DOWN DEPLOYMENTS TO 0 ---"
echo "Application will experience downtime during patching."

# Scale down CTFd App
echo "Scaling down ${APP_DEPLOYMENT_NAME} to 0 replicas..."
oc scale deployment "${APP_DEPLOYMENT_NAME}" -n "${NAMESPACE}" --replicas=0
echo "Waiting for ${APP_DEPLOYMENT_NAME} pods to terminate..."
# oc wait --for=delete pod -l app=${APP_DEPLOYMENT_NAME} -n ${NAMESPACE} --timeout=300s # Alternative for waiting for deletion
# Check actual pod count to ensure termination
for i in {1..30}; do # Max 30 retries * 10s delay = 5 minutes
    if [[ $(oc get pods -l app="${APP_DEPLOYMENT_NAME}" -n "${NAMESPACE}" -o json | jq '.items | length') -eq 0 ]]; then
        echo "${APP_DEPLOYMENT_NAME} pods terminated."
        break
    else
        echo "Waiting for ${APP_DEPLOYMENT_NAME} pods to terminate... (attempt $i)"
        sleep 10
    fi
done

# Scale down CTFd DB
echo "Scaling down ${DB_DEPLOYMENT_NAME} to 0 replicas..."
oc scale deployment "${DB_DEPLOYMENT_NAME}" -n "${NAMESPACE}" --replicas=0
echo "Waiting for ${DB_DEPLOYMENT_NAME} pods to terminate..."
# oc wait --for=delete pod -l app=${DB_DEPLOYMENT_NAME} -n ${NAMESPACE} --timeout=300s # Alternative
for i in {1..30}; do # Max 30 retries * 10s delay = 5 minutes
    if [[ $(oc get pods -l app="${DB_DEPLOYMENT_NAME}" -n "${NAMESPACE}" -o json | jq '.items | length') -eq 0 ]]; then
        echo "${DB_DEPLOYMENT_NAME} pods terminated."
        break
    else
        echo "Waiting for ${DB_DEPLOYMENT_NAME} pods to terminate... (attempt $i)"
        sleep 10
    fi
done

echo "All deployments scaled down to 0 replicas. Proceeding with patches."
echo "--------------------------------------------------------"

# --- PATCHING DEPLOYMENTS (WHILE SCALED DOWN) ---
echo "--- PATCHING DEPLOYMENTS ---"
echo "No new pods will start until scale up at the end."

# Generate SECRET_KEY
GENERATED_SECRET_KEY=$(openssl rand -hex 32)
echo "Generated SECRET_KEY: $GENERATED_SECRET_KEY"

# Patch CTFd Application Deployment (ctfd)
echo "Applying Deployment Strategy for ${APP_DEPLOYMENT_NAME} (maxSurge:0, maxUnavailable:1)..."
oc patch deployment "${APP_DEPLOYMENT_NAME}" -n "${NAMESPACE}" --type='strategic' -p='{"spec":{"strategy":{"rollingUpdate":{"maxSurge":0,"maxUnavailable":1},"type":"RollingUpdate"}}}'

echo "Applying Resource Limits and Requests for ${APP_DEPLOYMENT_NAME}..."
oc patch deployment "${APP_DEPLOYMENT_NAME}" -n "${NAMESPACE}" --type='strategic' -p='{"spec":{"template":{"spec":{"containers":[{"name":"'"${APP_CONTAINER_NAME}"'","resources":{"limits":{"cpu":"4000m","memory":"1Gi"},"requests":{"cpu":"2000m","memory":"512Mi"}}}]}}}}'

echo "Updating WORKERS Environment Variable for ${APP_DEPLOYMENT_NAME} to 5..."
oc patch deployment "${APP_DEPLOYMENT_NAME}" -n "${NAMESPACE}" --type='strategic' -p='{"spec":{"template":{"spec":{"containers":[{"name":"'"${APP_CONTAINER_NAME}"'","env":[{"name":"WORKERS","value":"5"}]}]}}}}'

echo "Setting SECRET_KEY Environment Variable for ${APP_DEPLOYMENT_NAME}..."
oc patch deployment "${APP_DEPLOYMENT_NAME}" -n "${NAMESPACE}" --type='strategic' -p='{"spec":{"template":{"spec":{"containers":[{"name":"'"${APP_CONTAINER_NAME}"'","env":[{"name":"SECRET_KEY","value":"'"$GENERATED_SECRET_KEY"'"}]}]}}}}'

echo "Setting RATELIMIT_DEFAULT Environment Variable for ${APP_DEPLOYMENT_NAME}..."
oc patch deployment "${APP_DEPLOYMENT_NAME}" -n "${NAMESPACE}" --type='strategic' -p='{"spec":{"template":{"spec":{"containers":[{"name":"'"${APP_CONTAINER_NAME}"'","env":[{"name":"RATELIMIT_DEFAULT","value":"1000 per 5 seconds"}]}]}}}}'

# Patch CTFd MySQL Database Deployment (ctfd-mysql-db)
echo "Applying Deployment Strategy for ${DB_DEPLOYMENT_NAME} (maxSurge:0, maxUnavailable:1)..."
# NOTE: If your DB is a StatefulSet, change 'kind: Deployment' in this patch to 'kind: StatefulSet'
oc patch deployment "${DB_DEPLOYMENT_NAME}" -n "${NAMESPACE}" --type='strategic' -p='{"spec":{"strategy":{"rollingUpdate":{"maxSurge":0,"maxUnavailable":1},"type":"RollingUpdate"}}}'

echo "Applying Resource Limits and Requests for ${DB_DEPLOYMENT_NAME}..."
# NOTE: If your DB is a StatefulSet, change 'kind: Deployment' in this patch to 'kind: StatefulSet'
oc patch deployment "${DB_DEPLOYMENT_NAME}" -n "${NAMESPACE}" --type='strategic' -p='{"spec":{"template":{"spec":{"containers":[{"name":"'"${DB_CONTAINER_NAME}"'","resources":{"limits":{"cpu":"1000m","memory":"2Gi"},"requests":{"cpu":"500m","memory":"1Gi"}}}]}}}}'

echo "All patches applied."
echo "--------------------------------------------------------"

# --- POST-TASKS: SCALE UP DEPLOYMENTS ---
echo "--- POST-TASKS: SCALING UP DEPLOYMENTS ---"
echo "Application will now become available."

# Scale up CTFd DB first (dependency for app)
echo "Scaling up ${DB_DEPLOYMENT_NAME} to ${DESIRED_REPLICA_COUNT} replicas..."
oc scale deployment "${DB_DEPLOYMENT_NAME}" -n "${NAMESPACE}" --replicas="${DESIRED_REPLICA_COUNT}"
echo "Waiting for ${DB_DEPLOYMENT_NAME} to be ready..."
oc rollout status deployment/"${DB_DEPLOYMENT_NAME}" -n "${NAMESPACE}"

# Scale up CTFd App
echo "Scaling up ${APP_DEPLOYMENT_NAME} to ${DESIRED_REPLICA_COUNT} replicas..."
oc scale deployment "${APP_DEPLOYMENT_NAME}" -n "${NAMESPACE}" --replicas="${DESIRED_REPLICA_COUNT}"
echo "Waiting for ${APP_DEPLOYMENT_NAME} to be ready..."
oc rollout status deployment/"${APP_DEPLOYMENT_NAME}" -n "${NAMESPACE}"

echo "--------------------------------------------------------"
echo "Script execution complete."
echo "Your CTFd application and database deployments are now configured."
echo "Please rerun your Playwright load test to measure performance."
echo "Remember to monitor both CTFd app and DB pod metrics during the test run."