.PHONY: help
.DEFAULT_GOAL := help

help: ## Shows this message.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Builds viktortrasto/twurl:latest image
	docker build -t viktortrasto/twurl:latest .

run: ## Runs the bot in a container
	docker run --rm -v \
	       $(dir $(realpath $(firstword $(MAKEFILE_LIST)))):/opt/bot \
	       viktortrasto/twurl:latest \
	       /bin/bash -c "cd /opt/bot && make run-bot" | tee -a bot.log

run-bot: ## Runs the bot code
	@./bot.sh
