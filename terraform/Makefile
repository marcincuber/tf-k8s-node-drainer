SHELL := /usr/bin/env bash
# All is the first target in the file so it will get picked up when you just run 'make' on its own

.PHONY: clean
clean:
	rm -rf .terraform

.PHONY: tf-plan-dev
tf-plan-dev:
	terraform init && terraform validate && terraform plan -var-file=vars/dev.tfvars

.PHONY: tf-apply-dev
tf-apply-dev:
	terraform init && terraform validate && terraform apply -var-file=vars/dev.tfvars -auto-approve

.PHONY: build-lambda-node-drainer
build-lambda-node-drainer:
	rm -f node_drainer.zip && \
	pip3 install -r ./node_drainer/drainer/requirements.txt --target ./lambda_build && \
	cp ./node_drainer/drainer/__init__.py ./node_drainer/drainer/handler.py ./node_drainer/drainer/k8s_utils.py ./lambda_build && \
	cd lambda_build && zip -r ../node_drainer.zip ./* && cd .. && rm -rf lambda_build