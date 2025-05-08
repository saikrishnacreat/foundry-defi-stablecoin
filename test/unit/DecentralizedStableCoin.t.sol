//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import{DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";

contract DecentralizedStableCoinTest is Test {
    DecentralizedStableCoin dsc;
    address owner;
    address user;

    function setUp() public {
        owner = address(this);
        user = address(1);
        dsc = new DecentralizedStableCoin();
    }

    // test minting
    function testOwnerCanMintTokens() public {
        // Here dsc is owner so it is allowing to mint
        uint256 mintAmount = 100e18;
        bool success = dsc.mint(user,mintAmount);
        assertTrue(success);
        assertEq(dsc.balanceOf(user),mintAmount);
    }

    // revert if non-owner tries to mint

    function testNonOwnerCannotMint() public {
        uint256 mintAmount = 100e18;
        vm.prank(user);
        vm.expectRevert();
        dsc.mint(user, mintAmount);
    }

    // revert if mint address is zero address

    function testRevertIfMintToZeroAddress() public {
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__NotZeroAddress.selector);
        dsc.mint(address(0),100e18);
    }

    // revert if mint amount is zero
    function testRevertIfMintZero() public{
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__MustBeMoreThanZero.selector);
        dsc.mint(user,0);
    }

    // test burn functionality

    function testOwnerCanBurnTokens() public {
        uint256 mintAmount = 100e18;
        dsc.mint(owner,mintAmount);
        dsc.burn(50e18);
        assertEq(dsc.balanceOf(owner),50e18);
    }

    // revert if non-owner tries to burn
    function testRevertIfNonOwnerBurns() public {
        dsc.mint(owner,100e18);

        vm.prank(user);
        vm.expectRevert();
        dsc.burn(10e18);

    }

    // revert if burn amount exceeds balance
    function testRevertIfBurnMoreThanBalance() public {
        dsc.mint(owner,10e18);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__BurnAmountExceedsBalance.selector);
        dsc.burn(20e18);

    }
    // revert if burn amount is zero

    function testRevertIfBurnZero() public {
        dsc.mint(owner,10e18);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__MustBeMoreThanZero.selector);
        dsc.burn(0);
    }

}