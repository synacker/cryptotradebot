# typed: true
module TradeApi
  module Common
    SATOCHI_IN_BTC = 100_000_000

    def satochi(btc)
      (btc * SATOCHI_IN_BTC).to_i
    end

    def revenue(satochi, commission)
      satochi - factor(satochi, commission)
    end

    def factor(satochi, value)
      (satochi * value).to_i
    end

    def bitcoin(satochi)
      satochi.to_f / SATOCHI_IN_BTC
    end


    def currency_name(market_name)
      market_name.split('-').last.to_sym
    end

    def spread(old_value, new_value)
      (old_value.to_f - new_value) / old_value * 100
    end
  end
end