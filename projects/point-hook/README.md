# Points Hook

## Description

The Hook is attached into `ETH <> TOKEN` pools. The aim is to incentivize swappers to buy `TOKEN` in exchange for `ETH`, and for `LPs` to add liquidity to the pool. Also users can refer to other users such that the referer will earn some commision every time the referree buys `TOKEN` for `ETH` or adds liquidity to the pool. This incentivization happens through the hook issuing a second `POINTS` token when desired action is occur.

1. When a user gets referred, we will mint a hardcoded amount of `POINTS` token to the referrer - for example `500 POINTS`.
2. When a swap takes place which buys `TOKEN` for `ETH` - we will issue `POINTS` equivalent to how much `ETH` was swapped in to the user, and 10% of that amount to the referrer(if any).
3. When someone adds liquidity, we will issue `POINTS` equivalent to how much `ETH` they added, and 10% of that amount to the referrer(if any).

## Chose of the hook functions

- for Case(1) - minting `POINTS` in case of swaps - `afterSwap`.
- for Case(3) - adding of liquidity - `afterAddLiquidity`.

