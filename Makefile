default:
	@echo "Please specify a target, i.e. 'make deploy ENV=(dev|test)' or 'make images'"

# Build images for backend-api and data-api
# if the current context is kind, load the images into the kind cluster
.PHONY: images
images:
	docker build -f backend_api/Dockerfile -t backend-api:latest ./backend_api
	docker build -f data_api/Dockerfile -t data-api:latest ./data_api
	@if kubectl config current-context | grep -q 'kind'; then \
		echo "Detected Kind cluster, loading images into Kind cache..."; \
		kind load docker-image backend-api:latest; \
		kind load docker-image data-api:latest; \
	fi

# Ansible will not upgrade chart if the version is the same (and I don't want to force it)
# So we need to bump the version before deploying, this is a workaround for local development
.PHONY: bumpChartVersion
bumpChartVersion:
	@VERSION_LINE=$$(grep "version:" ./helm/Chart.yaml); \
	VERSION=$$(echo $$VERSION_LINE | sed -E 's/version: ([0-9]+\.[0-9]+\.)([0-9]+)/\1\2/'); \
	MAJOR_MINOR=$$(echo $$VERSION | cut -d '.' -f 1,2); \
	PATCH=$$(echo $$VERSION | cut -d '.' -f 3); \
	NEW_PATCH=$$((PATCH + 1)); \
	sed -E "s/(version: [0-9]+\.[0-9]+\.)([0-9]+)/\1$$NEW_PATCH/" ./helm/Chart.yaml > Chart.tmp && mv Chart.tmp ./helm/Chart.yaml; \
	echo "Version bumped to $$MAJOR_MINOR.$$NEW_PATCH"

.PHONY: deploy
deploy: images bumpChartVersion
	ansible-playbook -i localhost -e "env=$(ENV)" --ask-vault-pass  ansible/playbook.yaml

.PHONY: verifyBackendAPI
verifyBackendAPI:
	@echo "Verifying Backend API"
	@kubectl port-forward -n tech-test service/technical-test-tech-test-backend-api 8080:80 & \
	PORT_FORWARD_PID=$$!; \
	sleep 3; \
	curl -v http://127.0.0.1:8080/health_check;echo; \
	kill $$PORT_FORWARD_PID;

.PHONY: verifyDataAPI
verifyDataAPI:
	@echo "Verifying data-api"
	@kubectl port-forward -n tech-test service/technical-test-tech-test-data-api 8080:80 & \
	PORT_FORWARD_PID=$$!; \
	sleep 3; \
	curl -v http://127.0.0.1:8080/health_check;echo; \
	kill $$PORT_FORWARD_PID;


.PHONY: verifyAll
verifyAll: verifyBackendAPI verifyDataAPI
	@echo "All services has been verified"
