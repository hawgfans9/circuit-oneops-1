COOKBOOKS_PATH ||= "/opt/oneops/inductor/circuit-oneops-1/components/cookbooks"

require 'fog/azurerm'
require "#{COOKBOOKS_PATH}/azure_sql/libraries/azure_sql.rb"
require "#{COOKBOOKS_PATH}/azure_base/libraries/utils.rb"

describe 'resize azure sql db' do
  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
  end

  it 'should be right sized' do
    azure_sql_client = Fog::SQL::AzureRM.new(@spec_utils.get_azure_creds)
    primary_sql_server = azure_sql_client.get_sql_server(@spec_utils.get_resource_group_name, @spec_utils.get_primary_sql_server_name)
    dbinfo = azure_sql_client.get_database(@spec_utils.get_resource_group_name, @spec_utils.get_primary_sql_server_name, @spec_utils.get_db_name)

    db_size = @spec_utils.get_db_size

    expect(db_size.value).to eq(dbinfo.CurrentServiceObjectiveName)
  end
end
