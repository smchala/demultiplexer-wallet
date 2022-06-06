from starkware.starknet.compiler.compile import \
    get_selector_from_name

print('increase_balance:')
print(hex(get_selector_from_name('increase_balance')))
print('balanceOf:')
print(hex(get_selector_from_name('balanceOf')))
