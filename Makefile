RUBY?=ruby
RUBYFLAGS?=
RUBY_BIN?=$(shell $(RUBY) -rrbconfig -e 'include Config; print CONFIG["bindir"]')
RUBY_LIB?=$(shell $(RUBY) -rrbconfig -e 'include Config; print CONFIG["sitelibdir"]')

test: unittest

unittest:
	$(RUBY) $(RUBYFLAGS) ./TestZenTest.rb

PREFIX=/usr/local
install:
	cp -f ZenTest.rb $(RUBY_BIN)/ZenTest
	cp -f ZenTest.rb $(RUBY_LIB)
	cp -f unit_diff.rb $(RUBY_BIN)/unit_diff
	chmod 555 $(RUBY_BIN)/ZenTest $(RUBY_BIN)/unit_diff
	chmod 444 $(RUBY_LIB)/ZenTest.rb

uninstall:
	rm -f $(RUBY_BIN)/ZenTest $(RUBY_BIN)/unit_diff $(RUBY_LIB)/ZenTest.rb

clean:
	rm -f *~
