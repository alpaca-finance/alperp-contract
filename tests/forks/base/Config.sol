// SPDX-License-Identifier: MIT
/**
 *   ∩~~~~∩
 *   ξ ･×･ ξ
 *   ξ　~　ξ
 *   ξ　　 ξ
 *   ξ　　 “~～~～〇
 *   ξ　　　　　　 ξ
 *   ξ ξ ξ~～~ξ ξ ξ
 * 　 ξ_ξξ_ξ　ξ_ξξ_ξ
 * Alpaca Fin Corporation
 */
pragma solidity 0.8.17;

contract Config {
  address internal constant ALPACA_BUSD_VAULT =
    0x7C9e73d4C71dae564d41F78d56439bB4ba87592f;
  address internal constant ALPACA_WBTC_VAULT =
    0x08FC9Ba2cAc74742177e0afC3dC8Aed6961c24e7;
  address internal constant ALPACA_BNB_VAULT =
    0xd7D069493685A581d27824Fc46EdA46B7EfC0063;

  address internal constant BUSD_TOKEN =
    0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
  address internal constant BTCB_TOKEN =
    0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
  address internal constant ETH_TOKEN =
    0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
  address internal constant USDT_TOKEN =
    0x55d398326f99059fF775485246999027B3197955;
  address internal constant USDC_TOKEN =
    0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
  address internal constant WBNB_TOKEN =
    0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  address internal constant ALPACA_TOKEN =
    0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F;

  address internal constant CHAINLINK_ORACLE =
    0x634902128543b25265da350e2d961C7ff540fC71;

  address internal constant BUSD_PHILANTROPHIST =
    0x8894E0a0c962CB723c1976a4421c95949bE2D4E3;
  address internal constant WBTC_PHILANTROPHIST =
    0xF977814e90dA44bFA03b6295A0616a897441aceC;
  address internal constant BNB_PHILANTROPHIST =
    0x0eD7e52944161450477ee417DE9Cd3a859b14fD0;

  address internal constant BUSD_CHAINLINK_ORACLE =
    0xcBb98864Ef56E9042e7d2efef76141f15731B82f;
  address internal constant WBTC_CHAINLINK_ORACLE =
    0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf;
  address internal constant BNB_CHAINLINK_ORACLE =
    0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;

  /// Pyth
  bytes32 internal constant BTCB_PYTH_PRICE_ID =
    0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43;
  bytes32 internal constant BNB_PYTH_PRICE_ID =
    0x2f95862b045670cd22bee3114c39763a4a08beeb663b145d283c31d7d1101c4f;
  bytes32 internal constant ETH_PYTH_PRICE_ID =
    0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
  bytes32 internal constant USDT_PYTH_PRICE_ID =
    0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b;
  bytes32 internal constant USDC_PYTH_PRICE_ID =
    0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a;

  /// Alperp
  address internal constant DEPLOYER =
    0xC44f82b07Ab3E691F826951a6E335E1bC1bB0B51;
  address internal constant PROXY_ADMIN =
    0x3dBcbbE5a361BF97D79538bCcED4dd03d04B9726;
  address internal constant POOL_DIAMOND_ADDRESS =
    0x18A15bF2Aa1E514dc660Cc4B08d05f9f6f0FdC4e;
  address internal constant POOL_ROUTER_04 =
    0x5E8466ed06f7Acaa78Ab21b0F5FEc6810afcC199;
  address internal constant ORDER_BOOK =
    0x366B1360d7D43aa6A8335E27696035f4EA66293f;
  address internal constant PARADEEN =
    0xBA61db6b2CFEbC1580BF692389e831B24bb0a5eF;
  address internal constant AP_ADDRESS =
    0x2Fb74F8E1e9EFaEEc31e57946e0C1bC6853ca4f1;
  address internal constant POOL_ORACLE =
    0x9fD00Faef95cc028bc343BaC1fC11E870635B974;
}
