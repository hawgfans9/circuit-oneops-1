require 'chef'
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)

module AzureServices
    class AzureSQL
        def initialize(creds)
            azure_resources_service = Fog::Resources::AzureRM.new
          end


   
    end

end