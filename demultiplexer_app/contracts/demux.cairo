%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict import dict_write, dict_update, dict_new, dict_read
from starkware.cairo.common.dict_access import DictAccess

from starkware.starknet.common.syscalls import (
    call_contract,
    get_caller_address,
    get_tx_info,
    get_contract_address,
    get_block_timestamp,
)
from libs.starknetarraymanipulation.contracts.array_manipulation import reverse
from starkware.cairo.common.alloc import alloc

from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_le, uint256_check
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    sign,
    signed_div_rem,
    unsigned_div_rem,
)
from starkware.cairo.common.math_cmp import is_le, is_le_felt

const YAGI_ROUTER_GOERLI_ADDRESS = 0x0221b6a7865025ca17a24eb7ab1c9423fffe8a92c61311e6b2e420239606cd6d
const MYARGENTX_ADDRESS = 0x0438b49f89fbd98dc2efedbff1a3e85c2798e22ae66e5d6ed8dcbb0a0f6a6bf6
const RECIPIENT_ADDRESS = 0x00b68ad3d5a97de6a013d5b22f70f1b39de67f182afd6f84936bb1b325d046b1
const RECIPIENT_ADDRESS_CHROME = 0x0462369e50f87dfe5cb354fe1c7d4d8f2315d3b6256e576e570edc54ca50b3c8
const ETH_L2_ADDRESS = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
# use utils/util.py to get the function hash
const BALANCE_OF_HASH = 0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e
const INCREASE_BALANCE_HASH = 0x362398bec32bc0ebb411203221a35a0301193a96f317ebe5e40be9f60d15320
const READY_STATE = 1
const PENDING_STATE = 2
const READY_FOR_EXECUTION_STATE = 3
const COMPLETED_STATE = 4
const FAILED_STATE = 5
const CANCELLED_STATE = 6
const EXPIRED_STATE = 7

# Configuration struct
struct Configuration:
    member send_amount : felt
    member send_type : felt
    member equal_weights : felt
    member multi_sig : felt
    member expiry_date : felt
end

# address -> name.eth would be a cool user experience
# Recipient struct
struct Recipient:
    member wallet_name : felt
    member email : felt
    member address : felt
    member weight : felt
    member recuring_period : felt
    member transaction_delay : felt
    member ready_to_send : felt
end

# Transaction state
#
# initialised -> 0
# ready -> 1
# pending -> 2
# completed -> 3
# failed -> 4
# cancelled -> 5
# expired -> 6
# Ready: once we have all recipients set and signaures done then we can set it to 1
# Pending: whe we start getting yagi probe task calls we are in a pending state
# Completed: when yagi invoke execute task we can mark a transaction completed
struct TransactionState:
    member address : felt
    member state : felt
end

@storage_var
func recipients_number() -> (index : felt):
end
@storage_var
func transactions_number() -> (index : felt):
end

@storage_var
func recipients(wallet_number : felt) -> (recipients : Recipient):
end

@storage_var
func recipients_transactions_delay(index : felt) -> (delay : felt):
end

@storage_var
func is_tx_ready(index : felt) -> (is_ready : felt):
end

@storage_var
func configuration() -> (configuration : Configuration):
end

@storage_var
func owner() -> (owner_address : felt):
end

@storage_var
func temp_recipients_index() -> (index : felt):
end

@storage_var
func current_recipient_index_to_check_transaction_delay() -> (index : felt):
end
@storage_var
func current_recipient() -> (recipient : Recipient):
end
@storage_var
func current_index() -> (index : felt):
end

@storage_var
func demux_state(index : felt) -> (demux_transaction_state : TransactionState):
end

@storage_var
func execute_task_test(recipient_index : felt) -> (time_stamp : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner_address : felt
):
    # owner_address : felt # TODO
    owner.write(value=owner_address)
    return ()
end

@view
func get_current_recipient{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    current_recipient : Recipient
):
    let (_current_recipient) = current_recipient.read()
    return (current_recipient=_current_recipient)
end

@view
func get_demux_transaction_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    index : felt
) -> (state : TransactionState):
    let (_state) = demux_state.read(index)
    return (_state)
end

