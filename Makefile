validate = ! bundle exec kwalify -lf schema/$1.yml data/$1.yml | grep INVALID

bootstrap: Gemfile.lock

test:
	$(call validate,assembler)

Gemfile.lock: Gemfile
	bundle install
