from starkware.starknet.compiler.compile import \
    get_selector_from_name

print(hex(get_selector_from_name('increase_balance')))
