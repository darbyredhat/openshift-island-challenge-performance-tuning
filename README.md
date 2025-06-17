# OpenShift Island Challenge Performance Tuning

This document provides instructions for setting up and running API-focused load tests against your CTFd application using Playwright. This setup is optimized for high-performance API testing, bypassing full UI rendering for each request and using a pre-authenticated session.

## **TL;DR: Playbook Overview**

* **Ensures Safe Updates with Downtime:** Scales down both your CTFd application and database to zero replicas before applying any changes, then scales them back up.
* **Generates Critical Security Key:** Automatically creates and sets a unique `SECRET_KEY` for your CTFd application.
* **Optimizes CTFd App Resources:** Significantly increases CPU allocation and sets the number of Gunicorn `WORKERS` for better concurrency.
* **Configures CTFd Rate Limiting:** Sets a high default rate limit to prevent "Too Many Requests" errors during load testing.
* **Optimizes CTFd Database Resources:** Allocates more CPU and increases Memory limits for the MySQL database pod.
* **Applies Safe Rollout Strategies:** Configures both deployments to update sequentially, avoiding multi-attach errors with persistent volumes.

