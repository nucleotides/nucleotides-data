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

types  = $(shell find controlled_vocabulary -type f)
inputs = $(shell find inputs -maxdepth 1 -type f)
files  = $(shell find inputs/data -type f)

.test_token/inputs/%: schema/% inputs/%
	$(call validate,$^)
	@touch $@

.test_token/inputs/data/%: schema/datum.yml inputs/data/%
	$(call validate,$^)
	@touch $@

.test_token/controlled_vocabulary/%: schema/controlled_vocabulary.yml controlled_vocabulary/%
	$(call validate,$^)
	@touch $@

.test_token/input_s3_files_exist: ./bin/validate-s3-files $(files)
	bundle exec $^
	touch $@

.test_token/cv_cross_refs: ./bin/cross-ref-controlled-vocab $(inputs) $(files)
	bundle exec $^
	touch $@

test: $(addprefix .test_token/,$(inputs) $(types) $(files)) \
	.test_token/input_s3_files_exist \
	.test_token/cv_cross_refs

################################################
#
# Bootstrap required resources
#
################################################

bootstrap: Gemfile.lock
	mkdir -p .test_token/controlled_vocabulary .test_token/inputs/data



Gemfile.lock: Gemfile
	bundle install --path vendor/bundle
