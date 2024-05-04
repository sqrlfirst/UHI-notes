# Gas Price Dynamic Hook

[Link to original repo from Haardik](https://github.com/haardikk21/gas-price-hook)

## Description

Hook keeps track of the moving average gas price over time onchain. When gas price is roughly equal to the average, we will charge a certain amount of fees. If gas price is over 10% higher than the average, we will charge the lower fees. If gas price is at least 10% lower than the average, we will charge the higher fees.

## Dynamic fees in V4

`Slot0` struct in `PoolManager`

```solidity
struct Slot0 {
    // the current price
    uint160 sqrtPriceX96;
    // the current tick
    int24 tick;
    // protocol swap fee represented as integer denominator (1/x), taken as a % of the LP swap fee
    // upper 8 bits are for 1->0, and the lower 8 are for 0->1
    // the minimum permitted denominator is 4 - meaning the maximum protocol fee is 25%
    // granularity is increments of 0.38% (100/type(uint8).max)
    uint16 protocolFee;
    // used for the swap fee, either static at initialize or dynamic via hook
    uint24 swapFee;
}
```

The fees charged on each swap are represented by the `swapFee` property in this struct. A dynamic fee hook, basically, just updates this property whenever it wishes to do so.

To do that call the `updateDynamicSwapFee` function on the `PoolManager` at any point - with the `PoolKey` and the new fee value like so
```solidity
poolManager.updateDynamicSwapFee(poolKey, NEW_FEES);
```



## TODO 

add fuzz test for hook