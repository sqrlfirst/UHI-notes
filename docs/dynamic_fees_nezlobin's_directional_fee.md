# Dynamic Fees: Nezlobin's directional fee

## What is impermanent loss?

- LPs in AMMs face impermanent loss when the relative price of assets in a pool change.
- Loss occurs if the value of those assets diverges from what they would have if they had just held tokens.
- "Impermanent" => Unrealized Losses, only made permanent if they withdraw their liquidity.

    **Example**

    1. Assume 1 ETH = 100 DAI
    2. Assume ETH/DAI pool exists with 95 ETH and 9500 DAI in it.
    3. LP adds 5 ETH and 500 DAI => 100 ETH and 10000 DAI in the pool.
    4. LP owns 5% of the pool share => 5 ETH and 500 DAI.
    5. Swapper buys 10 ETH, deltaX = -10
    6. (x - deltaX) x (y + deltaY) = 100 x 10_000
        => 90 x (10_000 + deltaY) = 1_000_000
        => deltaY = 1111.11...
    7. Pool => 90 ETH and 11,111.111... DAI
    8. Price of ETH => 1 ETH = 124 DAI
    9. LP owns 5% of Pool => 4.5 ETH + 555.555... DAI , at current prices in USD, this is: 1113.8... USD
    10. In case if LP held their assets instead of depositing in pool, assuming price increase would have happened regardless:
        LP would have 5 ETH + 500 DAI => 5 * 124 + 500 = 1120 USD
    11. 1120 > 1113.8 This is impermanent loss.

Generally low volatile pools - like stablecoin pairs, or stable asset pairs (stETH vs ETH) - don't have much impermanent loss.

## Problems of Impermanent Loss

With Uni v3 and concentrated liquidity, markets became more capital efficient - but not completely free of impermanent loss.

There are strategies to mitigate - active LP rebalancing protocols attempt to try to minimize IL and increase LP yields all the time.

[Paper about impermanent loss in Uniswap V3](https://arxiv.org/abs/2111.09192)

Paper analyzed 17 of the largest trading pools - covering 43 % of the TVL

Total fees earned since pool inception until cut-off date was $199.e3m

Total IL during this time was $260.1m

## Toxic order flow

Order flow is considered toxic when it is dominated by well informed arbitrageurs.

The paper highlighted that the large orders on Uniswap are dominated by informed arbitrageurs who only trade on the platform when there price inefficiencies.

In designing their trades, arbs make sure they are profitable net all fess and gas costs - and leace LPs on the wrong side of each trade.

LPs, on average then, make losses even after accounting for earned fees in the pools.

To fight toxic order flow, there 2 options:

  1. Make arbitrage trading more costly to deter arbitrageurs.
  2. Attract more regular, ***uninformed***, trading volume to the exchange.

Uninformed => everyday traders not trying to arbitrage across 100 different exchanges and taking advantage of slight market inefficiencies.
