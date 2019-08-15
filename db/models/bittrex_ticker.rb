require 'sequel'

module Models
  class BittrexTicker < Sequel::Model
    def last_record_data
      record = Models::BittrexTicker.reverse(:created_at).limit(1).first
      if record
        result = JSON::parse(record[:ticker_map], symbolize_names: true),
                 record[:start_balance].to_i,
                 record[:profit_balance].to_i
      else
        result = {}, 0, 0
      end
      result
    end

    def save_record(ticker, start_balance, profit_balance)
      Models::BittrexTicker.insert ticker_map: ticker,
                                   start_balance: start_balance,
                                   profit_balance: profit_balance,
                                   created_at: Time.now.utc
    end

  end
end