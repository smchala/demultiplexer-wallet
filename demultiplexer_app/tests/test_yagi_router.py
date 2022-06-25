import pytest
from starkware.starknet.testing.starknet import Starknet
import asyncio

# How to mock get_caller_address


@pytest.mark.asyncio
async def test_invoke():
    starknet = await Starknet.empty()
    contract = await starknet.deploy('contracts/yagi_router.cairo')
    print()

    await contract.set_transaction_delays().invoke()
