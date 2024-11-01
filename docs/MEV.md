# MEV

[Sandwich Protection Hook]()

# Content

- [MEV](#mev)
- [Content](#content)
  - [Sandwich Attacks](#sandwich-attacks)
  - [Mitigating Sandwich Attacks](#mitigating-sandwich-attacks)
  - [Mechanism design](#mechanism-design)
  - [Coincidence of Wants (CoW)](#coincidence-of-wants-cow)
  - [CoWSwap](#cowswap)
  - [Cow in Hooks](#cow-in-hooks)

## Sandwich Attacks

Sandwiching is type of toxic MEV that exists when an MEV searcher attemots to profit from the price volatility of an asset created due to a swapper's swap request.

## Mitigating Sandwich Attacks

- async swap design
  Sandwiches are works because txes are executed in the specific order:
  Frontrun -> Swap -> Backrun
  Large swaps can happen accross multiple blocks instead of happen atomically.

## Mechanism design

When we see a swap transaction, if it's considered to be a "large" enough swap, we should not execute the swap immediately and instead lock up the input tokens and have it be executed at a later point in time randomly (with reasonable upper limits).

To do so, we need to answer a few questions:

1. What is considered to be a large swap?
2. How do we lock up input tokens?
3. When should a "paused" swap be executed, exactly?
4. Who is conducting the transaction to execute the paused swap? How are they being paid back for their gas costs?

For (1) "high" slippage -> low "liquidity pools"(memecoins, small cap projects, newly launched tokens) or when large swap is taking place.

For (2) A NoOp in `beforeSwap` to have the hook take custody of the input tokens and return no output tokens back to the user.

For (3) this should ideally be an offchain component. For a proof of concept a centralized version is probably fine, but a decentralized network could also be built. The job of this offchain processor is to basically listen for when a swap is paused by the hook due to it being considered large, and assign it some random execution timestamp in the near future. Later, at that time, it should conduct a transaction (ideally through an MEV protected RPC) to instruct the hook to resume that swap transaction.

For (4) the offchain processor is the one executing the paused transactions - but how they are able to sustain themselves is something to think about. I think what can be done here is basically charging some fees on the hook level for "saving" users from toxic MEV.

## Coincidence of Wants (CoW)

TODO

## CoWSwap

## Cow in Hooks 
