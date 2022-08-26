terraform_context='terraform/local'
module='*'

.PHONY: install
serve:
	cd website; npm install

.PHONY: serve
serve:
	cd website; npm start

.PHONY: tf-fmt
tf-fmt:
	cd ./terraform && terraform fmt --recursive

.PHONY: test
test:
	bash hack/run-tests.sh $(terraform_context) $(module)

.PHONY: e2e-test
e2e-test:
	bash hack/run-e2e.sh $(terraform_context)

.PHONY: shell
shell:
	bash hack/shell.sh $(terraform_context)

.PHONY: update-helm-versions
update-helm-versions:
	bash hack/update-helm-versions.sh

.PHONY: verify-helm-metadata
verify-helm-metadata:
	bash hack/verify-helm-metadata.sh

.PHONY: create-infrastructure
create-infrastructure:
	bash hack/create-infrastructure.sh $(terraform_context)

.PHONY: destroy-infrastructure
destroy-infrastructure:
	bash hack/destroy-infrastructure.sh $(terraform_context)

.PHONY: lint-markdown
lint-markdown:
	bash hack/markdownlint.sh