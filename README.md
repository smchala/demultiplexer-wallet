Brouillion
# demultiplexer-wallet
one (wallet) to many (wallets) transfer capability smart contract, on Starknet L2

<img src="demultiplexer_app/resources/demultiplexer.png" width="400">


## Goal:
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

Example
```{
   "configuration":{
      "send_amount":3,
      "send_type":"coin",
      "recurring":{
         "value":0,
         "period":0
      },
      "equal_weights":1,
      "multisig":0,
      "cancel":{
         "is_manual":1,
         "expiry_date":1234567
      },
      "recipients":[
         {
            "address":"0x",
            "weight":1,
            "delay":0
         },
         {
            "address":"0x",
            "weight":1,
            "delay":0
         },
         {
            "address":"0x",
            "weight":1,
            "delay":0
         }
      ]
   }
}
```



## 1st steps

- Learn Cairo, tut
- Env
- 1st steps for poc
- Create wallet that user can input all config
- Check for funds are enough to cover what the user chose to send
- Validate all configs, weights….
- Store all into the contract
- Create logic to handle splitting the funds
- Look at integrating **yogi** for one off shot task in the future
- Check how to sign for future transfers
- Do we use a placeholder for the funds, how to lock the funds?
- Cancellation? God mode: define the boundaries
- Obviously test the shit out of ^^

Then we should be in business,


## Need to check EIP-4626: Tokenized Vault Standard 


### Playing with POC:

- Set total amount to send
- Set addresses to send to
- Add weight for each wallet (equal for each or not)
- One off shot/ recurring
- Date to send it
- Expiry date


