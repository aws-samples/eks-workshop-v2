.PHONY: serve
serve:
	cd site; hugo serve

.PHONY: tf-fmt
tf-fmt:
	cd ./terraform && terraform fmt --recursive
