import axios from "axios";
import { BigNumber } from "ethers";
import { parseEther } from "ethers/lib/utils";

export async function getCoinGeckoPriceUSD(
  assetId: string
): Promise<BigNumber> {
  let tokenPrice = BigNumber.from(0);
  try {
    const response = await axios.get(
      `https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=${assetId}`
    );
    tokenPrice = parseEther(response.data[0]["current_price"].toString());
  } catch (error) {
    throw new Error(`Error fetching price for ${assetId}: ${error}`);
  }

  return tokenPrice;
}
