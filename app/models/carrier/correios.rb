class Carrier::Correios < Carrier
  class << self

    def shipment_menu_links
      [
        ['Checar PLP', '/correios/:id/get_plp']
      ]
    end

    def general_settings
      [
        'Usuário Rastreamento',
        'Senha Rastreamento',
        'Usuário',
        'Senha',
        'Código Administrativo',
        'Contrato',
        'Codigo Serviço',
        'Cartão',
        'CNPJ'
      ]
    end

    def shipping_method_settings
      {
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
    end

    def tracking_url
      "https://www2.correios.com.br/sistemas/rastreamento/"
    end

    def get_tracking_number(shipment)
      account         = shipment.account
      shipping_method = shipment.shipping_method

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

    def prepare_label(shipment)
      if shipment.tracking_number.blank?
        shipment.tracking_number = get_tracking_number(shipment)
        shipment.save
      end
    end

    def get_delivery_updates(shipment)
      message = {
        "usuario" => shipment.account.correios_settings.dig('general','Usuário Rastreamento'),
        "senha" => shipment.account.correios_settings.dig('general','Senha Rastreamento'),
        "tipo" => "L",
        "resultado" => "T",
        "lingua" => "101",
        "objetos" => "PS935735024BR"
      }
      response = tracking_client.call(:busca_eventos, message:message)
      events = response.body.dig(:busca_eventos_response,:return,:objeto,:evento)
      events.each do |event|
        next if shipment.histories.find_by(description:event[:descricao])
        shipment.histories.create(
          description: event[:descricao],
          city: event[:cidade],
          state: event[:uf],
          date: event[:data] + " " + event[:hora],
          changed_by: 'Correios',
          category: 'carrier'
        )
      end
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
      ranges = account.correios_settings['shipping_methods'][shipping_method]['ranges'] || []
      ranges << range_hash
      account.correios_settings['shipping_methods'][shipping_method]['ranges'] = ranges
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

      response = client(account).call(:solicita_etiquetas, message:message)
      ranges   = response.body.dig(:solicita_etiquetas_response,:return)
      ranges.split(',')
    end

    def create_plp(shipments)
      account  = shipments.first.account
      user     = account.correios_settings.dig('general','Usuário')
      password = account.correios_settings.dig('general','Senha')
      posting_card = account.correios_settings.dig('general','Cartão')
      xml = build_xml(shipments)
      labels = []
      shipments.each do |shipment|
        labels << shipment.tracking_number[0..9] + shipment.tracking_number[-2..-1]
      end
      message = {
        "xml" =>  xml,
        "idPlpCliente" => 123123,
        "cartaoPostagem" => posting_card,
        "listaEtiquetas" => labels,
        "usuario" => user,
        "senha" => password,
      }
      client(account).call(:fecha_plp_varios_servicos, message:message)
    end

    def get_plp_xml(account,plp_number)
      user     = account.correios_settings.dig('general','Usuário')
      password = account.correios_settings.dig('general','Senha')
      message = {
        "idPlpMaster" => plp_number,
        "usuario" => user,
        "senha" => password,
      }
      client(account).call(:solicita_xml_plp, message:message)
    end

    def send_to_carrier(shipments)
      response = []
      begin
        correios_response = create_plp(shipments)
        plp_number = correios_response.body.dig(:fecha_plp_varios_servicos_response,:return)
        message = "Enviado na PLP #{plp_number}"
        shipments.each do |shipment|
          settings = shipment.settings
          settings['plp'] = plp_number
          shipment.update(settings:settings,sent_to_carrier:true)
          response << {
            shipment: shipment,
            success: shipment.sent_to_carrier,
            message: message
          }
        end
      rescue Exception => e
        shipments.each do |shipment|
          response << {
            shipment: shipment,
            success: shipment.sent_to_carrier,
            message: e.message
          }
        end
      end
      response
    end



    def build_xml(shipments)
      account  = shipments.first.account
      posting_card = account.correios_settings.dig('general','Cartão')
      contract = account.correios_settings.dig('general','Contrato')
      administrative_code = account.correios_settings.dig('general','Código Administrativo')

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.correioslog {
          xml.tipo_arquivo 'Postagem'
          xml.versao_arquivo '2.3'
          xml.plp {
            xml.id_plp
            xml.valor_global
            xml.mcu_unidade_postagem
            xml.nome_unidade_postagem
            xml.cartao_postagem posting_card
          }
          xml.remetente {
            xml.numero_contrato contract
            xml.numero_diretoria get_numero_diretoria(account.state)
            xml.codigo_administrativo administrative_code
            xml.nome_remetente account.name
            xml.logradouro_remetente account.street
            xml.numero_remetente account.number
            xml.complemento_remetente account.complement
            xml.bairro_remetente account.neighborhood
            xml.cep_remetente account.zip
            xml.cidade_remetente account.city
            xml.uf_remetente account.state
            xml.telefone_remetente account.phone
            xml.email_remetente account.email
          }
          xml.forma_pagamento
          shipments.each do |shipment|
            package = shipment.packages.last
            xml.objeto_postal {
              xml.numero_etiqueta shipment.tracking_number[0..9] + shipment.tracking_number[-2..-1]
              xml.codigo_objeto_cliente
              xml.codigo_servico_postagem '41106'
              xml.cubagem package.heigth * package.width * package.depth
              xml.peso package.weight
              xml.rt2
              xml.destinatario {
                xml.nome_destinatario shipment.full_name
                xml.telefone_destinatario shipment.phone
                xml.email_destinatario shipment.email
                xml.logradouro_destinatario shipment.street
                xml.complemento_destinatario shipment.complement
                xml.numero_end_destinatario shipment.number
              }
              xml.nacional {
                xml.bairro_destinatario shipment.neighborhood
                xml.cidade_destinatario shipment.city
                xml.uf_destinatario shipment.state
                xml.cep_destinatario shipment.zip
                xml.numero_nota_fiscal shipment.invoice_number
                xml.serie_nota_fiscal shipment.invoice_series
                xml.natureza_nota_fiscal
              }
              xml.servico_adicional {
                xml.codigo_servico_adicional '025'
              }
              xml.dimensao_objeto {
                xml.tipo_objeto '002'
                xml.dimensao_altura package.heigth
                xml.dimensao_largura package.width
                xml.dimensao_comprimento package.depth
                xml.dimensao_diametro 0
              }
            }
          end
        }
      end
      builder.to_xml
    end

    def get_numero_diretoria(state)
      hash = {
        'ACRE'=> '03',
        'ALAGOAS'=> '04',
        'AMAZONAS'=> '06',
        'AMAPÁ'=> '05',
        'BAHIA'=> '08',
        'BRASÍLIA'=> '10',
        'CEARÁ'=> '12',
        'ESPIRITO SANTO'=> '14',
        'GOIÁS'=> '16',
        'MARANHÃO'=> '18',
        'MINAS GERAIS'=> '20',
        'MATO GROSSO DO SUL'=> '22',
        'MATO GROSSO'=> '24',
        'PARÁ'=> '28',
        'PARAÍBA'=> '30',
        'PERNAMBUCO'=> '32',
        'PIAUÍ'=> '34',
        'PARANÁ'=> '36',
        'RIO DE JANEIRO'=> '50',
        'RIO GRANDE DO NORTE'=> '60',
        'RONDONIA'=> '26',
        'RORAIMA'=> '65',
        'RIO GRANDE DO SUL'=> '64',
        'SANTA CATARINA'=> '68',
        'SERGIPE'=> '70',
        'SÃO PAULO INTERIOR'=> '74',
        'SÃO PAULO'=> '72',
        'TOCANTINS'=> '75'
      }
      hash.find {|key,value| key.downcase.include?(state.downcase)}[1]
    end

    def busca_cliente
      user = account.correios_settings.dig('general','Usuário')
      password = account.correios_settings.dig('general','Senha')
      posting_card = account.correios_settings.dig('general','Cartão')
      contract = account.correios_settings.dig('general','Contrato')

      message = {
        "idContrato" => contract,
        "idCartaoPostagem" => posting_card,
        "usuario" => user,
        "senha" => password,
      }

      client(account).call(:busca_cliente, message:message)
    end

    def client(account)
      user = account.correios_settings.dig('general','Usuário')
      password = account.correios_settings.dig('general','Senha')
      Savon.client(
        wsdl: "https://apphom.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente?wsdl",
        basic_auth: [user,password],
        headers: { 'SOAPAction' => '' }
      )
    end

    def tracking_client
      Savon.client(
        wsdl: "http://webservice.correios.com.br/service/rastro/Rastro.wsdl",
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
