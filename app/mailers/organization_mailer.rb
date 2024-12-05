class OrganizationMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def invite_user(invitation)
    @invitation = invitation
    @organization = invitation.organization

    mail(
      to: @invitation.email,
      subject: "You've been invited to join #{@organization.name}"
    )
  end

  private

  def accept_invitation_url(invitation)
    accept_api_v1_invitation_url(invitation)
  end
  helper_method :accept_invitation_url
end
