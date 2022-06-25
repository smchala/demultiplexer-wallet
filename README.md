Brouillion
# demultiplexer-wallet
one (wallet) to many (wallets) transfer capability smart contract, on Starknet L2

<img src="demultiplexer_app/resources/demultiplexer.png" width="400">

# What is demux
Demux app is a Starknet smart contract that will allow the automation of transactions

A user will be able to:

- Send funds to multiple wallets

And/or

- Send funds at a specific date in the future

And/or

- Send funds to multiple users at multiple dates (recurring transactions)

## Potential use cases:

Demux should be the heart of the follwing dapps, other components should/will be added

- For individuals: Saving accounts (automatic), Birthday present (money, messages, videos, nft), pay bills or subscriptions, Wills (hooked up to legal entities e.g. decentralised solicitors?)...
- For Friends/family/daos: Pocket money kids, help, contributing to projects, lottery(random number generato)...
- For companies: Payroll, pay taxes, supply chain, discounts...



Thanks to account abstractions in Starknet we can sign multiple calls at once for great user experience (does not apply to recurring transactions, still thinking about it!)

#### Caveats:

A transaction will be cancelled if there are not enough funds

Only the deployer can set it up, no operation can be done by another address (except for Yagi, which we should check when executing their invocation)

# Flow of demux dapp

- Set demux configuration
- Set recipients
- Check all is set, configuration, recipients, enough funds
- Sign all transactions
- Create the transactions (ordered by transaction_delay) and store them
- Set Yagi (send demux address)
- Just wait for Yagi to call probe task
- When true (check recipients transaction_delay against block_time)
- Execute Task is invoked 
- Check there are enough funds for the first transaction
- Check signature for the first transaction
- Act on the first transaction
- Remove the first transaction from the lists of transactions and checks
- Yagi continue probing task but now for the next transaction that should be first in the list…

Assumption if the check for funds fails the current transaction is removed from the list of transactions list


#### Outstanding: 

Need to create a web interface to use argentX sdk to be able to sign multiple transactions

#### Note:

Demux is still a draft
Some tests are present for demux, but this is more as a learning exercise than production grade tests.
Still have to learn how to mock the syscalls.get_caller_address to test assert_owner in Yagi router!



#### Configuration: 

##### weights: 
- a weight/percentage to each receiving wallet (the weights/percentage sum should be less than 1/100% for all transactions, tbd: maybe not necessarily including securing transactions)
#### recipients: 
- wallets addresses if known to start with, then possibly support creating of wallets dynamically 
- weight for each address, how much of the total amout will be allocated to this address
#### multisig: 
- once the user created a new Demux-wallet with pending transactions, we need a way to unlock the funds in case we want to cancel or retrieve the funds if the user is not available anymore to avoid permanent loss we might need a secondary wallet address to divert the funds to
#### Events are defined by two properties
- eventType: at the moment there are two type of events, one shot or recurring
- enventSchedule: instant or delayed
#### Cancel: 
- Event? Nuke the transaction, voluntary from the user, only for delayed transaction
- ExpiryDate



## 1st steps

- Learn Cairo, tut
- Env
- 1st steps for poc
- Create wallet that user can input all config x
- Check for funds are enough to cover what the user chose to send
- Validate all configs, weights….
- Store all into the contract
- Create logic to handle splitting the funds
- Look at integrating **yogi** for one off shot task in the future (*** I m around here ***)
- Check how to sign for future transfers
- Do we use a placeholder for the funds, how to lock the funds?
- Cancellation? God mode: define the boundaries
- Obviously test the shit out of ^^

Then we should be in business,

