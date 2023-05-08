// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.6.1 (token/erc721/presets/ERC721MintablePausable.cairo)
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.uint256 import uint256_unsigned_div_rem
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.upgrades.library import Proxy

from src.token_uri import append_number_ascii, set_uri_base, read_uri_base
from src.interface.naming import Naming

struct Task {
    quest_id: felt,
    task_id: felt,
    user_addr: felt,
}

//
// Constructor
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt, uri_base_len: felt, uri_base: felt*, starkpath_public_key, full_name, short_name
) {
    Proxy.initializer(proxy_admin);
    ERC721.initializer(full_name, short_name);
    _starkpath_public_key.write(starkpath_public_key);
    set_uri_base(uri_base_len, uri_base);
    return ();
}

//
// Storage
//

@storage_var
func _completed_tasks(quest_id, task_id, user_addr) -> (is_blacklisted: felt) {
}

@storage_var
func _starkpath_public_key() -> (starkpath_public_key: felt) {
}

//
// Getters
//

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    return ERC721.name();
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    return ERC721.symbol();
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    return ERC721.balance_of(owner);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    return ERC721.owner_of(tokenId);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    return ERC721.get_approved(tokenId);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (approved: felt) {
    return ERC721.is_approved_for_all(owner, operator);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (tokenURI_len: felt, tokenURI: felt*) {
    alloc_locals;

    let (arr_len, arr) = read_uri_base(0);
    let (_, token_level) = uint256_unsigned_div_rem(tokenId, Uint256(100, 0));
    let (size) = append_number_ascii(token_level, arr + arr_len);

    return (arr_len + size, arr);
}

@view
func get_tasks_status{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tasks_len, tasks: Task*
) -> (status_len: felt, status: felt*) {
    alloc_locals;
    if (tasks_len == 0) {
        let (status: felt*) = alloc();
        return (0, status);
    }

    local next_tasks_length = tasks_len - 1;
    let (status_len: felt, status: felt*) = get_tasks_status(next_tasks_length, tasks);
    let current_task = tasks[next_tasks_length];
    let (is_completed) = _completed_tasks.read(
        current_task.quest_id, current_task.task_id, current_task.user_addr
    );
    assert status[next_tasks_length] = is_completed;
    return (status_len + 1, status);
}

//
// Externals
//

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    ERC721.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func mint{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}(tokenId: Uint256, quest_id, task_id, sig: (felt, felt)) {
    alloc_locals;

    let (local caller) = get_caller_address();

    // we don't need to check NFT type, it was generated by server
    // // get NFT type
    // let (_, local nft_type_uint) = uint256_unsigned_div_rem(tokenId, Uint256(100, 0));
    // // _uint256_to_felt(level_uint) from tests would be necessary for divisor > 2**128
    // let nft_type = nft_type_uint.low;

    // bind user, quest and reward together
    let (hashed) = hash2{hash_ptr=pedersen_ptr}(tokenId.low, tokenId.high);
    let (hashed) = hash2{hash_ptr=pedersen_ptr}(hashed, quest_id);
    let (hashed) = hash2{hash_ptr=pedersen_ptr}(hashed, task_id);
    let (hashed) = hash2{hash_ptr=pedersen_ptr}(hashed, caller);

    // ensure the mint has been whitelisted by starkpath
    let (starkpath_public_key) = _starkpath_public_key.read();
    verify_ecdsa_signature(hashed, starkpath_public_key, sig[0], sig[1]);

    // check if this task has been completed
    let (is_blacklisted) = _completed_tasks.read(quest_id, task_id, caller);
    assert is_blacklisted = FALSE;

    // blacklist that reward
    ERC721._mint(caller, tokenId);
    _completed_tasks.write(quest_id, task_id, caller, TRUE);

    return ();
}

//
// Admin
//
@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

@external
func setTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    arr_len: felt, arr: felt*
) {
    Proxy.assert_only_admin();
    set_uri_base(arr_len, arr);
    return ();
}
