class ContactController < ApplicationController
  def index
  end
  
  def send_mail
    ContactMailer.contact(params[:name], params[:email], params[:message]).deliver_now
    
    redirect_to contact_path, notice: "Your message has been sent!"
  end
end
