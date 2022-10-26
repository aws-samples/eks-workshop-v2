S3_ASSET_BUCKET ?= 
S3_ASSET_PREFIX ?= 
ZIPFILE ?= 

.PHONY: clean
clean:
	find event-engine/lib -name '*.js' -delete
	find event-engine/lib -name '*.d.ts' -delete
	find event-engine/bin -name '*.js' -delete
	find event-engine/bin -name '*.d.ts' -delete
	rm -rf event-engine/cdk.out/

.PHONY: build
build:
	cd event-engine && npm run-script build

.PHONY: synth-bootstrap
synth-bootstrap: clean build
	cd event-engine && npx cdk synth EventEngineStack

.PHONY: deploy
deploy:
	npx cdk deploy --app "npx ts-node --prefer-ts-exts event-engine/bin/event-engine.ts" EventEngineStack --require-approval=never \
		--previous-parameters=false \
		--parameters EventEngineStack:AssetBucketName=$(S3_ASSET_BUCKET) \
		--parameters EventEngineStack:AssetBucketPrefix=$(S3_ASSET_PREFIX) \
		--parameters EventEngineStack:SourceZipFile=$(ZIPFILE)

.PHONY: destroy
destroy:
	npx cdk destroy --app "npx ts-node --prefer-ts-exts event-engine/bin/event-engine.ts" EventEngineStack
