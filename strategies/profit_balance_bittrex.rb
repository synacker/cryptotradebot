require 'json'

require_relative '../trade_api/bittrex/client'
require_relative '../trade_api/bittrex/ticker'
require_relative '../trade_api/bittrex/portfolio'
require_relative '../trade_api/bittrex/exchange'


BUY_POSITIVE_CHANGES = %i[OpenBuyOrders_change, buy_volume_change, orders_change, Bid_change, Ask_change, Last_change, BaseVolume_change].freeze
SELL_NEGATIVE_CHANGES = %i[OpenSellOrders_change, sell_volume_change, spread_change].freeze

HOLDS_COUNT = 6

BITTREX_COMMISION = 0.0025

def invest_pair?(pair)
  result = true

  result &&= BUY_POSITIVE_CHANGES.all? do |field|
    pair[field].positive?
  end

  result &&= SELL_NEGATIVE_CHANGES.all? do |field|
    pair[field].negative?
  end
  result
end

def find_invest_pairs(ticker, portfolio)
  ticker.pairs.select {|pair| !portfolio.has?(pair[:name]) && invest_pair?(pair) }
end

start_balance = 0
profit_balance = 0
last_ticker = {}


client = TradeApi::Bittrex::Client.new(ENV.fetch('BITTREX_KEY'),
                                       ENV.fetch('BITTREX_SECRET'))
current_ticker = TradeApi::Bittrex::Ticker.new client
portfolio = TradeApi::Bittrex::Portfolio.new client
exchange = TradeApi::Bittrex::Exchange.new client

current_ticker.update!
portfolio.update!(current_ticker.ticker, BITTREX_COMMISION)
exchange.update!

sell_balance = portfolio.sell_balance

if sell_balance > profit_balance
  profit_balance = sell_balance
elsif sell_balance < profit_balance && sell_balance > start_balance
  exchange.cancel_all_orders
  exchange.sell_by_current_bid portfolio.actives
  start_balance = sell_balance
  profit_balance = sell_balance + 1
else
  invest_pairs = find_invest_pairs ticker, portfolio
  free_holds_count = HOLDS_COUNT - portfolio.holds_count
  invest_pairs = invest_pairs[0...free_holds_count] if invest_pairs.size > free_holds_count
  exchange.buy invest_pairs, portfolio.deposit / free_holds_count
end



#save current_ticker.ticker, start_balance, profit_balance