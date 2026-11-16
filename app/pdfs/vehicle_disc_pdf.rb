require "prawn/qrcode"

# Vehicle licence disc, drawn to match the ZIMURA template ("vehicle disc licensesS.pdf"):
# one A4 page per vehicle with the client's licence at the top and a square disc to cut out
# and display in the vehicle, showing its registration number, validity and a QR code.
class VehicleDiscPdf < Prawn::Document
  FONT_DIR = Rails.root.join("app/assets/fonts/pdf")
  MAROON = "8E1B1F"
  GOLD = "FFC20E"
  NAVY = "1E2B45"
  INK = "111111"

  def initialize(license, vehicles, logo_file)
    super(page_size: "A4", page_layout: :portrait, margin: 0, info: { Title: "Vehicle licence discs", Creator: "ZIMURA Billing" })
    @license = license
    @client = license.client
    @logo = logo_path_for(logo_file)
    register_fonts

    vehicles.each_with_index do |vehicle, i|
      start_new_page if i.positive?
      draw_page(vehicle)
    end
  end

  private

  def register_fonts
    font_families.update(
      "Playfair" => { normal: FONT_DIR.join("PlayfairDisplay-Variable.ttf").to_s },
      "Poppins" => { normal: FONT_DIR.join("Poppins-Medium.ttf").to_s, bold: FONT_DIR.join("Poppins-SemiBold.ttf").to_s },
      "Oswald" => { normal: FONT_DIR.join("Oswald-SemiBold.ttf").to_s }
    )
  end

  def logo_path_for(file)
    path = Rails.root.join("public/tenant_logo", File.basename(file.to_s))
    File.file?(path) ? path.to_s : nil
  end

  def draw_page(vehicle)
    w = bounds.width
    h = bounds.height
    draw_border(w, h)

    # Header: logo, title, client
    image(@logo, fit: [128, 128], at: [(w - 128) / 2, h - 52]) if @logo
    font("Playfair") do
      fill_color NAVY
      text_box "MUSIC COPYRIGHT LICENSE", at: [40, h - 205], width: w - 80, align: :center, size: 34, character_spacing: 0.5
      text_box "This license is hereby granted to", at: [40, h - 262], width: w - 80, align: :center, size: 15, character_spacing: 0.6
    end
    font("Poppins") do
      text_box @client.name.to_s.upcase, at: [50, h - 298], width: w - 100, height: 40, align: :center, size: 27,
                                         overflow: :shrink_to_fit, min_font_size: 14
    end
    stroke_color "56627A"
    line_width 0.8
    stroke_horizontal_line 108, w - 108, at: h - 352

    draw_disc(vehicle, w, h)

    # Date of issue
    issued = (@license.manager_approved_at || Time.current).to_date
    font("Oswald") do
      fill_color INK
      text_box issued.strftime("%d/%m/%y"), at: [0, 112], width: w, align: :center, size: 24
    end
    stroke_color INK
    line_width 0.8
    stroke_horizontal_line w / 2 - 82, w / 2 + 82, at: 76
    font("Playfair") do
      fill_color INK
      text_box "Date of Issue", at: [0, 66], width: w, align: :center, size: 15
    end
    fill_color "000000"
  end

  def draw_border(w, h)
    fill_color MAROON
    fill_rectangle [0, h], w, h
    fill_color GOLD
    fill_rectangle [5, h - 5], w - 10, h - 10
    fill_color "FFFFFF"
    fill_rectangle [11, h - 11], w - 22, h - 22
  end

  # The square to cut out: outer frame with the slogans, inner frame with the licence details.
  def draw_disc(vehicle, w, h)
    size_w = 246
    size_h = 226
    left = (w - size_w) / 2 + 6
    top = h - 460
    gap = 11

    draw_scissors(left - 34, top + 20)

    stroke_color "000000"
    line_width 2.2
    stroke_rectangle [left, top], size_w, size_h
    line_width 2.6
    stroke_rectangle [left + gap, top - gap], size_w - 2 * gap, size_h - 2 * gap

    # Slogans in the band between the two frames
    font("Times-Roman", style: :bold) do
      fill_color INK
      text_box "Let it Play", at: [left, top - 1], width: size_w, height: gap - 1, align: :center, valign: :center, size: 5.5
      text_box "Licensed for #{@license.license_for.presence || 'Music'}", at: [left, top - size_h + gap - 0.5], width: size_w, height: gap - 1,
               align: :center, valign: :center, size: 5.5
      rotate(270, origin: [left + 5.5, top - size_h / 2]) do
        text_box "Dont Stop The Music", at: [left + 5.5 - 45, top - size_h / 2 + 3], width: 90, align: :center, size: 5.5
      end
      rotate(90, origin: [left + size_w - 5.5, top - size_h / 2]) do
        text_box "Dont Stop The Music", at: [left + size_w - 5.5 - 45, top - size_h / 2 + 3], width: 90, align: :center, size: 5.5
      end
    end

    inner_left = left + gap
    inner_w = size_w - 2 * gap
    inner_top = top - gap

    # Faded logo figures behind the text (the lettering under them is clipped off, as in the template)
    if @logo
      mark = 168
      mark_left = inner_left + (inner_w - mark) / 2
      mark_top = inner_top - 14
      save_graphics_state
      rectangle [mark_left, mark_top], mark, mark * 0.6
      add_content("W n")
      transparent(0.2) { image @logo, fit: [mark, mark], at: [mark_left, mark_top] }
      restore_graphics_state
    end

    font("Times-Roman", style: :bold) do
      fill_color INK
      text_box "MUSIC COPYRIGHT LICENSE", at: [inner_left, inner_top - 42], width: inner_w, align: :center, size: 11.5
      text_box "This license is hereby granted to", at: [inner_left, inner_top - 58], width: inner_w, align: :center, size: 5.5
    end
    font("Poppins", style: :bold) do
      text_box vehicle.registration_number, at: [inner_left, inner_top - 69], width: inner_w, height: 16, align: :center,
                                           size: 12.5, character_spacing: 0.8, overflow: :shrink_to_fit
    end
    stroke_color INK
    line_width 0.6
    stroke_horizontal_line inner_left + 40, inner_left + inner_w - 40, at: inner_top - 88
    font("Times-Roman", style: :bold) do
      text_box "to exploit copyright music under ZIMURA's repertoire in compliance with the Copyright and Neighbouring Rights Act [Chapter 26:05]",
               at: [inner_left + 30, inner_top - 93], width: inner_w - 60, align: :center, size: 5.2, leading: 1
    end

    # QR code on a white tile
    qr = 46
    qr_left = inner_left + (inner_w - qr) / 2
    qr_top = inner_top - 124
    fill_color "FFFFFF"
    fill_rectangle [qr_left - 4, qr_top + 4], qr + 8, qr + 8
    fill_color "000000"
    render_qr_code(RQRCode::QRCode.new(qr_text(vehicle), level: :m), pos: [qr_left, qr_top], extent: qr, stroke: false)

    # Validity
    from = @license.renewal_date&.strftime("%d/%m/%Y").to_s
    to = @license.expiry_date&.strftime("%d/%m/%Y").to_s
    base = inner_top - (size_h - 2 * gap) + 6
    font("Times-Roman", style: :bold) do
      fill_color INK
      text_box "Valid From:", at: [inner_left + 6, base + 10], width: 40, size: 4.8
      text_box "To", at: [inner_left + 112, base + 10], width: 14, size: 4.8
    end
    font("Oswald") do
      text_box from, at: [inner_left + 35, base + 18], width: 72, size: 13
      text_box to, at: [inner_left + 125, base + 18], width: 72, size: 13
    end
    fill_color "000000"
  end

  # A small open pair of scissors marking where to cut.
  def draw_scissors(x, y)
    stroke_color "1F9E89"
    fill_color "1F9E89"
    line_width 1.6
    stroke_circle [x + 4, y - 9], 3.2
    stroke_circle [x + 4, y - 1], 3.2
    line_width 1.4
    stroke_line [x + 7, y - 8], [x + 24, y + 1]
    stroke_line [x + 7, y - 2], [x + 24, y - 11]
    fill_circle [x + 15, y - 5], 1.1
    fill_color "000000"
  end

  def qr_text(vehicle)
    "#{@client.tenant&.company_name} licence for #{@client.name}, vehicle #{vehicle.registration_number}. " \
      "#{@license.license_for}, valid #{@license.renewal_date&.strftime('%d %b %Y')} to #{@license.expiry_date&.strftime('%d %b %Y')}."
  end
end
