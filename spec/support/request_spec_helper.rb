module RequestSpecHelper
  def json_response
    JSON.parse(response.body)
  end

  def auth_headers(user)
    token = JwtService.encode({ user_id: user.id })
    { 'Authorization': "Bearer #{token}", 'Content-Type': 'application/json' }
  end
end
