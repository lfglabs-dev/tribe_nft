%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.uint256 import Uint256
from src.main import _hash_domain, _assert_token_level, _uint256_to_felt


@external
func test_hash_domain{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (hash_root) = _hash_domain(1, cast(new('123'), felt*));
    assert hash_root = '123';

    let (hash_subdomain) = _hash_domain(2, cast(new('123', '456'), felt*));
    let (expected_res) = hash2{hash_ptr=pedersen_ptr}('123', '456');
    assert hash_subdomain = expected_res;
    
    return ();
}

@external
func test_uint256_to_felt{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    let res = _uint256_to_felt(Uint256(1, 0));
    assert res = 1;

    return ();
}