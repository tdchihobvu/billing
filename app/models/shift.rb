class Shift < ApplicationRecord
  belongs_to :device

  # before_save :assign_shift_id
  validates :district_id, presence: true

  scope :active, -> {where(active: true)}
  scope :open, -> {where('start_time IS NOT NULL AND end_time IS NULL AND active = true')}

  def is_open
    return true if start_time.present? and active == true and end_time == nil
    return false if (start_time.present? and active == true and end_time.present?) || active == false
  end

  def status
    return 'Open' if start_time.present? and active == true and end_time == nil
    return 'Closed' if (start_time.present? and active == true and end_time.present?) || active == false
  end

  def shiftId
    self.shift_id
  end

  # def total_collected(currency)
  #   Receipt.where(shift_id: self.id, currency_id: currency.id, deleted: false).sum(:amount)
  # end

  def close_shift(end_time)
    currency = Currency.find(1)
    puts("we are here in close shift")
    self.update(end_time: end_time, close_shift_synced: true, total_collected: 0)
  end

  private

  # def assign_shift_id
  #   self.shift_id = "#{self.device.terminal_id}#{self.start_time.strftime("%d%m%Y%H%M")}"
  # end

end
