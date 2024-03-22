terraform_context='terraform'
module='-'
environment=''
shell_command=''
shell_simple_command=''
glob='-'


.PHONY: install
install:
	cd website; npm install

.PHONY: serve
serve: install
	bash hack/serve.sh

.PHONY: tf-fmt
tf-fmt:
	cd ./terraform && terraform fmt --recursive

.PHONY: test
test:
	bash hack/run-tests.sh $(environment) $(module) $(glob)

.PHONY: shell
shell:
	bash hack/shell.sh $(environment) $(shell_command) $(shell_simple_command)

.PHONY: reset-environment
reset-environment:
	bash hack/shell.sh $(environment) reset-environment

.PHONY: delete-environment
delete-environment:
	bash hack/shell.sh $(environment) delete-environment

.PHONY: update-helm-versions
update-helm-versions:
	bash hack/update-helm-versions.sh

.PHONY: verify-helm-metadata
verify-helm-metadata:
	bash hack/verify-helm-metadata.sh

.PHONY: create-infrastructure
create-infrastructure:
	bash hack/create-infrastructure.sh $(environment)

.PHONY: destroy-infrastructure
destroy-infrastructure:
	bash hack/destroy-infrastructure.sh $(environment)

.PHONY: lint-markdown
lint-markdown:
	bash hack/markdownlint.sh
