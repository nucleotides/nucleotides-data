validate = ! bundle exec kwalify -lf $1 | grep --after-context=1 INVALID
data     = $(subst .yml,,$(shell ls data))

test: \
	.rdm_container \
	$(addprefix .test_token/,$(shell find controlled_vocabulary -type f)) \
	$(addprefix .test_token/,$(shell find inputs/data -type f)) \
	$(addprefix .test_token/,$(shell find inputs -maxdepth 1 -type f)) \
	.test_token/input_s3_files_exist \
	.test_token/cv_cross_refs \
	.test_token/data_cross_refs
	$(docker_db) \
		--detach=false \
		--volume=$(realpath .):/data:ro \
		$(name) \
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
	@$(call validate,$^)
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

bootstrap: Gemfile.lock .rdm_container
	mkdir -p .test_token/controlled_vocabulary .test_token/inputs/data

.rdm_container:
	@export $(params) && \
		docker run \
		--env=POSTGRES_PASSWORD="$${PGPASSWORD}" \
		--env=POSTGRES_USER="$${PGUSER}" \
		--publish=$${PGPORT}:5432 \
		--detach=true \
		kiasaki/alpine-postgres:9.5 > $@
	@sleep 5

Gemfile.lock: Gemfile
	bundle install --path vendor/bundle

################################################
#
# Docker and DB environment variables
#
################################################

db_user = PGUSER=dummy
db_pass = PGPASSWORD=dummy
db_name = PGDATABASE=dummy
db_port = PGPORT=65432

ifdef DOCKER_HOST
       db_host  := PGHOST=$(shell echo ${DOCKER_HOST} | egrep -o "\d+.\d+.\d+.\d+")
else
       db_host  := PGHOST=localhost
endif

params  = $(db_user) $(db_pass) $(db_name) $(db_host) $(db_port)

name = nucleotides/api:staging

docker_db = docker run \
	    --env="$(db_user)" \
	    --env="$(db_name)" \
	    --env="$(db_pass)" \
	    --env="$(db_host)" \
	    --env="$(db_port)" \
	    --net=host
