# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    call_contract,
    get_caller_address,
    get_tx_info,
    get_contract_address,
)
from libs.cairocontracts.src.openzeppelin.security.pausable import Pausable
from starkware.cairo.common.alloc import alloc

# import du types uint256 (Entier non signe sur 256) et des operations dessus
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_le, uint256_check
# import des conditions mathemiques inferieurs ou egale et different de zero
from starkware.cairo.common.math import (
    abs_value,
    assert_250_bit,
    assert_in_range,
    assert_le,
    assert_le_felt,
    assert_lt,
    assert_lt_felt,
    assert_nn,
    assert_nn_le,
    assert_not_equal,
    assert_not_zero,
    horner_eval,
    sign,
    signed_div_rem,
    split_felt,
    split_int,
    sqrt,
    unsigned_div_rem,
)

const MYARGENTX_ADDRESS = 0x0438b49f89fbd98dc2efedbff1a3e85c2798e22ae66e5d6ed8dcbb0a0f6a6bf6
const RECIPIENT_ADDRESS = 0x00b68ad3d5a97de6a013d5b22f70f1b39de67f182afd6f84936bb1b325d046b1
const RECIPIENT_ADDRESS_CHROME = 0x0462369e50f87dfe5cb354fe1c7d4d8f2315d3b6256e576e570edc54ca50b3c8
const ETH_L2_ADDRESS = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
# use utils/util.py to get the function hash
const BALANCE_OF_HASH = 0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e
const INCREASE_BALANCE_HASH = 0x362398bec32bc0ebb411203221a35a0301193a96f317ebe5e40be9f60d15320

# address -> name.eth woudl be a cool user experience
using RecipientWallet = (address : felt, weight : felt)
using Recipient = (wallet_name : felt, email : felt, recipientWallet : RecipientWallet, recuring_period : felt, transaction_delay : felt)
using Configuration = (send_amount : felt, send_type : felt, equal_weights : felt, multi_sig : felt, expiry_date : felt)

@storage_var
func recipients_number() -> (index : felt):
end

@storage_var
func recipients(wallet_number : felt) -> (recipients : Recipient):
end

@storage_var
func configuration() -> (configuration : Configuration):
end

# @storage_var
# func owner() -> (owner_address : felt):
# end

# wip
# @constructor
# func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     # owner_address : felt
#     # owner.write(value=owner_address)
#     return ()
# end

# Define a storage variable.
@storage_var
func balance() -> (res : felt):
end

# TODO: email-> might need to pass it as a blob, pgp maybe? dont want spamming :)
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
    local new_recipients_wallet : RecipientWallet = (address=address, weight=weight)
    local new_recipients : Recipient = (wallet_name=wallet_name, email=email, recipientWallet=new_recipients_wallet, recuring_period=recuring_period, transaction_delay=transaction_delay)
    recipients.write(wallet_number=last_index, value=new_recipients)
    # keep track of recipients
    recipients_number.write(last_index + 1)
    return ()
end

@view
func get_recipient{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    wallet_number : felt
) -> (recepients : Recipient):
    let (res) = recipients.read(wallet_number=wallet_number)
    return (res)
end

@view
func get_recipients_number{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    index : felt
):
    let (res) = recipients_number.read()
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
func get_mycaller_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    caller : felt
):
    let (caller) = get_caller_address()
    return (caller)
end

# THIS WORKED, CHECKED ON VOYAGER!!!! :)
# NOT SURE HOW TO TEST THIS YET...
@external
func increase_recipients_balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ):
    alloc_locals
    # let (caller) = get_caller_address()
    # return (caller)

    let (call_calldata : felt*) = alloc()

    # call_array
    assert call_calldata[0] = 12

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
    # let (caller) = get_caller_address()
    # return (caller)

    let (call_calldata : felt*) = alloc()

    # call_array
    assert call_calldata[0] = RECIPIENT_ADDRESS_CHROME

    # assert call_calldata[1] = nonce

    let (res, res1) = call_contract(
        contract_address=ETH_L2_ADDRESS,
        function_selector=BALANCE_OF_HASH,
        calldata_size=1,
        calldata=call_calldata,
    )

    return (res, 2, res1)
