validate = ! bundle exec kwalify -lf $1 | grep --after-context=1 INVALID
data     = $(subst .yml,,$(shell ls data))
name     = nucleotides/data

################################################
#
# Deploy data container
#
################################################

deploy: .image
	docker login --username=$$DOCKER_USER --password=$$DOCKER_PASS --email=$$DOCKER_EMAIL
	docker tag $(name) $(name):staging
	docker push $(name):staging

.image: $(shell find controlled_vocabulary inputs -name '*.yml') Dockerfile
	docker build --tag=$(name) .
	touch $@

################################################
#
# Ensure inputs match schema, and S3 files exist
#
################################################

types  = $(addprefix cv/,$(shell ls controlled_vocabulary))
inputs = $(shell find inputs -maxdepth 1 -type f)
files = $(shell find inputs/data -maxdepth 1 -type f)

.test_token/inputs/%: schema/% inputs/%
	$(call validate,$^)
	@touch $@

.test_token/inputs/data/%: schema/datum.yml inputs/data/%
	$(call validate,$^)
	@touch $@

.test_token/cv/%: schema/controlled_vocabulary.yml controlled_vocabulary/%
	$(call validate,$^)
	@touch $@

.test_token/input_s3_files_exist: ./bin/validate-s3-files inputs/file.yml inputs/biological_source.yml
	@bundle exec $^
	@touch $@

test: $(addprefix .test_token/,$(inputs) $(types) $(files)) .test_token/input_s3_files_exist

################################################
#
# Bootstrap required resources
#
################################################

bootstrap: Gemfile.lock
	mkdir -p .test_token/cv .test_token/inputs/data



Gemfile.lock: Gemfile
	bundle install --path vendor/bundle
