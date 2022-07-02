TF_STATE_S3_BUCKET ?= terraformstate94163fde
ZIPFILE ?= eks-workshop-tf-stack.zip

.PHONY: zip
zip: $(ZIPFILE)

.PHONY: $(ZIPFILE)
$(ZIPFILE): $(shell git ls-files)
	rm -f $@
	git ls-files | xargs zip $@

.PHONY: tf-init-stack
tf-init-stack:
	cd ./terraform/workshop-stack && terraform init -backend-config="bucket=$(TF_STATE_S3_BUCKET)"