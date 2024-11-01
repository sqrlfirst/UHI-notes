// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {CurrencySettler} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {BeforeSwapDelta, toBeforeSwapDelta} from "v4-core/types/BeforeSwapDelta.sol";
import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";

/**
 * @title CSMM
 * @notice A CSMM is a pricing curve that follows the invariant `x + y = k`
 * instead of the traditional `x * y = k`.
 *
 * This is thereotically useful for stablecoins or pegged pairs(stETH/ETH),
 * but in practice it's usually not seen since depegs can happen
 */
contract CSMM is BaseHook {
    using CurrencySettler for Currency;

    struct CallbackData {
        uint256 amountEach;
        Currency currency0;
        Currency currency1;
        address sender;
    }

    /// Error thrown when someone tries to add liquidity directly to the PoolManager
    error AddLiquidityThroughHook();

    constructor(IPoolManager poolManager) BaseHook(poolManager) {}

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: true, // don't allow add liquidity normally
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true, // Override how swaps are done
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: true, // Allow beforeSwap to a return a custom delta
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    /// Disable adding liquidity through the PM
    function beforeAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert AddLiquidityThroughHook();
    }

    // Custom add liquidity function
    function addLiquidity(PoolKey calldata key, uint256 amountEach) external {
        poolManager.unlock(
            abi.encode(
                CallbackData(
                    amountEach,
                    key.currency0,
                    key.currency1,
                    msg.sender
                )
            )
        );
    }

    function _unlockCallback(
        bytes calldata data
    ) internal override returns (bytes memory) {
        CallbackData memory callbackData = abi.decode(data, (CallbackData));

        // Settle `amountEach` of each currency from the sender
        // i.e. Create a debit of `amountEach` of each currency with the Pool Manager
        callbackData.currency0.settle(
            poolManager,
            callbackData.sender,
            callbackData.amountEach,
            false // `burn` is false i.e. we're actually transferring tokens, not burning ERC-6909 Claim Tokens
        );
        callbackData.currency1.settle(
            poolManager,
            callbackData.sender,
            callbackData.amountEach,
            false
        );

        // Since we didn't go through the regular "modify liquidity" flow,
        // еру PM just has a debit of `amountEach` of each currency from us
        // We can, in exchange, get the ERC-6909 claim tokens for `amountEach` of each currency
        // to create a credit of `amountEach` of each currency to us
        // that balances out the debit

        // We will store this claim tokens with the hook, so when swaps take place
        // liquidity from our CSMM can be used by minting/burning claim tokens the hook owns
        callbackData.currency0.take(
            poolManager,
            address(this),
            callbackData.amountEach,
            true // true means we're minting ERC-6909 Claim Tokens for the hook, equivalent to money we just deposited to the PM
        );
        callbackData.currency1.take(
            poolManager,
            address(this),
            callbackData.amountEach,
            true
        );

        return "";
    }

    function beforeSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        uint256 amountInOurPositive = params.amountSpecified > 0
            ? uint256(params.amountSpecified)
            : uint256(-params.amountSpecified);

        /**
         * BalanceDelta is a packed value of (currency0Amount, currency1Amount)
         *
         * BeforeSwapDelta varies such that it is not sorted byt token0 and token1
         * Instead, it is sorted by "specifiedCurrency" and "unspecifiedCurrency"
         *
         * Specified currency => The currency in which the user is specifying the amount they're swapping for
         * Unspecified currency => The other currency
         *
         * For example, in an ETH/USDC pool there are 4 posssible swap cases:
         * 1. ETH for USDC with Exact Input for Output (amountSpecified = negative value representing ETH)
         * 2. ETH for USDC with Exact Output for Input (amountSpecified = positive value representing USDC)
         * 3. USDC for ETH with Exact Input for Output (amountSpecified = negative value representing USDC)
         * 4. USDC for ETH with Exact Output for Input (amountSpecified = positive value representing ETH)
         *
         * In Case(1):
         *      -> the user is specifying their swap amount in terms of ETH, so the specified currency is ETH
         *      -> the unspecified currency is USDC
         * In Case(2):
         *      -> the user is specifying their swap amount in terms of USDC, so the specified currency is USDC
         *      -> the unspecified currency is ETH
         * In Case(3):
         *      -> the user is specifying their swap amount in terms of USDC, so the specified currency is USDC
         *      -> the unspecified currency is ETH
         * In Case(4):
         *      -> the user is specifying their swap amount in terms of ETH, so the specified currency is ETH
         *      -> the unspecified currency is USDC
         *
         * - - - - - - - -
         *
         * Assume seroForOne = true (without loss of generality)
         * Assume abs(amountSpecified) = 100
         *
         * For an exact input swap where amountSpecified is negatice (-100)
         *      -> specified token = token0
         *      -> unspecified token = token1
         *      -> we set deltaSpecified = -(-100) = 100
         *      -> we set deltaUnspecified = -100
         *      -> i.e. hook is owed 100 specified token (token0) by PM (that comes from the user)
         *      -> and hook owes 100 unspecified token (token1) to PM (that goes to the user)
         *
         * For an exact output swap where amountSpecified is positive (100)
         *      -> specified token = token1
         *      -> unspecified token = token0
         *      -> we set deltaSpecified = 100
         *      -> we set deltaUnspecified = -100
         *      -> i.e. hook is owed 100 specified token (token1) by PM (that goes to the user)
         *      -> and hook owes 100 unspecified token (token0) to PM (that comes from the user)
         *
         *  In either case, we can design BeforeSwapDelta as (-params.amountSpecified, params.amountSpecified)
         *
         */

        BeforeSwapDelta beforeSwapDelta = toBeforeSwapDelta(
            int128(-params.amountSpecified), // So `amountSpecified` = +100
            int128(params.amountSpecified) // Unspecified amount(output delta) = -100
        );

        if (params.zeroForOne) {
            // if user is selling token0 and buying token1
            // They will be sending token0 to the PM, creating a degit of token0 in the PM
            // We will take claim tokens for that token0 from the PM and keep it in the hook to create an equivalent credit for ourselves
            key.currency0.take(
                poolManager,
                address(this),
                amountInOurPositive,
                true
            );

            // They will be receiving token1 from the PM, creating a credit of token1 in the PM
            // we will burn claim tokens for token1 from the hook so PM can pay the user
            key.currency1.settle(
                poolManager,
                address(this),
                amountInOurPositive,
                true
            );
        } else {
            key.currency0.settle(
                poolManager,
                address(this),
                amountInOurPositive,
                true
            );
            key.currency1.take(
                poolManager,
                address(this),
                amountInOurPositive,
                true
            );
        }

        return (this.beforeSwap.selector, beforeSwapDelta, 0);
    }
}
