.PHONY: serve
serve:
	cd site; hugo serve

.PHONY: tf-fmt
tf-fmt:
	cd ./terraform && terraform fmt --recursive

.PHONY: test
test:
	bash hack/run-tests.sh

.PHONY: e2e-test
e2e-test:
	bash hack/run-e2e.sh