if defined?(Rails::Server) || defined?(Rails::Console)
  begin
    # Establish connection
    ActiveRecord::Base.establish_connection

    # Check if the database is active and ready
    if ActiveRecord::Base.connection.active?
      ActiveRecord::Base.connection.execute("SELECT 1")
      puts "Database connected successfully."
    end
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid => e
    puts "Skipping database check: #{e.message}"
  end
end
