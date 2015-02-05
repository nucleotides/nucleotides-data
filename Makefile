validate = ! bundle exec kwalify -lf $1 | grep INVALID

data = assembler data_type benchmark_type

bootstrap: Gemfile.lock
	mkdir .test_token

test: $(foreach i,$(data),.test_token/$i)

.test_token/%: schema/%.yml data/%.yml
	$(call validate,$^)
	touch $@

Gemfile.lock: Gemfile
	bundle install
