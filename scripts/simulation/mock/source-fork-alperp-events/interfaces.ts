import { HardhatRuntimeEnvironment } from "hardhat/types";

export interface Caller {
  address: string;
  balance: string;
}

export interface SimpleType {
  type: string;
}

export interface Soltype {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType;
}

export interface DecodedInput {
  soltype: Soltype;
  value: any;
}

export interface BalanceDiff {
  address: string;
  original: string;
  dirty: string;
  is_miner: boolean;
}

export interface NonceDiff {
  address: string;
  original: string;
  dirty: string;
}

export interface Soltype2 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
}

export type Original = Record<string, string>;
export type Dirty = Record<string, string>;

export interface Raw {
  address: string;
  key: string;
  original: string;
  dirty: string;
}

export interface StateDiff {
  soltype: Soltype2;
  original: Original;
  dirty: Dirty;
  raw: Raw[];
}

export interface SimpleType2 {
  type: string;
}

export interface Soltype3 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType2;
}

export interface Input {
  soltype: Soltype3;
  value: any;
}

export interface Raw2 {
  address: string;
  topics: string[];
  data: string;
}

export interface Log {
  name: string;
  anonymous: boolean;
  inputs: Input[];
  raw: Raw2;
}

export interface Caller2 {
  address: string;
  balance: string;
}

export interface Caller3 {
  address: string;
  balance: string;
}

export interface SimpleType3 {
  type: string;
}

export interface Soltype4 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType3;
}

export interface DecodedOutput {
  soltype: Soltype4;
  value: string;
}

export interface Caller4 {
  address: string;
  balance: string;
}

export interface SimpleType4 {
  type: string;
}

export interface Component2 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType4;
}

export interface SimpleType5 {
  type: string;
}

export interface Component {
  name: string;
  type: string;
  storage_location: string;
  components: Component2[];
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType5;
}

export interface SimpleType6 {
  type: string;
}

export interface Soltype5 {
  name: string;
  type: string;
  storage_location: string;
  components: Component[];
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType6;
}

export interface DecodedOutput2 {
  soltype: Soltype5;
  value: any;
}

export interface Caller5 {
  address: string;
  balance: string;
}

export interface SimpleType7 {
  type: string;
}

export interface Component4 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType7;
}

export interface SimpleType8 {
  type: string;
}

export interface Component3 {
  name: string;
  type: string;
  storage_location: string;
  components: Component4[];
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType8;
}

export interface SimpleType9 {
  type: string;
}

export interface Soltype6 {
  name: string;
  type: string;
  storage_location: string;
  components: Component3[];
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType9;
}

export interface DecodedOutput3 {
  soltype: Soltype6;
  value: string;
}

export interface Caller6 {
  address: string;
  balance: string;
}

export interface SimpleType10 {
  type: string;
}

export interface Soltype7 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType10;
}

export interface DecodedOutput4 {
  soltype: Soltype7;
  value: any;
}

export interface Caller7 {
  address: string;
  balance: string;
}

export interface SimpleType11 {
  type: string;
}

export interface Soltype8 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType11;
}

export interface DecodedInput2 {
  soltype: Soltype8;
  value: any;
}

export interface SimpleType12 {
  type: string;
}

export interface Soltype9 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType12;
}

export interface DecodedOutput5 {
  soltype: Soltype9;
  value: any;
}

export interface Call8 {
  hash: string;
  contract_name: string;
  function_pc: number;
  function_op: string;
  absolute_position: number;
  caller_pc: number;
  caller_op: string;
  caller_file_index: number;
  caller_line_number: number;
  caller_code_start: number;
  caller_code_length: number;
  call_type: string;
  from: string;
  from_balance: string;
  to: string;
  to_balance: string;
  value?: any;
  block_timestamp: string;
  gas: number;
  gas_used: number;
  refund_gas: number;
  input: string;
  output: string;
  decoded_output?: any;
  network_id: string;
  calls?: any;
}

export interface Call7 {
  hash: string;
  contract_name: string;
  function_pc: number;
  function_op: string;
  absolute_position: number;
  caller_pc: number;
  caller_op: string;
  caller_file_index: number;
  caller_line_number: number;
  caller_code_start: number;
  caller_code_length: number;
  call_type: string;
  from: string;
  from_balance: string;
  to: string;
  to_balance: string;
  value?: any;
  block_timestamp: string;
  gas: number;
  gas_used: number;
  refund_gas: number;
  input: string;
  output: string;
  decoded_output?: any;
  network_id: string;
  calls: Call8[];
}

