%lang starknet
# Yagi router

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.design.access import assert_correct_admin_key

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
    owner_address : felt, demux_contract_address : fely
):
    owner.write(value=owner_address)
    demux_address.write(value=demux_contract_address)
    return ()
end

@view
func view_isaac_universe_address{syscall_ptr : felt, pedersen_ptr : HashBuiltin, range_check_ptr}(
    ) -> (curr_address : felt):
    let (curr_address) = isaac_universe_address.read()

    return (curr_address)
end

@external
func change_isaac_universe_address{syscall_ptr : felt, pedersen_ptr : HashBuiltin, range_check_ptr}(
    admin_key : felt, new_address : felt
) -> ():
    #
    # Check admin
    #
    assert_correct_admin_key(admin_key)

    isaac_universe_address.write(new_address)

    return ()
end

@view
func probeTask{syscall_ptr : felt, pedersen_ptr : HashBuiltin, range_check_ptr}() -> (bool : felt):
    let (demux_contract_address) = demux_address.read()

    let (bool) = IContractDemux.probe_demux_transfers(demux_contract_address)

    return (bool)
end

@external
func executeTask{syscall_ptr : felt, pedersen_ptr : HashBuiltin, range_check_ptr}() -> ():
    let (demux_contract_address) = demux_address.read()

    IContractDemux.execute_demux_transfers(demux_contract_address)

    return ()
end
