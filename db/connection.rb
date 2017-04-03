require "active_record"

ActiveRecord::Base.establish_connection({
  development:
    adapter: postgresql,
    database: development,
    username: <%= ENV['PG_USER'] %>,
    password: <%= ENV['PG_PASS'] %>,
    host: localhost

  })