end

# Increases the balance by the given amount.
@external
func set_configuration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    send_amount : felt, send_type : felt, equal_weights : felt, multi_sig : felt, expiry_date : felt
):
    alloc_locals
    # TODO: Check why the following was causing the function to fail on test net?
    # assert_not_zero(send_amount)
    # assert multi_sig = 0  # not supported yet, post poc!
    # assert_not_zero(expiry_date)

    local newConfiguration : Configuration = (
        send_amount=send_amount,
        send_type=send_type,
        equal_weights=equal_weights,
        multi_sig=multi_sig,
        expiry_date=expiry_date,
        )

    configuration.write(newConfiguration)
    return ()
end

# Increases the balance by the given amount.
@external
func increase_balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : felt
):
    let (res) = balance.read()
    balance.write(res + amount)
    return ()
end

@view
func is_configuration_set{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : felt
):
    alloc_locals

    # false -> 0, true -> 1
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

# Returns the current balance.
@view
func get_balance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : felt
):
    let (res) = balance.read()
    return (res)
end

@external
func set_transacions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : felt
):
    alloc_locals
    let (isReady) = is_configuration_set()
    # assert isReady = 1 #not sure why this fails on goerli

    return (isReady)
end

@view
func call_get_eth_balance{syscall_ptr : felt*, range_check_ptr}(wallet_address : felt) -> (
    res : Uint256
):
    let (res) = IERC20.balanceOf(contract_address=ETH_L2_ADDRESS, account=wallet_address)
    return (res=res)
end

#
@storage_var
func decimal_conversion_index() -> (index : felt):
end
# ) -> (call_calldata_len : felt, call_calldata : felt*):

@view
func convertDecimalToBinary{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    value : felt
) -> (call_calldata_len : felt, call_calldata : felt*):
    alloc_locals
    let (local call_calldata : felt*) = alloc()
    let (local index) = decimal_conversion_index.read()

    let (q, r) = unsigned_div_rem(value=value, div=2)
    assert call_calldata[index] = r
    decimal_conversion_index.write(index + 1)

    let (index) = decimal_conversion_index.read()

    loop:
    let (q, r) = unsigned_div_rem(value=q, div=2)
    assert call_calldata[index] = r
    decimal_conversion_index.write(index + 1)
    let (index) = decimal_conversion_index.read()

    jmp loop if q != 0

    return (index, call_calldata)
end

@view
func division_rem{syscall_ptr : felt*, range_check_ptr}(value, div) -> (q : felt, r : felt):
    let (q, r) = unsigned_div_rem(value=value, div=div)
    return (q, r)
end

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

# func swap{
#     syscall_ptr : felt*,
#     pedersen_ptr : HashBuiltin*,
#     range_check_ptr,
# }(account_id : felt, token_from : felt, amount_from : felt) -> (
#     amount_to : felt
# ):
#     # Verify that token_from is either TOKEN_TYPE_A or TOKEN_TYPE_B.
#     assert (token_from - TOKEN_TYPE_A) * (token_from - TOKEN_TYPE_B) = 0

# # Check requested amount_from is valid.
#     assert_nn_le(amount_from, BALANCE_UPPER_BOUND - 1)

# # Check user has enough funds.
#     let (account_from_balance) = get_account_token_balance(
#         account_id=account_id, token_type=token_from
#     )
#     assert_le(amount_from, account_from_balance)

# # Execute the actual swap.
#     let (token_to) = get_opposite_token(token_type=token_from)
#     let (amount_to) = do_swap(
#         account_id=account_id,
#         token_from=token_from,
#         token_to=token_to,
#         amount_from=amount_from,
#     )

# return (amount_to=amount_to)
# end

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
