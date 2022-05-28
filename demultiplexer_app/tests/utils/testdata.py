from utils.recipient import Recipient, RecipientWallet
from utils.configuration import Configuration


class TestData():
    # test data
    newConfiguration: Configuration = Configuration(
        send_amount=10,
        send_type=1,
        equal_weights=1,
        multi_sig=0,
        expiry_date=10,
    )

    # test data
    recipient_wallet_1 = RecipientWallet(
        0x032e7f10731ed079ed5a6678ab95e4f90ff23391890a140426d723ad82e62bdd, 1)
    recipient1 = Recipient(0x736d6368616c6140686f746d61696c2e636f6d,
                           0x73616d69406f747373736f2e636f6d, recipient_wallet_1, 0, 0, 0)

    # test data
    recipient_wallet_2 = RecipientWallet(
        0x045e7f10731ed079ed5a6678ab95e4f90ff23391890a140426d723ad82e62bdd, 1)
    recipient2 = Recipient(0x736d6368616c6140686636f6d,
                           0x73616d69406f747373736f2e636f6d, recipient_wallet_2, 0, 0, 0)

    def get_recipient1(contract):
        return contract.set_recipients(
            wallet_name=0x736d6368616c6140686f746d61696c2e636f6d,
            email=0x73616d69406f747373736f2e636f6d,
            address=0x032e7f10731ed079ed5a6678ab95e4f90ff23391890a140426d723ad82e62bdd,
            weight=1,
            recuring_value=0,
            recuring_period=0,
            transaction_delay=0,
        )

    def get_recipient2(contract):
        return contract.set_recipients(
            wallet_name=0x736d6368616c6140686636f6d,
            email=0x73616d69406f747373736f2e636f6d,
            address=0x045e7f10731ed079ed5a6678ab95e4f90ff23391890a140426d723ad82e62bdd,
            weight=1,
            recuring_value=0,
            recuring_period=0,
            transaction_delay=0,
        )
