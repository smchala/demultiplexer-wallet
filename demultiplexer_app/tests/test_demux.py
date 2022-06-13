"""demux.cairo test file."""
import os

import pytest
import asyncio

from starkware.starknet.testing.starknet import Starknet
from utils.recipient import Recipient
from utils.configuration import Configuration
from utils.testdata import TestData
# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "demux.cairo")
MOCK_ADDRESS = 0x0
'''Fix asyncio crash'''


@pytest.fixture(scope="session")
def event_loop():
    return asyncio.get_event_loop()


@pytest.fixture(scope="session")
async def starknet():
    return await Starknet.empty()


@pytest.fixture(scope="session")
async def contract(starknet):
    return await starknet.deploy(source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS],)


@pytest.mark.asyncio
async def test_can_get_a_specific_recipient(contract):
    """Test cam get one specific recipient"""

    # check initially the are no recipients
    execution_info = await contract.get_recipients_number().call()
    assert execution_info.result == (0,)

    # set 1st recipient
    await TestData.set_recipient1(contract).invoke()

    # check we have 1 recipient
    execution_info = await contract.get_recipients_number().call()
    assert execution_info.result == (1,)

    # set 2nd recipient
    await TestData.set_recipient2(contract).invoke()

    # check we have 2 recipients
    execution_info = await contract.get_recipients_number().call()
    assert execution_info.result == (2,)

    # TODO: try to find a better way to check eq!
    # Check the result of get_recipient() for 1st added wallet.
    execution_info = await contract.get_recipient(wallet_number=0).call()

    assert execution_info.result[0][0] == TestData.recipient1.wallet_name
    assert execution_info.result[0][1] == TestData.recipient1.email
    assert execution_info.result[0][2] == TestData.recipient1.address
    assert execution_info.result[0][3] == TestData.recipient1.weight
    assert execution_info.result[0][4] == TestData.recipient1.recuring_period
    assert execution_info.result[0][5] == TestData.recipient1.transaction_delay

    # Check the result of get_recipient() for 1st added wallet.
    execution_info = await contract.get_recipient(wallet_number=1).call()

    assert execution_info.result[0][0] == TestData.recipient2.wallet_name
    assert execution_info.result[0][1] == TestData.recipient2.email
    assert execution_info.result[0][2] == TestData.recipient2.address
    assert execution_info.result[0][3] == TestData.recipient2.weight
    assert execution_info.result[0][4] == TestData.recipient1.recuring_period
    assert execution_info.result[0][5] == TestData.recipient1.transaction_delay


@pytest.mark.asyncio
async def test_multiple_receipients_can_be_added():
    """Test multiple receipients can be added"""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS],
    )

    # check initially the are no recipients
    execution_info = await contract.get_recipients_number().call()
    assert execution_info.result == (0,)

    # set 1st recipient
    await TestData.set_recipient1(contract).invoke()
    # set 2nd recipient
    await TestData.set_recipient1(contract).invoke()

    # Check the result of recipients_number().
    execution_info = await contract.get_recipients_number().call()
    assert execution_info.result == (2,)


@ pytest.mark.asyncio
async def test_set_configuration(contract):
    """Test set_configuration method."""
    # Invoke set_configuration() .
    await contract.set_configuration(
        send_amount=10,
        send_type=1,
        equal_weights=1,
        multi_sig=0,
        expiry_date=10,).invoke()

    # Check the result of get_configuration().
    execution_info = await contract.get_configuration().call()
    assert execution_info.result[0][0] == TestData.newConfiguration.send_amount
    assert execution_info.result[0][1] == TestData.newConfiguration.send_type
    assert execution_info.result[0][2] == TestData.newConfiguration.equal_weights[0]
    assert execution_info.result[0][3] == TestData.newConfiguration.multi_sig
    assert execution_info.result[0][4] == TestData.newConfiguration.expiry_date


@ pytest.mark.asyncio
async def test_is_configuration_set_when_none_of_configuration_and_recipients_are_set():
    """Test is_configuration_set method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS],
    )

    # Check the result of is_configuration_set().
    execution_info = await contract.is_configuration_set().call()
    assert execution_info.result[0] == 0


@ pytest.mark.asyncio
async def test_is_configuration_set_when_recipients_is_set_only():
    """Test is_configuration_set method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS],
    )

    # Check the result of is_configuration_set().
    execution_info = await contract.is_configuration_set().call()
    assert execution_info.result[0] == 0

    # set 1st recipient
    await TestData.set_recipient1(contract).invoke()

    # Check the result of is_configuration_set().
    execution_info = await contract.is_configuration_set().call()
    assert execution_info.result[0] == 0


@ pytest.mark.asyncio
async def test_is_configuration_set_when_configuration_is_set_only():
    """Test is_configuration_set method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS],
    )

    # Check the result of is_configuration_set().
    execution_info = await contract.is_configuration_set().call()
    assert execution_info.result[0] == 0

    # Invoke set_configuration() .
    await contract.set_configuration(
        send_amount=10,
        send_type=1,
        equal_weights=1,
        multi_sig=0,
        expiry_date=10,).invoke()

    # Check the result of is_configuration_set().
    execution_info = await contract.is_configuration_set().call()
    assert execution_info.result[0] == 0


@ pytest.mark.asyncio
async def test_is_configuration_set_when_configuration_and_recipients_are_both_set():
    """Test is_configuration_set method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS],
    )

    # Check the result of is_configuration_set().
    execution_info = await contract.is_configuration_set().call()
    assert execution_info.result[0] == 0

    # Invoke set_configuration() .
    await contract.set_configuration(
        send_amount=10,
        send_type=1,
        equal_weights=1,
        multi_sig=0,
        expiry_date=10,).invoke()

    # set 1st recipient
    await TestData.set_recipient1(contract).invoke()

    # Check the result of is_configuration_set().
    execution_info = await contract.is_configuration_set().call()
    assert execution_info.result[0] == 1


@pytest.mark.asyncio
@pytest.mark.parametrize("input, result", [
    (0, [0, 0]),
    (1, [0, 1]),
    (10, [1, 0, 1, 0]),
    (233, [1, 1, 1, 0, 1, 0, 0, 1]),
    (53978, [1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0]),
    (11209824350, [1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1,
     0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0]),
    (23987543987239487293847234, [1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0,
     1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0]),
])
async def test_decimal_to_binary_conversion(contract, input, result):
    """Test convertDecimalToBinary method."""
    execution_info = await contract.convertDecimalToBinary(decimal_value=input).invoke()
    assert execution_info.result[0] == result


@pytest.mark.asyncio
@pytest.mark.parametrize("input, result", [
    ([0, 0],  1),
    ([1, 0],  0),
    ([1, 5],  1),
    ([5, 1],  0),
    ([0, 4],  1),
])
async def test_compareValues(contract, input, result):
    """Test compareValues method."""
    execution_info = await contract.compareValues(a=input[0], b=input[1]).invoke()
    assert execution_info.result[0] == result
