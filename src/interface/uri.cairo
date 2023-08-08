#[starknet::interface]
trait IURI<TContractState> {
    fn set_array(ref self: TContractState, fn_name: felt252, value: Span<felt252>);
    fn read_array(self: @TContractState, fn_name: felt252, i: felt252) -> Array<felt252>;
}
