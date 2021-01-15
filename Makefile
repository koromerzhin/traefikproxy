.DEFAULT_GOAL := help
ARGS          :=$(filter-out $@,$(MAKECMDGOALS))
NETWORK       := proxynetwork
STACK         := proxy
PROXY         := $(STACK)_traefik
PROXYFULLNAME := $(PROXY).1.$$(docker service ps -f 'name=$(PROXY)' $(PROXY) -q --no-trunc | head -n1)

%:
	@:

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

package-lock.json: package.json
	npm install

node_modules: package-lock.json
	npm install

install: node_modules ## Installation application
	@make docker-create-network -i
	@make docker-deploy -i

contributors: ## Contributors
	@npm run contributors

contributors-add: ## add Contributors
	@npm run contributors add

contributors-check: ## check Contributors
	@npm run contributors check

contributors-generate: ## generate Contributors
	@npm run contributors generate

docker-create-network: ## Create network
	docker network create --driver=overlay $(NETWORK)

docker-deploy: ## deploy
	docker stack deploy -c docker-compose.yml $(STACK)

docker-image-pull: ## Get docker image
	docker image pull traefik:2.3.7

docker-logs: ## logs docker
	docker service logs -f --tail 100 --raw $(PROXYFULLNAME)

docker-ls: ## docker service
	@docker stack services $(STACK)

docker-stop: ## docker stop
	@docker stack rm $(STACK)

linter-readme: ## linter README.md
	@npm run linter-markdown README.md

git-commit: ## Commit data
	npm run commit

git-check: ## CHECK before
	@make contributors-check -i
	@git status
