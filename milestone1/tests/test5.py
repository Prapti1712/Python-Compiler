class Account:
    def __init__(self, account_number: str, balance: float):
        self.account_number = account_number
        self.balance = balance
    def deposit(self, amount: float):
        self.balance += amount
    def withdraw(self, amount: float):
        if amount <= self.balance:
            self.balance -= amount
        else:
            print("Insufficient funds")
    def get_balance(self) -> float:
        return self.balance
class Transaction:
    def __init__(self, sender: str, receiver: str, amount: float):
        self.sender = sender
        self.receiver = receiver
        self.amount = amount
class Bank:
    def __init__(self):
        self.accounts = {}
        self.transactions = []
    def create_account(self, account_number: str, initial_balance: float):
        if account_number not in self.accounts:
            self.accounts[account_number] = Account(account_number, initial_balance)
        else:
            print("Account already exists")
    def make_transaction(self, sender: str, receiver: str, amount: float):
        if sender in self.accounts and receiver in self.accounts:
            if self.accounts[sender].balance >= amount:
                self.accounts[sender].withdraw(amount)
                self.accounts[receiver].deposit(amount)
                self.transactions.append(Transaction(sender, receiver, amount))
            else:
                print("Sender has insufficient funds")
        else:
            print("Invalid sender or receiver account number")
    def get_account_balance(self, account_number: str) -> float:
        if account_number in self.accounts:
            return self.accounts[account_number].get_balance()
        else:
            print("Account not found")
            return 0.0
    def get_transactions(self) -> list[Transaction]:
        return self.transactions


def main():
    bank = Bank()
    bank.create_account("123456", 1000.0)
    bank.create_account("789012", 500.0)
    bank.make_transaction("123456", "789012", 200.0)
    bank.make_transaction("123456", "789012", 900.0)
    bank.make_transaction("789012", "123456", 300.0)
    print("Account balance 123456:", bank.get_account_balance("123456"))
    print("Account balance 789012:", bank.get_account_balance("789012"))
    transactions = bank.get_transactions()
    print("Transactions:")
    for transaction in transactions:
        print("Sender:", transaction.sender)

if __name__ == "__main__":
    main()
