validate = ! bundle exec kwalify -lf $1 | grep INVALID
data     = $(subst .yml,,$(shell ls data))

test: $(foreach i,$(data),.test_token/$i)

bootstrap: Gemfile.lock
	mkdir .test_token

.test_token/%: schema/%.yml data/%.yml
	$(call validate,$^)
	touch $@

Gemfile.lock: Gemfile
	bundle install
