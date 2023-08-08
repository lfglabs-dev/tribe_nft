use array::{ArrayTrait, SpanTrait};
use debug::PrintTrait;
use zeroable::Zeroable;
use traits::Into;
use option::OptionTrait;
use starknet::testing;
use starknet::ContractAddress;

use super::constants::{OWNER, USER, OTHER, PUB_KEY};
use quests_nft_contract::main::{QuestsNftContract, Task};
use quests_nft_contract::interface::nft_contract::{
    IQuestsNftContract, IQuestsNftContractDispatcher, IQuestsNftContractDispatcherTrait
};
use quests_nft_contract::main::QuestsNftContract::{
    ContractState as QuestContractState, InternalTrait, URIImpl
};
use quests_nft_contract::main::QuestsNftContract::{
    _completed_tasksContractStateTrait, _starkpath_public_keyContractStateTrait
};

use openzeppelin::token::erc20::erc20::ERC20;
use openzeppelin::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};
use super::utils;


#[cfg(test)]
fn deploy_contract() -> IQuestsNftContractDispatcher {
    let mut calldata = ArrayTrait::<felt252>::new();
    calldata.append(OWNER().into());
    calldata.append(1);
    calldata.append(1);
    calldata.append(1);
    calldata.append(1);
    calldata.append(PUB_KEY());
    calldata.append('name');
    calldata.append('symbol');

    let address = utils::deploy(QuestsNftContract::TEST_CLASS_HASH, calldata);
    IQuestsNftContractDispatcher { contract_address: address }
}

#[cfg(test)]
#[test]
#[available_gas(200000000)]
fn test_get_tasks_status() {
    let mut main_state = QuestsNftContract::unsafe_new_contract_state();
    main_state._completed_tasks.write((1, 2, OWNER()), true);
    main_state._completed_tasks.write((4, 5, USER()), true);
    main_state._completed_tasks.write((7, 8, OTHER()), true);

    let tasks: Array::<Task> = array![
        Task {
            quest_id: 1, task_id: 2, user_addr: OWNER()
            }, Task {
            quest_id: 4, task_id: 5, user_addr: USER()
            }, Task {
            quest_id: 7, task_id: 8, user_addr: OTHER()
        }
    ];
    let task_status = QuestsNftContract::QuestsNftContractImpl::get_tasks_status(
        @main_state, tasks
    );
    let mut task_status = task_status.span();
    loop {
        if task_status.len() == 0 {
            break;
        }
        let task = task_status.pop_front().unwrap();
        assert(*task, 'should be true');
    };
}

#[cfg(test)]
#[test]
#[available_gas(200000000)]
fn test_mint() {
    let token_id = u256 { low: 1, high: 0 };
    let sig = (
        1094208782730574871620919072430208951490204247775683373909465774551048945387,
        922412600958550550799608278522552089977541350488672097838056058538088123750
    );

    let contract = deploy_contract();

    testing::set_contract_address(USER());
    contract.mint(token_id, 1, 1, sig);
}

