# Building blocks for the ZIMURA screens (see app/assets/stylesheets/_zimura.scss).
module DesignHelper
  def zmoney(amount, currency = nil, precision: 2)
    figure = number_with_precision(amount.to_d, precision: precision, delimiter: ",")
    return content_tag(:span, figure, class: "money") if currency.blank?

    content_tag(:span, class: "money") { content_tag(:span, currency, class: "cur") + figure }
  end

  # Status words come from the real system: Fully Paid, Partly Paid, Not Paid, Overpaid, Void.
  def zstatus_tag(invoice)
    label = invoice.deleted? ? "Void" : (invoice.status.present? ? Invoice.statuses[invoice.status] : "Not Paid")
    tone = case invoice.status
           when "fully_paid", "overpaid" then "paid"
           when "partly_paid" then "part"
           when "void", "deleted" then ""
           else "late"
           end
    tone = "" if invoice.deleted?
    content_tag(:span, label, class: "ztag #{tone}")
  end

  # Four bars that fill as an invoice ages past 30, 60 and 90 days.
  def zage(days)
    level = if days <= 0 then 0 elsif days <= 30 then 1 elsif days <= 60 then 2 elsif days <= 90 then 3 else 4 end
    bars = [6, 9, 12, 16].each_with_index.map { |h, k| content_tag(:i, "", class: (k < level ? "f" : nil), style: "height:#{h}px") }
    content_tag(:span, safe_join(bars), class: "zage", "aria-hidden": "true")
  end

  def zempty(title, body, action = nil)
    glyph = <<~SVG.html_safe
      <svg class="glyph" viewBox="0 0 64 64" aria-hidden="true"><circle cx="32" cy="36" r="20" fill="#f3b81b"/><path d="M26 54c0-9 2.6-15 6-19 3.4 4 6 10 6 19z" fill="var(--accent)"/><circle cx="32" cy="27" r="4" fill="var(--accent)"/></svg>
    SVG
    content_tag(:div, class: "zempty") do
      safe_join([glyph, content_tag(:h3, title), content_tag(:p, body), action].compact)
    end
  end

  # A "More" button with a menu. Items: [label, url, options] or :divider.
  def zmore_menu(items, label: "More")
    content_tag(:div, class: "zmore", data: { controller: "zmenu" }) do
      button = content_tag(:button, safe_join([label, content_tag(:i, "", class: "fas fa-chevron-down", "aria-hidden": "true")], " "),
                           type: "button", class: "b", "aria-haspopup": "menu", "aria-expanded": "false",
                           data: { action: "zmenu#toggle", zmenu_target: "button" })
      menu = content_tag(:div, class: "zmenu", role: "menu", hidden: true, data: { zmenu_target: "menu" }) do
        safe_join(items.map do |item|
          next tag.hr if item == :divider
          text, url, options = item
          options ||= {}
          if options.delete(:button)
            button_to(text, url, **options.merge(role: "menuitem", form: { class: "button_to" }))
          else
            link_to(text, url, **options.merge(role: "menuitem"))
          end
        end)
      end
      button + menu
    end
  end

  # Overdue invoices for the sidebar badge: unpaid and past the due date (or the validity window).
  def sidebar_overdue_count
    # Same rule and date window as the Invoices list's Overdue tab.
    @sidebar_overdue_count ||= tenant.invoices.where(invoice_date: (Date.current.beginning_of_year - 1.year)..Date.current)
                                     .overdue_after(invoice_validity).count
  end

  # ---- settings lists (shared/_crud_*) ----
  ZCRUD_SKIP = %w[id created_at updated_at tenant_id encrypted_password].freeze

  def zcrud_columns(model)
    model.column_names - ZCRUD_SKIP
  end

  def zcrud_label(column)
    column.to_s.delete_suffix("_id").humanize
  end

  def zcrud_numeric?(model, column)
    %i[decimal float integer].include?(model.columns_hash[column.to_s]&.type) && !column.to_s.end_with?("_id")
  end

  # How a linked record is named in lists: the first of these it has (users have no `name`).
  ZCRUD_NAME_METHODS = %i[name user_fullname fullname company_name description title username reference_number].freeze
  # Secrets are never shown in full: only enough to tell them apart.
  ZCRUD_SECRET = /token|password|secret|api_key/i

  def zcrud_record_name(linked)
    method = ZCRUD_NAME_METHODS.find { |m| linked.respond_to?(m) && linked.public_send(m).present? }
    method ? linked.public_send(method).to_s : "##{linked.id}"
  end

  def zcrud_value(record, column)
    value = record.public_send(column)
    if column.to_s.match?(ZCRUD_SECRET)
      return value.present? ? "••••#{value.to_s.last(4)}" : ""
    end
    if column.to_s.end_with?("_id")
      assoc = column.to_s.delete_suffix("_id")
      if record.respond_to?(assoc)
        linked = record.public_send(assoc)
        return zcrud_record_name(linked) if linked
      end
    end
    case value
    when true then "Yes"
    when false then "No"
    when BigDecimal, Float then number_with_precision(value, precision: 2, delimiter: ",")
    when Date then value.strftime("%d %b %Y")
    when Time, DateTime, ActiveSupport::TimeWithZone then value.strftime("%d %b %Y %H:%M")
    when nil then ""
    else value.to_s
    end
  end

  def zinitials(name)
    name.to_s.split.first(2).map { |w| w[0] }.join.upcase
  end

  # This company's roles, loaded once per page.
  def tenant_roles
    @tenant_roles ||= Role.for(tenant).to_a
  end

  # The name people see for a role.
  def role_label(key)
    tenant_roles.find { |r| r.key == key.to_s }&.name || key.to_s.humanize
  end

  # Role choices for the user forms. Only a Super admin may hand out the Super admin role.
  def role_options
    tenant_roles.reject { |r| r.superadmin? && !current_user.superadmin? }.map { |r| [r.name, r.key] }
  end

  # A licence's approval stage as a tag, with the reason it can't print yet as a tooltip.
  def zlicense_approval_tag(license)
    content_tag(:span, license.approval_label, class: "ztag #{license.approval_tone}", title: license.approval_hint)
  end

  # Licences waiting for this user to act on (for the sidebar count and the dashboard).
  def license_approvals_waiting_count
    return 0 unless current_user&.sees_license_approvals?

    @license_approvals_waiting_count ||= begin
      base = License.joins(:invoice).where(invoices: { tenant_id: tenant.id, deleted: false })
      statuses = []
      statuses << "awaiting_finance" if current_user.finance_officer?
      statuses << "awaiting_manager" if current_user.final_approver?
      base.where(approval_status: statuses).count
    end
  end

  AUTH_FALLBACK_BRAND = "#a83a3f"

  # Branding for signed-out pages. With a single company we can show its name, colour and logo;
  # with several we can't know whose page this is, so it stays neutral.
  def auth_brand
    @auth_brand ||= begin
      company = Tenant.count == 1 ? Tenant.first : nil
      settings = company ? company.system_settings.joins(:config_key).pluck("config_keys.name", "system_settings.config_value").to_h : {}
      color = settings["Background Color"].to_s.strip
      file = File.basename(settings["Logo Path"].to_s)
      {
        name: company&.trading_name.presence || company&.company_name || "Billing and Licensing",
        full_name: company&.company_name,
        color: color.match?(/\A#(\h{3}|\h{6})\z/) ? color : AUTH_FALLBACK_BRAND,
        logo: file.present? && File.file?(Rails.root.join("public", "tenant_logo", file)) ? "/tenant_logo/#{ERB::Util.url_encode(file)}" : nil
      }
    end
  end

  # The company's logo from the "Logo Path" setting (a file in public/tenant_logo), or nil.
  def tenant_logo_url
    file = File.basename(tenant_setting("Logo Path").to_s)
    return nil if file.blank? || !File.file?(Rails.root.join("public", "tenant_logo", file))
    "/tenant_logo/#{ERB::Util.url_encode(file)}"
  end
end
