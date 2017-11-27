COOKBOOKS_PATH ||= "/opt/oneops/inductor/circuit-oneops-1/components/cookbooks"

require 'fog/azurerm'
require "#{COOKBOOKS_PATH}/azure_sql/libraries/azure_sql.rb"
require "#{COOKBOOKS_PATH}/azure_base/libraries/utils.rb"

describe 'delete azure sql' do
  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
  end

  it 'primary should not exist' do
    azure_sql_client = Fog::SQL::AzureRM.new(@spec_utils.get_azure_creds)
    primary_sql_server = azure_sql_client.get_sql_server(@spec_utils.get_resource_group_name, @spec_utils.get_primary_sql_server_name)
        
    expect(primary_sql_server).to be_nil
  end

  it 'secondary should not exist' do
    azure_sql_client = Fog::SQL::AzureRM.new(@spec_utils.get_azure_creds)
    secondary_sql_server = azure_sql_client.get_sql_server(@spec_utils.get_resource_group_name, @spec_utils.get_secondary_sql_server_name)
    
    expect(secondary_sql_server).to be_nil
  end
end
