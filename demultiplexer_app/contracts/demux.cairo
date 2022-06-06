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
from starkware.cairo.common.math import assert_nn_le, assert_not_zero

# import du template de token ERC20 de openzeppelin
from openzeppelin.token.erc20.library import (
    ERC20_name,
    ERC20_symbol,
    ERC20_totalSupply,
    ERC20_decimals,
    ERC20_balanceOf,
    ERC20_allowance,
    ERC20_initializer,
    ERC20_approve,
    ERC20_increaseAllowance,
    ERC20_decreaseAllowance,
    ERC20_transfer,
    ERC20_transferFrom,
    ERC20_mint,
)

# import des modules de declaration et test d'ownership
from openzeppelin.access.ownable import Ownable_initializer, Ownable_only_owner, Ownable_get_owner
# import du syscall (appel systeme) get_caller_address pour recuperer l'adresse
# de la personne qui interagit avec le contrat
# from starkware.starknet.common.syscalls import get_caller_address
# import des differentes fonctions definie dans le contrat utils (./contracts/utils.cairo)

# import de la constante true
from openzeppelin.utils.constants import TRUE

# # Dans le cas present cap_ ne prend aucun argument en entree et retourne la
# # variable res qui est un Uint256
# @storage_var
# func cap_() -> (res : Uint256):
# end

# # Dans le cas present distribution_address ne prend aucun argument en entree et retourne la
# # variable res qui est un felt (Un entier non signe encode sur 252 bits)
# @storage_var
# func distribution_address() -> (res : felt):
# end

# Dans le cas present vault_address ne prend aucun argument en entree et retourne la
# variable res qui est un felt (Un entier non signe encode sur 252 bits)
@storage_var
func vault_address() -> (res : felt):
end

# Le constructeur est un ensemble d'instructions qui seront effectues une seule fois lors du deploiement du smart contract.
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt,
    symbol : felt,
    decimals : felt,
    initial_supply : Uint256,
    recipient : felt,
    owner : felt,
):
    # # On verifie bien que _cap est un entier compris entre 0 et 2**256 - 1
    # uint256_check(_cap)
    # Verifie que cap est plus grand que uint256 0 (0 sur les 256 bits)
    # Doit renvoyer a chaque fois 0
    # let (cap_valid) = uint256_le(_cap, Uint256(0, 0))
    # Normalement on obtient 1 car cap_valid = 0 si, permet de faire fail la fonction
    # en cas de non respect
    # Refacto possible en inversant les conditions
    # let (cap_valid) = uint256_le(Uint256(0,0),_cap)
    # assert_not_zero(cap_valid)
    # assert_not_zero(1 - cap_valid)
    # # Verification que l'address n'est pas nul car si address invalid ou nulle address = 0
    # assert_not_zero(_distribution_address)
    # Iniatilisation du token avec les 3 arguments name, symbol, decimals
    ERC20_initializer(name, symbol, decimals)
    # Mint des tokens avec l'address qui recoit les token et l'initial_supply qui lui est transferer
    ERC20_mint(recipient, initial_supply)
    # Attribution de la permission ownable a la personne qui a deployer le contrat (l'owner)
    Ownable_initializer(owner)
    # # ecriture de _cap dans le storage_var cap_
    # cap_.write(_cap)
    # # de meme pour la distribution_address
    # distribution_address.write(_distribution_address)
    return ()
end

#
# Getters
#

# @view
# func cap{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res : Uint256):
#     let (res : Uint256) = cap_.read()
#     return (res)
# end

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC20_name()
    return (name)
end

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC20_symbol()
    return (symbol)
end

@view
func totalSupply{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    totalSupply : Uint256
):
    let (totalSupply : Uint256) = ERC20_totalSupply()
    return (totalSupply)
end

@view
func decimals{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    decimals : felt
):
    let (decimals) = ERC20_decimals()
    return (decimals)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    account : felt
) -> (balance : Uint256):
    let (balance : Uint256) = ERC20_balanceOf(account)
    return (balance)
end

@view
func allowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, spender : felt
) -> (remaining : Uint256):
    let (remaining : Uint256) = ERC20_allowance(owner, spender)
    return (remaining)
end

#
# Externals
#

@external
func set_vault_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _vault_address : felt
):
    Ownable_only_owner()
    assert_not_zero(_vault_address)
    vault_address.write(_vault_address)
    return ()
end

@external
func transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    recipient : felt, amount : Uint256
) -> (success : felt):
    ERC20_transfer(recipient, amount)
    return (TRUE)
end

@external
func transferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    sender : felt, recipient : felt, amount : Uint256
) -> (success : felt):
    ERC20_transferFrom(sender, recipient, amount)
    return (TRUE)
end

@external
func approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    spender : felt, amount : Uint256
) -> (success : felt):
    ERC20_approve(spender, amount)
    return (TRUE)
end

@external
func increaseAllowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    spender : felt, added_value : Uint256
) -> (success : felt):
    ERC20_increaseAllowance(spender, added_value)
    return (TRUE)
end

@external
func decreaseAllowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    spender : felt, subtracted_value : Uint256
) -> (success : felt):
    ERC20_decreaseAllowance(spender, subtracted_value)
    return (TRUE)
end

@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to : felt, amount : Uint256
):
    alloc_locals
    # Authorized_only()
    let (totalSupply : Uint256) = ERC20_totalSupply()
    # let (cap : Uint256) = cap_.read()
    let (local sum : Uint256, is_overflow) = uint256_add(totalSupply, amount)
    assert is_overflow = 0
    # let (enough_supply) = uint256_le(sum, cap)
    # assert_not_zero(enough_supply)
    ERC20_mint(to, amount)
    return ()
end

# func Authorized_only{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     alloc_locals
#     let (owner : felt) = Ownable_get_owner()
#     let (xzkp_address : felt) = vault_address.read()
#     let (caller : felt) = get_caller_address()

# if owner == caller:
#         let (is_owner : felt) = 1
#     else:
#         let (is_owner : felt) = 0
#     end

# if xzkp_address == caller:
#         let (is_vault : felt) = 1
#     else:
#         let (is_vault : felt) = 0
#     end

# with_attr error_message("ZkPadToken:: Caller should be owner or vault"):
#         if (is_vault - 1) * (is_owner - 1) == 0:
#             let (is_valid : felt) = 1
#         else:
#             let (is_valid : felt) = 0
#         end
#         assert is_valid = 1
#     end

# return ()
# end

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