export interface SimpleType13 {
  type: string;
}

export interface Soltype10 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType13;
}

export interface Input2 {
  soltype: Soltype10;
  value: string;
}

export interface Raw3 {
  address: string;
  topics?: any;
  data: string;
}

export interface FunctionEmit {
  name: string;
  anonymous: boolean;
  inputs: Input2[];
  raw: Raw3;
}

export interface Call6 {
  hash: string;
  contract_name: string;
  function_name: string;
  function_pc: number;
  function_op: string;
  function_file_index: number;
  function_code_start: number;
  function_line_number: number;
  function_code_length: number;
  absolute_position: number;
  caller_pc: number;
  caller_op: string;
  caller_file_index: number;
  caller_line_number: number;
  caller_code_start: number;
  caller_code_length: number;
  call_type: string;
  from: string;
  from_balance: string;
  to: string;
  to_balance: string;
  value?: any;
  caller: Caller7;
  block_timestamp: string;
  gas: number;
  gas_used: number;
  input: string;
  decoded_input: DecodedInput2[];
  output: string;
  decoded_output: DecodedOutput5[];
  network_id: string;
  calls: Call7[];
  function_emits: FunctionEmit[];
  refund_gas?: number;
}

export interface SimpleType14 {
  type: string;
}

export interface Soltype11 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType14;
}

export interface DecodedInput3 {
  soltype: Soltype11;
  value: any;
}

export interface Call5 {
  hash: string;
  contract_name: string;
  function_name: string;
  function_pc: number;
  function_op: string;
  function_file_index: number;
  function_code_start: number;
  function_line_number: number;
  function_code_length: number;
  absolute_position: number;
  caller_pc: number;
  caller_op: string;
  caller_file_index: number;
  caller_line_number: number;
  caller_code_start: number;
  caller_code_length: number;
  call_type: string;
  from: string;
  from_balance: string;
  to: string;
  to_balance: string;
  value: string;
  caller: Caller6;
  block_timestamp: string;
  gas: number;
  gas_used: number;
  refund_gas: number;
  input: string;
  output: string;
  decoded_output: DecodedOutput4[];
  network_id: string;
  calls: Call6[];
  decoded_input: DecodedInput3[];
}

export interface SimpleType15 {
  type: string;
}

export interface Soltype12 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType15;
}

export interface DecodedInput4 {
  soltype: Soltype12;
  value: string;
}

export interface SimpleType16 {
  type: string;
}

export interface Soltype13 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType16;
}

export interface FunctionVariable {
  soltype: Soltype13;
  value?: boolean;
}

export interface Call4 {
  hash: string;
  contract_name: string;
  function_name: string;
  function_pc: number;
  function_op: string;
  function_file_index: number;
  function_code_start: number;
  function_line_number: number;
  function_code_length: number;
  absolute_position: number;
  caller_pc: number;
  caller_op: string;
  caller_file_index: number;
  caller_line_number: number;
  caller_code_start: number;
  caller_code_length: number;
  call_type: string;
  from: string;
  from_balance: string;
  to: string;
  to_balance: string;
  value?: any;
  caller: Caller5;
  block_timestamp: string;
  gas: number;
  gas_used: number;
  refund_gas: number;
  input: string;
  output: string;
  decoded_output: DecodedOutput3[];
  network_id: string;
  calls: Call5[];
  decoded_input: DecodedInput4[];
  function_variables: FunctionVariable[];
}

export interface SimpleType17 {
  type: string;
}

export interface Component6 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType17;
}

export interface SimpleType18 {
  type: string;
}

export interface Component5 {
  name: string;
  type: string;
  storage_location: string;
  components: Component6[];
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType18;
}

export interface SimpleType19 {
  type: string;
}

export interface Soltype14 {
  name: string;
  type: string;
  storage_location: string;
  components: Component5[];
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType19;
}

export interface FunctionVariable2 {
  soltype: Soltype14;
  value: string;
}

export interface SimpleType20 {
  type: string;
}

export interface Soltype15 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType20;
}

export interface DecodedInput5 {
  soltype: Soltype15;
  value: any;
}

