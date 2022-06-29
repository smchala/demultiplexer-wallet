"""demux.cairo test file."""
import os
from turtle import clear

import pytest
import asyncio
import logging
from typing import Optional
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.business_logic.state.state import BlockInfo
# from starkware.starknet.services.api.contract_definition import ContractDefinition
from starkware.starknet.compiler.compile import compile_starknet_files
from utils.testdata import TestData

# ////////////////////////////////////////////////////////////////////////////////

CONTRACT_FILE = os.path.join("contracts", "demux.cairo")
PATH = "/Users/samimchala/Documents/projects/PiggyCubeStartUp/IP/code/back end/demultiplexer-wallet/demultiplexer_app/contracts/demux.cairo"
MOCK_ADDRESS = 0x01234

# # ////////////////////////////////////////////////////////////////////////////////


@pytest.fixture(scope="session")
def event_loop():
    return asyncio.get_event_loop()


@pytest.fixture(scope="session")
async def starknet():
    return await Starknet.empty()


@pytest.fixture(scope="session")
async def contract(starknet):
    return await starknet.deploy(source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS])


# # ////////////////////////////////////////////////////////////////////////////////

# @pytest.fixture(scope="session")
def update_starknet_block(starknet, block_number=1, block_timestamp=1666672635, sequencer_address=0):
    starknet.state.state.block_info = BlockInfo(
        block_number=block_number,
        block_timestamp=block_timestamp,
        gas_price=0,
        sequencer_address=sequencer_address
    )


@pytest.fixture(scope="session")
def block_info_mock(starknet):
    class Mock:
        def __init__(self, current_block_info: BlockInfo):
            self.block_info = current_block_info

        def update(self, block_number: int, block_timestamp: int, gas_price: int = 0, sequencer_address: Optional[int] = None):
            starknet.state.state.block_info = BlockInfo(
                block_number, block_timestamp, gas_price, sequencer_address)

        def reset(self):
            starknet.state.state.block_info = self.block_info

        def set_block_number(self, block_number):
            starknet.state.state.block_info = BlockInfo(
                block_number,
                self.block_info.block_timestamp,
                self.block_info.gas_price,
                self.block_info.sequencer_address
            )

        def set_mock_block_timestamp(self):
            starknet.state.state.block_info = BlockInfo(
                self.block_info.block_number,
                1666672635,
                self.block_info.gas_price,
                self.block_info.sequencer_address
            )

        def set_gas_price(self, gas_price: int):
            starknet.state.state.block_info = BlockInfo(
                self.block_info.block_number,
                self.block_info.block_timestamp,
                gas_price,
                self.block_info.sequencer_address
            )

        def set_sequencer_address(self, sequencer_address: int):
            starknet.state.state.block_info = BlockInfo(
                self.block_info.block_number,
                self.block_info.block_timestamp,
                self.block_info.gas_price,
                sequencer_address
            )

    return Mock(starknet.state.state.block_info)

# # # ////////////////////////////////////////////////////////////////////////////////


@pytest.mark.asyncio
async def test_can_get_a_specific_recipient():
    """Test can get one specific recipient"""

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
    assert execution_info.result[0][6] == TestData.recipient1.ready_to_send

    # Check the result of get_recipient() for 1st added wallet.
    execution_info = await contract.get_recipient(wallet_number=1).call()

    assert execution_info.result[0][0] == TestData.recipient2.wallet_name
    assert execution_info.result[0][1] == TestData.recipient2.email
    assert execution_info.result[0][2] == TestData.recipient2.address
    assert execution_info.result[0][3] == TestData.recipient2.weight
    assert execution_info.result[0][4] == TestData.recipient2.recuring_period
    assert execution_info.result[0][5] == TestData.recipient2.transaction_delay
    assert execution_info.result[0][6] == TestData.recipient2.ready_to_send


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
    await TestData.set_recipient2(contract).invoke()

    # Check the result of recipients_number().
    execution_info = await contract.get_recipients_number().call()
    assert execution_info.result == (2,)


