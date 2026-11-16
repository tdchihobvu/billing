# Adds and removes a client's vehicles (permission: "Add and edit clients").
class VehiclesController < ApplicationController
  def create
    client = tenant.clients.find(params[:vehicle][:client_id])
    added = []
    errors = []
    # One plate per line or comma, so a fleet can be entered in one go.
    plates = params[:vehicle][:registration_number].to_s.split(/[\n,;]+/).map(&:squish).reject(&:blank?)
    plates = [""] if plates.empty?
    plates.each do |plate|
      vehicle = client.vehicles.new(tenant_id: tenant.id, registration_number: plate,
                                    make_model: params[:vehicle][:make_model], description: params[:vehicle][:description])
      vehicle.save ? added << vehicle.registration_number : errors << "#{plate.presence || 'Registration number'}: #{vehicle.errors.full_messages.to_sentence.sub(/\ARegistration number /, '')}"
    end
    flash_key = errors.any? ? :alert : :notice
    message = []
    message << "Added #{added.to_sentence}." if added.any?
    message << "Not added: #{errors.join('; ')}." if errors.any?
    redirect_to client_path(client, tab: "vehicles"), flash_key => message.join(" "), status: :see_other
  end

  def update
    vehicle = tenant_vehicles.find(params[:id])
    if vehicle.update(params.require(:vehicle).permit(:registration_number, :make_model, :description, :active))
      redirect_to client_path(vehicle.client, tab: "vehicles"), notice: "#{vehicle.registration_number} was updated.", status: :see_other
    else
      redirect_to client_path(vehicle.client, tab: "vehicles"), alert: vehicle.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def destroy
    vehicle = tenant_vehicles.find(params[:id])
    client = vehicle.client
    if vehicle.licenses.exists?
      # Keep the history of discs already issued; just stop using the vehicle.
      vehicle.update(active: false)
      notice = "#{vehicle.registration_number} has licences on record, so it was marked inactive instead of deleted."
    else
      vehicle.destroy
      notice = "#{vehicle.registration_number} was removed."
    end
    redirect_to client_path(client, tab: "vehicles"), notice: notice, status: :see_other
  end

  private

  def tenant_vehicles
    Vehicle.where(tenant_id: tenant.id)
  end
end
