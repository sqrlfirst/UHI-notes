# Points Hook

[LINK to original repo from haardik21](https://github.com/haardikk21/points-hook)

## Description

The Hook is attached into `ETH <> TOKEN` pools. The aim is to incentivize swappers to buy `TOKEN` in exchange for `ETH`, and for `LPs` to add liquidity to the pool. Also users can refer to other users such that the referer will earn some commision every time the referree buys `TOKEN` for `ETH` or adds liquidity to the pool. This incentivization happens through the hook issuing a second `POINTS` token when desired action is occur.

1. When a user gets referred, we will mint a hardcoded amount of `POINTS` token to the referrer - for example `500 POINTS`.
2. When a swap takes place which buys `TOKEN` for `ETH` - we will issue `POINTS` equivalent to how much `ETH` was swapped in to the user, and 10% of that amount to the referrer(if any).
3. When someone adds liquidity, we will issue `POINTS` equivalent to how much `ETH` they added, and 10% of that amount to the referrer(if any).

## Chose of the hook functions

- for Case(1) - minting `POINTS` in case of swaps - `afterSwap`.
- for Case(3) - adding of liquidity - `afterAddLiquidity`.

## TODO

1. Finish testing and cover edge cases. 
2. The `POINTS` token is easily game-able by anyone by creating a new pool for some random token and attaching this hook to it, and just wash-trading back and forth and farm a ton of `POINT`s. This can be fixed by either restricting the hook to a specific token pair - not just checking if ETH is Token 0 but also checking what Token 1 is, or it can be fixed by using different ERC-20 contracts for different pools by deploying new contracts in the `afterInitialize` hook which runs every time a new pool is initialized with this hook attached (or you can use ERC-6909 here!). -> This should be decomposited to tasks
3. For seriously doing something like this, you probably also want to do something inside `afterRemoveLiquidity` - maybe enforce a minimum time for how long they need to lock up their liquidity for. Otherwise the hook is game-able by just adding and removing liquidity over and over again to farm POINTs. -> This should be decomposited to tasks