ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Serial: threads share Devise login state and the test database.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { sign_in users(:one) }
  
  private
  
  # Attributes for creating a new record, with unique values changed.
  def fresh_attributes(record)
    attrs = record.attributes.except("id", "created_at", "updated_at")
    unique_columns(record).each { |column| attrs[column] = "#{attrs[column]}-#{SecureRandom.hex(4)}" if attrs[column].is_a?(String) }
    attrs.compact
  end

  def unique_columns(record)
    indexed = record.class.connection.indexes(record.class.table_name).select(&:unique).flat_map { |index| Array(index.columns) }
    validated = record.class.validators.grep(ActiveRecord::Validations::UniquenessValidator).flat_map(&:attributes).map(&:to_s)
    (indexed + validated).uniq & record.attribute_names
  end

  # A saved copy nothing refers to, for testing a real delete.
  def unreferenced_copy(record)
    copy = record.dup
    unique_columns(record).each { |column| copy[column] = "#{copy[column]}-#{SecureRandom.hex(4)}" if copy[column].is_a?(String) }
    copy.save!(validate: false)
    copy
  end
end
