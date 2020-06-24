###############
# BOILERPLATE # 
###############
# Import config.
# You can change the default config with `make CONFIG="config_special.env" build`
CONFIG ?= default.env
include config/$(CONFIG)
export $(shell sed 's/=.*//' config/$(CONFIG))

.PHONY: help
.DEFAULT_GOAL := help

########
# HELP #
########
help: ## Shows this message.
	@echo -e "Makefile helper for ${NAME} ${IMAGE_VERSION}.\n\nCommands reference:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo
version: ## Output the current version.
	@echo $(IMAGE_VERSION)

################
# DOCKER TASKS #
################
# Build the container
build-base: ## Builds the base container image.
	docker build -t $(REGISTRY_NAMESPACE)/$(IMAGE_NAME):$(IMAGE_VERSION) dockerfiles/$(IMAGE_NAME)/.

build-bot: ## Builds the container image including the bot.sh code
	cp -f src/bot.sh dockerfiles/$(IMAGE_NAME)-bot/
	docker build -t $(REGISTRY_NAMESPACE)/$(IMAGE_NAME)-bot:$(IMAGE_VERSION) dockerfiles/$(IMAGE_NAME)-bot/.

# Tag the containers
tag-base: tag-latest-base tag-version-base ## Generate base container tags for this version and latest tags.
tag-version-base: ## Generate base container version tag only.
	docker tag $(REGISTRY_NAMESPACE)/$(IMAGE_NAME):$(IMAGE_VERSION) $(REGISTRY_HOSTNAME)/$(REGISTRY_NAMESPACE)/$(IMAGE_NAME):$(IMAGE_VERSION)
tag-latest-base: ## Generate base container latest tag only.
	docker tag $(REGISTRY_NAMESPACE)/$(IMAGE_NAME):$(IMAGE_VERSION) $(REGISTRY_HOSTNAME)/$(REGISTRY_NAMESPACE)/$(IMAGE_NAME):latest
tag-bot: tag-latest-bot tag-version-bot ## Generate bot container tags for this version and latest tags.
tag-version-bot: ## Generate bot container version tag only.
	docker tag $(REGISTRY_NAMESPACE)/$(IMAGE_NAME)-bot:$(IMAGE_VERSION) $(REGISTRY_HOSTNAME)/$(REGISTRY_NAMESPACE)/$(IMAGE_NAME)-bot:$(IMAGE_VERSION)
tag-latest-bot: ## Generate bot container latest tag only.
	docker tag $(REGISTRY_NAMESPACE)/$(IMAGE_NAME)-bot:$(IMAGE_VERSION) $(REGISTRY_HOSTNAME)/$(REGISTRY_NAMESPACE)/$(IMAGE_NAME)-bot:latest

# Publish the container
publish-base: publish-latest-base publish-version-base ## Publish the base image to the remote registry.
publish-version-base: ## Publish base containers with version tag only.
	docker push $(REGISTRY_HOSTNAME)/$(REGISTRY_NAMESPACE)/$(IMAGE_NAME):$(IMAGE_VERSION)
publish-latest-base: ## Publish base containers with latest tag only.
	docker push $(REGISTRY_HOSTNAME)/$(REGISTRY_NAMESPACE)/$(IMAGE_NAME):latest
publish-bot: publish-latest-bot publish-version-bot ## Publish the bot image to the remote registry.
publish-version-bot: ## Publish bot containers with version tag only.
	docker push $(REGISTRY_HOSTNAME)/$(REGISTRY_NAMESPACE)/$(IMAGE_NAME)-bot:$(IMAGE_VERSION)
publish-latest-bot: ## Publish bot containers with latest tag only.
	docker push $(REGISTRY_HOSTNAME)/$(REGISTRY_NAMESPACE)/$(IMAGE_NAME)-bot:latest

#############
# EXECUTION #
#############
run: ## Runs the bot in a ruby container container.
	@echo Using config file: config/$(CONFIG)
	@docker run --rm -v $(dir $(realpath $(firstword $(MAKEFILE_LIST)))):/opt/bot \
	       $(REGISTRY_HOSTNAME)/$(REGISTRY_NAMESPACE)/$(IMAGE_NAME):latest \
	       /bin/bash -c "cd /opt/bot && make CONFIG=$(CONFIG) run-bot" | tee -a src/bot.log
run-local: ## Runs the bot in a ruby container container using the local image.
	@echo Using config file: config/$(CONFIG)
	@docker inspect $(REGISTRY_NAMESPACE)/$(IMAGE_NAME):$(IMAGE_VERSION) >/dev/null 2>&1 || (echo "Image not found. Run \"make build\" first."; exit 1)
	@docker run --rm -v $(dir $(realpath $(firstword $(MAKEFILE_LIST)))):/opt/bot \
	       $(REGISTRY_NAMESPACE)/$(IMAGE_NAME):$(IMAGE_VERSION) \
	       /bin/bash -c "cd /opt/bot && make CONFIG=$(CONFIG) run-bot" | tee -a src/bot.log
run-bot: ## Runs the bot code directly (requires ruby and twurl gem installed).
	@./src/bot.sh
