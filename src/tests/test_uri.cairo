use array::{ArrayTrait, SpanTrait};
use debug::PrintTrait;
use zeroable::Zeroable;
use traits::Into;
use option::OptionTrait;
use starknet::testing;

use quests_nft_contract::uri::URI;
use quests_nft_contract::uri::URI::{ContractState as URIContractState, InternalTrait, URIImpl};
// import storage var from contract
use quests_nft_contract::uri::URI::uri_baseContractStateTrait;

const URI_BASE_ADDR: felt252 =
    1209266896997105415752213740415541078936357741217049083484599104239755899928;
const CONTRACT_URI_ADDR: felt252 =
    1704559202763558178936526706922296156604440700745597723280658905842564602180;

#[cfg(test)]
#[test]
#[available_gas(200000000)]
fn test_set_read_array_uri() {
    let mut uri: URIContractState = URI::unsafe_new_contract_state();
    URI::URIImpl::set_array(ref uri, URI_BASE_ADDR, array![10, 20, 30].span());

    let name_read = URI::URIImpl::read_array(@uri, URI_BASE_ADDR, 0);
    let mut name_read = name_read.span();
    let mut index = 10;
    loop {
        if name_read.len() == 0 {
            break;
        }
        let val = name_read.pop_front().unwrap();
        let val = *val;
        assert(val == index, 'wrong value');
        index += 10;
    };
}
