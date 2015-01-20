bootstrap: Gemfile.lock

test:
	! bundle exec kwalify -lf schema/assembler.yml assembler.yml | grep INVALID
