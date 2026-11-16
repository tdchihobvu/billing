# Makes people replace a temporary or default password before using the system.
class PasswordChangesController < ApplicationController
  skip_before_action :require_password_change

  def edit
  end

  def update
    current_user.assign_attributes(password_params)

    if current_user.using_default_password?
      current_user.errors.add(:password, "cannot be your username followed by !@#")
      render :edit, status: :unprocessable_entity
    elsif current_user.save
      bypass_sign_in(current_user)
      redirect_to root_path, notice: "Your password has been changed.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
