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
