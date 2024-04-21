// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseHook} from "v4-periphery/BaseHook.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDeltaLibrary, BalanceDelta} from "v4-core/types/BalanceDelta.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";

contract PointsHook is BaseHook, ERC20 {
    using CurrencyLibrary for Currency;
    using BalanceDeltaLibrary for BalanceDelta;

    // Keeping track of user -> referrer
    mapping(address => address) public referredBy;

    // Amount of points someone gets for referring someone else
    uint256 public constant POINTS_FOR_REFERRAL = 500 * 10 ** 18;

    constructor(
        IPoolManager _manager,
        string memory _name,
        string memory _symbol,
        string memory
    ) BaseHook(_manager) ERC20(_name, _symbol, 18) {}

    // set up hook permissions
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
                beforeAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterAddLiquidity: true,
                afterRemoveLiquidity: false,
                beforeSwap: false,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false
            });
    }

    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata swapParams,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override poolManagerOnly returns (bytes4) {
        // If this is not an ETH-TOKEN pool with this hook attached, ignore
        // `isNative` function comes from the CurrencyLibrary
        if (!key.currency0.isNative()) return this.afterSwap.selector;

        // We only mint points if user is buying TOKNE with ETH
        if (!swapParams.zeroForOne) return this.afterSwap.selector;

        // Mint points equal to 20% of the amount of ETH they spent
        // Since its a zeroForOne swap:
        // if amountSpecified < 0:
        //    this is an "exact input for output" swap
        //    amount of ETH they spent is equal to |amountSpecified|
        // if amountSpecified > 0:
        //    this is an "exact output fot input" swap
        //    amount of ETH they spent is equal to BalanceDelata.amount0()

        uint256 ethSpendAmount = swapParams.amountSpecified < 0
            ? uint256(-swapParams.amountSpecified)
            : uint256(int256(-delta.amount0()));

        // pointsForSwap = 20% of ethSpendAmount
        uint256 pointsForSwap = ethSpendAmount / 5;

        // Mint the points including any referral points
        _assignPoints(hookData, pointsForSwap);

        return this.afterSwap.selector;
    }

    function afterAddLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override poolManagerOnly returns (bytes4) {
        // If this is not an ETH-TOKEN pool with this hook attache, ignore
        if (!key.currency0.isNative()) return this.afterAddLiquidity.selector;

        // Mint points equivalent to how much ETH they are adding in liquidity
        // amount0() is amount of Token 0 i.e. ETH
        // we do `-amount0` because its money leaving the user's wallet so will be a negative value, we flip the sign to make it positive
        uint256 pointsForAddingLiquidity = uint256(int256(-delta.amount0()));

        _assignPoints(hookData, pointsForAddingLiquidity);

        return this.afterAddLiquidity.selector;
    }

    function getHookData(
        address referrer,
        address referree
    ) public pure returns (bytes memory) {
        return abi.encode(referrer, referree);
    }

    function _assignPoints(
        bytes calldata hookData,
        uint256 referreePoints
    ) internal {
        // If no referrer/referree specified, no points will be assigned to anyone
        if (hookData.length == 0) return;

        // Decode the referrer and referree addresses
        (address referrer, address referree) = abi.decode(
            hookData,
            (address, address)
        );

        // if referree is zero address, then ignore
        if (referree == address(0)) return;

        // If this referree is being referred by someone for the first time,
        // set the given referrer address as their referrer
        // and mint POINTS_FOR_REFERRAL to that referrer address
        if (referredBy[referree] == address(0) && referrer != address(0)) {
            referredBy[referree] = referrer;
            _mint(referrer, POINTS_FOR_REFERRAL);
        }

        // Mint 10% worth of the referree's points to the referrer
        if (referredBy[referree] != address(0)) {
            _mint(referrer, referreePoints / 10);
        }

        //Mint the appropriate number of points to the referree
        _mint(referree, referreePoints);
    }
}
