import pytest
from starkware.starknet.testing.starknet import Starknet
import asyncio
import os
# How to mock get_caller_address???


CONTRACT_FILE = os.path.join("contracts", "yagi_router.cairo")
PATH = "./demultiplexer-wallet/demultiplexer_app/contracts/yagi_router.cairo"
MOCK_ADDRESS = 1234  # owner's address

# Note:
# due to the fact that I can't mock get_caller_address, for the tests to pass need to comment out the relevant asserts in yagi_router functions


@pytest.mark.asyncio
async def test_get_caller_address_test():
    starknet = await Starknet.empty()
    contract = await starknet.deploy(source='contracts/yagi_router.cairo', constructor_calldata=[MOCK_ADDRESS])

    execution_info = await contract.set_demux_address(1234).invoke()
    execution_info = await contract.set_owner(0).invoke()

    execution_info = await contract.get_caller_address_test().call()
    print(execution_info.result[0])
    assert execution_info.result[0] == 0x0

    execution_info = await contract.get_demux_address_test().call()
    print(execution_info.result[0])
    assert execution_info.result[0] == 1234
