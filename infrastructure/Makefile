TF_STATE_S3_BUCKET ?= terraformstate94163fde
ZIPFILE ?= eks-workshop-tf-stack.zip
# S3_ASSET_BUCKET ?= code-upload-bucket-eks-workshop-v2-25158
S3_ASSET_BUCKET ?= code-upload-bucket-eks-workshop-v2-16728
S3_ASSET_PREFIX ?= modules/4bc94302f57c4c418df7e029ed5ffffc/v1/
# S3_URL := s3://$(S3_ASSET_BUCKET)/$(S3_ASSET_PREFIX)$(ZIPFILE)
S3_URL := s3://$(S3_ASSET_BUCKET)/$(ZIPFILE)


.PHONY: upload
upload: $(ZIPFILE)
	@echo Note: If this fails, ensure the proper AWS credentials are set in the environment. These can be found in the Event Engine module configuration.
	aws s3 cp $(ZIPFILE) $(S3_URL)

.PHONY: zip
zip: $(ZIPFILE)

.PHONY: $(ZIPFILE)
$(ZIPFILE): $(shell git ls-files)
	rm -f $@
	git ls-files | xargs zip $@

.PHONY: clean
clean:
	rm -f $(ZIPFILE)
	find . -name '*.js' ! -name 'jest.config.js' -not -path './node_modules/*' -delete
	find . -name '*.d.ts' -not -path './node_modules/*' -delete
	rm -rf event-engine/cdk.out/
	rm -rf terraform/workshop-stack/.terraform
	rm terraform/workshop-stack/terraform.tfstate
	rm terraform/workshop-stack/terraform.tfstate.backup

.PHONY: build
build:
	npm run build

.PHONY: synth-bootstrap
synth-bootstrap: clean build zip
	npx cdk synth EventEngineStack

.PHONY: tf-init-stack
tf-init-stack:
	cd ./terraform/workshop-stack && terraform init --backend-config="bucket=$(TF_STATE_S3_BUCKET)" --backend-config="region=$(AWS_REGION)"

.PHONY: make-copy
make-copy:
	cp Makefile eks-workshop-tf-stack/
	cp -r terraform/ eks-workshop-tf-stack/terraform

.PHONY: deploy
deploy:
	npx cdk deploy --app "npx ts-node --prefer-ts-exts event-engine/bin/event-engine.ts" EventEngineStack --require-approval=never \
		--previous-parameters=false \
		--parameters EventEngineStack:EEAssetsBucket=$(S3_ASSET_BUCKET) \
		--parameters EventEngineStack:EEAssetsKeyPrefix=$(S3_ASSET_PREFIX) \
		--parameters EventEngineStack:SourceZipFile=$(ZIPFILE) \
		--parameters EventEngineStack:SourceZipFileChecksum=$$(openssl sha256 -hex -r $(ZIPFILE) | cut -d' ' -f1)