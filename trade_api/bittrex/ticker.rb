require_relative '../common'

module TradeApi
  module Bittrex
    class Ticker
      include Common

      attr_reader :ticker_map

      def initialize(client)
        @client = client
        @ticker_map = {}
      end

      def pairs
        @ticker_map.empty? ? [] : @ticker_map.values
      end

      def update!
        @ticker_map = @client.get_ticker
        @ticker_map.select! do |pair|
          pair[:MarketName].match('BTC-')
        end
        add_calculated_fields!
        to_hash!
      end

      def calculate_change_values!(last_ticker)
        @ticker_map.each do |name, pair|
          last_pair = last_ticker[name.to_sym]
          if last_pair
            CHANGE_FIELDS.each do |field|
              pair["#{field}_change".to_sym] = pair[field] - last_pair[field]
            end

            %i[Ask Bid].each do |field|
              pair["#{field}_change_spread".to_sym] = change_pair_spread pair, field
            end

            ORDER_FIELDS.each do |field|
              pair[field] = last_pair[field]
            end
          end
          pair
        end
      end

      private

      def to_hash!
        @ticker_map = @ticker_map.each_with_object({}) { |pair, result| result[pair[:name]] = pair }
      end

      def pair_spread(pair)
        pair[:Ask].zero? ? 0 : spread(pair[:Ask], pair[:Bid])
      end

      def change_pair_spread(pair, field)
        pair[field].zero? ? 0 : pair["#{field}_change".to_sym] / pair[field] * 100
      end

      def add_calculated_fields!
        @ticker_map.map! do |pair|
          BTC_FIELDS.each do |field|
            pair[field] = satochi pair[field]
          end

          pair[:name] = currency_name pair[:MarketName]

          ADDITIONAL_FIELDS.each do |field|
            pair[field] = 0
          end

          CHANGE_FIELDS.each do |field|
            pair["#{field}_change".to_sym] = 0
          end

          pair[:spread] = pair_spread pair
          pair[:orders] = pair[:OpenBuyOrders] + pair[:OpenSellOrders]

          pair
        end
      end


      BTC_FIELDS = %i[High Low Volume Last BaseVolume Bid Ask].freeze
      CHANGE_FIELDS = (BTC_FIELDS + %i[OpenSellOrders OpenBuyOrders spread orders sell_volume buy_volume]).freeze
      ORDER_FIELDS = %i[buy_ask buy_date buy_uuid]
      ADDITIONAL_FIELDS = (ORDER_FIELDS + %i[buy_volume sell_volume ask_change_spread bid_change_spread]).freeze
    end
  end
end