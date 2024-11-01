# Custom curve CSMM

[cssm-noop-hook](../projects/csmm-noop-hook/)

## Content

- [Custom curve CSMM](#custom-curve-csmm)
  - [Content](#content)
  - [NoOp hooks](#noop-hooks)
    - [NoOp Hooks types\*\*](#noop-hooks-types)
  - [BeforeSwapDelta](#beforeswapdelta)
  - [CSMM (constant sum market maker)](#csmm-constant-sum-market-maker)
  - [Mechanism design](#mechanism-design)
  - [Further improvements](#further-improvements)

## NoOp hooks

**NoOp Hooks** are called such because they have the ability to ask the core PoolManager contract to do "nothing". This mean is to "skip" over a certain part of the logic within the PoolManager.

### NoOp Hooks types**

- `beforeSwapReturnDelta`
    has the ability to partially, or completely, bypass the core swap logic of pool manager by taking care of the swap request itself inside `beforeSwap`.
- `afterSwapReturnDelta`
    has the ability to extract tokens to keep for itself from the swap's output amount, ask the user to send more that the input amount of the swap with the excess going to the hook, or add additional tokens to the swap's output amount for the user.
- `afterAddLiquidityReturnDelta`
    has the ability to charge the user an additional amount over what they're adding as liquidity, or send them some tokens.
- `afterRemoveLiquidityReturnDelta`
    same as above.

## BeforeSwapDelta

`BalanceDelta` - type returned from `swap` & `modifyLiquidity`. It is of the form `(amount0, amount1)` and represents the delta of `token0` and `token1` respectively after user performs an action. The user's responsibility is to account for this balance delta and receive the tokens it's responsible to receive, and pay for the tokens it's responsible to pay, from and to the PoolManager.

`BeforeSwapDelta` is *kind of simular*. It's a distinct type that can be returned from the `beforeSwap` hook function if the `beforeSwapReturnDelta` flag has been enabled.

`BeforeSwapDelta` is of the form `(amountSpecified, amountUnspecified)`.
`amountSpecified` refers to the delta amount of the token which was "specified" by the user.
`amountUnspecified` is the opposite. What does specified mean? Well, it depends on the swap parameters.

There are four types of swap configurations that are possible:

1. Exact Input Zero for One
    We specify `zeroForOne = true` and `amountSpecified = a negative number` in the swap parameters. This implies that we are specify an amount of `token0` to exactly receive in the user's wallet as the output of the swap.
2. Exact Output Zero for One
    We specify `zeroForOne = true` and `amountSpecified = a positive number` in the swap parameters. This implies that we are specify an amount of `token1` to exactly receive in the user's wallet as the output of the swap.  
3. Exact Input One for Zero
    Specified token is `token1`
4. Exact Output One for Zero
    Specified token is `token0`

## CSMM (constant sum market maker)

CSMM follows the pricing curve that uses addition instead of multiplication `x + y = k`.

CSMMs are great for stablecoins or stable assets. For example **USDC** vs **DAI** or **stETH** vs **ETH**.

## Mechanism design

Swap flow:

1. User calls `swap` on Swap Router
2. Swap Router calls `swap` on Pool Manager
3. Pool Manager calls `beforeSwap` on Hook
4. Hook should return a `BeforeSwapDelta` such as that it consumes the input token, and return an equal amount of the opposite token
5. Core swap logic gets skipped
6. Pool Manager returns final `BalanceDelta`
7. Swap Router accounts for the balances

For adding liquidity to the pool we need to do a couple of things:

1. Disable the default add and remove liquidity behaviour (we can do this by throwing an error from `beforeAddLiquidity` and `beforeRemoveLiquidity`)
2. Create a custom `addLiquidity` function on the hook contract that accepts tokens from the users to use as liquidity of the pool.

## Further improvements

- add way to remove liquidity
    create a mapping in the hook contract and store how many tokens each user added as liquidity over time to represent their share of the pool, and allow them to remove liquidity if they wish to based on that.
- Add way to charge fees
    We can do this by modifying our BeforeSwapDelta such that it doesn't give back exactly 1:1 amounts of tokens back, but instead gives back a little less output token back. For example, 99 output tokens in exchange for 100 input tokens would be a 1% fee being charged. This fee can be distributed to the LPs of your pool.

