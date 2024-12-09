module RequestSpecHelper
  def json_response
    JSON.parse(response.body)
  end

  def auth_token(user)
    token = JwtService.encode({ user_id: user.id })
    "Bearer #{token}"
  end

  def auth_headers(user)
    {
      'Authorization': auth_token(user),
      'Content-Type': 'application/json'
    }
  end
end
