%lang starknet
# Yagi router

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero

# //////////////////////////////////////////////////////////////////////////////////////
# Storage vars

@storage_var
func demux_address() -> (addr : felt):
end

@storage_var
func owner() -> (owner_address : felt):
end

@storage_var
func check_probe_task() -> (is_ready : felt):
end

# //////////////////////////////////////////////////////////////////////////////////////
# Constructor

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _owner_address : felt
):
    # check
    assert_not_zero(_owner_address)

    # Store owner
    owner.write(value=_owner_address)

    # demux_address.write(value=demux_contract_address) # wait until demux is good to go
    return ()
end

# //////////////////////////////////////////////////////////////////////////////////////
# View functions

# Yagi will call this function
@view
func probeTask{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    bool : felt
):
    alloc_locals
    # checks
    let (_demux_contract_address) = demux_address.read()
    assert_not_zero(_demux_contract_address)

    # Ask demux contract if we good to go!
    let (_bool) = IContractDemux.probe_demux_transfers(_demux_contract_address)

    # Use check_probe_task as a guard to be checked when executing
    if _bool == 1:
        check_probe_task.write(1)
    else:
        check_probe_task.write(0)
    end

    return (bool=_bool)
end

# # Need to find out how to mock get_caller_address!!!!!

# # FOR TESTING ONLY, TODO: will get rid of this
# @view
# func get_caller_address_test{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     ) -> (address : felt):
#     alloc_locals
#     let (_caller) = get_caller_address()
#     return (address=_caller)
# end

# # FOR TESTING ONLY, TODO: will get rid of this
# @view
# func get_demux_address_test{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     ) -> (address : felt):
#     alloc_locals
#     let (_demux) = demux_address.read()
#     return (address=_demux)
# end

# //////////////////////////////////////////////////////////////////////////////////////
# External functions

# When probeTask returns 1/true, then executeTask is called by yagi
@external
func executeTask{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> ():
    alloc_locals
    # Only execute if check_probe_task is 1/TRUE
    let (_check_probe_task) = check_probe_task.read()
    assert_not_zero(_check_probe_task)

    let (_demux_contract_address) = demux_address.read()
    # Invoke demux contract to execute
    IContractDemux.execute_demux_transfers(_demux_contract_address)
    return ()
end

# The only entity that yagi router can communicate with is the demux contract
@external
func set_demux_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _demux_contract_address : felt
):
    alloc_locals
    # checks
    assert_not_zero(_demux_contract_address)
    assert_owner()
    # store demux_address
    demux_address.write(value=_demux_contract_address)
    return ()
end

# Only called from demux contract, in case we get locked out by argentX and need to re-deploy another wallet addres as owner
@external
func set_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _new_owner_address : felt
):
    alloc_locals
    # checks
    let (_caller) = get_caller_address()
    let (_demux_contract_address) = demux_address.read()
    assert _caller = _demux_contract_address
    # store new owner
    owner.write(_new_owner_address)
    return ()
end

# //////////////////////////////////////////////////////////////////////////////////////
# Helper functions

func assert_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (_owner) = owner.read()
    let (_caller) = get_caller_address()
    assert _owner = _caller  # is _caller the contract address or the acccount that is calling the contract
    return ()
end

# //////////////////////////////////////////////////////////////////////////////////////
# Contracts interfaces

@contract_interface
namespace IContractDemux:
    func probe_demux_transfers() -> (bool : felt):
    end

    func execute_demux_transfers() -> ():
    end
end

# //////////////////////////////////////////////////////////////////////////////////////
# End