export interface Call3 {
  hash: string;
  contract_name: string;
  function_name: string;
  function_pc: number;
  function_op: string;
  function_file_index: number;
  function_code_start: number;
  function_line_number: number;
  function_code_length: number;
  absolute_position: number;
  caller_pc: number;
  caller_op: string;
  caller_file_index: number;
  caller_line_number: number;
  caller_code_start: number;
  caller_code_length: number;
  call_type: string;
  from: string;
  from_balance: string;
  to: string;
  to_balance: string;
  value: string;
  caller: Caller4;
  block_timestamp: string;
  gas: number;
  gas_used: number;
  input: string;
  output: string;
  decoded_output: DecodedOutput2[];
  network_id: string;
  calls: Call4[];
  function_variables: FunctionVariable2[];
  decoded_input: DecodedInput5[];
  refund_gas?: number;
}

export interface SimpleType21 {
  type: string;
}

export interface Soltype16 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType21;
}

export interface DecodedInput6 {
  soltype: Soltype16;
  value: any;
}

export interface SimpleType22 {
  type: string;
}

export interface Soltype17 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType22;
}

export interface FunctionVariable3 {
  soltype: Soltype17;
  value: string;
}

export interface Call2 {
  hash: string;
  contract_name: string;
  function_name: string;
  function_pc: number;
  function_op: string;
  function_file_index: number;
  function_code_start: number;
  function_line_number: number;
  function_code_length: number;
  absolute_position: number;
  caller_pc: number;
  caller_op: string;
  caller_file_index: number;
  caller_line_number: number;
  caller_code_start: number;
  caller_code_length: number;
  call_type: string;
  from: string;
  from_balance: string;
  to: string;
  to_balance: string;
  value?: any;
  caller: Caller3;
  block_timestamp: string;
  gas: number;
  gas_used: number;
  refund_gas: number;
  input: string;
  output: string;
  decoded_output: DecodedOutput[];
  network_id: string;
  calls: Call3[];
  decoded_input: DecodedInput6[];
  function_variables: FunctionVariable3[];
}

export interface SimpleType23 {
  type: string;
}

export interface Soltype18 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType23;
}

export interface DecodedInput7 {
  soltype: Soltype18;
  value: string;
}

export interface Call {
  hash: string;
  contract_name: string;
  function_name: string;
  function_pc: number;
  function_op: string;
  function_file_index: number;
  function_code_start: number;
  function_line_number: number;
  function_code_length: number;
  absolute_position: number;
  caller_pc: number;
  caller_op: string;
  caller_file_index: number;
  caller_line_number: number;
  caller_code_start: number;
  caller_code_length: number;
  call_type: string;
  from: string;
  from_balance: string;
  to: string;
  to_balance: string;
  value: string;
  caller: Caller2;
  block_timestamp: string;
  gas: number;
  gas_used: number;
  refund_gas: number;
  input: string;
  output: string;
  decoded_output: any[];
  network_id: string;
  calls: Call2[];
  decoded_input: DecodedInput7[];
}

export interface CallTrace {
  hash: string;
  contract_name: string;
  function_name: string;
  function_pc: number;
  function_op: string;
  function_file_index: number;
  function_code_start: number;
  function_line_number: number;
  function_code_length: number;
  absolute_position: number;
  caller_pc: number;
  caller_op: string;
  call_type: string;
  from: string;
  from_balance: string;
  to: string;
  to_balance: string;
  value: string;
  caller: Caller;
  block_timestamp: string;
  gas: number;
  gas_used: number;
  intrinsic_gas: number;
  refund_gas: number;
  input: string;
  decoded_input: DecodedInput[];
  balance_diff: BalanceDiff[];
  nonce_diff: NonceDiff[];
  state_diff: StateDiff[];
  logs: Log[];
  output: string;
  decoded_output?: any;
  network_id: string;
  calls: Call[];
}

export interface SimpleType24 {
  type: string;
}

export interface Soltype19 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType24;
}

export interface Input3 {
  soltype: Soltype19;
  value: any;
}

export interface Raw4 {
  address: string;
  topics: string[];
  data: string;
}

export interface Log2 {
  name: string;
  anonymous: boolean;
  inputs: Input3[];
  raw: Raw4;
}

export interface BalanceDiff2 {
  address: string;
  original: string;
  dirty: string;
  is_miner: boolean;
}

