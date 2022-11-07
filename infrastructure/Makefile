S3_ASSET_BUCKET ?= 
S3_ASSET_PREFIX ?= 
ZIPFILE ?= 

.PHONY: clean
clean:
	find cdk/lib -name '*.js' -delete
	find cdk/lib -name '*.d.ts' -delete
	find cdk/bin -name '*.js' -delete
	find cdk/bin -name '*.d.ts' -delete
	rm -rf cdk/cdk.out/

.PHONY: build
build:
	cd cdk && npm run-script build

.PHONY: synth-bootstrap
synth-bootstrap: clean build
	cd cdk && npx cdk synth EksWorkshopStack --path-metadata false

.PHONY: deploy
deploy:
	npx cdk deploy --app "npx ts-node --prefer-ts-exts cdk/bin/eks-workshop.ts" EksWorkshopStack --require-approval=never \
		--previous-parameters=false \
		--parameters EksWorkshopStack:AssetBucketName=$(S3_ASSET_BUCKET) \
		--parameters EksWorkshopStack:AssetBucketPrefix=$(S3_ASSET_PREFIX) \
		--parameters EksWorkshopStack:SourceZipFile=$(ZIPFILE)

.PHONY: destroy
destroy:
	npx cdk destroy --app "npx ts-node --prefer-ts-exts cdk/bin/eks-workshop.ts" EksWorkshopStack