# TODO: email-> might need to pass it as a blob, pgp maybe? dont want spamming :)
# Assuming the client will set the recipients ordered by transactions delay
@external
func set_recipients{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt,
    weight : felt,
    wallet_name : felt,
    email : felt,
    recuring_period : felt,
    transaction_delay : felt,
):
    alloc_locals
    let (last_index) = recipients_number.read()
    local new_recipients : Recipient = Recipient(wallet_name=wallet_name, email=email, address=address, weight=weight, recuring_period=recuring_period, transaction_delay=transaction_delay, ready_to_send=0)
    recipients.write(wallet_number=last_index, value=new_recipients)
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
    # update demux transaction state, todo: make sure no duplicate addresses entry
    # for testing we set to 1, once signature is done then we can set 1 then as expected
    demux_state.write(last_index, TransactionState(address=address, state=PENDING_STATE))
    # keep track of recipients
    recipients_number.write(last_index + 1)
    if last_index == 0:
        current_recipient.write(new_recipients)
    end
    return ()
end

@view
func get_recipient{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    wallet_number : felt
) -> (recepients : Recipient):
    alloc_locals
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
    let (res) = recipients.read(wallet_number=wallet_number)
    return (res)
end
# //////////////////////////////////////////////////////////////////////////////////////
# FOR TESTING YAGI ONLY
@view
func get_execute_task_test{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    index : felt
) -> (time_stamp : felt):
    let (_res) = execute_task_test.read(index)
    return (time_stamp=_res)
end

@view
func get_current_recipient_index_to_check_transaction_delay{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> (index : felt):
    let (_res) = current_recipient_index_to_check_transaction_delay.read()
    return (index=_res)
end

# //////////////////////////////////////////////////////////////////////////////////////

@view
func get_recipients_number{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    index : felt
):
    let (res) = recipients_number.read()
    return (res)
end

@view
func get_is_tx_ready{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    index : felt
) -> (res : felt):
    let (res) = is_tx_ready.read(index)
    return (res)
end

@view
func get_configuration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : Configuration
):
    let (res) = configuration.read()
    return (res)
end

@view
func get_transaction_delay{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    index : felt
) -> (res : felt):
    let (res) = recipients_transactions_delay.read(index)
    return (res)
end

@view
func owner_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    owner_address : felt
):
    let (owner_address) = owner.read()
    return (owner_address)
end

@view
func get_mycaller_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    caller : felt
):
    let (caller) = get_caller_address()
    return (caller)
end

@external
func increase_recipients_balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ):
    alloc_locals

    let (call_calldata : felt*) = alloc()

    # call_array
    assert call_calldata[0] = 12

    # TODO: set up the nonce
    # assert call_calldata[1] = nonce

    call_contract(
        contract_address=RECIPIENT_ADDRESS,
        function_selector=INCREASE_BALANCE_HASH,
        calldata_size=1,
        calldata=call_calldata,
    )

    return ()
end

@external
func get_eth_l2_balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : felt, res1_len : felt, res1 : felt*
):
    # balanceOf str_to_felt 1814801012269441699686
    alloc_locals
    let (call_calldata : felt*) = alloc()
    assert call_calldata[0] = RECIPIENT_ADDRESS_CHROME
    # assert call_calldata[1] = nonce # TODO DECLATE AN ONCE STORAGE VAR
    let (res, res1) = call_contract(
        contract_address=ETH_L2_ADDRESS,
        function_selector=BALANCE_OF_HASH,
        calldata_size=1,
        calldata=call_calldata,
    )

    return (res, 2, res1)
end

@external
func set_configuration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    send_amount : felt, send_type : felt, equal_weights : felt, multi_sig : felt, expiry_date : felt
):
    alloc_locals
    assert_not_zero(send_amount)
    assert multi_sig = 0  # not supported yet, post poc!
    assert_not_zero(expiry_date)

    local newConfiguration : Configuration = Configuration(
        send_amount=send_amount,
        send_type=send_type,
        equal_weights=equal_weights,
        multi_sig=multi_sig,
        expiry_date=expiry_date,
        )

    configuration.write(newConfiguration)
    return ()
end

@view
func is_configuration_set{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : felt
):
    alloc_locals
    # TODO: complete validation of all fields
    local is_configured = 1
    let (recipientsNumber) = recipients_number.read()
    let (current_configuration) = configuration.read()
    if recipientsNumber == 0:
        return (0)
    end
    if current_configuration.send_amount == 0:
        return (0)
    end

    return (is_configured)
end

