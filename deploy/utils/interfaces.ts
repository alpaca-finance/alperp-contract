import { BigNumberish } from "ethers"

export interface Transaction {
  info: string
  chainId: number
  queuedAt: string
  executedAt: string
  executionTransaction: string
  target: string
  value: string
  signature: string
  paramTypes: Array<string>
  params: Array<any>
  eta: string
}

export type MultiSignProposeTransactionOptions = {
  nonce?: number
}

export interface MultiSigServiceInterface {
  getAddress(): string

  proposeTransaction(
    to: string,
    value: BigNumberish,
    data: string,
    opts?: MultiSignProposeTransactionOptions
  ): Promise<string>
}
