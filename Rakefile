require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

namespace :app do
  Sequel::Model.db = Sequel.connect ENV.fetch('DATABASE_URL')
  require_relative 'bots/bittrex'
  require_relative 'db/models/bittrex_ticker'
  bot = Bittrex::Bot.new ENV.fetch('BITTREX_KEY'),
                         ENV.fetch('BITTREX_SECRET')
  desc 'Turn profit balance strategy'
  task :turn do
    tickers = Models::BittrexTicker.new
    bot.turn_profit_balance_strategy!(tickers)
  end

  task :sell_all do
    bot.sell_all
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

  desc 'Run migrations'
  task :clear do
    Sequel.connect(postgresql_url) do |db|
      db.execute 'DELETE FROM bittrex_tickers'
    end
  end

end