export interface NonceDiff2 {
  address: string;
  original: string;
  dirty: string;
}

export interface Soltype20 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
}

export type Original2 = Record<string, string>;

export type Dirty2 = Record<string, string>;

export interface Raw5 {
  address: string;
  key: string;
  original: string;
  dirty: string;
}

export interface StateDiff2 {
  soltype: Soltype20;
  original: Original2;
  dirty: Dirty2;
  raw: Raw5[];
}

export interface TransactionInfo {
  contract_id: string;
  block_number: number;
  transaction_id: string;
  contract_address: string;
  method: string;
  parameters?: any;
  intrinsic_gas: number;
  refund_gas: number;
  call_trace: CallTrace;
  stack_trace?: any;
  logs: Log2[] | null;
  balance_diff: BalanceDiff2[];
  nonce_diff: NonceDiff2[];
  state_diff: StateDiff2[];
  raw_state_diff?: any;
  console_logs?: any;
  created_at: string;
}

export interface Transaction {
  hash: string;
  block_hash: string;
  block_number: number;
  from: string;
  gas: number;
  gas_price: number;
  gas_fee_cap: number;
  gas_tip_cap: number;
  cumulative_gas_used: number;
  gas_used: number;
  effective_gas_price: number;
  input: string;
  nonce: number;
  to: string;
  index: number;
  value: string;
  access_list?: any;
  status: boolean;
  addresses: string[];
  contract_ids: string[];
  network_id: string;
  timestamp: string;
  function_selector: string;
  transaction_info: TransactionInfo;
  method: string;
  decoded_input?: any;
  call_trace?: any;
}

export interface Data {
  nonce: number;
  balance: string;
}

export type Storage = Record<string, string>;

export interface StateObject {
  address: string;
  data: Data;
  storage: Storage;
}

export interface Log3 {
  logIndex: string;
  address: string;
  topics: string[];
  data: string;
  blockHash: string;
  blockNumber: string;
  removed: boolean;
  transactionHash: string;
  transactionIndex: string;
}

export interface Receipt {
  transactionHash: string;
  transactionIndex: string;
  blockHash: string;
  blockNumber: string;
  from: string;
  to: string;
  cumulativeGasUsed: string;
  gasUsed: string;
  effectiveGasPrice: string;
  contractAddress?: any;
  logs: Log3[];
  logsBloom: string;
  status: string;
  type: string;
}

export interface BlockHeader {
  number: string;
  hash: string;
  stateRoot: string;
  parentHash: string;
  sha3Uncles: string;
  transactionsRoot: string;
  receiptsRoot: string;
  logsBloom: string;
  timestamp: string;
  difficulty: string;
  gasLimit: string;
  gasUsed: string;
  miner: string;
  extraData: string;
  mixHash: string;
  nonce: string;
  baseFeePerGas: string;
  size: string;
  totalDifficulty: string;
  uncles?: any;
  transactions?: any;
}

export interface Simulation {
  id: string;
  project_id: string;
  fork_id: string;
  alias: string;
  description: string;
  internal: boolean;
  hash: string;
  state_objects: StateObject[];
  network_id: string;
  block_number: number;
  transaction_index: number;
  from: string;
  to: string;
  input: string;
  gas: number;
  queue_origin: string;
  gas_price: string;
  value: string;
  method: string;
  status: boolean;
  fork_height: number;
  block_hash: string;
  nonce: number;
  receipt: Receipt;
  access_list?: any;
  block_header: BlockHeader;
  parent_id: string;
  created_at: string;
  timestamp: string;
  branch_root: boolean;
}

export interface ContractInfo {
  id: number;
  path: string;
  name: string;
  source: string;
}

export interface SimpleType25 {
  type: string;
}

export interface Component7 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType25;
}

export interface NestedType {
  type: string;
}

export interface SimpleType26 {
  type: string;
  nested_type: NestedType;
}

export interface Input4 {
  name: string;
  type: string;
  storage_location: string;
  components: Component7[];
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType26;
}

export interface SimpleType27 {
  type: string;
}

export interface Component8 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType27;
}

export interface NestedType2 {
  type: string;
}

export interface SimpleType28 {
  type: string;
  nested_type: NestedType2;
}

export interface Output {
  name: string;
  type: string;
  storage_location: string;
  components: Component8[];
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType28;
}

