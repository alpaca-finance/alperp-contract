-include .env

export FOUNDRY_TEST=src/tests/integrations
export FOUNDRY_ETH_RPC_URL=${ARCHIVE_NODE_RPC}
export FOUNDRY_FORK_BLOCK_NUMBER=22558708


test-integration: node_modules
	@forge test -vvv --ffi -c src/tests/integrations

.PHONY: config
config:
	forge config

node_modules:
	@yarn