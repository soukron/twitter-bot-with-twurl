.PHONY: help
.DEFAULT_GOAL := help

help: ## Shows this message.
	@echo -e "Makefile for Viktortrasto Bot.\n\nCommands reference:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo

build: ## Builds viktortrasto/twurl:latest image with ruby and twurl gem.
	docker build -t viktortrasto/twurl:latest .

run: ## Runs the bot in a ruby container container.
	@docker inspect viktortrasto/twurl:latest >/dev/null 2>&1 || (echo "Image not found. Run \"make build\" first."; exit 1)
	docker run --rm -v \
	       $(dir $(realpath $(firstword $(MAKEFILE_LIST)))):/opt/bot \
	       viktortrasto/twurl:latest \
	       /bin/bash -c "cd /opt/bot && make run-bot" | tee -a bot.log

run-bot: ## Runs the bot code directly (requires ruby and twurl gem installed).
	@./bot.sh
