terraform_context='terraform'
module='-'
environment=''
shell_command=''
shell_simple_command=''
glob='-'
cluster='all'
CONTAINER_CLI ?= docker

# Roots containing version-controlled Terraform. There is no root terraform/
# directory; cluster-level config lives in cluster/terraform and per-module lab
# config under manifests/**/.workshop/terraform.
terraform_dirs=cluster/terraform manifests

# ECR Public authorization tokens last 12 hours, so logging in on every
# invocation is wasted work. Record the last login in a stamp file and let make
# skip the login while that stamp is current. Stamped per container CLI because
# docker and finch keep their credentials in separate config files.
ecr_login_stamp=.make/ecr-login-$(CONTAINER_CLI)
ecr_login_ttl_mins=660

# Runs when this makefile is parsed: discard an aged-out stamp so the rule below
# is considered out of date and the login runs again. Assigned to a throwaway
# variable so any output from find cannot be parsed as a makefile directive.
_ecr_stamp_expiry_check := $(shell find $(ecr_login_stamp) -mmin +$(ecr_login_ttl_mins) -delete 2>/dev/null)

$(ecr_login_stamp):
	@mkdir -p $(dir $@)
	@if [ -n "$${SKIP_CREDENTIALS:-}" ]; then \
	  echo "SKIP_CREDENTIALS set, skipping public.ecr.aws login"; \
	else \
	  set -x; \
	  aws ecr-public get-login-password --region us-east-1 | $(CONTAINER_CLI) login --username AWS --password-stdin public.ecr.aws; \
	fi
	@touch $@

# The stamp only tracks elapsed time, not whether the stored credential still
# works. Use this to force a fresh login after logging out or switching account.
.PHONY: ecr-login
ecr-login:
	@rm -f $(ecr_login_stamp)
	@$(MAKE) --no-print-directory $(ecr_login_stamp)

.PHONY: install
install:
	yarn install

.PHONY: build
build: install
	yarn build

.PHONY: warning
warning:
	@echo "Note: 'make serve' now does a full static build. For dev mode, use 'make start' instead."

.PHONY: serve
serve: warning build
	yarn serve

.PHONY: start
start: install
	yarn start

.PHONY: tf-fmt
tf-fmt:
	@for dir in $(terraform_dirs); do terraform fmt -recursive $$dir; done

.PHONY: test
test: $(ecr_login_stamp)
	bash hack/run-tests.sh $(environment) $(module) $(glob)

.PHONY: shell
shell: $(ecr_login_stamp)
	bash hack/shell.sh $(environment)

.PHONY: ide
ide: $(ecr_login_stamp)
	bash hack/shell.sh $(environment) ide

.PHONY: reset-environment
reset-environment: $(ecr_login_stamp)
	bash hack/shell.sh $(environment) reset-environment

.PHONY: delete-environment
delete-environment: $(ecr_login_stamp)
	bash hack/shell.sh $(environment) delete-environment

.PHONY: pre-provision
pre-provision:
	bash hack/pre-provision-resources.sh $(environment) $(action) $(module)

.PHONY: create-infrastructure
create-infrastructure: $(ecr_login_stamp)
	CONTAINER_CLI=$(CONTAINER_CLI) bash hack/create-infrastructure.sh $(environment) $(cluster)

# The event-style flow in one command: create the clusters, then apply the
# pre-provisioned lab resources against them. Ordering matters because
# pre-provisioning targets an existing cluster. Scope it to a single module with
# module=<chapter>/<module> to skip every other module's pre-provisioned
# resources.
#
# create-infrastructure runs as a prerequisite rather than through a recursive
# $(MAKE) call: passing environment through a sub-make command line would strip
# the quoting that keeps an empty environment from being read as the next
# positional argument.
.PHONY: create-environment
create-environment: create-infrastructure
	bash hack/pre-provision-resources.sh $(environment) apply $(module)

.PHONY: destroy-infrastructure
destroy-infrastructure: $(ecr_login_stamp)
	CONTAINER_CLI=$(CONTAINER_CLI) bash hack/destroy-infrastructure.sh $(environment) $(cluster)

.PHONY: deploy-ide
deploy-ide:
	bash hack/deploy-ide-cfn.sh $(environment)

.PHONY: destroy-ide
destroy-ide:
	bash hack/destroy-ide-cfn.sh $(environment)

.PHONY: lint
lint:
	yarn lint

