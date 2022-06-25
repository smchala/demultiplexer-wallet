%lang starknet
# Yagi router

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero

@contract_interface
namespace IContractDemux:
    func probe_demux_transfers() -> (bool : felt):
    end

    func execute_demux_transfers() -> ():
    end
end

@storage_var
func demux_address() -> (addr : felt):
end

@storage_var
func owner() -> (owner_address : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner_address : felt
):
    owner.write(value=owner_address)
    # demux_address.write(value=demux_contract_address) # wait until demux is good to go
    return ()
end

# Yagi will call this function
@view
func probeTask{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    bool : felt
):
    let (demux_contract_address) = demux_address.read()
    assert_not_zero(demux_contract_address)
    let (bool) = IContractDemux.probe_demux_transfers(demux_contract_address)

    return (bool)
end

# When probeTask returns 1/true, then executeTask is called by yagi
@external
func executeTask{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> ():
    let (demux_contract_address) = demux_address.read()
    assert_not_zero(demux_contract_address)
    IContractDemux.execute_demux_transfers(demux_contract_address)
    return ()
end

# The only entity that yagi router can communicate with is the demux contract
@external
func set_demux_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    demux_contract_address : felt
):
    assert_not_zero(demux_contract_address)
    assert_owner()
    demux_address.write(value=demux_contract_address)
    return ()
end

func assert_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (_owner) = owner.read()
    let (_caller) = get_caller_address()
    assert_not_zero(_owner)
    assert_not_zero(_caller)
    assert _owner = _caller  # is _caller the contract address or the acccount that is calling the contract
    return ()
end

# FOR TESTING ONLY, TODO: will get rid of this
@view
func get_caller_address_test() -> (address : felt):
    let (_caller) = get_caller_address()
    return (_caller)
end
