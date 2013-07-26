require 'time'
require 'omf_rc'
require 'nokogiri'
require 'open-uri'

module OmfRc::ResourceProxy::DirectionalAntennaController
  include OmfRc::ResourceProxyDSL

  register_proxy :directional_antenna_controller
end

module OmfRc::ResourceProxy::Arduino
  include OmfRc::ResourceProxyDSL

  register_proxy :directional, :create_by => :directional_antenna_controller

  property :yaw, default: 0
  property :host

  configure :yaw do |directional, value|
    W=0.01445203370824 * (45 * 45) + 9.071565715837409*45 + 859.7024322029524
    res = directional.send_command("ajax_inputs/Y#{value}W#{W}END")
    directional.property.yaw = value
    res
  end

  work :send_command do |directional, command|
    doc = Nokogiri::HTML(open("http://#{directional.property.host}/#{command}"))
    res = doc.xpath('//p').text.strip
    res
  end
end

OmfCommon.init(:development, communication: { url: 'xmpp://alpha:pw@localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Arduino controller >> Connected to XMPP server"
    directional = OmfRc::ResourceFactory.create(:directional_antenna_controller, uid: 'directional_antenna_controller')
    comm.on_interrupted { directional.disconnect }
  end
end
