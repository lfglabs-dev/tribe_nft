%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_unsigned_div_rem
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.invoke import invoke
from starkware.starknet.common.syscalls import storage_read, storage_write

// token_uri
@storage_var
func uri_base(char_id: felt) -> (ascii_code: felt) {
}

@storage_var
func contract_uri(char_id: felt) -> (ascii_code: felt) {
}

func _compute_addr{pedersen_ptr: HashBuiltin*, range_check_ptr}(
    storage_var: codeoffset, len_inputs: felt, inputs: felt*
) -> (addr: felt) {
    alloc_locals;
    let (local func_pc) = get_label_location(storage_var);
    _prepare_call(pedersen_ptr, range_check_ptr, len_inputs, inputs + len_inputs);
    call abs func_pc;
    ret;
}

func _prepare_call(
    pedersen_ptr: HashBuiltin*, range_check_ptr, inputs_len: felt, inputs: felt*
) -> () {
    if (inputs_len == 0) {
        [ap] = pedersen_ptr, ap++;
        [ap] = range_check_ptr, ap++;
        return ();
    }
    _prepare_call(pedersen_ptr, range_check_ptr, inputs_len - 1, inputs - 1);
    [ap] = [inputs - 1], ap++;
    return ();
}

func set_array{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    storage_var: codeoffset, arr_len: felt, arr: felt*
) {
    alloc_locals;
    if (arr_len == 0) {
        return ();
    }
    local next_arr_len = arr_len - 1;
    let (addr) = _compute_addr(storage_var, 1, new (next_arr_len));
    let value = 1 + arr[next_arr_len];
    storage_write(addr, value);

    return set_array(storage_var, next_arr_len, arr);
}

func read_array{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    storage_var: codeoffset, i
) -> (arr_len: felt, arr: felt*) {
    alloc_locals;
    let (addr) = _compute_addr(storage_var, 1, new (i));
    let (value) = storage_read(addr);
    if (value == 0) {
        let (arr) = alloc();
        return (0, arr);
    }
    let (arr_len, arr) = read_array(storage_var, i + 1);
    assert arr[i] = value - 1;
    return (arr_len + 1, arr);
}

func append_number_ascii{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    num: Uint256, arr: felt*
) -> (added_len: felt) {
    alloc_locals;
    local ten: Uint256 = Uint256(10, 0);
    let (q: Uint256, r: Uint256) = uint256_unsigned_div_rem(num, ten);
    let digit = r.low + 48;  // ascii

    if (q.low == 0 and q.high == 0) {
        assert arr[0] = digit;
        return (1,);
    }

    let (added_len) = append_number_ascii(q, arr);
    assert arr[added_len] = digit;
    return (added_len + 1,);
}
