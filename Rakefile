require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

namespace :app do

  desc 'Turn profit balance strategy'
  task :turn do
    Sequel::Model.db = Sequel.connect ENV.fetch('DATABASE_URL')
    require_relative 'strategies/profit_balance_bittrex'
    require_relative 'db/models/bittrex_ticker'
    tickers = Models::BittrexTicker.new
    strategy = Strategies::Bittrex::ProfitBalance.new ENV.fetch('BITTREX_KEY'),
                                                     ENV.fetch('BITTREX_SECRET'),
                                                     tickers
    strategy.turn!
  end

end

namespace :db do
  postgresql_url = ENV.fetch('DATABASE_URL')

  desc 'Run migrations'
  task :migrate, [:version] do |_t, args|
    Sequel.extension :migration
    Sequel.extension :pg_json
    version = args[:version].to_i if args[:version]
    Sequel.connect(postgresql_url) do |db|
      Sequel::Migrator.run(db, 'db/migrations', target: version)
    end
  end

end