@ pytest.mark.asyncio
async def test_set_configuration():
    """Test set_configuration method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS],
    )
    # Invoke set_configuration() .
    await contract.set_configuration(
        send_amount=10,
        send_type=1,
        equal_weights=1,
        multi_sig=0,
        expiry_date=10,
    ).invoke()

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
        expiry_date=10,
    ).invoke()

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
        expiry_date=10,
    ).invoke()

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
async def test_decimal_to_binary_conversion(input, result):
    """Test convertDecimalToBinary method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS],
    )
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
async def test_compareValues(input, result):
    """Test compareValues method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS],
    )
    execution_info = await contract.compareValues(a=input[0], b=input[1]).invoke()
    assert execution_info.result[0] == result


@pytest.mark.asyncio
async def test_isTransactionReady():
    """Test isTransactionReady method. check 2 recipients transaction_delay with 1 set in the past and 1 in the future"""
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS],
    )
    # set 1st recipient with an older timestamp: 1646672635
    update_starknet_block(starknet)
    # set 1st recipient
    await TestData.set_recipient1(contract).invoke()

    # # set 2nd recipient
    await TestData.set_recipient2(contract).invoke()

    # Check the result of recipients_number().
    execution_info = await contract.get_recipients_number().call()
    assert execution_info.result == (2,)

    # Check the result of get_recipient(). is the correct transaction_delay for recipient1
    execution_info = await contract.get_recipient(0).call()
    assert execution_info.result[0][5] == 1646672635

    # Check the result of get_recipient(). is the correct transaction_delay for recipient2
    execution_info = await contract.get_recipient(1).call()
    assert execution_info.result[0][5] == 1686672635

    execution_info = await contract.is_transaction_ready(0).invoke()
    assert execution_info.result[0] == 1  # ready to send!

    execution_info = await contract.is_transaction_ready(1).invoke()
    assert execution_info.result[0] == 0  # not ready to send!


@pytest.mark.asyncio
async def test_get_transaction_delay():
    """Test get_transaction_delay method. """
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS],
    )

    # set 1st recipient
    await TestData.set_recipient1(contract).invoke()
    # set 2nd recipient
    await TestData.set_recipient2(contract).invoke()

    # Check the result of recipients_number().
    recipient_number = await contract.get_recipients_number().call()
    assert recipient_number.result == (2,)

    execution_info = await contract.get_recipient(wallet_number=0).call()
    assert execution_info.result[0][5] == TestData.recipient1.transaction_delay

    execution_info = await contract.get_recipient(wallet_number=1).call()
    assert execution_info.result[0][5] == TestData.recipient2.transaction_delay

    await contract.traverse_recipients_map(2).invoke()
    execution_info = await contract.get_transaction_delay(0).invoke()
    assert execution_info.result[0] == 1646672635

    execution_info = await contract.get_transaction_delay(1).invoke()
    assert execution_info.result[0] == 1686672635


@pytest.mark.asyncio
async def test_get_transactions_delay():
    """Test get_transaction_delay method, check if transactions are ready. """
    starknet = await Starknet.empty()

    # # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE, constructor_calldata=[MOCK_ADDRESS],
    )
    update_starknet_block(starknet)
    # set 1st recipient
    await TestData.set_recipient1(contract).invoke()

    # # set 2nd recipient
    await TestData.set_recipient2(contract).invoke()

    recipient_number = await contract.get_recipients_number().call()
    assert recipient_number.result == (2,)

    execution_info = await contract.get_recipient(wallet_number=0).call()
    assert execution_info.result[0][5] == TestData.recipient1.transaction_delay

    execution_info = await contract.get_recipient(wallet_number=1).call()
    assert execution_info.result[0][5] == TestData.recipient2.transaction_delay

    await contract.checkTransactions(2).invoke()
    execution_info = await contract.is_transaction_ready(0).invoke()
    assert execution_info.result[0] == 1

    execution_info = await contract.is_transaction_ready(1).invoke()
    assert execution_info.result[0] == 0
