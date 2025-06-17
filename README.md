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
      * **Configuration:** Ensure you are logged in as `admin` to the correct cluster and project:
        ```bash
        oc login -u admin --server=<your_openshift_api_url>
        oc project ctfd
        ```
      * **Verify:** `oc whoami` and `oc project`

Okay, you're ready to run your Ansible playbook to apply the optimizations!

Assuming you have:
* **Ansible** installed locally.
* The **`community.kubernetes` collection** installed (`ansible-galaxy collection install community.kubernetes`).
* The **`oc` CLI** installed and configured to connect to your remote OpenShift cluster, and you are logged into the correct project (`oc project <your-ctfd-namespace>`).
* Your `tune-openshift-island-challenge.yaml` playbook file and `inventory.ini` file in the same directory.
* You are currently in that directory in your terminal.

### **How to Run Your Ansible Playbook:**

Run the following command in your terminal:

```bash
ansible-playbook -i inventory.ini tune-openshift-island-challenge.yaml
```

**Explanation:**

* `ansible-playbook`: The command to execute an Ansible playbook.
* `-i inventory.ini`: Specifies your `inventory.ini` file, which tells Ansible to run the playbook against `localhost` using a local connection.
* `tune-openshift-island-challenge.yaml`: The name of your Ansible playbook file.

### **What to Expect:**

* The playbook will first **scale down** your CTFd application and database deployments to zero replicas. **This will cause downtime for your CTFd application.**
* It will then apply all the `oc patch` commands we've defined, updating the configurations for both your CTFd app and MySQL database.
* Finally, it will **scale your database back up**, wait for it to be ready, and then **scale your CTFd application back up**.
* The entire process will be logged in your terminal, and you'll see messages indicating task progress and rollouts.

After the playbook completes, your CTFd application and database will be running with all the performance and stability optimizations applied. 