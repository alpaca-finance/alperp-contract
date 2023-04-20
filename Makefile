-include .env

test-unit:
	@echo "Running unit tests"
	@forge test --watch -vvv --no-match-contract \ForkTest\

test-fork:
	@echo "Running fork tests"
	@forge test --watch -vvv --match-contract \ForkTest\

.PHONY: config
config:
	forge config

node_modules:
	@yarn