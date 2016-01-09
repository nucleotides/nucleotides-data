validate = ! bundle exec kwalify -lf $1 | grep INVALID
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

.image: $(shell find data -name '*.yml') Dockerfile
	docker build --tag=$(name) .
	touch $@

################################################
#
# Test data with the schema
#
################################################

test: $(foreach i,$(data),.test_token/$i)

.test_token/%: schema/%.yml data/%.yml
	$(call validate,$^)
	touch $@

################################################
#
# Bootstrap required resources
#
################################################

bootstrap: Gemfile.lock
	mkdir .test_token

Gemfile.lock: Gemfile
	bundle install
