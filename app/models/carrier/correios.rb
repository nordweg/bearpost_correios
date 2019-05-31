class Carrier::Correios
  class << self
    def id
      name.demodulize.downcase
    end

    def display_name
      id.titleize
    end

    def settings_field
      "#{id}_settings"
    end

    def settings
      {
        'general': [
          'Usuário',
          'Senha',
          'Código Administrativo',
          'Contrato',
          'Codigo Serviço',
          'Cartão',
          'CNPJ'
        ],
        'shipping_methods': {
          'PAC': [
            'carrier_service_id',
            'label_minimum_quantity',
            'label_reorder_quantity',
          ],
          'Sedex': [
            'carrier_service_id',
            'label_minimum_quantity',
            'label_reorder_quantity'
          ]
        }
      }.with_indifferent_access
    end

    def shipping_methods
      settings[:shipping_methods].keys
    end

    def tracking_url
      "https://www2.correios.com.br/sistemas/rastreamento/"
    end

    def get_tracking_number(package)
      account         = package.shipment.account
      shipping_method = package.shipment.shipping_method

      check_tracking_number_availability(account,shipping_method)

      current_range = account.correios_settings['shipping_methods'][shipping_method]['ranges'].first
      prefix        = current_range['prefix']
      number        = current_range['next_number']
      sufix         = current_range['sufix']
      verification_digit = get_verification_digit(number)
      tracking_number    = "#{prefix}#{number}#{verification_digit}#{sufix}"

      if current_range['next_number'] + 1 > current_range['last_number']
        account.correios_settings['shipping_methods'][shipping_method]['ranges'].delete(current_range)
      else
        current_range['next_number'] += 1
      end
      account.save

      tracking_number
    end

    # private

    def check_tracking_number_availability(account,shipping_method)
      settings        = account.correios_settings['shipping_methods'][shipping_method]
      ranges          = settings['ranges'] || []

      if count_available_labels(account,shipping_method) < settings['label_minimum_quantity'].to_i
        save_new_range(account,shipping_method)
      end
    end

    def save_new_range(account,shipping_method)
      ranges_array = get_ranges_from_correios(account,shipping_method)
      next_number  = ranges_array[0][2..9]
      last_number  = ranges_array[-1][2..9]
      prefix       = ranges_array[0][0..1]
      sufix        = ranges_array[0][-2..-1]
      range_hash   = {
        "created_at":  DateTime.now,
        "prefix":      prefix,
        "next_number": next_number.to_i,
        "last_number": last_number.to_i,
        "sufix":       sufix,
      }
      account.correios_settings['shipping_methods'][shipping_method]['ranges'] << range_hash
      account.save
    end

    def count_available_labels(account,shipping_method)
      settings = account.correios_settings['shipping_methods'][shipping_method]
      return 0 if settings['ranges'].blank?
      total = 0
      settings['ranges'].each do |range|
        total += range['last_number'] - range['next_number'] + 1
      end
      total
    end

    def check_posting_card
      message = {
        "numeroCartaoPostagem" =>  "0067599079",
        "usuario" => "sigep",
        "senha" => "n5f9t8",
      }
      response = client.call(:get_status_cartao_postagem, message:message)

      response.body.dig(:get_status_cartao_postagem_response,:return)
    end

    def get_ranges_from_correios(account,shipping_method)
      reorder_quantity = account.correios_settings.dig('shipping_methods',shipping_method,'label_reorder_quantity')
      reorder_quantity = '10' if reorder_quantity.blank?

      message = {
        "tipoDestinatario" =>  "C",
        "identificador" => "34028316000103",
        "idServico" => "124849",
        "qtdEtiquetas" => reorder_quantity,
        "usuario" => "sigep",
        "senha" => "n5f9t8",
      }

      response = client.call(:solicita_etiquetas, message:message)
      ranges   = response.body.dig(:solicita_etiquetas_response,:return)
      ranges.split(',')
    end

    def client
      Savon.client(
        wsdl: "https://apphom.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente?wsdl",
        basic_auth: ["sigep", "n5f9t8"],
        headers: { 'SOAPAction' => '' }
      )
    end

    def get_verification_digit(number)
      multipliers = [8, 6, 4, 2, 3, 5, 9, 7]
      total = 0

      number.to_s.chars.map(&:to_i).each_with_index do |number,index|
        total += number * multipliers[index]
      end

      remainder = total % 11

      if remainder == 0
        verification_digit = 5;
      elsif remainder == 1
        verification_digit = 0;
      else
        verification_digit = 11 - remainder
      end

      verification_digit
    end
  end
end
