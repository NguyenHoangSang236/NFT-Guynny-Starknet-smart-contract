// /// Interface representing `HelloContract`.
// /// This interface allows modification and retrieval of the contract balance.
// #[starknet::interface]
// pub trait IHelloStarknet<TContractState> {
//     /// Increase contract balance.
//     fn increase_balance(ref self: TContractState, amount: u256);
//     /// Retrieve contract balance.
//     fn get_balance(self: @TContractState) -> u256;
// }

// /// Simple contract for managing balance.
// #[starknet::contract]
// mod HelloStarknet {
//     use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
//     use core::num::traits::Zero;

//     #[storage]
//     struct Storage {
//         balance: u256,
//     }

//     #[abi(embed_v0)]
//     impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
//         fn increase_balance(ref self: ContractState, amount: u256) {
//             assert(!amount.is_zero(), 'Amount cannot be 0');
//             self.balance.write(self.balance.read() + amount);
//         }

//         fn get_balance(self: @ContractState) -> u256 {
//             self.balance.read()
//         }
//     }
// }

use starknet::ContractAddress;

#[derive(Drop, Serde, Copy, PartialEq, Hash, Clone)]
struct AttackFigure {
    damage: u256,
    critical_chance: u16,
    life_steal_percentage: u16,
    armor_penetration: u256,
    healing_reduce_percentage: u16,
    aiming_angle: u256,
}

#[derive(Drop, Serde, Copy, PartialEq, Hash)]
struct DefenseFigure {
    armor: u256,
    health_point: u256,
    mana_point: u256,
    cooldown_reduce_percentage: u16,
    dodge_chance: u16,
    healing_speed: u16,
}

#[derive(Drop, Serde, Copy, PartialEq, Hash)]
struct GameItem {
    id: felt252,
    item_id: felt252,
    user_name: felt252,
    selling_price: u256,
    level: u8,
    attack_figure: AttackFigure,
    defense_figure: DefenseFigure,
    owner: ContractAddress,
}

/// Interface representing `GameItemContract`.
#[starknet::interface]
pub trait IGameItemContract<TContractState> {
    /// Create a new game item
    fn create_item(
        ref self: TContractState, 
        id: felt252,
        item_id: felt252,
        user_name: felt252, 
        selling_price: u256, 
        level: u8,
        damage: u256,
        armor: u256,
        critical_chance: u16,
        life_steal_percentage: u16,
        armor_penetration: u256,
        healing_reduce_percentage: u16,
        aiming_angle: u256,
        health_point: u256,
        mana_point: u256,
        cooldown_reduce_percentage: u16,
        dodge_chance: u16,
        healing_speed: u16,
    );
    
    /// Get item information
    fn get_item_info(self: @TContractState, id: felt252) -> GameItem;
    
    /// Change the username of an item
    fn change_username(ref self: TContractState, id: felt252, new_user_name: felt252);
    
    /// Update the selling price of an item
    fn update_selling_price(ref self: TContractState, id: felt252, new_price: u256);
}

/// Game item contract implementation
#[starknet::contract]
mod GameItemContract {
    use starknet::get_caller_address;
    use core::num::traits::Zero;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map};
    use super::{AttackFigure, DefenseFigure, GameItem};

    #[storage]
    struct Storage {
        items: Map<felt252, GameItem>,
        item_exists: Map<felt252, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ItemCreated: ItemCreated,
        UsernameChanged: UsernameChanged,
        PriceUpdated: PriceUpdated,
    }

    #[derive(Drop, starknet::Event)]
    struct ItemCreated {
        id: felt252,
        item_id: felt252,
        user_name: felt252,
        selling_price: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct UsernameChanged {
        id: felt252,
        old_user_name: felt252,
        new_user_name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct PriceUpdated {
        id: felt252,
        old_price: u256,
        new_price: u256,
    }

    #[abi(embed_v0)]
    impl GameItemContractImpl of super::IGameItemContract<ContractState> {
        fn create_item(
            ref self: ContractState,
            id: felt252,
            item_id: felt252,
            user_name: felt252,
            selling_price: u256,
            level: u8,
            damage: u256,
            armor: u256,
            critical_chance: u16,
            life_steal_percentage: u16,
            armor_penetration: u256,
            healing_reduce_percentage: u16,
            aiming_angle: u256,
            health_point: u256,
            mana_point: u256,
            cooldown_reduce_percentage: u16,
            dodge_chance: u16,
            healing_speed: u16,
        ) {
            // Check if item already exists
            assert!(!self.item_exists.entry(id).read(), "Item already exists");
            
            // Create attack and defense figures with extended attributes
            let attack_figure = AttackFigure { 
                damage,
                critical_chance,
                life_steal_percentage,
                armor_penetration,
                healing_reduce_percentage,
                aiming_angle,
            };
            
            let defense_figure = DefenseFigure { 
                armor,
                health_point,
                mana_point,
                cooldown_reduce_percentage,
                dodge_chance,
                healing_speed,
            };
            
            // Get caller address (owner)
            let owner = get_caller_address();
            
            // Create new game item
            let game_item = GameItem {
                id,
                item_id,
                user_name,
                selling_price,
                level,
                attack_figure,
                defense_figure,
                owner,
            };
            
            // Store the item
            self.items.entry(id).write(game_item);
            self.item_exists.entry(id).write(true);
            
            // Emit event
            self.emit(ItemCreated {
                id,
                item_id,
                user_name,
                selling_price,
            });
        }
        
        fn get_item_info(self: @ContractState, id: felt252) -> GameItem {
            // Check if item exists
            assert!(self.item_exists.entry(id).read(), "Item does not exist");
            
            // Return item info
            self.items.entry(id).read()
        }
        
        fn change_username(ref self: ContractState, id: felt252, new_user_name: felt252) {
            // Check if item exists
            assert!(self.item_exists.entry(id).read(), "Item does not exist");
            
            // Get item
            let mut item = self.items.entry(id).read();
            
            // Check if caller is the owner
            let caller = get_caller_address();
            assert!(caller == item.owner, "Only owner can change username");
            
            // Store old username for event
            let old_user_name = item.user_name;
            
            // Update username
            item.user_name = new_user_name;
            
            // Save updated item
            self.items.write(id, item);
            
            // Emit event
            self.emit(UsernameChanged {
                id,
                old_user_name,
                new_user_name,
            });
        }
        
        fn update_selling_price(ref self: ContractState, id: felt252, new_price: u256) {
            // Check if item exists
            assert!(self.item_exists.read(id), "Item does not exist");
            
            // Get item
            let mut item = self.items.read(id);
            
            // Check if caller is the owner
            let caller = get_caller_address();
            assert!(caller == item.owner, "Only owner can update price");
            
            // Store old price for event
            let old_price = item.selling_price;
            
            // Update price
            item.selling_price = new_price;
            
            // Save updated item
            self.items.write(id, item);
            
            // Emit event
            self.emit(PriceUpdated {
                id,
                old_price,
                new_price,
            });
        }
    }
}