export interface Abi {
  type: string;
  name: string;
  constant: boolean;
  anonymous: boolean;
  stateMutability: string;
  inputs: Input4[];
  outputs: Output[];
}

export interface SimpleType29 {
  type: string;
}

export interface Component9 {
  name: string;
  type: string;
  storage_location: string;
  components?: any;
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType29;
}

export interface NestedType3 {
  type: string;
}

export interface SimpleType30 {
  type: string;
  nested_type: NestedType3;
}

export interface State {
  name: string;
  type: string;
  storage_location: string;
  components: Component9[];
  offset: number;
  index: string;
  indexed: boolean;
  simple_type: SimpleType30;
}

export interface Data2 {
  main_contract: number;
  contract_info: ContractInfo[];
  abi: Abi[];
  raw_abi?: any;
  states: State[];
}

export interface Contract {
  id: string;
  contract_id: string;
  balance: string;
  network_id: string;
  public: boolean;
  export: boolean;
  verified_by: string;
  verification_date?: any;
  address: string;
  contract_name: string;
  ens_domain?: any;
  type: string;
  evm_version: string;
  compiler_version: string;
  optimizations_used: boolean;
  optimization_runs: number;
  libraries?: any;
  data: Data2;
  creation_block: number;
  creation_tx: string;
  creator_address: string;
  created_at: string;
  number_of_watches?: any;
  language: string;
  in_project: boolean;
  number_of_files: number;
}

export interface IRootObject {
  transaction: Transaction;
  simulation: Simulation;
  contracts: Contract[];
}

export interface IPosition {
  id: string;
  positionId: string;
  primaryAccount: string;
  subAccountId: string;
  collateralToken: string;
  indexToken: string;
  exposure: string;

  size: string;
  collateral: string;
  averagePrice: string;
  entryBorrowingRate: string;
  entryFundingRate: string;
  reserveAmount: string;
  realizedPnl: string;
  price: string;

  fundingFeeDebt: string;
  openInterest: string;

  createdAt: string;
  updatedAt: string;
  closedAt?: string | null;
  liquidatedAt?: string | null;
}

export interface IPositionLog {
  id: string;
  tx: string;
  logIndex: string;

  positionId: string;
  primaryAccount: string;
  subAccountId: string;
  collateralToken: string;
  indexToken: string;
  collateralDeltaUsd: string;
  sizeDelta: string;
  exposure: string;
  realizedPnl: string;
  price: string;
  feeUsd: string;

  eventName: string;
  createdAt: string;
}

export interface IStatistic {
  id: string;
  totalTradingVolume: string;
  totalFees: string;
  openInterest: string;
  accVolume7Days: string;
  accVolume30Days: string;
  avgVolume7Days: string;
  avgVolume30Days: string;
}

export interface ILongShortLog {
  id: string;
  indexToken: string;
  sizeDelta: string;
  isLong: boolean;
  triggerPrice: string;
  triggerAboveThreshold: boolean;
  markPrice: string;
}

export interface ISwapLog {
  id: string;
  path: Array<string>;
  amountIn: string;
  amountOut: string;
  triggerPrice: string;
  triggerAboveThreshold: boolean;
}

export enum TypeLog {
  LongShort = "LongShort",
  Swap = "Swap",
}

export enum Action {
  CreateIncreaseOrder = "CreateIncreaseOrder",
  ExecuteIncreaseOrder = "ExecuteIncreaseOrder",
  UpdateIncreaseOrder = "UpdateIncreaseOrder",
  CancelIncreaseOrder = "CancelIncreaseOrder",

  CreateDecreaseOrder = "CreateDecreaseOrder",
  ExecuteDecreaseOrder = "ExecuteDecreaseOrder",
  UpdateDecreaseOrder = "UpdateDecreaseOrder",
  CancelDecreaseOrder = "CancelDecreaseOrder",

  CreateSwapOrder = "CreateSwapOrder",
  ExecuteSwapOrder = "ExecuteSwapOrder",
  UpdateSwapOrder = "UpdateSwapOrder",
  CancelSwapOrder = "CancelSwapOrder",

  Swap = "Swap",

  Liquidation = "Liquidation",
}

export enum EventSource {
  LiquidityFacet = "LiquidityFacet",
  PerpTradeFacet = "PerpTradeFacet",
  Orderbook = "Orderbook",
  MarketOrderRouter = "MarketOrderRouter",
}

