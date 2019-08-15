Sequel.migration do
  up do
    create_table(:bittrex_tickers) do
      primary_key :id
      Timestamp :created_at
      jsonb :ticker_map
      jsonb :portfolio
      BigDecimal :start_balance
      BigDecimal :profit_balance

      index :created_at
    end
  end
end