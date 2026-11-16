# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  EMAIL_FAILURES = [ArgumentError, Net::ProtocolError, Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError].freeze

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    super
  rescue *EMAIL_FAILURES => e
    logger.error("Password reset email failed: #{e.class}: #{e.message}")
    redirect_to new_user_password_path, status: :see_other,
                alert: "We could not send the reset email. Try again later, or ask your administrator to reset your password."
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
