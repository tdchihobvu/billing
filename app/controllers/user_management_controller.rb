class UserManagementController < ApplicationController

  before_action :set_user, only: %i[ details reset ]

  def index
    @users = tenant.users
  end

  def new
    @user = User.new
    @user.tenant_id = tenant.id
  end

  def save
    @user = User.new(user_params)

    if @user.save
      redirect_to details_user_management_index_url(id: @user), notice: "User was successfully created."
    else
      @user.errors.each do |u|
        puts("******** #{u.full_message}")
      end
      render :new, status: :unprocessable_entity
    end
  end

  def details
  end

  def edit
    @user = User.find(params[:id])

  end

  def update
    @user = User.find(params[:user][:id])
    if current_user.role == 'superadmin'
      if @user.update(user_params)
        redirect_to user_management_index_url, notice: "User was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end 
    else
      redirect_to user_management_index_url, notice: "Ooops! You do not have sufficient privileges to access the page.", status: :see_other
    end   
  end

  def reset
    pass = "#{@user.username.downcase}!@#"
    if current_user.role == 'superadmin'
      @user.update_attribute(:password, pass)
    end
    redirect_to details_user_management_index_url(id: @user), notice: "User Password reset successful"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:firstname, :lastname, :username, :tenant_id, :role, :email, :password, :password_confirmation)
    end

end
