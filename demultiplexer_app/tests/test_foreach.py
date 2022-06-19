import pytest
from starkware.starknet.testing.starknet import Starknet
import asyncio


@pytest.mark.asyncio
async def test_invoke():
    starknet = await Starknet.empty()
    contract = await starknet.deploy('contracts/foreach.cairo')
    print()

    await contract.set_transaction_delays().invoke()

    ret = await contract.get_transactions_delays(0).call()
    print(f'> invoke::find_ride() returns: {ret.result}')
    assert ret.result[0] == 1234
    ret = await contract.get_transactions_delays(1).call()
    print(f'> invoke::find_ride() returns: {ret.result}')
    assert ret.result[0] == 3456
    ret = await contract.get_transactions_delays(2).call()
    print(f'> invoke::find_ride() returns: {ret.result}')
    assert ret.result[0] == 7890
    ret = await contract.get_transactions_delays(3).call()
    print(f'> invoke::find_ride() returns: {ret.result}')
    assert ret.result[0] == 5321
    ret = await contract.get_transactions_delays(4).call()
    print(f'> invoke::find_ride() returns: {ret.result}')
    assert ret.result[0] == 4567
