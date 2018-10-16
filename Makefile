install: conf
	chmod +x dotpm.p6
	cp -p dotpm.p6 /usr/local/bin/dotpm

conf:
	chmod +x conf.sh
	./conf.sh
