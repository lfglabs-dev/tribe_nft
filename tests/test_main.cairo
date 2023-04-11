%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.uint256 import Uint256
from src.main import _hash_domain, _assert_token_level, _uint256_to_felt


@external
func test_hash_domain{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let (hash_root) = _hash_domain(1, cast(new('test'), felt*));
    let (expected) = hash2{hash_ptr=pedersen_ptr}('test', 0);
    assert hash_root = expected;

    let (hash_subdomain) = _hash_domain(2, cast(new('123', 'test'), felt*));
    let (rec) = hash2{hash_ptr=pedersen_ptr}('123', 0);
    let (expected_sub) = hash2{hash_ptr=pedersen_ptr}('test', rec);
    assert hash_subdomain = expected_sub;
    
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