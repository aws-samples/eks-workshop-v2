TF_STATE_S3_BUCKET ?= terraformstate94163fde
ZIPFILE ?= eks-workshop-tf-stack.zip

.PHONY: zip
zip: $(ZIPFILE)

.PHONY: $(ZIPFILE)
$(ZIPFILE): $(shell git ls-files)
	rm -f $@
	zip -r $(ZIPFILE) ./ --exclude "*.terraform/*" --exclude "*node_modules/*"

.PHONY: tf-init-stack
tf-init-stack:
	cd ./terraform/workshop-stack && terraform init -backend-config="bucket=$(TF_STATE_S3_BUCKET)"