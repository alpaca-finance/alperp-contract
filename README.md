# Alperp Contract

**Perpetual DEX breed from the magical farm**

## Local Development

The following assumes the use of `node@>=14`.

### Install Dependencies

1.  Copy `.env.example` file and change its name to `.env` in the project folder
2.  Run `yarn` to install all dependencies

### Install Forge

```
$ curl -L https://foundry.paradigm.xyz | bash # install foundryup
$ foundryup # install forge and cast
```

### Compile Contracts

`yarn compile`

Note: There will be a new folder called `typechain` generated in your project workspace. You will need to navigate to `typechain/index.ts` and delete duplicated lines inside this file in order to proceed.

### Run Tests with Foundry

```
# unit tests
$ yarn test:unit
# integration tests
$ yarn test:integration
```

## Licensing

The primary license for Alpaca Protocol is the MIT License, see [MIT LICENSE](https://github.com/alpaca-finance/bsc-alpaca-contract/blob/main/LICENSE).
