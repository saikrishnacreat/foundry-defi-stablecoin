//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    //////////////////////////////
    ////// Constructor Tests ///////
    //////////////////////////////
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTOkenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    //////////////////////////
    ////// Price Tests ///////
    //////////////////////////

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dsce.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
    }

    //////////////////////////////////////
    ////// depositCollateral Tests ///////
    //////////////////////////////////////

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock("RAN", "RAN", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dsce.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInfomation(USER);
        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }
    // write tests and bring coverage to 80percentage

    // mintdsc with proper collateral
    function testCanMintDscWithEnoughCollateral() public depositedCollateral {
        vm.startPrank(USER);
        uint256 mintAmount = 5 ether;
        dsce.mintDsc(mintAmount);
        uint256 dscBalance = dsc.balanceOf(USER);
        assertEq(dscBalance, mintAmount);
        vm.stopPrank();
    }
    // revert mint if user exceeds collateral value'

    function testRevertsIfMintAmountExceedsCollateralValue() public depositedCollateral {
        vm.startPrank(USER);
        uint256 overMintedAmount = 10001 ether;
        vm.expectRevert();
        dsce.mintDsc(overMintedAmount);
        vm.stopPrank();
    }

    // test redeem collateral

    function testCanRedeemCollateral() public depositedCollateral {
        vm.startPrank(USER);
        dsce.redeemCollateral(weth, 5 ether);
        uint256 balance = ERC20Mock(weth).balanceOf(USER);
        assertEq(balance, 5 ether);
        vm.stopPrank();
    }

    // revert redeeming more than deposited

    function testRevertsIfRedeemMoreThanDeposited() public depositedCollateral {
        vm.startPrank(USER);
        vm.expectRevert();
        dsce.redeemCollateral(weth, 20 ether);
        vm.stopPrank();
    }

    // edge case: zero mint amount

    function testRvertsOnZeroMintAmount() public depositedCollateral {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.mintDsc(0);
        vm.stopPrank();
    }
    // test get collateral value
    function testGetAccountCollateralValueAfterDeposit() public depositedCollateral {
        uint256 value = dsce.getAccountCollateralValue(USER);
        uint256 expected = dsce.getUsdValue(weth, AMOUNT_COLLATERAL);
        assertEq(value,expected);
    }

    // Ensure minted DSC is tracked under user account info.
    function testMintUpdatesAccountInfoCorrectly() public depositedCollateral {
        vm.startPrank(USER);
        uint256 mintAmount = 5 ether;
        dsce.mintDsc(mintAmount);

        (uint256 dscMinted, ) = dsce.getAccountInfomation(USER);
        assertEq(dscMinted , mintAmount);
        vm.stopPrank();
    }

    //This checks state consistency after partial redemption.

    function testCanPartiallyRedeemCollateralAfterMint() public depositedCollateral {
        vm.startPrank(USER);
        dsce.mintDsc(5 ether);
        dsce.redeemCollateral(weth, 2 ether);
        uint256 userBalance = ERC20Mock(weth).balanceOf(USER);
        assertEq(userBalance, 2 ether);
        vm.stopPrank();
    }

    function testRevertsIfRedeemBreaksHealthFactor() public depositedCollateral {
        vm.startPrank(USER);
        dsce.mintDsc(5 ether);
        vm.expectRevert();
        dsce.redeemCollateral(weth, 900 ether);
        vm.stopPrank();
    }

    function testCanFullyRedeemAfterBurningDsc() public depositedCollateral {
    vm.startPrank(USER);
    dsce.mintDsc(5 ether);
    dsc.approve(address(dsce), 5 ether);
    dsce.burnDsc(5 ether);
    dsce.redeemCollateral(weth, AMOUNT_COLLATERAL);

    uint256 finalBalance = ERC20Mock(weth).balanceOf(USER);
    assertEq(finalBalance, AMOUNT_COLLATERAL); // fully redeemed
    vm.stopPrank();
}


}
