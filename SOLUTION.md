# Solution of the task

## Checklist of tasks
- Add a new backend api:
  - ```/download_external_logs``` makes a call to external service's api.
  - The external download API is dummy api, _you may leave it blank,_ however it requires $EXTERNAL_INTGERATION_KEY to authenticate
  - the external api has multiple enviroments so the integration key varies by enviroment
    - Done. See [Stack installation steps section](#stack-installation-steps)
- Update the health check to fit the new architecture
    - Done.
    - I used startup/health probe for the `Data API` (because `/` endpoint performing some writes to the filesystem, which can be not available).
    - I used just health probe for the `Backend API` (since it's a simple API and doesn't have any startup logic).
    - Script also contained logic about logging the health status to the console - I don't understand the purpose of this; to check application logs check [Victoria Logs section](#victoria-logs)
- Create helmchart for the stack
    - Done, Helm chart is available in the `helm` folder
- Deployment via Ansible
    - Done, Ansible playbook is available in the `ansible` folder
- Monitoring Kubernetes Applications - Demonstrate how to monitor the node and Pod and containers resource utilization
    -  Done, I used Grafana and Victoria Metrics for monitoring, see [Monitoring stack section](#monitoring-stack)
- How to display only resource utilization for Pods with specific label (k8s-app=kube-Devops)
    - Use filter directly in Kubectl: `kubectl top pods -A -l app.kubernetes.io/managed-by=Helm`

## Prerequisites

- Running k8s cluster, I used Docker Desktop
- Kubectl is pointing to the cluster
- Make installed, I used `GNU Make 3.81` - this is done to avoid polluting this document with long commands and was useful during development/testing
- Ansible installed, I used version `2.17.4`
- Kubernetes core collection installed using `ansible-galaxy collection install kubernetes.core`
- Images for `backend_api` and `data_api` are available in the Docker cache (since I didn't push them to the registry and no CI is mentioned in the scope), to build them use: `make images`

## Stack installation steps

Backend API requires `EXTERNAL_INTEGRATION_KEY` to authenticate with the external service. The key is stored in the Ansible vault. To run the playbook, you need to provide the vault password.

Backend API has 2 dummy environments: `dev` and `test`. The environments have different `EXTERNAL_INTEGRATION_KEY` values.

> __NOTE__: I attached vault password for both environments in the email.

Run the following command to deploy the stack to the `dev` environment (to deploy to `test` environment, replace `dev` with `test`):

### Deploy the stack

```bash
make deploy ENV=dev
```

> __NOTE__: Since the docker tags are always `latest`, the Makefile will bump patch version of the Helm Chart so Ansible can deploy the latest code.

### Access the APIs and the Monitoring stack

#### Backend API and Data API
Both APIs are exposed as services inside the cluster, if you want to verify connectivity, you can use the following commands:

```bash
make verifyAll #to verify connectivity to both APIs
make verifyDataAPI
make verifyBackendAPI
```

If you want to access the APIs from outside the cluster, you can use port-forwarding:

##### Backend API
```bash
kubectl port-forward -n tech-test service/technical-test-tech-test-backend-api 8080:80
```

###### Data API
```bash
kubectl port-forward -n tech-test service/technical-test-tech-test-data-api 8080:80
```

### Monitoring stack

### Victoria Logs
- Victoria Logs configured to collect logs from all containers/nodes running in the cluster.
- Additionally, `Data API` has a sidecar container (Fluent Bit) that sends logs to Victoria Logs:
    - This application can be found if filtered using: `application_name: "data_api"`

Victoria Logs accessible via the following commands:

```bash
kubectl port-forward -n victoria-logs services/victoria-logs-victoria-logs-single-server 9428:9428
# Access Victoria Logs at http://127.0.0.1:9428/select/vmui/
```

### Grafana
Grafana is exposed as a service inside the cluster, if you want to access it, you can use the following commands:

```bash
# Get the password from admin user
kubectl get secrets -n vm vm-grafana -o=jsonpath='{.data.admin-password}' | base64 -d; echo
kubectl port-forward -n vm services/vm-grafana 8080:80
# Access Grafana at http://localhost:8080
```

> __NOTE__: Due to the [bug in Cadvisor](https://github.com/google/cadvisor/issues/3336) some metrics for default dashboards are not available. This is why I have to install separate dashboard via Ansible.

Dashboards:
- [Pods/Containers](http://localhost:8080/d/alex_k8s_views_pods/alex-kubernetes-views-pods?orgId=1&refresh=30s&var-datasource=P4169E866C3094E38&var-cluster=.*&var-namespace=tech-test&var-pod=All&var-resolution=30s&var-job=kube-state-metrics)
- [Nodes](http://localhost:8080/d/rYdddlPWk/node-exporter-full?orgId=1&refresh=1m)

Both dashboards are useful for monitoring workload and to get insights into the cluster.
