# OpenShift Island Challenge Performance Tuning

This document provides instructions for setting up and running API-focused load tests against your CTFd application using Playwright. This setup is optimized for high-performance API testing, bypassing full UI rendering for each request and using a pre-authenticated session.

## **TL;DR: Playbook Overview**

* **Ensures Safe Updates with Downtime:** Scales down both your CTFd application and database to zero replicas before applying any changes, then scales them back up.
* **Generates Critical Security Key:** Automatically creates and sets a unique `SECRET_KEY` for your CTFd application.
* **Optimizes CTFd App Resources:** Significantly increases CPU allocation and sets the number of Gunicorn `WORKERS` for better concurrency.
* **Configures CTFd Rate Limiting:** Sets a high default rate limit to prevent "Too Many Requests" errors during load testing.
* **Optimizes CTFd Database Resources:** Allocates more CPU and increases Memory limits for the MySQL database pod.
* **Applies Safe Rollout Strategies:** Configures both deployments to update sequentially, avoiding multi-attach errors with persistent volumes.

#### **Step 1: Install System Requirements (if not already installed)**

Make sure you have the following installed on your macOS or Linux system.

1.  **`community.kubernetes` Ansible Collection**:

      * This collection provides the Ansible modules (`k8s_patch`, `k8s_rollout`, `k8s_scale`) that allow Ansible to interact with Kubernetes/OpenShift resources.
      * **Installation:**
        ```bash
        ansible-galaxy collection install community.kubernetes
        ```
      * **Verify:** `ansible-galaxy collection list | grep kubernetes`

2.  **OpenShift CLI (`oc`)**:

      * The playbook executes `oc` commands locally. It must be installed and securely configured to connect to your target OpenShift cluster.  
      * **Configuration:** Ensure you are logged into the correct cluster and project (namespace):
        ```bash
        oc login -u <your_username> --server=<your_api_server_url>
        oc project <your-ctfd-namespace> # e.g., oc project ctfd
        ```
      * **Verify:** `oc whoami` and `oc project`
