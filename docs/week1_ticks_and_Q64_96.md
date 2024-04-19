### Ticks and Q64.96 Numbers

**Ticks Insight #1** 
_Ticks break up the continuous finite price curve into a curve with evenly spaced discrete points._

_Each discrete point represents a specific price at which trades can occur._

**Ticks Insight #2**
_The gap between two adjacent ticks - called **tick spacing** - is the smallest relative price movement possible for a given pair of assets in a pool._

**Ticks <> Prices**

The relative price of an asset at a given tick is represented by this neat little equation:

$p(i) = 1.0001^{i}$

Ticks represent price based on the price of `Token 0` relative to `Token 1`. 

The sorting of token based on lexicographically sorting their contract addresses.

If `A` is `0x000..`, while `B` is `0x123..` then `A` is `Token 0` and `B` is the `Token 1`.

💡 Uniswap v4 has support for pools with native tokens

`1.0001` was chosen because **for each tick, the relative price moves by 0.01%**, this movement is called a **basis point** or **bps**.

| **Basis Point** | **Percentage** |
| --------------- | -------------- |
| 1               | 0.01%          |
| 10              | 0.10%          |
| 50              | 0.50%          |
| 100             | 1.00%          |
| 275             | 2.75%          |
| 400             | 4.00%          |
| 1000            | 10.00%         |
ticks stored in `int24` the `MIN_TICK` and `MAX_TICK` are in range `[-887_272, 887_272]`

**Liquidity Math**


$L_x = x * (sqrt{P} * sqrt{p_b})\over(sqrt{p_b}-sqrt{P})$

$y = L_x(sqrt{P} - sqrt{p_a})$

**Q64.96 Number** 

Q64.96 is a way represented rational numbers that uses 64 bits for integer part and 96 bits for fractional part

$Q = D * (2^k)\ where\ k\ =\ 96$
*D* is decimal notation of the number

For example: `1.000234 * 2^96` = `79246701904292675448540839620.378624`

how this works, take a look at `getSqrtRatioAtTick` and `getTickAtSqrtRatio` [LINK](https://github.com/Uniswap/v4-core/blob/main/src/libraries/TickMath.sol)