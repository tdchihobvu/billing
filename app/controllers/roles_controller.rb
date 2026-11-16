# Roles and permissions: Super admins create roles, choose what each can do, and assign people.
# Access is the "roles.manage" permission, which only the Super admin role has.
class RolesController < ApplicationController
  before_action :load_roles
  before_action :set_role, only: %i[show edit update destroy assign]
  before_action :refuse_superadmin_role, only: %i[edit update destroy]

  def index
    @counts = tenant.users.group(:role).count
  end

  def show
    redirect_to edit_role_path(@role) unless @role.superadmin?
    @people = @role.users.order(:firstname, :lastname)
  end

  def new
    source = @roles.find { |r| r.id.to_s == params[:copy] }
    @role = Role.new(tenant_id: tenant.id, permissions: source ? source.permissions : [],
                     name: source ? "#{source.name} (copy)" : nil, description: source&.description)
  end

  def create
    @role = Role.new(role_params.merge(tenant_id: tenant.id, built_in: false, position: (@roles.map(&:position).max || 0) + 1))
    if @role.save
      redirect_to edit_role_path(@role), notice: "#{@role.name} was created. Now add the people who should have it."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @people = @role.users.order(:firstname, :lastname)
    @others = tenant.users.where.not(role: [@role.key, "superadmin"]).where.not(id: current_user.id).order(:firstname, :lastname)
  end

  def update
    if @role.update(role_params)
      redirect_to edit_role_path(@role), notice: "#{@role.name} was saved. People with this role get the change on their next page."
    else
      @people = @role.users.order(:firstname, :lastname)
      @others = tenant.users.where.not(role: [@role.key, "superadmin"]).where.not(id: current_user.id).order(:firstname, :lastname)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @role.destroy
      redirect_to roles_path, notice: "#{@role.name} was deleted.", status: :see_other
    else
      redirect_to edit_role_path(@role), alert: @role.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # Moves the chosen people into this role.
  def assign
    return redirect_to(roles_path, alert: "Super admins are made from the Users page, one at a time.") if @role.superadmin?

    ids = Array(params[:user_ids]).reject(&:blank?)
    people = tenant.users.where(id: ids).where.not(role: "superadmin").where.not(id: current_user.id)
    moved = people.select { |u| u.update(role: @role.key) }
    notice = moved.any? ? "#{moved.map(&:fullname).to_sentence} #{moved.size == 1 ? 'is' : 'are'} now #{@role.name}." : "Choose at least one person to add."
    redirect_to edit_role_path(@role, anchor: "people"), notice: notice, status: :see_other
  end

  private

  def load_roles
    @roles = Role.for(tenant).to_a
  end

  def set_role
    @role = Role.where(tenant_id: tenant.id).find(params[:id])
  end

  def refuse_superadmin_role
    redirect_to role_path(@role), alert: "The Super admin role always has every permission and can't be changed." if @role.superadmin?
  end

  def role_params
    permitted = params.require(:role).permit(:name, :description, permissions: [])
    permitted[:permissions] ||= [] if params[:role].key?(:permissions_submitted)
    permitted
  end
end
