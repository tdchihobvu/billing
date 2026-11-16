# A problem worth a person's attention, shown on Administration -> System health.
# SystemEvent.record never raises: logging a problem must not cause another one.
class SystemEvent < ApplicationRecord
  belongs_to :tenant, optional: true
  belongs_to :user, optional: true

  KINDS = {
    "payment_sync" => ["Payment not applied", "fa-sync-alt"],
    "page_error" => ["Page or export failed", "fa-exclamation-triangle"],
    "mobile_upload" => ["Phone upload refused", "fa-mobile-alt"],
    "balance" => ["Balance check", "fa-balance-scale"]
  }.freeze

  validates :kind, :title, presence: true

  scope :open, -> { where(resolved_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # Often called while a payment or invoice is being saved. The insert runs in its own
  # savepoint, so if it fails only the log entry is lost, never the surrounding save.
  def self.record(kind:, title:, details: nil, tenant: nil, tenant_id: nil, user: nil, path: nil, record: nil)
    event = new(kind: kind, title: title.to_s.truncate(250).presence, details: details.to_s.truncate(4000).presence,
                tenant_id: tenant&.id || tenant_id, user_id: user&.id, path: path.to_s.truncate(500).presence,
                record_type: record&.class&.name, record_id: record&.id)
    return nil unless event.valid?

    transaction(requires_new: true) { event.save! }
    event
  rescue StandardError => e
    Rails.logger.error("Could not record system event (#{kind}: #{title}): #{e.message}")
    nil
  end

  def kind_label
    KINDS.dig(kind, 0) || kind.humanize
  end

  def icon
    KINDS.dig(kind, 1) || "fa-info-circle"
  end

  def resolve!(by)
    update!(resolved_at: Time.current, resolved_by_id: by&.id)
  end
end
