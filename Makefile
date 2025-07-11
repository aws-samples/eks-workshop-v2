terraform_context='terraform'
module='-'
environment=''
shell_command=''
shell_simple_command=''
glob='-'

.PHONY: install
install:
	yarn install

.PHONY: serve
serve: install
	yarn serve

.PHONY: tf-fmt
tf-fmt:
	cd ./terraform && terraform fmt --recursive

.PHONY: test
test:
	bash hack/run-tests.sh $(environment) $(module) $(glob)

.PHONY: shell
shell:
	bash hack/shell.sh $(environment)

.PHONY: ide
ide:
	bash hack/shell.sh $(environment) ide

.PHONY: reset-environment
reset-environment:
	bash hack/shell.sh $(environment) reset-environment

.PHONY: delete-environment
delete-environment:
	bash hack/shell.sh $(environment) delete-environment

.PHONY: create-infrastructure
create-infrastructure:
	bash hack/create-infrastructure.sh $(environment)

.PHONY: destroy-infrastructure
destroy-infrastructure:
	bash hack/destroy-infrastructure.sh $(environment)

.PHONY: deploy-ide
deploy-ide:
	bash hack/deploy-ide-cfn.sh $(environment)

.PHONY: destroy-ide
destroy-ide:
	bash hack/destroy-ide-cfn.sh $(environment)

.PHONY: lint
lint:
	yarn lint