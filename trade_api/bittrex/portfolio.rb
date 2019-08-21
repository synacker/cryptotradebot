require_relative '../common'
require_relative 'client'

module TradeApi
  module Bittrex
    class Portfolio
      include Common

      attr_reader :actives
      attr_reader :deposit

      def initialize(client)
        @client = client
        @actives = {}
        @deposit = 0
      end

      def has?(currency_name)
        @actives.key? currency_name.to_sym
      end

      def available(currency_name)
        has?(currency_name) ? @actives[currency_name][:Available] : 0
      end

      def update!
        @actives = {}
        @deposit = 0
        @client.get_balances.each do |balance|
          active_name = balance[:Currency].to_sym
          balance_value = balance[:Balance]
          if active_name == :BTC
            @deposit = satochi balance[:Available]
          else
            @actives[active_name] = balance if balance_value.positive?
          end
        end
      end

      def holds_count
        @actives.size
      end

      def sell_balance(ticker, commission)
        sell_balance = 0
        @actives.keys.each do |currency_name|
          sell_balance += revenue(available(currency_name) * ticker[currency_name][:Bid], commission).to_i
        end
        sell_balance += deposit
        sell_balance
      end
    end
  end
end