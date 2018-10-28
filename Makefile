include config.mk

aws = pipenv run aws

bucket:
	$(aws) s3api head-bucket --bucket "$(bucket_name)" 2>/dev/null || $(aws) s3 mb s3://$(bucket_name)

build:
	pipenv lock -r | pipenv run pip install -r /dev/stdin -t dist/
	cp -r src/. dist

test:
	pipenv run python -m pytest tests/

clean:
	rm -rf dist/

deploy: test build bucket
	$(aws) cloudformation package \
		--template-file sam.yml \
	    --s3-bucket $(bucket_name) \
		--output-template-file dist/sam.yml
	$(aws) cloudformation deploy \
		--template-file dist/sam.yml \
		--stack-name $(stack_name) \
		--capabilities CAPABILITY_IAM
	$(aws) cloudformation list-stack-resources --stack-name $(stack_name)

undeploy:
	$(aws) cloudformation delete-stack --stack-name $(stack_name)
	$(aws) cloudformation wait stack-delete-complete --stack-name $(stack_name)
