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
	bash hack/shell.sh $(environment)

.PHONY: reset-environment
reset-environment:
	bash hack/shell.sh $(environment) reset-environment

.PHONY: delete-environment
delete-environment:
	bash hack/shell.sh $(environment) delete-environment

.PHONY: create-infrastructure
create-infrastructure:
	bash hack/exec.sh $(environment) 'cat /cluster/eksctl/cluster.yaml | envsubst | eksctl create cluster -f -'

.PHONY: destroy-infrastructure
destroy-infrastructure:
	bash hack/exec.sh $(environment) 'cat /cluster/eksctl/cluster.yaml | envsubst | eksctl delete cluster --wait --force --disable-nodegroup-eviction --timeout 45m -f -'
