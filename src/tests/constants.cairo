fn OWNER() -> starknet::ContractAddress {
    starknet::contract_address_const::<10>()
}

fn OTHER() -> starknet::ContractAddress {
    starknet::contract_address_const::<20>()
}

fn USER() -> starknet::ContractAddress {
    starknet::contract_address_const::<123>()
}

fn ZERO() -> starknet::ContractAddress {
    Zeroable::zero()
}

fn ENCODED_NAME() -> felt252 {
    1426911989
}

fn OTHER_NAME() -> felt252 {
    1234567890
}

fn BLOCK_TIMESTAMP() -> u64 {
    103374042_u64
}

fn WL_CLASS_HASH() -> felt252 {
    11111
}

fn OTHER_WL_CLASS_HASH() -> felt252 {
    222222
}

fn CLASS_HASH_ZERO() -> starknet::ClassHash {
    starknet::class_hash_const::<0>()
}

fn NEW_CLASS_HASH() -> starknet::ClassHash {
    starknet::class_hash_const::<10>()
}

fn PUB_KEY() -> felt252 {
    1095623355248375262820959622846165753592095890967336187639500777460596474969
}
