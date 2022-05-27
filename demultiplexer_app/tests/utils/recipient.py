
class RecipientWallet():
    def __init__(self, _address, _weight, _value):
        self.address = _address
        self.weight = _weight
        self.value = _value

    def __eq__(self, other):
        return self.address == other.address and \
            self.weight == other.weight and \
            self.value == other.navalueme


class Recipient():

    def __init__(self, _name, _email, _recipient_wallet, _recuring_value, _recuring_period, _transaction_delay):
        self.name = _name
        self.email = _email
        self.recipient_wallet = _recipient_wallet
        self.recuring_value = _recuring_value
        self.recuring_period = _recuring_period
        self.transaction_delay = _transaction_delay

    def __eq__(self, other):
        return self.name == other.name and \
            self.email == other.email and \
            self.recipient_wallet == other.recipient_wallet and \
            self.recuring_value == other.recuring_value and \
            self.recuring_period == other.recuring_period and \
            self.transaction_delay == other.transaction_delay
