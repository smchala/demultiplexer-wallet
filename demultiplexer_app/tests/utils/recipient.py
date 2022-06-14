class Recipient():

    def __init__(self, _wallet_name, _email, _address, _weight, _recuring_period, _transaction_delay, _ready_to_send,
                 ):
        self.wallet_name = _wallet_name
        self.email = _email
        self.address = _address
        self.weight = _weight
        self.recuring_period = _recuring_period
        self.transaction_delay = _transaction_delay
        self.ready_to_send = _ready_to_send

    def __eq__(self, other):
        return self.wallet_name == other.wallet_name and \
            self.email == other.email and \
            self.address == other.address and \
            self.weight == other.weight and \
            self.recuring_period == other.recuring_period and \
            self.transaction_delay == other.transaction_delay and \
            self.ready_to_send == other.ready_to_send
