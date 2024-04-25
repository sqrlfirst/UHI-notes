# Limit Orders

[haardik21 original repo](https://github.com/haardikk21/take-profits-hook)

## Take profit Orders

A take-profit is a type of order where the user wants to sell a token once it's price is increases to hit a certain price.

## Mechanism design

Functions that needed:

- placing an order
- cancel the order after placing(if not filled)
- withdraw/redeem tokens after order is filled

## Assumptions

// TODO - can be observed as improvements further

1. We are going to try and fulfill every order that exist within the range the tick moved after a swap, with zero considerationfor the fact that this will increase gas costs for the original swapper.
2. We will not consider slippage for placed orders, and allow infinite slippage.
3. We will not support pools with native ETH as one of the tokens in the pair.

### Placing Order

### Cancel Order

### Redeem output tokens