
class JwtService
  HMAC_SECRET = Rails.application.credentials.secret_key_base
  ALGORITHM = 'HS256'.freeze

  def self.encode(payload)
    JWT.encode(payload, HMAC_SECRET, ALGORITHM)
  end

  def self.decode(token)
    JWT.decode(token, HMAC_SECRET, true, algorithm: ALGORITHM).first
  rescue JWT::DecodeError
    nil
  end
end
