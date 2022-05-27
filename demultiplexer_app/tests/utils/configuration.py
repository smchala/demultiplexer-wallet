class Configuration():

    def __init__(self, send_amount, send_type, equal_weights, recuring_value, recuring_period, transaction_delay, expiry_date, multi_sig):
        self.send_amount = send_amount
        self.send_type = send_type
        self.recuring_value = recuring_value
        self.recuring_period = recuring_period
        self.equal_weights = equal_weights,
        self.multi_sig = multi_sig
        self.transaction_delay = transaction_delay
        self.expiry_date = expiry_date

    def __eq__(self, other):
        return self.send_amount == other.send_amount and \
            self.send_type == other.send_type and \
            self.recuring_value == other.recuring_value and \
            self.recuring_period == other.recuring_period and \
            self.equal_weights == other.equal_weights and \
            self.multi_sig == other.multi_sig and \
            self.transaction_delay == other.transaction_delay and \
            self.expiry_date == other.expiry_date
