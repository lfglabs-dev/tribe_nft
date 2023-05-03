%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_lt_felt

@external
func test_hash_domain{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    return ();
}

func _uint256_to_felt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    val: Uint256
) -> felt {
    assert_lt_felt(val.high, 2 ** 123);
    return val.high * (2 ** 128) + val.low;
}

@external
func test_uint256_to_felt{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let res = _uint256_to_felt(Uint256(1, 0));
    assert res = 1;

    return ();
}
