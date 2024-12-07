class AuthMailer < ApplicationMailer
  default from: "noreply@yourdomain.com"

  def password_reset
    @user = params[:user]
    @reset_url = "#{ENV['FRONTEND_URL']}/reset-password?token=#{@user.reset_password_token}"
    mail(to: @user.email, subject: "Reset your password")
  end

  def email_verification
    @user = params[:user]
    @verification_url = "#{ENV['FRONTEND_URL']}/verify-email?token=#{@user.email_verification_token}"
    mail(to: @user.email, subject: "Verify your email")
  end
end
