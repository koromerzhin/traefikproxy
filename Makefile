isDocker := $(shell docker info > /dev/null 2>&1 && echo 1)

.DEFAULT_GOAL := help

NETWORK       := proxynetwork
STACK         := proxy

PROXY         := $(STACK)_traefik
PROXYFULLNAME := $(PROXY).1.$$(docker service ps -f 'name=$(PROXY)' $(PROXY) -q --no-trunc | head -n1)


REVERSE         := $(STACK)_reverse
REVERSEFULLNAME := $(REVERSE).1.$$(docker service ps -f 'name=$(REVERSE)' $(REVERSE) -q --no-trunc | head -n1)

SUPPORTED_COMMANDS := contributors git docker linter logs ssh inspect update sleep
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif

.PHONY: help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

package-lock.json: package.json
	@npm install

node_modules: package-lock.json
	@npm install

.PHONY: isdocker
isdocker: ## Docker is launch
ifeq ($(isDocker), 0)
	@echo "Docker is not launch"
	exit 1
endif

.PHONY: sleep
sleep: ## sleep
	@sleep  $(COMMAND_ARGS)

.PHONY: install
install: node_modules ## Installation application
	@make folders -i
	@make docker create-network -i
	@make docker deploy -i

.PHONY: folders
folders: ## creation des dossier
	@mkdir letsencrypt

.PHONY: contributors
contributors: node_modules ## Contributors
ifeq ($(COMMAND_ARGS),add)
	@npm run contributors add
else ifeq ($(COMMAND_ARGS),check)
	@npm run contributors check
else ifeq ($(COMMAND_ARGS),generate)
	@npm run contributors generate
else
	@npm run contributors
endif

.PHONY: logs
logs: isdocker ## Scripts logs
ifeq ($(COMMAND_ARGS),stack)
	@docker service logs -f --tail 100 --raw $(STACK)
else ifeq ($(COMMAND_ARGS),proxy)
	@docker service logs -f --tail 100 --raw $(PROXYFULLNAME)
else ifeq ($(COMMAND_ARGS),reverse)
	@docker service logs -f --tail 100 --raw $(REVERSEFULLNAME)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make logs ARGUMENT"
	@echo "---"
	@echo "stack: logs stack"
	@echo "proxy: PROXY"
	@echo "reverse: REVERSE"
endif

.PHONY: docker
docker: isdocker ## Scripts docker
ifeq ($(COMMAND_ARGS),create-network)
	@docker network create --driver=overlay $(NETWORK)
else ifeq ($(COMMAND_ARGS),deploy)
	@docker stack deploy -c docker-compose.yml $(STACK)
else ifeq ($(COMMAND_ARGS),ls)
	@docker stack services $(STACK)
else ifeq ($(COMMAND_ARGS),stop)
	@docker stack rm $(STACK)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make docker ARGUMENT"
	@echo "---"
	@echo "create-network: create network"
	@echo "deploy: deploy"
	@echo "ls: docker service"
	@echo "stop: docker stop"
endif

.PHONY: linter
linter: node_modules ## Scripts Linter
ifeq ($(COMMAND_ARGS),all)
	@make linter readme -i
else ifeq ($(COMMAND_ARGS),readme)
	@npm run linter-markdown README.md
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make linter ARGUMENT"
	@echo "---"
	@echo "all: all"
	@echo "readme: linter README.md"
endif

.PHONY: git
git: node_modules ## Scripts GIT
ifeq ($(COMMAND_ARGS),check)
	@make contributors check -i
	@make linter all -i
	@git status
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make git ARGUMENT"
	@echo "---"
	@echo "check: CHECK before"
endif

.PHONY: ssh
ssh: isdocker ## ssh
ifeq ($(COMMAND_ARGS),proxy)
	@docker exec -it $(PROXYFULLNAME) sh
else ifeq ($(COMMAND_ARGS),reverse)
	@docker exec -it $(REVERSEFULLNAME) /bin/bash
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make ssh ARGUMENT"
	@echo "---"
	@echo "proxy: PROXY"
	@echo "reverse: REVERSE"
endif

.PHONY: inspect
inspect: isdocker ## inspect
ifeq ($(COMMAND_ARGS),proxy)
	@docker service inspect $(PROXY)
else ifeq ($(COMMAND_ARGS),reverse)
	@docker service inspect $(REVERSE)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make inspect ARGUMENT"
	@echo "---"
	@echo "proxy: PROXY"
	@echo "reverse: REVERSE"
endif

.PHONY: update
update: isdocker ## update
ifeq ($(COMMAND_ARGS),proxy)
	@docker service update $(PROXY)
else ifeq ($(COMMAND_ARGS),reverse)
	@docker service update $(REVERSE)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make update ARGUMENT"
	@echo "---"
	@echo "proxy: PROXY"
	@echo "reverse: REVERSE"
endif
