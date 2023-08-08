#[starknet::contract]
mod URI {
    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use traits::Into;
    use starknet::StorageBaseAddress;
    use integer::{u256_safe_divmod, u256_as_non_zero, u256_from_felt252};
    use quests_nft_contract::interface::uri::IURI;

    const URI_BASE_ADDR: felt252 =
        1209266896997105415752213740415541078936357741217049083484599104239755899928;
    const CONTRACT_URI_ADDR: felt252 =
        1704559202763558178936526706922296156604440700745597723280658905842564602180;

    #[storage]
    struct Storage {
        uri_base: LegacyMap<felt252, felt252>,
        contract_uri: LegacyMap<felt252, felt252>,
    }

    #[external(v0)]
    impl URIImpl of IURI<ContractState> {
        fn set_array(ref self: ContractState, fn_name: felt252, value: Span<felt252>) {
            let mut value = value;
            let mut index = 0;
            loop {
                if value.len() == 0 {
                    break ();
                }
                let base = self._compute_base_address(URI_BASE_ADDR, index);
                let address_domain = 0;
                let val = value.pop_front().expect('error getting value');
                self._set(address_domain, base, *val + 1, 0_u8);
                index += 1;
            };
        }

        fn read_array(self: @ContractState, fn_name: felt252, i: felt252) -> Array<felt252> {
            let address_domain = 0;
            let mut value = ArrayTrait::new();
            let mut i = i;
            loop {
                let base = self._compute_base_address(fn_name, i);
                let val = self._get(address_domain, base, 0_u8);
                if val == 0 {
                    break ();
                }
                value.append(val - 1);
                i += 1;
            };
            value
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _compute_base_address(
            self: @ContractState, fn_name: felt252, param: felt252
        ) -> StorageBaseAddress {
            let mut hash: felt252 = hash::LegacyHash::<felt252>::hash(fn_name, param);
            starknet::storage_base_address_from_felt252(hash)
        }

        fn _set(
            ref self: ContractState,
            address_domain: u32,
            base: starknet::StorageBaseAddress,
            value: felt252,
            offset: u8
        ) {
            starknet::storage_write_syscall(
                address_domain, starknet::storage_address_from_base_and_offset(base, offset), value
            );
        }

        fn _get(
            self: @ContractState,
            address_domain: u32,
            base: starknet::StorageBaseAddress,
            offset: u8,
        ) -> felt252 {
            starknet::storage_read_syscall(
                address_domain, starknet::storage_address_from_base_and_offset(base, offset)
            )
                .unwrap_syscall()
        }
    }
}
