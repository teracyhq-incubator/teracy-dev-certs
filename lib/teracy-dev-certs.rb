require 'teracy-dev'

require_relative 'teracy-dev-certs/processors/certs'

module TeracyDevCerts
  def self.init
    TeracyDev.register_processor(Processors::Certs.new)
  end
end
