class CorreiosController < ActionController::Base

  def save_new_range
    account         = Account.find_by(id:params[:account_id])
    shipping_method = params[:shipping_method]
    Carrier::Correios.save_new_range(account,shipping_method)
    redirect_to edit_carrier_path(Carrier::Correios.id)
  end

  def send_plp
    account          = Account.find(params[:account_id])
    shipping_method  = params[:shipping_method]

    ready_to_ship = account.shipments.ready.where("settings->>'plp' IS NULL")

    if ready_to_ship.any?
      begin
        plp_number    = Carrier::Correios.close_plp(account,shipping_method)
        ready_to_ship.each do |shipment|
          settings = shipment.settings
          settings['plp'] = plp_number
          shipment.update(settings:settings)
        end
        flash[:success] = "PLP #{plp_number} criada com sucesso"
      rescue Exception => e
        flash[:error] = e.message
      end
    else
      flash[:alert] = 'Não há envios novos'
    end
    redirect_to edit_carrier_path(Carrier::Correios.id)
  end

  def get_plp
    begin
      shipment = Shipment.find(params[:shipment_id])
      account  = shipment.account
      if shipment.settings['plp'].blank?
        redirect_to shipment_path(shipment), alert: 'Não há PLP relacionada a este envio'
      else
        plp_xml = Carrier::Correios.get_plp_xml(account, shipment.settings['plp'])
      end
    rescue Exception => e
      flash[:error] = e.message
      redirect_to shipment_path(shipment)
    end
  end
end
