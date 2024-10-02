# Solution of the task

## Checklist of tasks
- Add a new backend api:
  - ```/download_external_logs``` makes a call to external service's api.
  - The external download API is dummy api, _you may leave it blank,_ however it requires $EXTERNAL_INTGERATION_KEY to authenticate
  - the external api has multiple environments so the integration key varies by environment
> Implemented, verification is available in [Backend API](#backend-api) section
- Update the health check to fit the new architecture
> - I used startup/health probe combination for the `Data API` (because `/` endpoint performing some writes to the filesystem, which is not covered by liveness probe).
> - I used just health probe for the `Backend API` (since it's a simple API and doesn't have any startup logic).
> - Script also contained logic about logging the health status to the console - I don't understand the purpose of this so I did not migrated it 1 to 1. Application logs could be checked using [Victoria Logs section](#victoria-logs), application health can be checked using commands in [verify section](#verify-backend-api-and-data-api).
- Create helmchart for the stack
> - Helm chart is available in the `helm` folder
> - Helm chart created using `helm create` command offers least-privileged permissions for containers and follows [Baseline Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/#baseline)
> - To further enhance security, `nobody` user in used in the application containers.
> - For Data API init container is used to create a directory and set permissions for it.
- Deployment via Ansible
> Ansible playbook is available in the `ansible` folder. To bring up stack use [Stack installation steps](#stack-installation-steps) 
- Monitoring Kubernetes Applications - Demonstrate how to monitor the node and Pod and containers resource utilization
> - I used Grafana and Victoria Metrics for monitoring, see [Monitoring stack section](#monitoring-stack) and [Dashboards section](#dashboards)
- How to display only resource utilization for Pods with specific label (k8s-app=kube-Devops)
    - Use filter directly in Kubectl: `kubectl top pods -A -l app.kubernetes.io/managed-by=Helm`

## Stack installation steps

### Prerequisites

- Running k8s cluster, I used Docker Desktop
- Kubectl is pointing to the cluster
- Make installed, I used `GNU Make 3.81` - this is done to avoid polluting this document with long commands and was useful during development/testing
- Ansible installed, I used version `2.17.4`
- Kubernetes core collection installed using `ansible-galaxy collection install kubernetes.core`
- Images for `backend_api` and `data_api` are available in the Docker cache (since I didn't push them to the registry and no CI is mentioned in the scope), to build them use: `make images`
- Backend API requires `EXTERNAL_INTEGRATION_KEY` to authenticate with the external service. The key is stored in the Ansible vault. To run the playbook, you need to provide the vault password.

### Installation/upgrade steps

> __NOTE__: Make sure you have Ansible Vault password ready, I attached it to email.

Backend API has 2 dummy environments: `dev` and `test`. The environments have different `EXTERNAL_INTEGRATION_KEY` values.

Run the following command to deploy the stack to the `dev` environment (to deploy to `test` environment, replace `dev` with `test`):

### Deploy the stack

```bash
make deploy ENV=dev
```

> __NOTE__: Since the docker tags are always `latest`, the Makefile will bump patch version of the Helm Chart so Ansible can deploy the latest code.

### Access the APIs and the Monitoring stack

#### Verify Backend API and Data API
Both APIs are exposed as services inside the cluster, if you want to check health of applications, you can use the following commands:

```bash
make verifyAll #to verify connectivity to both APIs
make verifyDataAPI
make verifyBackendAPI
```

If you want to access the APIs from outside the cluster, you can use port-forwarding:

##### Backend API

>__NOTE__: `/download_external_logs` endpoints just proxy request with key to the same endpoint but on different path `/api_1`.

```bash
kubectl port-forward -n tech-test service/technical-test-tech-test-backend-api 8080:80

#Endpoints:
# curl -v 127.0.0.1:8080/api_1
# curl -v 127.0.0.1:8080/download_external_logs
# curl -v 127.0.0.1:8080/health_check
```

###### Data API
[Application logs (stdout)](http://127.0.0.1:9428/select/vmui/#/?query=kubernetes_container_name%3A+%22data-api)
```bash
kubectl port-forward -n tech-test service/technical-test-tech-test-data-api 8080:80

#Endpoints:
# curl -v 127.0.0.1:8080/health_check
# curl -v 127.0.0.1:8080/
```

### Monitoring stack

### Victoria Logs
Victoria Logs accessible via the following commands:

```bash
kubectl port-forward -n victoria-logs services/victoria-logs-victoria-logs-single-server 9428:9428
# Access Victoria Logs at http://127.0.0.1:9428/select/vmui/
```

- Victoria Logs configured to collect logs from all containers/nodes running in the cluster.
- Additionally, `Data API` has a sidecar container (Fluent Bit) that sends logs from `/configured_path` directory to Victoria Logs. This is done because mounting the host directory to the pod is not allowed in [Baseline Policy](https://kubernetes.io/docs/concepts/security/pod-security-standards/#baseline).
    - This application logs can be found using filter: `application_name: "data_api"` - [link](http://127.0.0.1:9428/select/vmui/#/?query=application_name%3A+%22data_api%22&g0.range_input=1h)

### Grafana
Grafana is exposed as a service inside the cluster, if you want to access it, you can use the following commands:

```bash
# Get the password from admin user
kubectl get secrets -n vm vm-grafana -o=jsonpath='{.data.admin-password}' | base64 -d; echo
kubectl port-forward -n vm services/vm-grafana 8080:80
# Access Grafana at http://localhost:8080
```

> __NOTE__: Due to the [bug in Cadvisor](https://github.com/google/cadvisor/issues/3336) some metrics for default dashboards are not available. This is why I have to install separate dashboard via Ansible.

#### Dashboards
- [Pods/Containers](http://localhost:8080/d/alex_k8s_views_pods/alex-kubernetes-views-pods?orgId=1&refresh=30s&var-datasource=P4169E866C3094E38&var-cluster=.*&var-namespace=tech-test&var-pod=All&var-resolution=30s&var-job=kube-state-metrics)
- [Nodes](http://localhost:8080/d/rYdddlPWk/node-exporter-full?orgId=1&refresh=1m)

Both dashboards are useful for monitoring workload and to get insights into the cluster.
