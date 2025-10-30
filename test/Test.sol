// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {AlchemistCurator} from "../src/AlchemistCurator.sol";




/// @notice This interface replaces the original import: 
/// `import {IVaultV2} from "../lib/IVaultV2.sol";`
///
///@notice The reason for creating this local interface is to simplify the setup:
/// we only need a minimal Vault interface that exposes `addAdapter` and `removeAdapter`
/// for testing purposes. 
///
///@notice It has **no effect on the behavior** of the `_setStrategy()` function.
interface _IVaultV2 {
    function addAdapter(address adapter) external;
    function removeAdapter(address adapter) external;
    function submit(bytes calldata data) external;
    function decreaseRelativeCap(bytes memory id, uint256 amount) external;
    function decreaseAbsoluteCap(bytes memory id, uint256 amount) external;
    function increaseRelativeCap(bytes memory id, uint256 amount) external;
    function increaseAbsoluteCap(bytes memory id, uint256 amount) external;
}



/// @notice This mock contract represents a Vault entity.
/// We need a Vault instance to assign adapters to it in the test.
///
/// The functions here are implemented only for  compatibility
/// with the `_IVaultV2` interface — they do not affect the behavior
/// of `_setStrategy()` in any way.
///
/// @notice It simply shows that a Vault entity exists, which allows
/// the Curator contract to interact with it as expected.

contract MockVault is _IVaultV2 {
    address public lastAddedAdapter;
    address public lastRemovedAdapter;

    function addAdapter(address adapter) external override {
        lastAddedAdapter = adapter;
    }
    function removeAdapter(address adapter) external override {
        lastRemovedAdapter = adapter;
    }
    function submit(bytes calldata) external override {}
    function decreaseRelativeCap(bytes memory, uint256) external override {}
    function decreaseAbsoluteCap(bytes memory, uint256) external override {}
    function increaseRelativeCap(bytes memory, uint256) external override {}
    function increaseAbsoluteCap(bytes memory, uint256) external override {}
}



/// @notice This mock contract represents an Adapter entity.
/// It is only used to provide an address that can be linked to Vaults
/// through the `_setStrategy()` function.
///
/// @dev No internal logic is required — only the address matters.  
contract Adaptor {

}


//test start🐧
contract TestAdapterReassignment is Test {
    AlchemistCurator curator;
    Adaptor adapter;

    /// @notice We create two Vaults because we want to verify whether
    /// a single adapter can be assigned to two different Vaults simultaneously.
    MockVault vault1;
    MockVault vault2;

    address admin = address(0xAAA1);
    address operator = address(0xBBB2);

    function setUp() public {
        curator = new AlchemistCurator(admin, operator);
        vault1 = new MockVault();
        vault2 = new MockVault();
        adapter = new Adaptor();
        

        vm.startPrank(operator);  
        curator.setStrategy(address(adapter), address(vault1));
        vm.stopPrank();
        address mappedVault1 = curator.adapterToMYT(address(adapter));
        console.log("mapped vault address that connected to adaptor from befor ----------->",mappedVault1);


    }

    
    function test_AdapterCanBeReassignedToDifferentVault_WithoutAnyCheck() public {
        vm.startPrank(operator);

        // This mapping is defined in the AlchemistCurator contract:
        // mapping(address => address) public adapterToMYT;

        // In this step, we attempt to assign the same adapter to a new vault (vault2)
        curator.setStrategy(address(adapter), address(vault2));

        address mappedVault2 = curator.adapterToMYT(address(adapter));
        console.log("Mapped vault address connected now ------------> ", mappedVault2);

        /// @notice At this point, the adapter has been successfully re-bound from vault1 to vault2.
        /// @notice However, there is **no validation or safety check** to ensure that the adapter
        ///         wasn’t already connected to a previous vault.
        ///
        /// @notice The function should either:
        ///         - enforce a prior call to `removeStrategy()` before call setStrategy() , or
        ///         - add a validation check inside `_setStrategy()` to prevent reassignment
        ///           if the adapter is already mapped to another vault.

        assertEq(mappedVault2, address(vault2), "Adapter mapping was not overwritten as expected!");

        vm.stopPrank();
}


}
