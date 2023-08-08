from starknet_py.hash.storage import get_storage_var_address

uri_base = get_storage_var_address("uri_base")
print("uri_base", uri_base)

contract_uri = get_storage_var_address("contract_uri")
print("contract_uri", contract_uri)