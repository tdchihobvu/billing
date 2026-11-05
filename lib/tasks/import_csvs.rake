
require "csv"

namespace :csv do
  desc "Import CSV files into existing PostgreSQL tables"
  task import: :environment do
    directory = ENV.fetch(
      "CSV_DIR",
      Rails.root.join("storage", "csv_imports").to_s
    )

    # Change these model names and filenames to match your app.
    imports = {
      "tenant_categories.csv" => TenantCategory,
      "tenants.csv" => Tenant,
      "users.csv" => User,
      "user_logs.csv" => UserLog,
      "client_types.csv" => ClientType,
      "license_categories.csv" => LicenseCategory,
      "license_options.csv" => LicenseOption,
      "industries.csv" => Industry,
      "currencies.csv" => Currency,
      "payment_forms.csv" => PaymentForm,
      "setting_categories.csv" => SettingCategory,
      "config_keys.csv" => ConfigKey,
      "system_settings.csv" => SystemSetting,
      "banks.csv" => Bank,
      "regions.csv" => Region,
      "regional_offices.csv" => RegionalOffice,
      "districts.csv" => District,
      "device_settings.csv" => DeviceSetting,
      "tarrifs.csv" => Tarrif,
      "devices.csv" => Device,
      "clients.csv" => Client,
      "branches.csv" => Branch,
      "shifts.csv" => Shift,
      "system_modules.csv" => SystemModule,
      "exchange_rates.csv" => ExchangeRate,
      "invoice_categories.csv" => InvoiceCategory,
      "invoices.csv" => Invoice,
      "invoice_items.csv" => InvoiceItem,
      "licenses.csv" => License,
      # "active_storage_attachments.csv" => ActiveStorageAttachment,
      # "active_storage_blobs.csv" => ActiveStorageBlob,
      "notifications.csv" => Notification,
      "receipts.csv" => Receipt,
      "transactions.csv" => Transaction,
      "vat_types.csv" => VatType
    }

    models = imports.values.uniq
    connection = ActiveRecord::Base.connection

    if connection.adapter_name == "PostgreSQL"
      tables = models.map do |model|
        connection.quote_table_name(model.table_name)
      end

      connection.execute(
        "TRUNCATE TABLE #{tables.join(', ')} RESTART IDENTITY CASCADE"
      )
    else
      models.reverse_each(&:delete_all)

      models.each do |model|
        next unless connection.adapter_name == "SQLite"

        connection.execute(
          "DELETE FROM sqlite_sequence WHERE name = " \
          "#{connection.quote(model.table_name)}"
        )
      end
    end

    imports.each do |filename, model|
      path = File.join(directory, filename)

      unless File.file?(path)
        abort "CSV file not found: #{path}"
      end

      puts "Importing #{filename} into #{model.table_name}..."

      count = 0

      model.transaction do
        CSV.foreach(path, headers: true).with_index(2) do |csv_row, line|
          attributes = csv_row.to_h.transform_keys(&:to_s)

          if attributes.keys.any?(&:nil?) ||
             attributes.keys.any? { |key| key.strip.empty? }
            raise "Invalid header in #{filename}"
          end

          unknown = attributes.keys - model.column_names
          unless unknown.empty?
            raise "Unknown columns in #{filename}: #{unknown.join(', ')}"
          end

          attributes.transform_values! do |value|
            value == "" ? nil : value
          end

          record = model.new(attributes)
          pass = 'admin123'
          if model == User && record.new_record? && record.password.blank?
            record.password = pass
            record.password_confirmation = pass
            record.reset_password_token = SecureRandom.hex(16)
            record.unlock_token = SecureRandom.hex(16)
          end

          if model == Client && record.phone.blank?
            record.phone = "0000000000"
          end

          if model == Client && record.cp_mobile.blank?
            record.cp_mobile = "0000000000"
          end

          if model == Client && record.email.blank?
            record.email = "noemail@zimura.co.zw"
          end

          if model == Client && record.cp_name.blank?
            record.cp_name = record.name
          end

          unless record.save
            raise "#{filename}, row #{line}: " \
                  "#{record.errors.full_messages.join(', ')}"
          end

          count += 1
        end
      end

      puts "Imported #{count} rows from #{filename}"
    end

    puts "All CSV imports completed successfully."

    models.each do |model|
      next unless model.column_names.include?("id")

      connection.reset_pk_sequence!(model.table_name)
    end
  end
end
