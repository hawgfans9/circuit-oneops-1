
=begin
This spec has tests that validates a successfully completed oneops-azure deployment
=end

COOKBOOKS_PATH ||="/opt/oneops/inductor/circuit-oneops-1/components/cookbooks"

require 'chef'
require 'fog/azurerm'
require 'json'
require 'uri'
require 'azure'
(
  Dir.glob("#{COOKBOOKS_PATH}/azure/libraries/*.rb") +
  Dir.glob("#{COOKBOOKS_PATH}/azure_base/libraries/*.rb")
).each {|lib| require lib}
#require 'azure/storage'


describe "Azure SQL" do
    before(:each) do
        @spec_utils = AzureSpecUtils.new($node)
    end
    
    context "resource group" do
        it "should exist" do
          rg_svc = AzureBase::ResourceGroupManager.new($node)
          exists = rg_svc.exists?
    
          expect(exists).to eq(true)
        end
    end
    
    context "SQL Server" do
        it "should exist" do
            #need to get node information here, not sure on that part
            azure_sql_client = Fog::SQL::AzureRM.new(@spec_utils.get_azure_creds)
            resource_group_name = @spec_utils.get_resource_group_name
            #verify these lines with Aaron
            primary_server_name = @spec_utils.get_primary_server_name
            primary_server_name = $node['name']
            puts("\t\tLooking for #{primary_server_name} in Azure.")    
            sql_server = azure_sql_client.get_sql_server(resource_group_name, primary_server_name)
        
            expect(sql_server).not_to be_nil
            expect(sql_server.name).to eq(primary_server_name)

        end

        it "should have the right firewall rule count" do
            #check node details here
            rulelist = $node['azuresql']['inbound'].tr('"[]\\', '').split(',')
            puts("\t\tLooking for #{rulelist.length} firewall rules on sql server.")      
            azure_sql_client = Fog::SQL::AzureRM.new(@spec_utils.get_azure_creds)
            resource_group_name = @spec_utils.get_resource_group_name
            #verify these lines with Aaron
            primary_server_name = @spec_utils.get_primary_server_name
            primary_server_name = $node['name']
      
            fwrules = azure_sql_client.list_firewall_rules(resource_group_name, primary_server_name)
          
            expect(fwrules.length).to eq(rulelist.length)
          end
      
          it "should validate auditing" do
            #check node details here
            auditconfig = $node['azuresql']['inbound'].tr('"[]\\', '').split(',')
            azure_sql_client = Fog::SQL::AzureRM.new(@spec_utils.get_azure_creds)
            resource_group_name = @spec_utils.get_resource_group_name
            #verify these lines with Aaron
            primary_server_name = @spec_utils.get_primary_server_name
            primary_server_name = $node['name']
            puts("\t\tLooking for #{primary_server_name}'s auditing status on server.")      
            
            #need this functionality added to Fog 
            auditstatus = azure_sql_client.Get-AzureRmSqlServerAuditingPolicy(resource_group_name, primary_server_name)
          
            expect(auditconfig.value).to eq(auditstatus.AuditState)
          end
          
    end

    context "SQL Database" do
        it "should exist" do
            #need to get node information here, not sure on that part
            azure_sql_client = Fog::SQL::AzureRM.new(@spec_utils.get_azure_creds)
      
            resource_group_name = @spec_utils.get_resource_group_name
            #verify these lines with Aaron
            primary_server_name = @spec_utils.get_primary_server_name
            primary_server_name = $node['name']
            db_name = $node['db_name']
            
            puts("\t\tLooking for #{primary_server_name}:#{db_name} in Azure.")    
            
            sql_server = azure_sql_client.get_database(resource_group_name, primary_server_name, db_name)
        
            expect(sql_server).not_to be_nil
            expect(sql_server.name).to eq(primary_server_name)

        end

        it "should validate database auditing" do
            #check node details here
            auditconfig = $node['azuresql']['inbound'].tr('"[]\\', '').split(',')
            azure_sql_client = Fog::SQL::AzureRM.new(@spec_utils.get_azure_creds)
            resource_group_name = @spec_utils.get_resource_group_name
            #verify these lines with Aaron
            primary_server_name = @spec_utils.get_primary_server_name
            primary_server_name = $node['name']
            db_name = $node['dbname']
            puts("\t\tLooking for #{primary_server_name}:#{db_name}'s auditing status on server.")      
            
            #need this functionality added to Fog 
            dbauditstatus = azure_sql_client.Get-AzureRmSqlDatabaseAuditing(resource_group_name, primary_server_name, db_name)
          
            expect(auditconfig.value).to eq(dbauditstatus.AuditState)
          end
          
          it "should validate georeplication" do
            #check node details here
            georepconfig = $node['azuresql']['inbound'].tr('"[]\\', '').split(',')
            azure_sql_client = Fog::SQL::AzureRM.new(@spec_utils.get_azure_creds)
            resource_group_name = @spec_utils.get_resource_group_name
            #verify these lines with Aaron
            primary_server_name = @spec_utils.get_primary_server_name
            primary_server_name = @spec_utils.get_secondary_server_name
            
            primary_server_name = $node['name']
            db_name = $node['dbname']
            puts("\t\tLooking for #{primary_server_name}:#{db_name}'s geo-replication partner server.")      
            
            #need this functionality added to Fog 
            #Get-AzureRmSqlDatabaseReplicationLink -ServerName azrsqlsvrsjvp5aq63cksseastus2 -ResourceGroupName pflazure-ruby-deployment -DatabaseName NewUserDB1  -PartnerResourceGroupName resource_group_name
            georepstatus = azure_sql_client.Get-AzureRmSqlDatabaseReplicationLink(resource_group_name, primary_server_name, db_name, resource_group_name)
          
            expect(primary_server_name.value).to eq(georepstatus.PartnerServerName)
          end

          
    end

    
end