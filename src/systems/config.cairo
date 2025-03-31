use lyricsflip::constants::Genre;
use starknet::ContractAddress;

#[starknet::interface]
pub trait IGameConfig<TContractState> {
    //TODO
    fn set_game_config(ref self: TContractState, admin_address: ContractAddress);
    fn set_cards_per_round(ref self: TContractState, cards_per_round: u32);
    fn set_admin_address(ref self: TContractState, admin_address: ContractAddress);
}

// dojo decorator
#[dojo::contract]
pub mod game_config {
    use core::num::traits::zero::Zero;
    use dojo::event::EventStorage;
    use dojo::model::{Model, ModelStorage};
    use dojo::world::{IWorldDispatcherTrait, WorldStorage};
    use lyricsflip::constants::GAME_ID;
    use lyricsflip::models::config::GameConfig;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
    use super::IGameConfig;


    #[abi(embed_v0)]
    impl GameConfigImpl of IGameConfig<ContractState> {
        //TODO
        fn set_game_config(ref self: ContractState, admin_address: ContractAddress) {}

        fn set_cards_per_round(ref self: ContractState, cards_per_round: u32) {
            // Check that the value being set is non-zero
            assert(cards_per_round != 0, 'cards_per_round cannot be zero');

            // Get the world dispatcher
            let mut world = self.world_default();

            // Get the current game config
            let mut game_config: GameConfig = world.read_model(GAME_ID);

            // Update the cards_per_round field
            game_config.cards_per_round = cards_per_round;

            // Save the updated game config back to the world
            world.write_model(@game_config);
        }

        fn set_admin_address(ref self: ContractState, admin_address: ContractAddress) {
            assert(
                admin_address != Zero::<ContractAddress>::zero(), 'admin_address cannot be zero',
            );

            let mut world = self.world_default();
            let mut game_config: GameConfig = world.read_model(GAME_ID);

            game_config.admin_address = admin_address;
            world.write_model(@game_config);
        }
    }

    #[generate_trait]
    pub impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"lyricsflip")
        }

        fn assert_caller_is_admin(self: @ContractState) -> bool {
            let mut world = self.world_default();
            let mut game_config: GameConfig = world.read_model(GAME_ID);

            let caller: ContractAddress = get_caller_address();

            // Check if the caller is the admin address
            let is_admin: bool = game_config.admin_address == caller;

            is_admin
        }
    }
}

#[cfg(test)]
pub mod tests {

    use starknet::{ ContractAddress, testing, contract_address_const };

    use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
    use dojo::world::{ WorldStorage, WorldStorageTrait };
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDef, ContractDefTrait, WorldStorageTestTrait };

    use lyricsflip::models::config::{GameConfig, m_GameConfig};
    use lyricsflip::constants::GAME_ID;
    use super::game_config;
    use super::game_config::{ InternalTrait };

    fn namespace_def() -> NamespaceDef {
        NamespaceDef {
            namespace: "lyricsflip",
            resources: [
                TestResource::Model(m_GameConfig::TEST_CLASS_HASH),
                TestResource::Contract(game_config::TEST_CLASS_HASH)
            ].span(),
        }
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"lyricsflip", @"game_config")
                .with_writer_of([dojo::utils::bytearray_hash(@"lyricsflip")].span())
        ].span()
    }

    fn setup_world_and_state() -> (WorldStorage, game_config::ContractState) {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());
        
		let mut state = game_config::contract_state_for_testing();

        return (world, state);
    }

    // Test Case 1: Caller is Admin
    #[test]
    fn test_caller_is_admin() {
        let admin: ContractAddress = contract_address_const::<0x1>();
        let (mut world, mut state) = setup_world_and_state();

        // Set up GameConfig with admin_address = 0x1
        let mut g_config: GameConfig = world.read_model(GAME_ID);
        g_config.admin_address = admin;
        world.write_model(@g_config);

        // Set caller to admin
        testing::set_caller_address(admin);

        // Call the internal function directly
        let is_admin = state.assert_caller_is_admin();
        assert(is_admin, 'Caller should be admin');
    }

    // Test Case 2: Caller is Not Admin
    #[test]
    fn test_caller_is_not_admin() {
        let admin: ContractAddress = contract_address_const::<0x1>();
        let non_admin = contract_address_const::<0x2>();
        let (mut world, mut state) = setup_world_and_state();

        // Set up GameConfig with admin_address = 0x1
        let mut g_config: GameConfig = world.read_model(GAME_ID);
        g_config.admin_address = admin;
        world.write_model(@g_config);

        // Set caller to non_admin
        testing::set_caller_address(non_admin);

        // Call the internal function directly
        let is_admin = state.assert_caller_is_admin();
        assert(!is_admin, 'Caller should not be admin');
    }

}
