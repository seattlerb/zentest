RUBY?=ruby
RUBYFLAGS?=
RUBY_BIN?=$(shell $(RUBY) -rrbconfig -e 'include Config; print CONFIG["bindir"]')

test: unittest
	@for f in *.result; do rb=$$(basename $$f .result).rb; echo $$rb; $(RUBY) $(RUBYFLAGS) ./ZenTest.rb $$rb | tail +2 > tmp.txt; diff $$f tmp.txt || exit 1; done
	-rm -f tmp.txt

unittest:
	$(RUBY) $(RUBYFLAGS) ./TestZenTest.rb


PREFIX=/usr/local
install:
	cp -f ZenTest.rb $(RUBY_BIN)/ZenTest
	cp -f unit_diff.rb $(RUBY_BIN)/unit_diff
	chmod 555 $(RUBY_BIN)/ZenTest $(RUBY_BIN)/unit_diff

uninstall:
	rm -f $(RUBY_BIN)/ZenTest $(RUBY_BIN)/unit_diff

clean:
	rm -f *~
