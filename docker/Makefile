.PHONY: install

install:
	command -v colima >/dev/null 2>&1 || brew install colima
	command -v docker >/dev/null 2>&1 || brew install docker
	command -v dockerdocker-compose >/dev/null 2>&1 || brew install docker-compose

start:
	colima start
	colima status
	docker context use colima

stop:
	colima status
	colima stop
