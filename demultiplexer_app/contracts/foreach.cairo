%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

@storage_var
func recipients_transactions_delay(index : felt) -> (delay : felt):
end

@storage_var
func index() -> (idx : felt):
end

@external
func set_transaction_delays{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (res : felt):
    alloc_locals
    let (arr : felt*) = alloc()
    assert [arr] = 1234
    assert [arr + 1] = 3456
    assert [arr + 2] = 7890
    assert [arr + 3] = 5321
    assert [arr + 4] = 4567

    let (res) = array_loop(arr, 5)
    index.write(0)
    return (res)
end

@view
func get_transactions_delays{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    index : felt
) -> (res : felt):
    let (recipientstransactionsdelay) = recipients_transactions_delay.read(index)
    return (res=recipientstransactionsdelay)
end

func array_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    arr : felt*, size
) -> (res : felt):
    alloc_locals

    if size == 0:
        let (res) = recipients_transactions_delay.read(0)
        return (res=res)
    else:
        # do the business here!
        # check each element and do what ever with it
        let (_index) = index.read()
        recipients_transactions_delay.write(_index, [arr])
        index.write(_index + 1)
    end
    let (_result) = array_loop(arr=arr + 1, size=size - 1)

    return (res=_result)
end
