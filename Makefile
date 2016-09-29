validate = ! bundle exec kwalify -lf $1 | grep --after-context=1 INVALID
data     = $(subst .yml,,$(shell ls data))

ifndef DOCKER_HOST
$(error Docker does not appear to be running)
endif

test: .rdm_container $(addprefix .test_token/,$(inputs) $(types) $(files)) \
	.test_token/input_s3_files_exist \
	.test_token/cv_cross_refs \
	.test_token/data_cross_refs
	@docker run \
	  --env="$(db_user)" \
	  --env="$(db_pass)" \
	  --env="$(db_name)" \
	  --env=POSTGRES_HOST=//localhost:54345 \
	  --net=host \
	  --volume=$(realpath .):/data:ro \
	  nucleotides/api:staging \
	  migrate &> .test_token/migration.log


################################################
#
# Ensure inputs match schema, and S3 files exist
#
################################################
types  = $(shell find controlled_vocabulary -type f)
inputs = $(shell find inputs -maxdepth 1 -type f)
files  = $(shell find inputs/data -type f)

.test_token/inputs/%: schema/% inputs/%
	@$(call validate,$^)
	@touch $@

.test_token/inputs/data/%: schema/datum.yml inputs/data/%
	@$(call validate,$^)
	@touch $@

.test_token/controlled_vocabulary/%: schema/controlled_vocabulary.yml controlled_vocabulary/%
	$(call validate,$^)
	@touch $@

.test_token/input_s3_files_exist: ./bin/validate-s3-files $(files)
	@bundle exec $^
	@touch $@

.test_token/cv_cross_refs: ./bin/cross-ref-controlled-vocab $(inputs) $(files)
	@bundle exec $^
	@touch $@

.test_token/data_cross_refs: ./bin/cross-ref-data-sets inputs/benchmark.yml $(files)
	@bundle exec $^
	@touch $@

################################################
#
# Bootstrap required resources
#
################################################

bootstrap: Gemfile.lock
	mkdir -p .test_token/controlled_vocabulary .test_token/inputs/data

.rdm_container:
	docker run \
	  --env="$(db_user)" \
	  --env="$(db_pass)" \
          --publish=54345:5432 \
	  --detach=true \
	  kiasaki/alpine-postgres:9.5 > $@

Gemfile.lock: Gemfile
	bundle install --path vendor/bundle

################################################
#
# Docker and DB environment variables
#
################################################

db_user := POSTGRES_USER=postgres
db_pass := POSTGRES_PASSWORD=pass
db_name := POSTGRES_NAME=postgres

ifdef docker_host
       db_host  := POSTGRES_HOST=//$(docker_host):5433
else
       db_host  := POSTGRES_HOST=//localhost:5433
endif
