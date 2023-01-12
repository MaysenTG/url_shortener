class ContactMailer < ApplicationMailer
  default from: "greenwood.maysen@gmail.com"
  
  def contact(name, email, message)
    @user_name = name
    @user_email = email
    @message = message

    mail(to: "greenwood.maysen@gmail.com", subject: 'New contact message')
  end
end
