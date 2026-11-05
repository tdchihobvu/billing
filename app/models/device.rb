class Device < ApplicationRecord
  belongs_to :user
  belongs_to :regional_office
  belongs_to :tenant
  has_many :shifts


  def active_shift(current_user)
    Shift.where("device_id = #{self.id} AND username = '#{current_user.username}'").last
  end

  def status
    return "Active" if active == true
    return "Inactive" if active == false
  end

  def self.generate_token
    SecureRandom.hex(16)
  end

  def self.generate_device_id
    # SecureRandom.uuid
    SecureRandom.random_number(1000..10000)
  end

end