@view
func call_get_eth_balance{syscall_ptr : felt*, range_check_ptr}(wallet_address : felt) -> (
    res : Uint256
):
    let (res) = IERC20.balanceOf(contract_address=ETH_L2_ADDRESS, account=wallet_address)
    return (res=res)
end

# //////////////////////////////////////////////////////////////////////////////////////
#  YAGI will call these functions

# At the moment, reocurring transactions are not supported
# only delayed ones, therefore the number of transactions checked is based on the number of recipients only
# might have time to introduce recurring feature, will see...

# checking all good with is_le
@view
func compareValues{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(a, b) -> (
    bool : felt
):
    let (is_le_felt) = is_le(a, b)
    return (is_le_felt)
end

# only delayed transactions, no recurring ones yet, hopefully soon!
@view
func is_transaction_ready{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    index : felt
) -> (is_le_felt : felt):
    alloc_locals
    let is_le_felt = 0
    # todo check config is set
    let (_blocktimestamp) = get_block_timestamp()
    let (_recipient) = recipients.read(index)
    let (is_le_felt) = is_le(_recipient.transaction_delay, _blocktimestamp)
    return (is_le_felt)
end
# only delayed transactions, no recurring ones yet, hopefully soon!
@view
func is_recipient_ready{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    transaction_delay : felt
) -> (is_le_felt : felt):
    alloc_locals
    let is_le_felt = 0
    # todo check config is set
    let (_blocktimestamp) = get_block_timestamp()
    let (is_le_felt) = is_le(transaction_delay, _blocktimestamp)
    return (is_le_felt)
end

# @external
# func check_recipients_transactions_delays{
#     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
# }(size : felt, _index : felt) -> (res : felt):
#     alloc_locals
#     let _result = 0
#     if size == 0:
#         let (res) = recipients_transactions_delay.read(0)
#         return (res=res)
#     else:
#         # do the business here!
#         # check each element and do what ever with it
#         # let (_index) = temp_recipients_index.read()

# let (_recipients) = recipients.read(_index)
#         let (_is_transaction_ready) = is_transaction_ready(_index)
#         recipients_transactions_delay.write(_index, _is_transaction_ready)
#         let (_state) = get_transaction_state(
#             _is_transaction_ready, PENDING_STATE, READY_FOR_EXECUTION_STATE
#         )
#         # update demux transaction state, todo: make sure no duplicate addresses entry
#         demux_state.write(_index, TransactionState(address=_recipients.address, state=_state))  # for testing we set to 1, once signature is done then we can set 1 then as expected
#     end

# let (_result) = check_recipients_transactions_delays(size=size - 1, _index=_index + 1)

# return (res=_result)
# end

@view
func get_transaction_state(
    _is_transaction_ready : felt, current_state : felt, next_step : felt
) -> (new_state : felt):
    if _is_transaction_ready == 0:
        return (new_state=current_state)
    end
    if _is_transaction_ready == 1:
        return (new_state=next_step)
    end
    return (new_state=FAILED_STATE)
end

# //////////////////////////////////////////////////////////////////////////////////////
# YAGI router, will invoke these functions
@view
func probe_demux_transfers{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    bool : felt
):
    alloc_locals

    # # # Make sure yagi_router is calling
    # # let (_caller_address) = get_caller_address()
    # # assert _caller_address = YAGI_ROUTER_GOERLI_ADDRESS

    # # Current assumption is all recipients are ordered by transaction_delay, who orders them is yet to be
    # # finalised, more likely demux should take care of that but for now the assumption isthe list is ordered.
    # # current_recipient stores the current recipient that is needed to use so it can be checked
    # # (corresponding recipient's transaction delay)

    let (_current_recipient) = current_recipient.read()
    let (_is_transaction_ready) = is_recipient_ready(_current_recipient.transaction_delay)

    return (_is_transaction_ready)
end

@external
func execute_demux_transfers{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (block_time : felt):
    # Make sure yagi_router is calling
    # let (_caller_address) = get_caller_address()
    # assert _caller_address = YAGI_ROUTER_GOERLI_ADDRESS
    # FOR TESTING

    let _blockTimestamp = 0
    let (_blockTimestamp) = get_block_timestamp()
    let (_current_recipient) = current_recipient.read()

    execute_task_test.write(_current_recipient.address, _blockTimestamp)

    let (_index) = current_index.read()
    let (next_recipient) = recipients.read(_index + 1)
    current_recipient.write(next_recipient)
    current_index.write(_index + 1)

    return (block_time=_blockTimestamp)
end

# //////////////////////////////////////////////////////////////////////////////////////
# YAGI, setting up demux address

# set_demux_address(YAGI_ROUTER_GOERLI_ADDRESS, demux_address=...)
@contract_interface
namespace IContractYagi:
    func set_demux_address(demux_address : felt) -> ():
    end

    func set_owner(owner_address : felt) -> ():
    end
end

# //////////////////////////////////////////////////////////////////////////////////////
# ERC20

@contract_interface
namespace IERC20:
    func name() -> (name : felt):
    end

    func symbol() -> (symbol : felt):
    end

    func decimals() -> (decimals : felt):
    end

    func totalSupply() -> (totalSupply : Uint256):
    end

    func balanceOf(account : felt) -> (balance : Uint256):
    end

    func allowance(owner : felt, spender : felt) -> (remaining : Uint256):
    end

    func transfer(recipient : felt, amount : Uint256) -> (success : felt):
    end

    func transferFrom(sender : felt, recipient : felt, amount : Uint256) -> (success : felt):
    end

    func approve(spender : felt, amount : Uint256) -> (success : felt):
    end
end

# //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
# section: DO NOT REMOVE!
# TODO: set up configuration to use this converter so we can use the original planned set up with decimals, 48 to 63
# check doc for details (not public yet)

@storage_var
func decimal_conversion_index() -> (index : felt):
end

@view
func convertDecimalToBinary{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    decimal_value : felt
) -> (binary_array_len : felt, binary_array : felt*):
    alloc_locals
    let (local inversedArray : felt*) = alloc()
    # Convert decimal to binary, result is an array [LSB, ..., MSB]
    let (len, inversedArray) = convertToBinary(decimal_value)
    # Reversing the above array to the correct order: [MSB, ..., LSB]
    let (local resultArray : felt*) = alloc()
    let (len, resultArray) = reverse(len, inversedArray)

    return (len, resultArray)
end

func convertToBinary{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    decimal_value : felt
) -> (binary_array_len : felt, binary_array : felt*):
    alloc_locals
    let (local binary_array : felt*) = alloc()
    decimal_conversion_index.write(0)
    let (local index) = decimal_conversion_index.read()

    # Conversion to binary,
    # Dividing the decimal by 2 as binary is base 2
    # the cairo unsigned_div_rem method returns q and r
    # q is the result of decimal_value/2
    # r is the remainder
    # add the r's to an array
    # repeat it using a jmp until q = 0
    # we end up with an array: [LSB,...,MSB]

    let (q, r) = unsigned_div_rem(value=decimal_value, div=2)
    assert binary_array[index] = r
    decimal_conversion_index.write(index + 1)

    let (index) = decimal_conversion_index.read()

    loop:
    let (q, r) = unsigned_div_rem(value=q, div=2)
    assert binary_array[index] = r
    decimal_conversion_index.write(index + 1)
    let (index) = decimal_conversion_index.read()

    jmp loop if q != 0

    return (index, binary_array)
end

@view
func division_rem{syscall_ptr : felt*, range_check_ptr}(value, div) -> (q : felt, r : felt):
    let (q, r) = unsigned_div_rem(value=value, div=div)
    return (q, r)
end
# //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
# @view
# func get_tx_max_fee{syscall_ptr : felt*}() -> (max_fee : felt):
#     let (tx_info) = get_tx_info()
#     return (max_fee=tx_info.max_fee)
# end

# todo: should allow the user to remove a specific recipient: remove_recipient(wallet_number: felt)
# todo: should allow the user to remove all recipients: remove_aal_recipient()

# !!!!!!!!!
# Check user has enough funds.
#     let (account_from_balance) = get_account_token_balance(
#         account_id=account_id, token_type=token_from
#     )

# TODO!! check signatures
# TAKEN FROM https://hackmd.io/@sambarnes/BJvGs0JpK
# # Vehicle signers can attest to a state hash -- data storage & verification off-chain
# @external
# func attest_state{
#         syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
#         ecdsa_ptr : SignatureBuiltin*}(vehicle_id : felt, nonce : felt, state_hash : felt):
#     # Note the addition of an ecdsa_ptr implicit argument, this is required in functions
#     # that verify ECDSA signatures.

# # Verify the vehicle has been registered with a signer
#     let (signer_public_key) = vehicle_signer_public_key.read(vehicle_id=vehicle_id)
#     assert_not_zero(signer_public_key)

# # Make sure the current nonce was used
#     let (expected_nonce) = vehicle_nonce.read(vehicle_id=vehicle_id)
#     assert expected_nonce - nonce = 0

# # Expected Signed Message = H( nonce + H( vehicle_id , H( signer_public_key ) ) )
#     let (h1) = hash2{hash_ptr=pedersen_ptr}(state_hash, 0)
#     let (h2) = hash2{hash_ptr=pedersen_ptr}(vehicle_id, h1)
#     let (message_hash) = hash2{hash_ptr=pedersen_ptr}(nonce, h2)

# # Verify signature is valid and covers the expected signed message
#     let (sig_len : felt, sig : felt*) = get_tx_signature()
#     assert sig_len = 2 # ECDSA signatures have two parts, r and s
#     verify_ecdsa_signature(
#         message=message_hash, public_key=signer_public_key, signature_r=sig[0], signature_s=sig[1])
#     # If the contract passes ^this line, the signaure verification passed.
#     # Otherwise, the execution would halt and the transaction would revert.

# # Register state & increment nonce
#     vehicle_state.write(vehicle_id=vehicle_id, nonce=nonce, value=state_hash)
#     vehicle_nonce.write(vehicle_id=vehicle_id, value=nonce + 1)
#     return ()
# end
# test examples
# @pytest.mark.asyncio
# async def test_attest_state_invalid_nonce(contract_factory):
#     """Should fail with invalid nonce"""
#     _, contract = contract_factory

# state_hash = 1234
#     nonce = 666
#     message_hash = pedersen_hash(
#         nonce, pedersen_hash(some_vehicle, pedersen_hash(state_hash, 0))
#     )
#     sig_r, sig_s = sign(msg_hash=message_hash, priv_key=some_signer_secret)

# with pytest.raises(StarkException):
#         await contract.attest_state(
#             vehicle_id=some_vehicle,
#             nonce=nonce,
#             state_hash=state_hash,
#         ).invoke(signature=[sig_r, sig_s])

# @pytest.mark.asyncio
# async def test_attest_state_invalid_signature(contract_factory):
#     """Should fail with invalid nonce"""
#     _, contract = contract_factory
#     with pytest.raises(StarkException):
#         await contract.attest_state(
#             vehicle_id=some_vehicle,
#             nonce=0,
#             state_hash=1234,
#         ).invoke(signature=[123456789, 987654321])

# @pytest.mark.asyncio
# async def test_attest_state(contract_factory):
#     """Should successfully attest to a state hash & increment nonce"""
#     _, contract = contract_factory

# state_hash = 1234
#     nonce = 0
#     message_hash = pedersen_hash(
#         nonce, pedersen_hash(some_vehicle, pedersen_hash(state_hash, 0))
#     )
#     sig_r, sig_s = sign(msg_hash=message_hash, priv_key=some_signer_secret)

# await contract.attest_state(
#         vehicle_id=some_vehicle,
#         nonce=nonce,
#         state_hash=state_hash,
#     ).invoke(signature=[sig_r, sig_s])

# # Check the nonce was incremented
#     new_nonce = await contract.get_nonce(vehicle_id=some_vehicle).call()
#     assert new_nonce.result == (nonce + 1,)

# import sys
# from starkware.crypto.signature.signature import (
#     pedersen_hash, sign)

# priv_key = 10000000 #pull from env or set to your priv key
# num_args = 0
# prev = 0
# curr = 0
# counter = 1
# args = []
# if(len(sys.argv) > 1):
#     num_args = len(sys.argv) - 1
#     curr = int(sys.argv[1])
#     for index, value in enumerate(sys.argv):
#         if index >=1:
#             args.append(int(value))

# def hash_calculator(counter, prev, curr, args, length):
#     if length == 0:
#         return 0
#     else:
#         prev = pedersen_hash(prev,curr)
#         if counter < length:
#             curr = args[counter]
#             counter +=1
#             return hash_calculator(counter, prev, curr, args, length)
#         else:
#             return pedersen_hash(prev, length)

# calc_hash = hash_calculator(counter, prev, curr, args, len(args))

# def signature(hash, priv_key):
#     if hash ==0:
#         return (0,0)
#     else:
#         return sign(
#             msg_hash = hash,
#             priv_key = priv_key
#         )

# r,s = signature(calc_hash, priv_key)
# print(r, s, sep=', ')
