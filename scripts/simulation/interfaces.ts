export interface IConfig {
  Tokens: {
    ALPACA: string;
    ALP: string;
    WBNB: string;
    ETH: string;
    BTCB: string;
    DAI: string;
    USDC: string;
    USDT: string;
    BUSD: string;
  };
  PoolRouter: string;
  WNativeRelayer: string;
  ThirdParty: {
    Oracle: {
      Pyth: {
        address: string;
        priceIDs: Record<string, string>;
      };
    };
  };
  Pools: {
    ALP: {
      poolDiamond: string;
      fastPriceFeed: string;
      oracle: string;
      orderbook: string;
      marketOrderRouter: string;
      facets: {
        admin: string;
        accessControl: string;
        farm: string;
        diamondCut: string;
        diamondLoupe: string;
        liquidity: string;
        fundingRate: string;
        getter: string;
        ownership: string;
        perpTrade: string;
        diamondInitializer: string;
        poolConfigInitializer: string;
        accessControlInitializer: string;
      };
    };
  };
  TimelockController: string;
}

export interface IS3Service {
  upload<T>(content: T, bucketName: string, fileName: string): Promise<any>;
}
