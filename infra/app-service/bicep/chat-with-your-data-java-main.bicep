targetScope = 'subscription'



@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string


// ================ //
// App Parameters   //
// ================ //


param searchServiceName string = ''
param searchServiceLocation string = ''
// The free tier does not support managed identity (required) or semantic search (optional)
@allowed(['basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param searchServiceSkuName string // Set in main.parameters.json
param searchIndexName string // Set in main.parameters.json
param searchQueryLanguage string // Set in main.parameters.json
param searchQuerySpeller string // Set in main.parameters.json

param storageAccountName string = ''
param storageResourceGroupLocation string = location
param storageContainerName string = 'content'
param storageSkuName string // Set in main.parameters.json


param formRecognizerServiceName string = ''


param formRecognizerSkuName string = 'S0'

param chatGptDeploymentName string // Set in main.parameters.json
param chatGptDeploymentCapacity int = 30
param chatGptModelName string = 'gpt-35-turbo'
param chatGptModelVersion string = '0613'
param embeddingDeploymentName string // Set in main.parameters.json
param embeddingDeploymentCapacity int = 30
param embeddingModelName string = 'text-embedding-ada-002'

// Used for the optional login and document level access control system
param useAuthentication bool = false
param serverAppId string = ''
@secure()
param serverAppSecret string = ''
param clientAppId string = ''

// Used for optional CORS support for alternate frontends
param allowedOrigin string = '' // should start with https://, shouldn't end with a /

@description('Id of the user or app to assign application roles')
param userPrincipalId string = ''



// ====================================== //
// App Service Landing Zones Parameters   //
// ===================================== //

@description('Required. The name of the environmentName (e.g. "dev", "test", "prod", "preprod", "staging", "uat", "dr", "qa"). Up to 8 characters long.')
@maxLength(8)
param lzaEnvironmentName string = 'azd'

@description('CIDR of the HUB vnet i.e. 192.168.0.0/24 - optional if you want to use an existing hub vnet (vnetHubResourceId)')
param vnetHubAddressSpace string = '10.242.0.0/20'

@description('CIDR of the subnet hosting the azure Firewall - optional if you want to use an existing hub vnet (vnetHubResourceId)')
param subnetHubFirewallAddressSpace string = '10.242.0.0/26'

@description('CIDR of the subnet hosting the Bastion Service - optional if you want to use an existing hub vnet (vnetHubResourceId)')
param subnetHubBastionAddressSpace string = '10.242.0.64/26'

@description('CIDR of the SPOKE vnet i.e. 192.168.0.0/24')
param vnetSpokeAddressSpace string = '10.240.0.0/20'

@description('CIDR of the subnet that will hold the app services plan')
param subnetSpokeAppSvcAddressSpace string = '10.240.0.0/26'

@description('CIDR of the subnet that will hold devOps agents etc ')
param subnetSpokeDevOpsAddressSpace string = '10.240.10.128/26'

@description('CIDR of the subnet that will hold the private endpoints of the supporting services')
param subnetSpokePrivateEndpointAddressSpace string = '10.240.11.0/24'

@description('Optional. A numeric suffix (e.g. "001") to be appended on the naming generated for the resources. Defaults to empty.')
param numericSuffix string = ''

@description('Resource tags that we might need to add to all resources (i.e. Environment, Cost center, application name etc)')
param resourceTags object = {}

@description('Default is empty. If empty, then a new hub will be created. If given, no new hub will be created and we create the  peering between spoke and and existing hub vnet')
param vnetHubResourceId string = ''

@description('Internal IP of the Azure firewall deployed in Hub. Used for creating UDR to route all vnet egress traffic through Firewall. If empty no UDR')
param firewallInternalIp string = ''

@description('Defines the name, tier, size, family and capacity of the App Service Plan. Plans ending to _AZ, are deplying at least three instances in three Availability Zones. EP* is only for functions')
@allowed([ 'S1', 'S2', 'S3', 'P1V3', 'P2V3', 'P3V3', 'P1V3_AZ', 'P2V3_AZ', 'P3V3_AZ' ])
param webAppPlanSku string = 'S1'

@description('Kind of server OS of the App Service Plan')
@allowed([ 'Windows', 'Linux'])
param webAppBaseOs string = 'Linux'

@description('mandatory, the username of the admin user of the jumpbox VM')
param adminUsername string = 'azureuser'

@description('mandatory, the password of the admin user of the jumpbox VM ')
@secure()
param adminPassword string


@description('set to true if you want to deploy a jumpbox/devops VM')
param deployJumpHost bool = true



var expandedTags = union({
  'azd-env-name': environmentName
}, resourceTags)


//Using the azd enviroment name as the workload name. For the LZA enviroment concept (which is different from the azd env concept) I'm using the static string 'azd
module appServiceLza 'lza-libs/appservice-landing-zone-accelerator/scenarios/secure-baseline-multitenant/bicep/main.bicep' = {
  name: 'app-service-lza'
  params: {
    location: location
    workloadName: environmentName
    environmentName: lzaEnvironmentName
    numericSuffix: numericSuffix
    resourceTags: expandedTags
    vnetHubAddressSpace: vnetHubAddressSpace
    subnetHubFirewallAddressSpace: subnetHubFirewallAddressSpace
    subnetHubBastionAddressSpace: subnetHubBastionAddressSpace
    vnetSpokeAddressSpace: vnetSpokeAddressSpace
    subnetSpokeAppSvcAddressSpace: subnetSpokeAppSvcAddressSpace
    subnetSpokeDevOpsAddressSpace: subnetSpokeDevOpsAddressSpace
    subnetSpokePrivateEndpointAddressSpace: subnetSpokePrivateEndpointAddressSpace
    vnetHubResourceId: vnetHubResourceId
    firewallInternalIp: firewallInternalIp
    webAppPlanSku: webAppPlanSku
    webAppBaseOs: webAppBaseOs
    linuxFxVersion:'JAVA|17-java17'
    adminUsername: adminUsername
    adminPassword: adminPassword
    enableEgressLockdown: false
    deployOpenAi: true
    deployJumpHost: deployJumpHost
    installClis: true
    installSsms: false
    installJava: true
    installNode: true
    installPython: true
    installPwsh: true
    autoApproveAfdPrivateEndpoint: false

  }
}

/**this is an hack which is somehow tight coupling the app biceps with the asa LZA internal implementation. 
* You can't use the spokeresourcename as output of a module. it needs to be known at compile time. See https://github.com/Azure/bicep/issues/4992
**/


var spokeResourceGroupName = 'rg-spoke-${environmentName}-${lzaEnvironmentName}-${location}'
var openAIAccountName = appServiceLza.outputs.openAIAccountName
var appServiceIdentityPrincipalId = appServiceLza.outputs.webappUserIdentityAssignedPrincipalId
var appServiceIdentityClientId = appServiceLza.outputs.webAppUserAssignedManagedIdenityClientId

//adding azd tags so app service instance deployed by the LZA is discovered during azd deploy phase
var azdRequiredTags = { 
  'azd-service-name': 'backend' 
}

module appSupportingServices 'modules/supporting-services-main.bicep' = {
  name: 'app-supporting-services'
  scope: resourceGroup(spokeResourceGroupName)
  params: {
    appServiceName:appServiceLza.outputs.webAppResourceName
    azdServiceTags: azdRequiredTags
    appServiceIdentityPrincipalId:appServiceIdentityPrincipalId
    appServiceIdentityClientId:appServiceIdentityClientId
    userPrincipalId:userPrincipalId
    environmentName: environmentName
    location: location
    searchServiceName: searchServiceName
    searchServiceLocation: searchServiceLocation
    searchServiceSkuName: searchServiceSkuName
    searchIndexName: searchIndexName
    searchQueryLanguage: searchQueryLanguage
    searchQuerySpeller: searchQuerySpeller
    storageAccountName: storageAccountName
    storageResourceGroupLocation: storageResourceGroupLocation
    storageContainerName: storageContainerName
    storageSkuName: storageSkuName
    openAIAccountName: openAIAccountName
    formRecognizerServiceName: formRecognizerServiceName
    formRecognizerSkuName: formRecognizerSkuName
    chatGptDeploymentName: chatGptDeploymentName
    chatGptDeploymentCapacity: chatGptDeploymentCapacity
    chatGptModelName: chatGptModelName
    chatGptModelVersion: chatGptModelVersion
    embeddingDeploymentName: embeddingDeploymentName
    embeddingDeploymentCapacity: embeddingDeploymentCapacity
    embeddingModelName: embeddingModelName
    useAuthentication: useAuthentication
    serverAppId: serverAppId
    serverAppSecret: serverAppSecret
    clientAppId: clientAppId
    allowedOrigin: allowedOrigin
  }
  dependsOn: [
    appServiceLza
  ]
}


output AZURE_RESOURCE_GROUP string = spokeResourceGroupName
output AZURE_TENANT_ID string = tenant().tenantId

// Shared by all OpenAI deployments
output OPENAI_HOST string = 'azure'
output AZURE_OPENAI_EMB_MODEL_NAME string = embeddingModelName
output AZURE_OPENAI_CHATGPT_MODEL string = chatGptModelName
// Specific to Azure OpenAI
output AZURE_OPENAI_SERVICE string = openAIAccountName
output AZURE_OPENAI_RESOURCE_GROUP string = spokeResourceGroupName
output AZURE_OPENAI_CHATGPT_DEPLOYMENT string =  chatGptDeploymentName
output AZURE_OPENAI_EMB_DEPLOYMENT string = embeddingDeploymentName


output AZURE_FORMRECOGNIZER_SERVICE string = appSupportingServices.outputs.formRecognizerService
output AZURE_FORMRECOGNIZER_RESOURCE_GROUP string = spokeResourceGroupName

output AZURE_SEARCH_INDEX string = searchIndexName
output AZURE_SEARCH_SERVICE string = appSupportingServices.outputs.azureSearchService
output AZURE_SEARCH_SERVICE_RESOURCE_GROUP string = spokeResourceGroupName

output AZURE_STORAGE_ACCOUNT string = appSupportingServices.outputs.azureStorageAccount
output AZURE_STORAGE_CONTAINER string = storageContainerName
output AZURE_STORAGE_RESOURCE_GROUP string = spokeResourceGroupName

output BACKEND_URI string = appServiceLza.outputs.webAppHostName
