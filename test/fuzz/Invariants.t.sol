// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";


contract Invariants is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc,dsce, config) = deployer.run();
        (,,weth,wbtc,) = config.activeNetworkConfig();
        // targetContract(address(dsce));
        /*
        In Foundry (a smart contract development framework), targetContract() is a function provided by the StdInvariant contract from the forge-std library. It is used specifically when writing invariant tests.
        Purpose of targetContract()
        It tells Foundry's fuzzing engine (used during invariant testing) which contract to target for calling functions during fuzz testing.

        In simpler terms:
        You are testing for conditions that must always hold true (invariants), regardless of what sequence of function calls are made.
        targetContract(address) informs the test engine to randomly call functions from the specified contract (Handler in your case), and then check that your defined invariants are always true.
        */
        handler = new Handler(dsce, dsc);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {

        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 totalBtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(weth,totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, totalBtcDeposited);

        console.log("weth value: ", wethValue);
        console.log("wbtc value: ", wbtcValue);
        console.log("total supply: ",totalSupply);
        console.log("Times mint called : ", handler.timesMintIsCalled());

        assert(wethValue+wbtcValue>=totalSupply);

    }

    function invariant_gettersShouldNotRevert() public view {
        //  forge inspect DSCEngine methods
        dsce.getAdditionalFeedPrecision();
        dsce.getCollateralTokens();
        dsce.getLiquidationBonus();
        dsce.getLiquidationThreshold();
        dsce.getMinHealthFactor();
        dsce.getPrecision();
        dsce.getDsc();
        // dsce.getTokenAmountFromUsd();
        // dsce.getCollateralTokenPriceFeed();
        // dsce.getCollateralBalanceOfUser();
        // getAccountCollateralValue();
    }

}

