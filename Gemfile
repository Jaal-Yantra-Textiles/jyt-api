source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.6" # Adjust this to your Ruby version

# Rails core gems
gem "rails", "~> 8.0.0"
gem "pg", "~> 1.5"
gem "puma", "~> 6.5"

# API related gems
gem "rack-cors"
gem "active_model_serializers"
gem "pagy" # For pagination
gem "oj" # For faster JSON parsing

# Authentication & Authorization
gem "bcrypt"
gem "jwt"

gem "bootsnap", ">= 1.4.4", require: false

gem "omniauth"
gem "omniauth-rails_csrf_protection"


## Social Accounts
gem "omniauth-google-oauth2"
gem "omniauth-facebook"

# For Paging
gem "kaminari"

# Gemfile
gem "jsonapi-serializer"

# Development and testing gems
group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "pry-rails"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rswag-api"
  gem "rswag-ui"
  gem "rswag-specs"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "listen"
  gem "spring"
  gem "annotate"
  gem "bullet" # For N+1 query detection
end

group :test do
  gem "shoulda-matchers"
  gem "database_cleaner-active_record"
end
