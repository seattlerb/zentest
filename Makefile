RUBY?=ruby
RUBYFLAGS?=

test: unittest
	@for f in *.result; do rb=$$(basename $$f .result).rb; echo $$rb; $(RUBY) $(RUBYFLAGS) ./ZenTest.rb $$rb | tail +2 > tmp.txt; diff $$f tmp.txt || exit 1; done
	-rm -f tmp.txt

unittest:
	$(RUBY) $(RUBYFLAGS) ./TestZenTest.rb


clean:
	rm -f *~
