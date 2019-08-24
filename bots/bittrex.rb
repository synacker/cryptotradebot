require 'json'

require_relative '../trade_api/bittrex/client'
require_relative '../trade_api/bittrex/ticker'
require_relative '../trade_api/bittrex/portfolio'
require_relative '../trade_api/bittrex/exchange'

module Bittrex
  class Bot
    def initialize(bittrex_key, bittrex_secret)
      @client = TradeApi::Bittrex::Client.new(bittrex_key,
                                             bittrex_secret)
      @current_ticker = TradeApi::Bittrex::Ticker.new @client
      @portfolio = TradeApi::Bittrex::Portfolio.new @client
      @exchange = TradeApi::Bittrex::Exchange.new @client
    end

    def sell_all
      portfolio = TradeApi::Bittrex::Portfolio.new @client
      exchange = TradeApi::Bittrex::Exchange.new @client

      portfolio.update!
      exchange.update!

      exchange.cancel_all_orders
      exchange.sell_by_current_bid portfolio.actives
    end

    def turn_profit_balance_strategy!(tickers)
      last_ticker, start_balance, profit_balance = tickers.last_record_data

      @current_ticker.update!
      @current_ticker.calculate_change_values! last_ticker if last_ticker

      @portfolio.update!
      @exchange.update!

      if start_balance.zero?
        start_balance = @portfolio.deposit
        profit_balance = start_balance + 1
      end

      sell_balance = @portfolio.sell_balance(@current_ticker.ticker_map, BITTREX_COMMISSION)

      puts "Deposit: #{@portfolio.deposit}"
      puts "Sell balance: #{sell_balance}"
      puts "Start balance: #{start_balance}"
      puts "Profit balance: #{profit_balance}"
      puts @portfolio.actives.to_json

      if sell_balance > profit_balance
        profit_balance = sell_balance
      elsif sell_balance < profit_balance && sell_balance > start_balance
        @exchange.cancel_all_orders
        @exchange.sell_by_current_bid @portfolio.actives
        start_balance = sell_balance
        profit_balance = sell_balance + 1
      elsif !last_ticker.empty?
        invest_markets = find_invest_markets
        free_holds_count = MAX_HOLDS_COUNT - @portfolio.holds_count
        invest_markets = invest_markets[0...free_holds_count] if invest_markets.size > free_holds_count

        @exchange.buy invest_markets, @portfolio.deposit / free_holds_count, BITTREX_COMMISSION if invest_markets.size.positive?
      end

      tickers.save_record @current_ticker.ticker_map.to_json, start_balance, profit_balance
    end

    private

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

    def find_invest_markets
      @current_ticker.pairs
          .select {|pair| !@portfolio.has?(pair[:name]) && invest_pair?(pair)}
          .map {|pair| pair[:MarketName]}
    end

    def calculate_order_volume(order_type, orders)
      volume = 0
      orders[order_type].each do |order|
        volume += order[:Quantity] * satochi(order[:Rate])
      end
      volume
    end

    BUY_POSITIVE_CHANGES = %i[OpenBuyOrders_change buy_volume_change orders_change Bid_change High_change Ask_change Last_change BaseVolume_change].freeze
    SELL_NEGATIVE_CHANGES = %i[OpenSellOrders_change sell_volume_change spread_change].freeze

    MAX_HOLDS_COUNT = 3

    BITTREX_COMMISSION = 0.0025

  end
end
