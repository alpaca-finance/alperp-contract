-include .env

test-unit:
	@echo "Running unit tests"
	@forge test --watch -vvv --no-match-contract \ForkTest\

test-fork:
	@echo "Running fork tests on ${ARCHIVE_NODE_RPC} at block ${FORK_BLOCK}"
	@forge test --watch -vvv --fork-url ${ARCHIVE_NODE_RPC} --fork-block-number ${FORK_BLOCK} --match-contract \ForkTest\

.PHONY: config
config:
	forge config

node_modules:
	@yarn