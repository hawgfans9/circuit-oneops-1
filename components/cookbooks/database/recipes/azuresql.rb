require 'fog/azurerm'
require 'azure/storage'
require 'json'
require 'uri'
require 'azure'

mssql = node['workorder']['payLoad']['DependsOn'].select { |db|
db['ciClassName'].split('.').last == 'AzureSQL' }

@subscription_id = node['database']['subscriptionid']

#set deployment parameters and write file
tags = {    applicationname: node['database']['appname'], # 'TestAZRSQLDep',    
            notificationdistlist: node['database']['notificationdistlist'], # 'pflucas',    
            costcenter: node['database']['costcenter'], # '05.US.08052',    
            platform: node['database']['platform'], # 'db',    
            deploymenttype: node['database']['deploymenttype'], # 'dev',    
            ownerinfo: 'N:'+node['database']['owneremail']+';T:'node['database']['ownerteam'] # 'N:David.Clements@walmartlabs.com;T:Strati Public Cloud',    
            environmentinfo: 'T:'+node['database']['environment']+';N:'node['database']['envname'] # 'T:DEV;N:azuresqlmultireg',    
            sponsorinfo: 'E:Unknown;T:Unknown' #'E:'+node['database']['dbname']+';T:'node['database']['dbname'] # 'E:Unknown;T:Unknown' 
        }

tags=tags.to_json

#where will this be housed
@templatelink='https://pflazrsqlsapced.blob.core.windows.net/testazrsql-georeplication/testsqlsrv.json?sv=2017-04-17&ss=bfqt&srt=sco&sp=rwdlacup&se=2018-11-14T18:59:24Z&st=2017-11-14T10:59:24Z&spr=https&sig=DEcmr2IX48%2BgdUYWbOMZDwrfdXNJjhBVxGuGDmQSsXo%3D&sr=b'


# build the deployment template parameters from Hash to {key: {value: value}} format
DEPLOYMENT_PARAMETERS = {
    subid: @subscription_id,
    AuditSASubId: @subscription_id
}   
#db fields
deploy_params = DEPLOYMENT_PARAMETERS.merge(administratorLogin: node['database']['administratorLogin']) #PublicCloudTeam')
deploy_params = deploy_params.merge(administratorLoginPassword: node['database']['administratorLoginPassword']) #'PublicCl0ud!')
deploy_params = deploy_params.merge(deployPackageFileName:  node['database']['deployPackageFileName']) #'NewUserDB.bacpac')
deploy_params = deploy_params.merge(databaseName:  node['database']['databaseName']) #'NewUserDB1')
deploy_params = deploy_params.merge(primaryLocation:  node['database']['primaryLocation']) #'eastus2')
deploy_params = deploy_params.merge(secondaryLocation:  node['database']['secondaryLocation']) #'southcentralus')
deploy_params = deploy_params.merge(DBSize:  node['database']['DBSize']) #"S0")
deploy_params = deploy_params.merge(projectName:  node['database']['projectName']) #'TestAzrSQL-GeoReplication')
deploy_params = deploy_params.merge(tagValues:  node['database']['tagValues']) #'tagshere')
#deployment management fields
deploy_params = deploy_params.merge(deployPackageFolder:  node['database']['administratorLogin']) #'Resources')
deploy_params = deploy_params.merge(_artifactsLocation:  node['database']['_artifactsLocation']) #'eastus2')
deploy_params = deploy_params.merge(FWRLink:  node['database']['FWRLink']) #"https://pflazrsqlsapced.blob.core.windows.net/testazrsql-georeplication/firewall.json?sv=2017-04-17&ss=bfqt&srt=sco&sp=rwdlacup&se=2018-11-14T18:59:24Z&st=2017-11-14T10:59:24Z&spr=https&sig=DEcmr2IX48%2BgdUYWbOMZDwrfdXNJjhBVxGuGDmQSsXo%3D&sr=b")
deploy_params = deploy_params.merge(_artifactsLocationSasToken:  node['database']['_artifactsLocationSasToken']) #'?sv=2017-04-17&ss=bfqt&srt=sco&sp=rwdlacup&se=2018-11-14T18:59:24Z&st=2017-11-14T10:59:24Z&spr=https&sig=DEcmr2IX48%2BgdUYWbOMZDwrfdXNJjhBVxGuGDmQSsXo%3D&sr=b')
deploy_params = deploy_params.merge(storageendpoint:  node['database']['storageendpoint']) #'https://pflazrsqlsapced.blob.core.windows.net')
deploy_params = deploy_params.merge(storageaccountname:  node['database']['storageaccountname']) #'pflazrsqlsapced')
deploy_params = deploy_params.merge(storagekey:  node['database']['storagekey']) #'meiEuEMBl0B+QlfmGZS3rC2nyvaJMGsS7Oa86AculpoxBiP31k7XX1rIHi9EKh4beui7fbf+Q3ch3ez53EMpeA==')
deploy_params = deploy_params.merge(storageUri:  node['database']['storageUri']) #'https://pflazrsqlsapced.blob.core.windows.net/testazrsql-georeplication/NewUserDB.bacpac')
#OMS fields
deploy_params = deploy_params.merge(omsauditsasc:  node['database']['omsauditsasc']) #'pflauditsqlsc')
deploy_params = deploy_params.merge(omsauditsaeu2:  node['database']['omsauditsaeu2']) #'pflauditsqleu')
deploy_params = deploy_params.merge(rgname:  node['database']['rgname']) #'pfl-test-rg')
deploy_params = deploy_params.merge(OMSWorkspaceID:  node['database']['OMSWorkspaceID']) #"/subscriptions/a328a887-0623-45bb-a830-d94791d76d1d/resourcegroups/defaultresourcegroup-eus/providers/microsoft.operationalinsights/workspaces/defaultworkspace-a328a887-0623-45bb-a830-d94791d76d1d-eus")
deploy_params = deploy_params.merge(OMSWorkspaceName:  node['database']['OMSWorkspaceName']) #"DefaultWorkspace-a328a887-0623-45bb-a830-d94791d76d1d-EUS")
deploy_params = deploy_params.merge(AuditRG:  node['database']['auditresourcegroup']) #"PatriciasOrg-pfl-test-554560-TestEnv-eus2")

#format parameters and prep for upload
deploy_params = Hash[*deploy_params.map{ |k, v| [k,  {value: v}] }.flatten]
deploy_params=deploy_params.to_json
deploy_params = deploy_params.gsub('"value":"tagshere"','"value":'+tags)
deploy_params = '{    "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",    "contentVersion": "1.0.0.0",    "parameters":'+deploy_params+'}' 

   

        
verifyrg=azure_resources_service.resource_groups.check_resource_group_exists(@subscription_id)

if verifyrg!=true 
    location = node['database']['location'], #'eastus2'
    
    azure_resources_service.resource_groups.create(name:@resource_group, location: location , tags: tags )
    verifyrg=azure_resources_service.resource_groups.check_resource_group_exists(@resource_group)
end



        dbname = node['database']['dbname']
username = node['database']['username']
password = node['database']['password']




















