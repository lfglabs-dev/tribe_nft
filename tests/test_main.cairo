%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_lt_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from src.main import get_tasks_status, mint, _completed_tasks, Task, _starkpath_public_key

@external
func test_get_tasks_status{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    _completed_tasks.write(1, 2, 3, 'a');
    _completed_tasks.write(4, 5, 6, 'b');
    _completed_tasks.write(7, 8, 9, 'c');

    let (len, tasks_status) = get_tasks_status(
        3, cast(new (Task(1, 2, 3), Task(4, 5, 6), Task(7, 8, 9)), Task*)
    );

    assert tasks_status[0] = 'a';
    assert tasks_status[1] = 'b';
    assert tasks_status[2] = 'c';
    return ();
}

@external
func test_mint{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*
}() {
    let token_id = Uint256(1, 0);
    tempvar pub_key;
    tempvar sig_0;
    tempvar sig_1;
    %{
        from starkware.crypto.signature.signature import private_to_stark_key, pedersen_hash, sign
        ids.pub_key = private_to_stark_key(1)
        print(ids.pub_key)
        stop_prank_callable = start_prank(123)
        hashed = pedersen_hash(pedersen_hash(pedersen_hash(pedersen_hash(1, 0), 1), 1), 123)
        sig = sign(hashed, 1)
        ids.sig_0 = sig[0]
        ids.sig_1 = sig[1]
    %}

    _starkpath_public_key.write(pub_key);
    mint(token_id, 1, 1, (sig_0, sig_1));
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
