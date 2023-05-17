%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_lt_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from src.token_uri import _compute_addr, set_array, read_array
from src.main import tokenURI, setTokenURI

@storage_var
func test(a: felt) -> (b: felt) {
}

@external
func test_read_write{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    set_array(test.addr, 3, new (1, 2, 3));

    let (length, toto) = read_array(test.addr, 0);
    assert length = 3;
    assert toto[0] = 1;
    assert toto[1] = 2;
    assert toto[2] = 3;

    return ();
}
