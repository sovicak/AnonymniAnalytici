# CMD https://enigmampc.github.io/catalyst/install.html
source activate catalyst

catalyst ingest-exchange -x bitfinex -i btc_usd -f minute

catalyst run -f algorithms/buy_btc_simple.py -x bitfinex --start 2016-1-1 --end 2017-9-30 -c usd --capital-base 100000 -o algorithms/export/buy_btc_simple_out.pickle
