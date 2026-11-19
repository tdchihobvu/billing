require "prawn/qrcode"

# Payment receipt. Layout follows what leading billing systems put first (Stripe, Xero):
# who was paid, the amount received in large type, when and how it was paid, what it was
# applied to, and what is still owed. A voided receipt is clearly marked VOID.
class ReceiptPdf < Prawn::Document
  include ActionView::Helpers::NumberHelper

  FONT_DIR = Rails.root.join("app/assets/fonts/pdf")
  INK = "1C1718"
  SOFT = "6F6364"
  LINE = "E6DADB"
  PAID = "1E7A4C"
  LATE = "B42318"

  def initialize(receipt, tenant:, logo_file:, brand: "A83A3F", user_title: "Inspector")
    super(page_size: "A4", margin: [36, 40, 50, 40], info: { Title: "Receipt #{receipt.reference_number}", Creator: "Aibes Billing System" })
    @r = receipt
    @tenant = tenant
    @brand = brand.to_s.delete("#").presence || "A83A3F"
    @brand = "A83A3F" unless @brand.match?(/\A\h{6}\z/)
    @logo = logo_path_for(logo_file)
    @user_title = user_title
    @void = receipt.deleted
    register_fonts

    draw_accent
    draw_header
    draw_title
    draw_amount
    draw_parties
    draw_allocation
    draw_notes
    draw_closing
    draw_void_mark if @void
    draw_footer
  end

  private

  # ---------------------------------------------------------------- setup
  def register_fonts
    font_families.update(
      "Playfair" => { normal: FONT_DIR.join("PlayfairDisplay-Variable.ttf").to_s },
      "Poppins" => { normal: FONT_DIR.join("Poppins-Medium.ttf").to_s, bold: FONT_DIR.join("Poppins-SemiBold.ttf").to_s },
      "Oswald" => { normal: FONT_DIR.join("Oswald-SemiBold.ttf").to_s }
    )
    font "Helvetica"
  end

  def logo_path_for(file)
    path = Rails.root.join("public/tenant_logo", File.basename(file.to_s))
    File.file?(path) ? path.to_s : nil
  end

  def money(value)
    number_with_precision(value.to_d, precision: 2, delimiter: ",")
  end

  def cur
    @r.currency&.name.to_s
  end

  # A pale tint of the brand colour for panels.
  def tint(hex, amount)
    r, g, b = hex.scan(/../).map { |c| c.to_i(16) }
    [r, g, b].map { |c| (c + (255 - c) * amount).round.clamp(0, 255).to_s(16).rjust(2, "0") }.join
  end

  def label(text, at:, width: 200, align: :left)
    fill_color SOFT
    text_box text.upcase, at: at, width: width, size: 7, character_spacing: 0.8, style: :bold, align: align
    fill_color INK
  end

  # ---------------------------------------------------------------- sections
  def draw_accent
    canvas do
      fill_color @brand
      fill_rectangle [0, bounds.top], bounds.width, 6
      fill_color "F3B81B"
      fill_rectangle [0, bounds.top - 6], bounds.width, 2
      fill_color INK
    end
  end

  def draw_header
    top = cursor
    image @logo, fit: [74, 74], at: [0, top] if @logo
    lines = [@tenant.address_1, @tenant.address_2, [@tenant.location, @tenant.city].compact_blank.join(", "), @tenant.country].compact_blank
    contact = [(@tenant.phone_1.presence && "T: #{@tenant.phone_1}#{", #{@tenant.mobile_1}" if @tenant.mobile_1.present?}"), (@tenant.sales_email.presence && "E: #{@tenant.sales_email}")].compact
    tax = [(@tenant.vat_number.presence && "VAT No: #{@tenant.vat_number}"), (@tenant.bp_number.presence && "TIN: #{@tenant.bp_number}")].compact

    bounding_box([bounds.width - 260, top], width: 260) do
      font("Poppins", style: :bold) { text @tenant.company_name.to_s, size: 11.5, align: :right, color: INK }
      move_down 3
      (lines + contact + tax).each { |l| text l, size: 8, align: :right, color: SOFT, leading: 1 }
    end
    move_cursor_to [top - 84, cursor].min - 14
  end

  def draw_title
    y = cursor
    font("Playfair") { text_box "Receipt", at: [0, y], size: 32, color: INK, width: 250 }
    # Status pill + number on the right
    status = @void ? "VOID" : "PAID"
    colour = @void ? LATE : PAID
    pill_w = 54
    fill_color tint(colour, 0.86)
    fill_rounded_rectangle [bounds.width - pill_w, y - 2], pill_w, 18, 9
    fill_color colour
    text_box status, at: [bounds.width - pill_w, y - 2], width: pill_w, height: 18, align: :center, valign: :center, size: 8.5, style: :bold, character_spacing: 1
    fill_color INK
    label "Receipt No.", at: [bounds.width - 220, y - 24], width: 220, align: :right
    font("Poppins", style: :bold) { text_box @r.reference_number.to_s, at: [bounds.width - 220, y - 33], width: 220, align: :right, size: 14 }
    move_down 62
  end

  def draw_amount
    h = 96
    y = cursor
    fill_color tint(@brand, 0.93)
    fill_rounded_rectangle [0, y], bounds.width, h, 10
    fill_color @brand
    fill_rounded_rectangle [0, y], 5, h, 2

    label "Amount received", at: [22, y - 18]
    font("Oswald") do
      fill_color INK
      text_box cur, at: [22, y - 36], size: 16, width: 60
      cur_w = width_of(cur, size: 16) + 6
      text_box money(@r.amount), at: [22 + cur_w, y - 28], size: 36, width: 260, overflow: :shrink_to_fit
    end

    facts = [
      ["Date received", @r.transaction_date&.strftime("%d %B %Y")],
      ["Payment method", @r.payment_form&.name],
      ["Recorded by", @r.user&.fullname.presence || @r.user_fullname]
    ]
    col_x = bounds.width - 220
    facts.each_with_index do |(k, v), i|
      yy = y - 16 - i * 25
      label k, at: [col_x, yy], width: 200
      font("Poppins") { text_box v.to_s.presence || "Not given", at: [col_x, yy - 9], size: 9.5, width: 205, color: INK }
    end
    move_down h + 22
  end

  def draw_parties
    y = cursor
    c = @r.client
    label "Received from", at: [0, y]
    bounding_box([0, y - 12], width: 250) do
      font("Poppins", style: :bold) { text c.name.to_s.upcase, size: 11, color: INK }
      move_down 2
      [c.address_1, [c.address_2, c.location].compact_blank.join(" "), [c.city, c.country].compact_blank.join(", ")].compact_blank.each { |l| text l, size: 8.5, color: SOFT }
      extra = [(c.client_account_number.presence && "Account No: #{c.client_account_number}"), (c.vat_number.presence && "VAT No: #{c.vat_number}"), (c.bp_number.presence && "TIN: #{c.bp_number}")].compact
      move_down 2 if extra.any?
      extra.each { |l| text l, size: 8.5, color: SOFT }
      @left_bottom = cursor
    end
    left_end = cursor

    move_cursor_to y
    label "Payment for", at: [bounds.width - 240, y], width: 240
    bounding_box([bounds.width - 240, y - 12], width: 240) do
      text @r.description.to_s.presence || "Payment", size: 9.5, color: INK, leading: 1.5
      if @r.reason.present? && @r.reason != @r.description
        move_down 2
        text @r.reason.to_s, size: 8.5, color: SOFT
      end
    end
    move_cursor_to [left_end, cursor].min - 18
  end

  def draw_allocation
    inv = @r.invoice
    label "Applied to", at: [0, cursor]
    move_down 12

    if inv
      paid_to_date = inv.amount_paid.to_d
      total = inv.invoice_total.to_d
      remaining = [total - paid_to_date, 0].max
      balance_text = if @void then "Not applied (void)"
                     elsif remaining <= 0.5 then "Paid in full"
                     else "#{inv.currency&.name} #{money(remaining)}"
                     end
      rows = [["Invoice", "Invoice date", "Invoice total", "This receipt", "Balance remaining"],
              [inv.invoice_number.to_s, inv.invoice_date&.strftime("%d %b %Y").to_s, "#{inv.currency&.name} #{money(total)}",
               "#{cur} #{money(@r.amount)}", balance_text]]
      widths = [110, 90, 105, 100, bounds.width - 405]
    else
      rows = [["Applied to", "This receipt"],
              ["#{@r.client.name}'s account (no invoice selected)", "#{cur} #{money(@r.amount)}"]]
      widths = [bounds.width - 140, 140]
    end

    table(rows, width: bounds.width, column_widths: widths, header: true,
                cell_style: { size: 9, padding: [8, 8], borders: [:bottom], border_color: LINE, border_width: 0.8, text_color: INK }) do |t|
      t.row(0).font_style = :bold
      t.row(0).size = 7.5
      t.row(0).text_color = SOFT
      t.row(0).background_color = tint(@brand, 0.95)
      t.row(0).borders = []
      cols = rows.first.size
      t.columns(cols == 5 ? 2..4 : 1..1).align = :right
      t.cells[1, 0].font_style = :bold
      t.cells[1, cols == 5 ? 3 : 1].font_style = :bold
      if cols == 5
        last = t.cells[1, 4]
        last.font_style = :bold
        last.text_color = case last.content
                          when "Paid in full" then PAID
                          when "Not applied (void)" then SOFT
                          else LATE
                          end
      end
    end
    move_down 14
  end

  def draw_notes
    notes = []
    inv = @r.invoice
    if inv&.respond_to?(:discount_amount) && inv.discount_amount.to_d.positive?
      notes << "Invoice #{inv.invoice_number} includes a discount of #{inv.currency&.name} #{money(inv.discount_amount)}."
    end
    rate = @r.rate.to_d
    if cur.present? && cur != "USD" && rate.positive? && rate != 1
      notes << "Exchange rate used: 1 USD = #{number_with_precision(rate, precision: 4, strip_insignificant_zeros: true)} #{cur}."
    end
    if @void
      notes << "This receipt was voided#{" on #{@r.void_date.strftime('%d %B %Y')}" if @r.void_date}#{": #{@r.void_reason}" if @r.void_reason.present?}. It no longer counts as a payment."
    end
    return if notes.empty?

    notes.each do |n|
      fill_color @void && n.start_with?("This receipt was voided") ? LATE : SOFT
      text n, size: 8.5
      move_down 3
    end
    fill_color INK
    move_down 8
  end

  def draw_closing
    y = [cursor, 150].max
    qr_size = 64
    qr_text = @r.verification_text(@tenant.company_name)
    stroke_color LINE
    line_width 0.8
    stroke_horizontal_line 0, bounds.width, at: y
    render_qr_code(RQRCode::QRCode.new(qr_text, level: :m), pos: [0, y - 12], extent: qr_size, stroke: false)
    fill_color SOFT
    text_box "Scan to check this receipt", at: [qr_size + 10, y - 22], size: 7.5, width: 140
    fill_color INK
    closing = @void ? "This payment was voided" : "Thank you for your payment!"
    font("Playfair") { text_box closing, at: [bounds.width - 300, y - 16], width: 300, align: :right, size: 17, color: @void ? LATE : INK }
    contact = [@tenant.sales_email, @tenant.phone_1].compact_blank.join(" · ")
    if contact.present?
      fill_color SOFT
      text_box "Questions about this receipt? #{contact}", at: [bounds.width - 300, y - 42], width: 300, align: :right, size: 8
      fill_color INK
    end
  end

  def draw_void_mark
    transparent(0.13) do
      fill_color LATE
      rotate(30, origin: [bounds.width / 2, 420]) do
        font("Oswald") { text_box "VOID", at: [0, 500], width: bounds.width, align: :center, size: 170 }
      end
    end
    fill_color INK
  end

  def draw_footer
    by = @r.user&.user_fullname.presence || @r.user_fullname
    number_pages "Receipt ##{@r.reference_number} | Transaction By #{by} | Generated from Aibes Billing System ver7.1",
                 start_count_at: 0, page_filter: :all, at: [0, -22], width: bounds.width, align: :right, size: 7, color: SOFT
    number_pages "A product of Dapsoft Solutions | <page> of <total>",
                 start_count_at: 0, page_filter: :all, at: [0, -32], width: bounds.width, align: :right, size: 5.5, color: SOFT
  end
end
