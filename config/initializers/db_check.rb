# config/initializers/db_check.rb
begin
  ActiveRecord::Base.establish_connection
  ActiveRecord::Base.connection.active? # This will verify the active connection
  ActiveRecord::Base.connection.execute('SELECT 1')
  puts 'Database connected successfully.'
rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid => e
  puts "Database connection error: #{e.message}"
  exit(1)
end