export interface IPerpLog {
  id: string;
  tx: string;
  type: TypeLog;
  action: Action;
  eventSource: EventSource;

  account: string;
  subAccount: string;

  createdAt: string;

  longShortLog?: ILongShortLog;
  swapLog?: ISwapLog;
}

export interface IDayData {
  id: string;
  date: string;
  volumeUSD: string;
  feeUSD: string;
}

export enum OrderStatus {
  Open = "open",
  Cancelled = "cancelled",
  Executed = "executed",
}

export interface IIncreaseOrder {
  id: string;
  eventSource: EventSource;
  purchaseToken: string;
  purchaseTokenAmount: string;
  collateralToken: string;
  indexToken: string;
  sizeDelta: string;
  isLong: boolean;
}

export interface IDecreaseOrder {
  id: string;
  eventSource: EventSource;
  collateralToken: string;
  collateralDelta: string;
  indexToken: string;
  sizeDelta: string;
  isLong: boolean;
}

export interface ISwapOrder {
  id: string;
  eventSource: EventSource;
  path: Array<string>;
  amountIn: string;
  minOut: string;
}

export interface IOrder {
  id: string;

  type: string;
  eventSource: EventSource;

  account: string;
  subAccount: string;
  status: OrderStatus;
  index: string;

  triggerPrice?: string;
  triggerAboveThreshold?: boolean;

  createdTimestamp: string;
  cancelledTimestamp?: string;
  executedTimestamp?: string;

  increaseOrder: IIncreaseOrder | null;
  decreaseOrder: IDecreaseOrder | null;
  swapOrder: ISwapOrder | null;
}

export interface QueryResponse<T> {
  data: {
    [key: string]: T;
  };
}

export enum Exposure {
  Long = "LONG",
  Short = "SHORT",
}

export enum PositionLogEvents {
  IncreasePosition = "INCREASE_POSITION",
  DecreasePosition = "DECREASE_POSITION",
  LiquidatePosition = "LIQUIDATE_POSITION",
}

export type IPositionLogEventsKey = "IncreasePosition" | "DecreasePosition";

export type IPositionEventsKey = "UpdatePosition" | "ClosePosition";

export type IStatisticEventsKey =
  | "IncreasePosition"
  | "DecreasePosition"
  | "Swap"
  | "CollectBorrowingFee"
  | "CollectPositionFee"
  | "CollectSwapFee";

export type IOrderBookEventsKey =
  | "CreateIncreaseOrder"
  | "CancelIncreaseOrder"
  | "ExecuteIncreaseOrder"
  | "UpdateIncreaseOrder"
  | "CreateDecreaseOrder"
  | "CancelDecreaseOrder"
  | "ExecuteDecreaseOrder"
  | "UpdateDecreaseOrder"
  | "CreateSwapOrder"
  | "CancelSwapOrder"
  | "ExecuteSwapOrder"
  | "UpdateSwapOrder";

export type IMarketOrderRouterEventsKey =
  | "CreateIncreasePosition"
  | "CancelIncreasePosition"
  | "ExecuteIncreasePosition"
  | "CreateDecreasePosition"
  | "CancelDecreasePosition"
  | "ExecuteDecreasePosition"
  | "CreateSwapOrder"
  | "CancelSwapOrder"
  | "ExecuteSwapOrder";

export type IHandler = (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
) => Promise<void>;

export type IUnionPerpTradeEvents =
  | IPositionLogEventsKey
  | IPositionEventsKey
  | IStatisticEventsKey;

export type IOrderBookEvents = IOrderBookEventsKey;

export type IMarketOrderRouterEvents = IMarketOrderRouterEventsKey;

export type IPerpTradeEventHandlers = Record<IUnionPerpTradeEvents, IHandler>;

export type IOrderBookEventHandlers = Record<IOrderBookEvents, IHandler>;

export type IMarketOrderRouterEventHandlers = Record<
  IMarketOrderRouterEvents,
  IHandler
>;

export interface ISimulationRecord {
  "Simulation ID": string;
  Function: string;
  Block: string;
  Timestamp: string;
  "Last Synced": string;
  NOTE: "" | "IGNORED";
}

export interface IOutputJSONFile {
  filename: string;
  queryResponseKey: string;
}

// NOTE: there are a lot of field
// but we will only define only use one
export interface ITenderlySimulationList {
  id: string;
  created_at: string;
  parent_id: string;
}
