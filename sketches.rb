gem build bearpost_correios.gemspec
gem install bearpost_correios

# Benchmark

require 'benchmark'
n = 50_000

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

Benchmark.bm do |benchmark|
  benchmark.report("Match") do
    n.times do
      hash.find {|key,value| key.downcase.match('rio')}
    end
  end

  benchmark.report("Include") do
    n.times do
      hash.find {|key,value| key.downcase.include?('rio')}
    end
  end
end

#
Account.where("correios_settings->'general'->>'Cartão' = ?", "0067599079")

response.body.dig(:fecha_plp_varios_servicos_response,:return)
=> 25561192
=> 25561528
=> 25561528


Carrier::Correios.get_plp_xml(account,'25561192')

#
Shipment.create(
  :status => "ready",
  :shipment_number => "teste_#{rand(1000)}",
  :company_id => 1,
  :cost => 179.0,
  :carrier_name => "correios",
  :invoice_series => 2,
  :invoice_number => 2331,
  :sender_first_name => "Nordweg",
  :sender_last_name => "Acessórios de Couro Ltda",
  :sender_email => "",
  :sender_phone => "",
  :sender_cpf => "13536856000128",
  :sender_street => "Rod. Pres. Getúlio Vargas",
  :sender_number => "1722",
  :sender_complement => "",
  :sender_neighborhood => "CENTRO",
  :sender_zip => "95166000",
  :sender_city => "Picada Café",
  :sender_city_code => "4314423",
  :sender_state => "RS",
  :recipient_first_name => "Victor",
  :recipient_last_name => "Hugo  Okamoto Husch",
  :recipient_email => "",
  :recipient_phone => "",
  :recipient_cpf => "08318692918",
  :recipient_street => "Rua Formigueiro",
  :recipient_number => "327",
  :recipient_complement => "Casa",
  :recipient_neighborhood => "Jd Morumbi",
  :recipient_zip => "86708150",
  :recipient_city => "Arapongas",
  :recipient_city_code => "4101507",
  :recipient_state => "PR",
  :sender_country => "Brasil",
  :recipient_country => "Brasil",
  :account_id => 6,
  :shipping_method => "PAC",
  :packages_attributes => [{
    :heigth => 10.0,
    :width => 20.0,
    :depth => 30.0,
    :weight => 40.0
  }]
)
