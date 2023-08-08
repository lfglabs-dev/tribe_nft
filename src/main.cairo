#[derive(Serde, Copy, Drop, starknet::storage)]
struct Task {
    quest_id: felt252,
    task_id: felt252,
    user_addr: starknet::ContractAddress,
}

const URI_BASE_ADDR: felt252 =
    1209266896997105415752213740415541078936357741217049083484599104239755899928;
const CONTRACT_URI_ADDR: felt252 =
    1704559202763558178936526706922296156604440700745597723280658905842564602180;

#[starknet::contract]
mod QuestsNftContract {
    use array::{SpanTrait, ArrayTrait};
    use openzeppelin::token::erc721::interface;
    use openzeppelin::token::erc721::erc721::ERC721;
    use openzeppelin::introspection::src5::SRC5;
    // use openzeppelin::access::ownable::ownable::Ownable;
    // use openzeppelin::access::ownable::interface::IOwnable;
    use option::OptionTrait;
    use traits::Into;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;
    use integer::{u256_safe_divmod, u256_as_non_zero};
    use ecdsa::check_ecdsa_signature;
    use starknet::StorageBaseAddress;

    use debug::PrintTrait;

    use super::Task;
    use quests_nft_contract::interface::uri::IURI;
    use quests_nft_contract::interface::nft_contract::IQuestsNftContract;
    use super::{URI_BASE_ADDR, CONTRACT_URI_ADDR};
    use quests_nft_contract::utils::append_number_ascii;

    #[storage]
    struct Storage {
        _starkpath_public_key: felt252,
        _completed_tasks: LegacyMap<(felt252, felt252, ContractAddress), bool>,
        // URI
        uri_base: LegacyMap<felt252, felt252>,
        contract_uri: LegacyMap<felt252, felt252>,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        proxy_admin: ContractAddress,
        token_uri_base_arr: Array::<felt252>,
        contract_uri_arr: Array::<felt252>,
        starkpath_public_key: felt252,
        full_name: felt252,
        short_name: felt252
    ) {
        self
            .initializer(
                proxy_admin,
                token_uri_base_arr,
                contract_uri_arr,
                starkpath_public_key,
                full_name,
                short_name
            );
    }

    //
    // External
    //

    #[external(v0)]
    impl QuestsNftContractImpl of IQuestsNftContract<ContractState> {
        //
        // Getters
        // 
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::SRC5Impl::supports_interface(@unsafe_state, interface_id)
        }

        fn name(self: @ContractState) -> felt252 {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721MetadataImpl::name(@unsafe_state)
        }

        fn symbol(self: @ContractState) -> felt252 {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721MetadataImpl::symbol(@unsafe_state)
        }

        fn balanceOf(self: @ContractState, owner: ContractAddress) -> u256 {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::balance_of(@unsafe_state, owner)
        }

        fn ownerOf(self: @ContractState, token_id: u256) -> ContractAddress {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::owner_of(@unsafe_state, token_id)
        }

        fn getApproved(self: @ContractState, token_id: u256) -> ContractAddress {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::get_approved(@unsafe_state, token_id)
        }

        fn isApprovedForAll(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::is_approved_for_all(@unsafe_state, owner, operator)
        }

        fn tokenURI(self: @ContractState, token_id: u256) -> Array<felt252> {
            let mut arr = self.read_array(URI_BASE_ADDR, 0);

            let (_, token_level, _) = u256_safe_divmod(
                token_id, u256_as_non_zero(u256 { low: 100, high: 0 })
            );
            let size = append_number_ascii(token_level, ref arr);
            arr
        }

        fn contractURI(self: @ContractState) -> Array<felt252> {
            self.read_array(CONTRACT_URI_ADDR, 0)
        }

        fn get_tasks_status(self: @ContractState, tasks: Array<Task>) -> Array<bool> {
            if tasks.len() == 0 {
                return array![];
            }

            let mut tasks = tasks.span();
            let mut res = array![];
            loop {
                if tasks.len() == 0 {
                    break;
                }
                let current_task = tasks.pop_front().expect('error in get_tasks_status');
                let is_completed = self
                    ._completed_tasks
                    .read((*current_task.quest_id, *current_task.task_id, *current_task.user_addr));
                res.append(is_completed);
            };
            res
        }

