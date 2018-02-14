from catalyst.api import order_target_percent, record, symbol, set_benchmark

def initialize(context):
    context.ASSET_NAME = 'USDT_REP'
    context.asset = symbol(context.ASSET_NAME)
    set_benchmark(context.asset)
    context.is_first_time = True
    
    # For all trading pairs in the poloniex bundle, the default denomination
    # currently supported by Catalyst is 1/1000th of a full coin. Use this
    # constant to scale the price of up to that of a full coin if desired.
    context.TICK_SIZE = 1.0


def handle_data(context, data):
    
    # Define base price and make initial trades to achieve target investment
    # ratio of 0.5

    if context.is_first_time:
        order_target_percent(
        context.asset,
        0.5,
    )
        context.base_price = data[context.asset].price
        context.first_price = data[context.asset].price
        context.is_first_time = False
                       
    # Retrieve current asset price from pricing data
    price = data[context.asset].price
    REP_cumulative_return = (price/context.first_price-1)*100
    Portfolio_cumulative_return = (context.portfolio.portfolio_value/
                                   context.portfolio.starting_cash-1)*100
    
    # Trading logic: rebalance to a 0.5 investment ratio every time the price
    # of the asset doubles or decreases to half the initial price
    if price > context.base_price*1.1:
        order_target_percent(
            context.asset,
            0.5,
        )
        context.base_price = data[context.asset].price
    elif price < context.base_price/1.1:
        order_target_percent(
            context.asset,
            0.5,
        )
        context.base_price = data[context.asset].price
    
    price = data[context.asset].price
    # Save values for later inspection
    record(price=price,
           base_price=context.base_price,
           cash=context.portfolio.cash,
           leverage=context.account.leverage,
           Portfolio_cumulative_return=Portfolio_cumulative_return,
           REP_cumulative_return=REP_cumulative_return,
    )


def analyze(context=None, results=None):
    import matplotlib.pyplot as plt
    import pandas as pd
    import sys
    import os
    from os.path import basename
    
    # Plot the portfolio and asset data.
    ax1 = plt.subplot(221)
    results[[
        'Portfolio_cumulative_return',
        'REP_cumulative_return',
    ]].plot(ax=ax1)
    ax1.set_ylabel('Percent Return (%)')

    ax2 = plt.subplot(222, sharex=ax1)
    ax2.set_ylabel('{asset} (USD)'.format(asset=context.ASSET_NAME))
    (context.TICK_SIZE * results[[
            'price',
            'base_price',
    ]]).plot(ax=ax2)

    trans = results.ix[[t != [] for t in results.transactions]]
    buys = trans.ix[
        [t[0]['amount'] > 0 for t in trans.transactions]
    ]
    sells = trans.ix[
        [t[0]['amount'] < 0 for t in trans.transactions]
    ]

    ax2.plot(
        buys.index,
        context.TICK_SIZE * results.price[buys.index],
        '^',
        markersize=10,
        color='g',
    )
    ax2.plot(
        sells.index,
        context.TICK_SIZE * results.price[sells.index],
        'v',
        markersize=10,
        color='r',
    )


    ax3 = plt.subplot(223, sharex=ax1)
    results[['leverage']].plot(ax=ax3)
    ax3.set_ylabel('Leverage ')

    ax4 = plt.subplot(224, sharex=ax1)
    results[['cash']].plot(ax=ax4)
    ax4.set_ylabel('Cash (USD)')

    plt.legend(loc=3)

    # Show the plot.
    plt.gcf().set_size_inches(16, 8)
    plt.show()
    
    # Save results in CSV file
    filename = os.path.splitext(basename(sys.argv[3]))[0]
    results.to_csv(filename + '.csv')
