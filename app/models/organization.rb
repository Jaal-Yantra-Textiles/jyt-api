class Organization < ApplicationRecord
    belongs_to :owner, class_name: "User"
    has_and_belongs_to_many :members,
        class_name: "User",
        join_table: "organizations_users"

    has_many :assets, dependent: :destroy

    has_many :invitations
    validates :name, presence: true
    validates :industry, presence: true

    # for the dynamic models
    has_many :dynamic_model_definitions

      def invite_user(email)
          invitation = invitations.create(email: email, status: "pending")
          if invitation.persisted?
            OrganizationMailer.invite_user(invitation).deliver_later
            true
          else
            false
          end
        end

        def add_user(user)
            if self.members.exists?(user.id)
              errors.add(:user, "is already part of the organization")
              return false
            end
            members << user
            true
        end

      def super_admin?(user)
         user == owner
       end
end
