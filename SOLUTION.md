# Solution of the task

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