        //
        // Externals
        //

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::approve(ref unsafe_state, to, token_id)
        }

        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::set_approval_for_all(ref unsafe_state, operator, approved)
        }

        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::transfer_from(ref unsafe_state, from, to, token_id)
        }

        fn safeTransferFrom(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            tokenId: u256,
            data: Span<felt252>
        ) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::safe_transfer_from(ref unsafe_state, from, to, tokenId, data)
        }

        fn mint(
            ref self: ContractState,
            token_id: u256,
            quest_id: felt252,
            task_id: felt252,
            sig: (felt252, felt252)
        ) {
            let caller = get_caller_address();

            // we don't need to check NFT type, it was generated by server
            // get NFT type
            let (_, nft_type_uint, _) = u256_safe_divmod(
                token_id, u256_as_non_zero(u256 { low: 100, high: 0 })
            );
            // _uint256_to_felt(level_uint) from tests would be necessary for divisor > 2**128
            // let nft_type = nft_type_uint.low;
            // bind user, quest and reward together
            let hashed: felt252 = hash::LegacyHash::hash(
                hash::LegacyHash::hash(
                    hash::LegacyHash::hash(
                        hash::LegacyHash::<felt252>::hash(
                            token_id.low.into(), token_id.high.into()
                        ),
                        quest_id
                    ),
                    task_id
                ),
                caller
            );

            // ensure the mint has been whitelisted by starkpath
            let starkpath_public_key = self._starkpath_public_key.read();
            let (sig_r, sig_s) = sig;
            let is_valid = check_ecdsa_signature(hashed, starkpath_public_key, sig_r, sig_s);
            assert(is_valid, 'Invalid signature');

            // check if this task has been completed
            let is_blacklisted = self._completed_tasks.read((quest_id, task_id, caller));
            assert(!is_blacklisted, 'Invalid signature');

            // blacklist that reward
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::_mint(ref unsafe_state, caller, token_id);
            self._completed_tasks.write((quest_id, task_id, caller), true);
        }

        fn setTokenURI(ref self: ContractState, arr: Array<felt252>) {
            // assert admin 
            self.set_array(URI_BASE_ADDR, arr.span());
        }

        fn setContractURI(ref self: ContractState, arr: Array<felt252>) {
            // assert admin 
            self.set_array(CONTRACT_URI_ADDR, arr.span());
        }

        fn setContractName(ref self: ContractState, full_name: felt252, short_name: felt252) {
            // assert admin 
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::initializer(ref unsafe_state, full_name, short_name);
        }
    }

    //
    // URI impl
    //

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

    //
    // Ownable impl
    //

    // #[external(v0)]
    // impl IOwnableImpl of ownable::IOwnable<ContractState> {
    //     fn owner(self: @ContractState) -> ContractAddress {
    //         let ownable_self = Ownable::unsafe_new_contract_state();

    //         ownable_self.owner()
    //     }

    //     fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
    //         let mut ownable_self = Ownable::unsafe_new_contract_state();

    //         ownable_self.transfer_ownership(:new_owner);
    //     }

    //     fn renounce_ownership(ref self: ContractState) {
    //         let mut ownable_self = Ownable::unsafe_new_contract_state();

    //         ownable_self.renounce_ownership();
    //     }
    // }

    //
    // Internal
    //

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(
            ref self: ContractState,
            proxy_admin: ContractAddress,
            token_uri_base: Array::<felt252>,
            contract_uri_arr: Array<felt252>,
            starkpath_public_key: felt252,
            full_name: felt252,
            short_name: felt252
        ) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::initializer(ref unsafe_state, full_name, short_name);
            self._starkpath_public_key.write(starkpath_public_key);
            self.set_array(URI_BASE_ADDR, token_uri_base.span());
            self.set_array(CONTRACT_URI_ADDR, contract_uri_arr.span());
        }
    }

    //
    // Internal URI
    //

    #[generate_trait]
    impl InternalURIImpl of InternalURITrait {
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
