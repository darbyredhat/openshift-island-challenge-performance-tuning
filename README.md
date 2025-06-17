# OpenShift Island Challenge Performance Tuning

This document provides instructions for setting up and running API-focused load tests against your CTFd application using Playwright. This setup is optimized for high-performance API testing, bypassing full UI rendering for each request and using a pre-authenticated session.

## **TL;DR: Playbook Overview**

* **Ensures Safe Updates with Downtime:** Scales down both your CTFd application and database to zero replicas before applying any changes, then scales them back up.
* **Generates Critical Security Key:** Automatically creates and sets a unique `SECRET_KEY` for your CTFd application.
* **Optimizes CTFd App Resources:** Significantly increases CPU allocation and sets the number of Gunicorn `WORKERS` for better concurrency.
* **Configures CTFd Rate Limiting:** Sets a high default rate limit to prevent "Too Many Requests" errors during load testing.
* **Optimizes CTFd Database Resources:** Allocates more CPU and increases Memory limits for the MySQL database pod.
* **Applies Safe Rollout Strategies:** Configures both deployments to update sequentially, avoiding multi-attach errors with persistent volumes.

## **Step 1: Install System Requirements (if not already installed)**

Make sure you have the following installed on your macOS or Linux system.

1.  **`community.kubernetes` Ansible Collection**:

      * This collection provides the Ansible modules (`k8s_patch`, `k8s_rollout`, `k8s_scale`) that allow Ansible to interact with Kubernetes/OpenShift resources.
      * **Installation:**
        ```bash
        ansible-galaxy collection install community.kubernetes
        ansible-galaxy collection install kubernetes.core\n
        pip install kubernetes PyYAML
        python3 -m venv path/to/venv\n    source path/to/venv/bin/activate
        python3 -m pip install kubernetes PyYAML
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

## **Step 2: Run Your Ansible Playbook:**

1. Clone this git repo

```bash
git clone https://github.com/darbyredhat/openshift-island-challenge-performance-tuning
cd openshift-island-challenge-performance-tuning 
```

2. Run the following command in your terminal:

```bash
ansible-playbook tune-openshift-island-challenge.yaml
```

### **What to Expect:**

* The playbook will first **scale down** your CTFd application and database deployments to zero replicas. **This will cause downtime for your CTFd application.**
* It will then apply all the `oc patch` commands we've defined, updating the configurations for both your CTFd app and MySQL database.
* Finally, it will **scale your database back up**, wait for it to be ready, and then **scale your CTFd application back up**.
* The entire process will be logged in your terminal, and you'll see messages indicating task progress and rollouts.

After the playbook completes, your CTFd application and database will be running with all the performance and stability optimizations applied. 

## Metrics: Before and After

Okay, let's put together a "before and after" table of your API load test results. This will clearly highlight the impact of all the optimizations you've applied.

**Before Optimization:** (New environment, unoptimized, 50 concurrent users)
**After Optimization:** (New environment, fully optimized, 50 concurrent users)

---

### **API Load Test Performance: Before & After Optimization**

| Metric | Before Optimization (Unoptimized CTFd) | After Optimization (Optimized CTFd) | Improvement / Notes |
| :-------------------------------------- | :------------------------------------- | :---------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Total Test Duration** (for 5 min test) | 308.13 seconds                         | 304.12 seconds                      | Consistent (test ran for full duration both times)                                                                                                                  |
| **Total API Flows Attempted** | 1333                                   | **3286** | **+146% Increase in Flows (Signifies much higher throughput and capacity)** |
| **Flow Success Rate** | 99.85%                                 | **99.97%** | **Maintained near-perfect stability** |
| **Overall API Call Success Rate** | 100.00%                                | 100.00%                             | **Maintained perfect individual API call stability** |
| **Avg Full API Flow Duration Per User** | 11141.49ms (11.14s)                    | **4253.67ms (4.25s)** | **~2.6x Faster (Overall user journey is significantly more efficient)** |
| **Avg Individual API Call Time** | 1087.98ms (1.09s)                      | **103.30ms (0.10s)** | **~10.5x Faster (Individual API calls are now lightning fast, averaging under 100ms!)** |
| **P90 Individual API Call Time** | 1814.40ms (1.81s)                      | **171.00ms (0.17s)** | **~10.6x Faster (90% of calls are very fast)** |
| **P99 Individual API Call Time** | 2143.84ms (2.14s)                      | **320.06ms (0.32s)** | **~6.7x Faster (The slowest 1% of calls are now completing in just under 1/3 of a second, indicating excellent consistency and elimination of significant long tails).** |

---

**Conclusion:**

This table clearly demonstrates the dramatic and successful impact of the optimizations you applied. Your CTFd backend API has been transformed from struggling under load to being a highly performant, stable, and scalable system.