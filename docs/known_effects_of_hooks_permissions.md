# Known Effects of Hook Permissions

List of things that hooks could do that could be malicious or frustrating to users. Based on [this](https://github.com/Uniswap/v4-core/blob/main/docs/security/Known_Effects_of_Hook_Permissions.pdf).
Examples are [here](../projects/malicious-hooks/)

*Note* **JIT** -> "just in time" liquidity. Liquidity thats added immediately before a swap to get LP fees. Often then removed again immediately after the swap.

## Content

- [Known Effects of Hook Permissions](#known-effects-of-hook-permissions)
  - [Content](#content)
  - [Hooks without Custom Accounting](#hooks-without-custom-accounting)
    - [beforeSwap](#beforeswap)
    - [afterSwap](#afterswap)
    - [beforeSwap+afterSwap](#beforeswapafterswap)
    - [beforeAddLiquidity](#beforeaddliquidity)
    - [afterAddLiquidity](#afteraddliquidity)
    - [beforeRemoveLiquidity](#beforeremoveliquidity)
    - [afterRemoveLiquidity](#afterremoveliquidity)
    - [beforeDonate](#beforedonate)
    - [afterDonate](#afterdonate)
    - [before+afterDonate](#beforeafterdonate)
  - [Custom Accounting Hooks](#custom-accounting-hooks)
    - [beforeSwap returns delta](#beforeswap-returns-delta)
      - [exactInput swaps](#exactinput-swaps)
      - [exactOutput swaps](#exactoutput-swaps)
    - [afterSwap returns delta](#afterswap-returns-delta)
    - [afterAddLiquidity returns delta](#afteraddliquidity-returns-delta)
    - [afterRemoveLiquidity returns delta](#afterremoveliquidity-returns-delta)

## Hooks without Custom Accounting

### beforeSwap

- cause a revert (either through pushing the price, just reverting outright, or removing liquidity)
- frontrun the user's swap, pushing user to their max slippage
- cause a partial fill (by removing liquidity)
- JIT causing other in-range LPs to reap fewer fees

TODO add examples for each case

### afterSwap

- cause a revert
- backrun

TODO add examples for each case

### beforeSwap+afterSwap

- a guaranteed (risk-free) sandwich of the swap
- a guaranteed (risk-free) JIT of liquidity causing other in-range LPs to reap less reward

TODO add examples for each case

### beforeAddLiquidity

- cause a revert
- cause the ration of the two tokens owed to the pool to be different than expected by swapping to different price

TODO add examples for each case

### afterAddLiquidity

- cause a revert

TODO add examples for each case

### beforeRemoveLiquidity

- cause a revert, implying user funds could be permanently locked and fees to be never collected

TODO add examples for each case

### afterRemoveLiquidity

- cause a revert, implying user funds could be permanently locked and fees to be never collected

TODO add examples for each case

### beforeDonate

- cause a revert

TODO add examples for each case

### afterDonate

- cause a revert

TODO add examples for each case

### before+afterDonate

sandwich a donation and potentially capture all of it

TODO add examples for each case

## Custom Accounting Hooks

### beforeSwap returns delta

the below can ONLY happen if the hook also has the beforeSwap Hook

#### exactInput swaps

- can push swapper to max slippage (ie if the router reverts when maxOutput < deltaUnspecified, a hook can set deltaUnspecified to maxOutputAmount)
- can "take" all specified token without crediting the user with anything
    (should be checked in the router)
- can take full unspecified amount (if nonzero)
    (should be checked in the router)
- on low liquidity pools, note an example for a badly written hook that blindly credits without checking liquidity status. A user can always take the full creditable amount from the hook, and in this case it happens without the user paying anything.
  - lets say a hook gives the user an extra 1% of amountSpecified to every trade
  - lets say a the pool only has liquidity for 1 ETH -> 1500 USDC left available

    1. a user trades 100 ETH exact input, the hook contributes 1 ETH
    2. the pool tries to trade 101 ETH exact input, but only 1 ETH liquidity is available to trade on the pool
    3. 1 ETH is taken from the hook and credited to the pool manager, and the user pays (1 ETH - 1 ETH) 0 ETH input, and is given all 3500 USDC output

TODO add examples for each case

#### exactOutput swaps

- can push swapper to max slippage (ie if the router reverts when maxInput > deltaUnspecified, a hook can set delta Unspecified to maxInputAmount - 1)
- can take full unspecified amount, CANNOT take any of specified amount (should be checked in the router)
- on low liquidity pools, note an example for a badly written hook that blindly credits without checking liquidity status. A user can always take the full creditable amount from the hook.
  - lets say a hook gives the user an extra 1% of amountSpecified to every trade
  - lets say a the pool only has liquidity for 1 ETH -> 1500 USDC left available

    1. a user trades 700000 USDC  exactOutput, the hook gives 7000 USDC output
    2. the pool tries to trade 693000 USDC output, but only 3500 is available for 1 ETH input
    3. the user is charged 1 ETH, and is given (7000 + 3500) (10500) USDC


TODO add examples for each case

### afterSwap returns delta

The bellow can happen only if the hook also has the afterSwap hook

-can take full unspecified token from user (should be checked in the router)

TODO add examples for each case

### afterAddLiquidity returns delta

The bellow can happen only if the hook also has the afterAddLiquidity hook

- can take extra amounts of token0 and token1 (fee on add) (should be checked in the router)
- can pay for the amounts of token0 and token1 on behalf of user (on add)

TODO add examples for each case

### afterRemoveLiquidity returns delta

The bellow can happen only if the hook also has the afterRemoveLiquidity hook

- can take full amounts in both tokens from user(should be checked in the router)

TODO add examples for each case
