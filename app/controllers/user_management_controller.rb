# People who use the system. Access is set by the "users.view" / "users.manage" permissions
# (see Permission). Only a Super admin can make someone a Super admin, or change one.
class UserManagementController < ApplicationController
  before_action :set_user, only: %i[details reset]
  before_action :load_roles

  def index
    order = @roles.map(&:key)
    @users_by_role = tenant.users.order(:firstname, :lastname).group_by(&:role)
                           .sort_by { |role, _| order.index(role) || order.size }.to_h
    @total_users = @users_by_role.values.sum(&:size)
    @role = @users_by_role.key?(params[:role]) ? params[:role] : "all"
  end

  def new
    @user = User.new(tenant_id: tenant.id, role: params[:role].presence_in(@roles.map(&:key)) || "cashier")
  end

  def save
    @user = User.new(user_params)
    @user.tenant_id = tenant.id
    @user.role = "cashier" if @user.role.blank?
    @user.temporary_password = true
    @user.must_change_password = true
    return refuse_superadmin(:new) unless may_assign?(@user.role)

    if @user.save
      redirect_to details_user_management_index_url(id: @user), notice: "#{@user.fullname} was added as #{@user.role_name}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def details
  end

  def edit
    @user = tenant.users.find(params[:id])
    return redirect_to(details_user_management_index_path(id: @user), alert: "Only a Super admin can edit a Super admin.") unless may_change?(@user)
  end

  def update
    @user = tenant.users.find(params[:user][:id])
    return redirect_to(user_management_index_url, alert: "Only a Super admin can edit a Super admin.", status: :see_other) unless may_change?(@user)

    attrs = user_params
    new_role = attrs[:role].presence || @user.role
    if @user == current_user && new_role != @user.role
      return redirect_to(user_management_index_url, alert: "You can't change your own role. Ask another Super admin.", status: :see_other)
    end
    return refuse_superadmin(:edit) unless may_assign?(new_role)

    if @user.update(attrs)
      redirect_to user_management_index_url, notice: "#{@user.fullname} was updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def reset
    return redirect_to(details_user_management_index_path(id: @user), alert: "Only a Super admin can reset a Super admin's password.") unless may_change?(@user)

    temporary = User.temporary_password
    @user.temporary_password = true
    @user.password = temporary
    @user.must_change_password = true
    @user.save!(validate: false)
    redirect_to details_user_management_index_url(id: @user), notice: "Temporary password for #{@user.username}: #{temporary}. It is shown only once, and they must change it when they sign in."
  end

  private

  def set_user
    @user = tenant.users.find(params[:id])
  end

  def load_roles
    @roles = Role.for(tenant).to_a
  end

  # Only a Super admin may touch another Super admin.
  def may_change?(user)
    current_user.superadmin? || !user.superadmin?
  end

  # Only a Super admin may hand out the Super admin role.
  def may_assign?(role_key)
    current_user.superadmin? || role_key != "superadmin"
  end

  def refuse_superadmin(view)
    @user.errors.add(:role, "Super admin can only be given by a Super admin")
    render view, status: :unprocessable_entity
  end

  def user_params
    params.require(:user).permit(:firstname, :lastname, :username, :role, :email, :password, :password_confirmation)
  end
end
