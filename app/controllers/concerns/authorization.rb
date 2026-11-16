# Checks the signed-in user's role permissions before every page and action (see Permission).
# A page no permission covers is open only to a Super admin, so nothing is left open by mistake.
module Authorization
  extend ActiveSupport::Concern

  # Open to everyone who is signed in.
  OPEN = %w[welcome#index quick_search password_changes].freeze

  included do
    before_action :authorize_permission!, unless: :devise_controller?
    helper_method :can?, :can_any?
  end

  def can?(permission)
    current_user&.can?(permission) || false
  end

  def can_any?(*permissions)
    current_user&.can_any?(*permissions) || false
  end

  private

  def authorize_permission!
    return unless current_user
    return if current_user.superadmin?
    return if OPEN.include?(controller_path) || OPEN.include?("#{controller_path}##{action_name}")

    needed = Permission.for_action(controller_path, action_name)
    return if needed.any? { |p| current_user.can?(p) }

    deny_access(needed)
  end

  def deny_access(needed)
    what = needed.any? ? needed.map { |p| Permission.label(p).downcase }.to_sentence(two_words_connector: " or ", last_word_connector: " or ") : "this page"
    message = "Your role (#{current_user.role_name}) doesn't allow you to #{what.sub(/\Aview/, 'view')}. Ask a Super admin if you need it."
    message = "Your role (#{current_user.role_name}) can't open this page. Ask a Super admin if you need it." if needed.empty?

    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, alert: message, status: :see_other }
      format.any { head :forbidden }
    end
  end
end
