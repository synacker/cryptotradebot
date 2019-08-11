require 'typhoeus'
require 'base64'
require 'openssl'

module TradeApi
  module Bittrex
    class Client
      def initialize(key, secret)
        @key = key.strip
        @secret = secret.strip
      end

      def open_orders
        bittrex_get 'market/getopenorders'
      end

      def create_buy_orders(orders)
        #create_orders :buy, orders
      end

      def create_sell_orders(orders)
        #create_orders :sell, orders
      end


      def markets_info(market_names)
        hydra = Typhoeus::Hydra.hydra
        result = []
        market_names.each do |market_name|
          request = public_request 'public/getmarketsummary',
                                   market: market_name
          request.on_complete do |response|
            market = JSON::parse(response.body, symbolize_names: true)[:result]&.first
            result.push market if market
          end
          hydra.queue request
        end
        hydra.run
        result
      end

      def cancel_orders(uuids)
        hydra = Typhoeus::Hydra.hydra

        uuids.each do |uuid|
          request = private_request 'market/cancel',
                                    uuid: uuid
          request.on_complete do |response|
            result = JSON::parse(response.body, symbolize_names: true)
            puts "cancel order #{uuid} result: #{result}"
          end

          hydra.queue request
        end
        hydra.run
      end

      def cancel_all_orders
        cancel_uuids = open_orders.map { |order| order[:OrderUuid] }
        cancel_orders cancel_uuids
      end


      def get_balances
        bittrex_get('account/getbalances')
      end

      def get_order_books(market_names)
        hydra = Typhoeus::Hydra.hydra
        result = {}
        market_names.each do |market_name|
          request = public_request 'public/getorderbook',
                                   market: market_name,
                                   type: :both
          request.on_complete do |response|
            orders = invoke_result response.body
            result[market_name] = orders
          end
          hydra.queue request
        end
        hydra.run
        result
      end

      def get_ticker
        bittrex_get 'public/getmarketsummaries', false
      end

      private

      def invoke_result(response)
        json = JSON::parse(response, symbolize_names: true)
        success = json[:success]
        if success
          json[:result]
        else
          raise 'Bad response: ' + json.to_json
        end
      end

      def create_orders(type, orders)
        hydra = Typhoeus::Hydra.hydra
        orders.reject! { |order| order[:quantity].zero? }
        created_orders = []
        orders.each do |order|
          request = order_request type, order
          request.on_complete do |response|
            order_result = invoke_result response.body
            order[:type] = type
            order[:created_at] = Time.now.utc
            order[:uuid] = order_result[:uuid]
            created_orders.push order
            puts "#{type} order #{order.to_json} creation result: #{response.to_json}"
          end
          hydra.queue request
        end
        hydra.run
        created_orders
      end

      def order_request(type, order)
        path = case type
               when :buy
                 'market/buylimit'
               when :sell
                 'market/selllimit'
               end
        private_request path,
                        market: order[:market],
                        quantity: order[:quantity],
                        rate: order[:rate]
      end


      def bittrex_get(path, private = true)
        response = if private
                     (private_request path).run
                   else
                     (public_request path).run
                   end
        invoke_result response.body
      end

      def public_request(path, params = {})
        Typhoeus::Request.new(url(path),
                              method: :get,
                              params: params)
      end

      def private_request(path, params = {})
        nonce = Time.now.to_i
        url = url(path)
        params[:apikey] = @key
        params[:nonce] = nonce
        apisign = signature(full_url(url, params))

        Typhoeus::Request.new(url,
                              method: :get,
                              params: params,
                              headers: {apisign: apisign})
      end

      def signature(url)
        OpenSSL::HMAC.hexdigest('sha512', @secret, url)
      end

      def full_url(url, params)
        query = params.map {|k, v| "#{k}=#{v}"}.join '&'
        "#{url}?#{query}"
      end

      def url(path)
        "#{BITTREX_HOST}/#{path}"
      end

      BITTREX_HOST = 'https://bittrex.com/api/v1.1'.freeze

    end
  end
end