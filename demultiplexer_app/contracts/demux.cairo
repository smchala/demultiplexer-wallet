# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_tx_info
from starkware.cairo.common.math import assert_not_zero, assert_le, assert_nn

# from starkware.starknet.common.syscalls import (
#     call_contract,
#     get_tx_signature,
#     get_contract_address,
#     get_caller_address,
# )

# address -> xxxxx.eth woudl be a cool user experience
using RecipientWallet = (address : felt, weight : felt)
using Recipient = (wallet_name : felt, email : felt, recipientWallet : RecipientWallet, recuring_value : felt, recuring_period : felt, transaction_delay : felt)
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
    recuring_value : felt,
    recuring_period : felt,
    transaction_delay : felt,
):
    alloc_locals
    let (last_index) = recipients_number.read()
    local new_recipients_wallet : RecipientWallet = (address=address, weight=weight)
    local new_recipients : Recipient = (wallet_name=wallet_name, email=email, recipientWallet=new_recipients_wallet, recuring_value=recuring_value, recuring_period=recuring_period, transaction_delay=transaction_delay)
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
