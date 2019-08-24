require_relative '../common'
require_relative 'client'
require_relative 'portfolio'

module TradeApi
  module Bittrex
    class Exchange
      include Common

      def initialize(client)
        @client = client
        @opened_orders = {}
      end

      def update!
        @client.open_orders.each do |order|
          @opened_orders[order[:Exchange]] = order
        end
      end

      def buy(markets, active_deposit, commission, markup = 0)
        active_deposit = active_deposit / (1 + commission)
        buy_orders = @client.markets_info(markets).map do |market|
          order = {}
          order[:market] = market[:MarketName]
          order[:rate] = market[:Ask] + bitcoin(markup)
          order[:quantity] = active_deposit.to_f / satochi(order[:rate])
          order
        end


        @client.create_buy_orders buy_orders
      end

      def cancel_all_orders
        @client.cancel_all_orders
      end

      def sell_by_current_bid(actives, markdown = 0)
        sell_markets = actives.values.map do |active|
          "BTC-#{active[:Currency].to_s}"
        end
        sell_orders = @client.markets_info(sell_markets).map do |market|
          order = {}
          order[:market] = market[:MarketName]
          order[:rate] = market[:Bid] + bitcoin(markdown)
          order[:quantity] = actives[currency_name order[:market]][:Available]
          order
        end

        @client.create_sell_orders sell_orders
      end
    end
  end
end