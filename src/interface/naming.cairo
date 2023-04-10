%lang starknet

@contract_interface
namespace Naming {
    func domain_to_address(domain_len: felt, domain: felt*) -> (address: felt) {
    }

    func domain_to_expiry(domain_len: felt, domain: felt*) -> (address: felt) {
    }

    func address_to_domain(address: felt) -> (domain_len: felt, domain: felt*) {
    }
}