// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.6.1 (token/erc721/presets/ERC721MintablePausable.cairo)
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.hash import hash2

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.security.pausable.library import Pausable
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.upgrades.library import Proxy

from src.token_uri import append_number_ascii, set_uri_base, read_uri_base
from src.interface.naming import Naming

//
// Constructor
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt, 
    uri_base_len: felt, 
    uri_base: felt*, 
    naming_address: felt,
    expiry: felt
) {
    Ownable.initializer(proxy_admin);
    Proxy.initializer(proxy_admin);
    ERC721.initializer('Stark Tribe NFT', 'TRB');
    set_uri_base(uri_base_len, uri_base);
    naming_contract.write(naming_address);
    min_expiry.write(expiry);

    return ();
}

//
// Storage
//

@storage_var
func _blacklisted(domain: felt, level: felt) -> (is_blacklisted: felt) {
}

@storage_var
func naming_contract() -> (address: felt) {
}

@storage_var
func min_expiry() -> (timestamp: felt) {
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
    let (size) = append_number_ascii(tokenId, arr + arr_len);

    return (arr_len + size, arr);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return Ownable.owner();
}

@view
func paused{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (paused: felt) {
    return Pausable.is_paused();
}

//
// Externals
//

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    Pausable.assert_not_paused();
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    Pausable.assert_not_paused();
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    Pausable.assert_not_paused();
    ERC721.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    Pausable.assert_not_paused();
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*}(
    tokenId: Uint256,
) {
    alloc_locals;
    Pausable.assert_not_paused();

    let (contract) = naming_contract.read();
    let (local caller) = get_caller_address();
    let (domain_len, domain) = Naming.address_to_domain(contract, caller);
    let (hashed_domain) = _hash_domain(domain_len, domain);
    let (_, local token_level) = unsigned_div_rem(tokenId.low, 100);

    with_attr error_message("You already minted with this domain") {
        let (is_blacklisted) = _blacklisted.read(hashed_domain, token_level);
        assert is_blacklisted = 0;
    }

    with_attr error_message("You don't own a domain or a subdomain, you cannot mint an NFT") {
        assert_not_zero(domain_len);
    }

    _assert_token_level(caller, domain_len, domain, token_level);

    ERC721._mint(caller, tokenId);
    _blacklisted.write(hashed_domain, token_level, 1);

    return ();
}

func _assert_token_level{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    caller: felt, 
    domain_len: felt, 
    domain: felt*, 
    token_level: felt
) {
    alloc_locals;
    let (contract) = naming_contract.read();

    if (token_level == 1) {
        with_attr error_message("You don't own a subdomain, you cannot mint an NFT of level 1") {
            assert is_le(1, domain_len) = TRUE;
        }
        return ();
    }

    if (token_level == 2) {
        with_attr error_message("You don't own a root domain, you cannot mint an NFT of level 2") {
            assert domain_len = 1;
        }
        return ();
    }

    if (token_level == 3) {
        with_attr error_message("You don't own a root domain, you cannot mint an NFT of level 3") {
            assert domain_len = 1;
        }
        let (_min_expiry) = min_expiry.read();
        let (expiry) = Naming.domain_to_expiry(contract, domain_len, domain);
        let (block_timestamp) = get_block_timestamp();
        with_attr error_message("Your domain expiry is less than 3 years, you cannot mint an NFT of level 3") {
            assert is_le(_min_expiry, expiry) = TRUE;
        }
        return ();
    }
    return ();
}


func _hash_domain{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    domain_len: felt, domain: felt*
) -> (hash: felt){
    if (domain_len == 2){
        let (hash) = hash2{hash_ptr=pedersen_ptr}(domain[0], domain[1]);
        return (hash,);
    }
    return (domain[0],);
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

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}

@external
func pause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Pausable._pause();
    return ();
}

@external
func unpause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Pausable._unpause();
    return ();
}