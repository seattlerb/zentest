

test:
	./TestZenTest.rb
	-./ZenTest.rb testcase0.rb > tmp.txt; diff testcase0.result tmp.txt
	-./ZenTest.rb testcase1.rb > tmp.txt; diff testcase1.result tmp.txt
	-./ZenTest.rb testcase2.rb > tmp.txt; diff testcase2.result tmp.txt
	-./ZenTest.rb testcase3.rb > tmp.txt; diff testcase3.result tmp.txt
	-./ZenTest.rb testcase4.rb > tmp.txt; diff testcase4.result tmp.txt
	-rm -f tmp.txt

clean:
	rm -f *~
