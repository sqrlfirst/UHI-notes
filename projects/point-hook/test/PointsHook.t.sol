// SPDx-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

import {PoolManager} from "v4-core/PoolManager.sol";
import [IPoolManager} from "v4-core/interfaces/IPoolManager.sol";]

import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";

import {PointsHook} from "../src/PointsHook.sol";
import {HookMiner} from "./utils/HookMiner.sol";

contract TestPointsHook is Test, Deployers {
    using CurrencyLibrary for Currency;

    MockERC20 token;

    Currency ethCurrency = Currency.wrap(address(0));
    Currency tokenCurrency;

    PointsHook hook;

    function setUp() public {
        // Deploy PoolManager and Router contracts
        deployFreshManagerAndRouters();

        // Deploy out Token Contract
        token = new MockERC20("Test Token", "TEST", 18);
        tokenCurrency = Currency.wrap(address(token));

        // 
        token.mint(address(this), 1000 ether);
        token.mint(address(1), 1000 ether);

        uint160 flags = uint160(Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.AFTER_SWAP_FLAG);
        (, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            0,
            type(PointsHook).creationCode,
            abi.encode(manager, "Points Token", "TEST_POINTS");
        );

        hook = new PointsHook{salt: salt}(
            manager, 
            "Points Token",
            "TEST_POINTS"
        );

        token.approve(address(swapRouter), type(uint256).max);
        token.approve(address(modifyLiquidityRouter), type(uint256).max);
    
        (key, ) = initPool(
            ethCurrency, // Currency 0 - ETH
            tokenCurrency, // Currency 1 - TOKEN
            hook, // HookContract
            3000, // SwapFees
            SQRT_RATIO_1_1, // Initial SQRT(P) value = 1
            ZERO_BYTES // No additional `initData`
        );
    }

    function test_addLiquidityAndSwap() public {}

    function test_addLiquidityAndSwapWithReferral() public {}
}