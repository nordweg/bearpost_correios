Rails.application.routes.draw do
  post "/correios/:shipment_id/get_plp",                        to: "correios#get_plp"
  
  post "/correios/:account_id/:shipping_method/send_plp",       to: "correios#send_plp"
  post "/correios/:account_id/:shipping_method/",               to: "correios#save_new_range"
end
