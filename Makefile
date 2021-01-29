.DEFAULT_GOAL := help

NETWORK       := proxynetwork
STACK         := proxy

PROXY         := $(STACK)_traefik
PROXYFULLNAME := $(PROXY).1.$$(docker service ps -f 'name=$(PROXY)' $(PROXY) -q --no-trunc | head -n1)

SUPPORTED_COMMANDS := contributors git docker linter logs
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif
%:
	@:

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

package-lock.json: package.json
	@npm install

node_modules: package-lock.json
	@npm install

install: node_modules ## Installation application
	@make folders -i
	@make docker create-network -i
	@make docker deploy -i

folders: ## creation des dossier
	@mkdir letsencrypt

contributors: ## Contributors
ifeq ($(COMMAND_ARGS),add)
	@npm run contributors add
else ifeq ($(COMMAND_ARGS),check)
	@npm run contributors check
else ifeq ($(COMMAND_ARGS),generate)
	@npm run contributors generate
else
	@npm run contributors
endif

docker-create-network: ## Create network
	@docker network create --driver=overlay $(NETWORK)

docker-deploy: ## deploy
	@docker stack deploy -c docker-compose.yml $(STACK)

docker-image-pull: ## Get docker image
	@docker image pull traefik:2.3.7


logs: ## Scripts logs
ifeq ($(COMMAND_ARGS),stack)
	@docker service logs -f --tail 100 --raw $(STACK)
else ifeq ($(COMMAND_ARGS),proxy)
	@docker service logs -f --tail 100 --raw $(PROXYFULLNAME)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make logs ARGUMENT"
	@echo "---"
	@echo "stack: logs stack"
	@echo "proxy: proxy"
endif

docker: ## Scripts docker
ifeq ($(COMMAND_ARGS),create-network)
	@docker network create --driver=overlay $(NETWORK)
else ifeq ($(COMMAND_ARGS),deploy)
	@docker stack deploy -c docker-compose.yml $(STACK)
else ifeq ($(COMMAND_ARGS),image-pull)
	@docker image pull traefik:2.3.7
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
	@echo "image-pull: Get docker image"
	@echo "ls: docker service"
	@echo "stop: docker stop"
endif

linter: ## Scripts Linter
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

git: ## Scripts GIT
ifeq ($(COMMAND_ARGS),commit)
	@npm run commit
else ifeq ($(COMMAND_ARGS),check)
	@make contributors check -i
	@make linter all -i
	@git status
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make git ARGUMENT"
	@echo "---"
	@echo "commit: Commit data"
	@echo "check: CHECK before"
endif


ssh: ## SSH
	@docker exec -it $(PROXYFULLNAME) /bin/bash

inspect: ## inspect
	@docker service inspect $(PROXY)

update: ## update
	@docker service update $(PROXY)