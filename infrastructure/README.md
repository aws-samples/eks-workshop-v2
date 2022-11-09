## Testing Instructions

1. Ensure to `cd` into `infrastructure` folder
2. Create an S3 bucket in the same region as workshop target
3. Replace/provide the name of the S3 bucket in the `S3_ASSET_BUCKET` variable in `infrastructure/Makefile`
4. run `make upload`
5. run `make deploy`
