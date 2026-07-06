# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def approved(user)
    @user = user
    mail subject: "Your account has been approved", to: user.email_address
  end

  def rejected(user)
    @user = user
    mail subject: "Your registration request", to: user.email_address
  end

  def suspended(user)
    @user = user
    mail subject: "Your account has been suspended", to: user.email_address
  end
end
