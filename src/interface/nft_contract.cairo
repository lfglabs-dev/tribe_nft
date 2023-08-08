use quests_nft_contract::main::Task;

#[starknet::interface]
trait IQuestsNftContract<TContractState> {
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn balanceOf(self: @TContractState, owner: starknet::ContractAddress) -> u256;
    fn ownerOf(self: @TContractState, token_id: u256) -> starknet::ContractAddress;
    fn getApproved(self: @TContractState, token_id: u256) -> starknet::ContractAddress;
    fn isApprovedForAll(
        self: @TContractState, owner: starknet::ContractAddress, operator: starknet::ContractAddress
    ) -> bool;
    fn tokenURI(self: @TContractState, token_id: u256) -> Array<felt252>;
    fn contractURI(self: @TContractState) -> Array<felt252>;
    // fn owner(self: @TContractState) -> starknet::ContractAddress;
    fn get_tasks_status(self: @TContractState, tasks: Array<Task>) -> Array<bool>;
    // Externals
    fn approve(ref self: TContractState, to: starknet::ContractAddress, token_id: u256);
    fn setApprovalForAll(
        ref self: TContractState, operator: starknet::ContractAddress, approved: bool
    );
    fn transferFrom(
        ref self: TContractState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        token_id: u256
    );
    fn safeTransferFrom(
        ref self: TContractState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        tokenId: u256,
        data: Span<felt252>
    );
    fn mint(
        ref self: TContractState,
        token_id: u256,
        quest_id: felt252,
        task_id: felt252,
        sig: (felt252, felt252)
    );
    fn setTokenURI(ref self: TContractState, arr: Array<felt252>);
    fn setContractURI(ref self: TContractState, arr: Array<felt252>);
    fn setContractName(ref self: TContractState, full_name: felt252, short_name: felt252);
}
