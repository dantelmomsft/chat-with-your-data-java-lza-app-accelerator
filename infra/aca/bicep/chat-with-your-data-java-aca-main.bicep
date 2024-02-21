targetScope = 'subscription'


@description('The name of the workload that is being deployed. Up to 10 characters long.')
@minLength(2)
@maxLength(10)
param workloadName string = 'java-chat'

@minLength(1)
@maxLength(8)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environment string

@minLength(1)
@description('Primary location for all resources. This is limited by the ones supporting the required OpenAI models')
@allowed(['australiaeast','canadaeast', 'eastus2', 'francecentral', 'uksouth', 'japaneast', 'swedencentral'])
param location string

// ====================================== //
// ACA Landing Zones Parameters           //
// ===================================== //

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}


// Hub Virtual Network
@description('The address prefixes to use for the virtual network.')
param hubVnetAddressPrefixes array

// Hub Bastion
@description('Enable or disable the creation of the Azure Bastion.')
param enableBastion bool

@description('CIDR to use for the Azure Bastion subnet.')
param bastionSubnetAddressPrefix string

@description('CIDR to use for the gatewaySubnet.')
param gatewaySubnetAddressPrefix string

@description('CIDR to use for the azureFirewallSubnet.')
param azureFirewallSubnetAddressPrefix string

@description('CIDR to use for the AzureFirewallManagementSubnet, which is required by AzFW Basic.')
param azureFirewallSubnetManagementAddressPrefix string

// Hub Virtual Machine
@description('The size of the virtual machine to create. See https://learn.microsoft.com/azure/virtual-machines/sizes for more information.')
param vmSize string

@description('The username to use for the virtual machine.')
param vmAdminUsername string

@description('The password to use for the virtual machine.')
@secure()
param vmAdminPassword string

@description('The SSH public key to use for the virtual machine.')
@secure()
param vmLinuxSshAuthorizedKeys string

@allowed(['linux', 'windows', 'none'])
param vmJumpboxOSType string = 'none'

@description('CIDR to use for the virtual machine subnet.')
param vmJumpBoxSubnetAddressPrefix string

// Spoke

@description('CIDR of the Spoke Virtual Network.')
param spokeVNetAddressPrefixes array

@description('CIDR of the Spoke Infrastructure Subnet.')
param spokeInfraSubnetAddressPrefix string

@description('CIDR of the Spoke Private Endpoints Subnet.')
param spokePrivateEndpointsSubnetAddressPrefix string

@description('CIDR of the Spoke Application Gateway Subnet.')
param spokeApplicationGatewaySubnetAddressPrefix string

@description('Enable or disable the createion of Application Insights.')
param enableApplicationInsights bool

@description('The FQDN of the Application Gateway. Must match the TLS Certificate.')
param applicationGatewayFqdn string

@description('Enable or disable Application Gateway Certificate (PFX).')
param enableApplicationGatewayCertificate bool

@description('The name of the certificate key to use for Application Gateway certificate.')
param applicationGatewayCertificateKeyName string

@description('Enable usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = true


@description('Optional, default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false.')
param deployZoneRedundantResources bool = true

@description('Optional, default value is true. If true, Azure Policies will be deployed')
param deployAzurePolicies bool = true

@description('Optional. DDoS protection mode. see https://learn.microsoft.com/azure/ddos-protection/ddos-protection-sku-comparison#skus')
@allowed([
  'Enabled'
  'Disabled'
  'VirtualNetworkInherited'
])
param ddosProtectionMode string = 'Disabled'


// ================ //
// App Parameters   //
// ================ //



// The free tier does not support managed identity (required) or semantic search (optional)
@allowed(['basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param searchServiceSkuName string // Set in main.parameters.json
param searchIndexName string // Set in main.parameters.json
param searchQueryLanguage string // Set in main.parameters.json
param searchQuerySpeller string // Set in main.parameters.json


param storageContainerName string = 'content'
param storageSkuName string // Set in main.parameters.json



param formRecognizerSkuName string = 'S0'

param chatGptDeploymentName string // Set in main.parameters.json
param chatGptDeploymentCapacity int = 30
param chatGptModelName string = 'gpt-35-turbo'
param chatGptModelVersion string = '0613'
param embeddingDeploymentName string // Set in main.parameters.json
param embeddingDeploymentCapacity int = 60
param embeddingModelName string = 'text-embedding-ada-002'

@description('The name of the queue where event grid will publish the blob notifications')
param queueName string = 'documents-queue'


@description('Id of the user to assign application roles for CLI to ingest documents')
param userPrincipalId string = ''

var expandedTags = union({
  'azd-env-name': environment
}, tags)



module acaLza 'lza-libs/aca-landing-zone-accelerator/scenarios/aca-internal/bicep/main.bicep' = {
  name: 'aca-lza-internal-scenario-deployment'
  params: {
    location:location
    workloadName: workloadName
    tags:expandedTags
    environment:environment
    vnetAddressPrefixes:hubVnetAddressPrefixes
    gatewaySubnetAddressPrefix:gatewaySubnetAddressPrefix
    azureFirewallSubnetAddressPrefix:azureFirewallSubnetAddressPrefix
    azureFirewallSubnetManagementAddressPrefix:azureFirewallSubnetManagementAddressPrefix
    enableBastion:enableBastion
    bastionSubnetAddressPrefix:bastionSubnetAddressPrefix

    spokeVNetAddressPrefixes:spokeVNetAddressPrefixes
    spokeInfraSubnetAddressPrefix:spokeInfraSubnetAddressPrefix
    spokePrivateEndpointsSubnetAddressPrefix:spokePrivateEndpointsSubnetAddressPrefix
    spokeApplicationGatewaySubnetAddressPrefix:spokeApplicationGatewaySubnetAddressPrefix
    vmJumpBoxSubnetAddressPrefix:vmJumpBoxSubnetAddressPrefix
    vmSize:vmSize
    vmJumpboxOSType:vmJumpboxOSType
    vmAdminUsername:vmAdminUsername
    vmAdminPassword:vmAdminPassword
    vmLinuxSshAuthorizedKeys:vmLinuxSshAuthorizedKeys
    
    enableDaprInstrumentation:false
    deployHelloWorldSample:false
    deployOpenAi:true
    deployRedisCache:false
    enableApplicationInsights:enableApplicationInsights
    enableApplicationGatewayCertificate:enableApplicationGatewayCertificate
    applicationGatewayCertificateKeyName:applicationGatewayCertificateKeyName
    applicationGatewayFqdn:applicationGatewayFqdn
    ddosProtectionMode:ddosProtectionMode
    deployZoneRedundantResources:deployZoneRedundantResources
    deployAzurePolicies:deployAzurePolicies

    enableTelemetry:enableTelemetry

  }
}




/**this is an hack which is somehow tight coupling the app biceps with the aca LZA internal implementation. 
* You can't use the spokeresourcename as output of a module. it needs to be known at compile time. See https://github.com/Azure/bicep/issues/4992
**/
var namingRules = json(loadTextContent('lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/naming/naming-rules.jsonc'))
var spokeResourceGroupName = '${namingRules.resourceTypeAbbreviations.resourceGroup}-${workloadName}-spoke-${environment}-${namingRules.regionAbbreviations[toLower(location)]}'


var logAnalyticsWsId = acaLza.outputs.logAnalyticsWorkspaceId
var hubVNetId = acaLza.outputs.hubVNetId
var hubVNetName = acaLza.outputs.hubVNetName
var spokeVnetId = acaLza.outputs.spokeVNetId
var spokeVnetName = acaLza.outputs.spokeVnetName
var subnetPeName = acaLza.outputs.spokePrivateEndpointsSubnetName

var applicationGatewaySubnetId = acaLza.outputs.spokeApplicationGatewaySubnetId
var keyVaultId = acaLza.outputs.keyVaultId

var applicationInsightsName = acaLza.outputs.applicationInsightsName
var containerAppsEnvironmentName = acaLza.outputs.containerAppsEnvironmentName
var containerRegistryName = acaLza.outputs.containerRegistryName

var openAIAccountName = acaLza.outputs.openAIAccountName



module installBuildDependencies 'modules/vm/install-build-depedencies.bicep' = {
  name: 'install-build-dependencies-deployment'
  scope: resourceGroup(spokeResourceGroupName)
  params: {
   vmName: acaLza.outputs.vmJumpBoxName
   location: location
  }
  
}

module appDepedencies 'modules/app-dependencies.bicep' = {
  name: 'app-depedencies-deployment'
  scope: resourceGroup(spokeResourceGroupName)
  params: {
    logAnalyticsWsId:logAnalyticsWsId
    hubVNetId:hubVNetId
    hubVNetName:hubVNetName
    spokeVnetId:spokeVnetId
    spokeVnetName:spokeVnetName
    subnetPrivateEndpointName:subnetPeName
    environment: environment
    workloadName: workloadName
    location: location
    searchServiceSkuName: searchServiceSkuName
    searchIndexName: searchIndexName
    storageContainerName: storageContainerName
    storageSkuName: storageSkuName
    openAIAccountName: openAIAccountName
    formRecognizerSkuName: formRecognizerSkuName
    chatGptDeploymentName: chatGptDeploymentName
    chatGptDeploymentCapacity: chatGptDeploymentCapacity
    chatGptModelName: chatGptModelName
    chatGptModelVersion: chatGptModelVersion
    embeddingDeploymentName: embeddingDeploymentName
    embeddingDeploymentCapacity: embeddingDeploymentCapacity
    embeddingModelName: embeddingModelName
    serviceBusSkuName: 'Premium' //Private endpoints supportyed only in Premium SKU
    queueName: queueName
  }
  dependsOn: [
    acaLza
  ]
}


module apps 'modules/apps.bicep' = {
  name: 'apps-deployment'
  scope: resourceGroup(spokeResourceGroupName)
  params: {
    environment: environment
    workloadName: workloadName
    location: location
    userPrincipalId: userPrincipalId
    containerAppsEnvironmentName:containerAppsEnvironmentName
    containerRegistryName:containerRegistryName
    openAIAccountName: openAIAccountName
    applicationInsightsName: applicationInsightsName
    searchServiceName: appDepedencies.outputs.azureSearchService
    searchIndexName: searchIndexName
    searchQueryLanguage: searchQueryLanguage
    searchQuerySpeller: searchQuerySpeller
    storageAccountName: appDepedencies.outputs.azureStorageAccount
    storageContainerName: storageContainerName
    documentIntelligenceName: appDepedencies.outputs.documentIntelligenceName
    chatGptDeploymentName: chatGptDeploymentName
    chatGptModelName: chatGptModelName
    embeddingDeploymentName: embeddingDeploymentName
    embeddingModelName: embeddingModelName
    serviceBusNamespaceName: appDepedencies.outputs.serviceBusNamespace
    queueName: queueName
  }
  dependsOn: [
    appDepedencies
  ]

}

/* Expose web frontend 

module applicationGateway 'lza-libs/aca-landing-zone-accelerator/scenarios/aca-internal/bicep/modules/06-application-gateway/deploy.app-gateway.bicep' =  {
  name: take('applicationGateway-${deployment().name}-deployment', 64)
  scope: resourceGroup(spokeResourceGroupName)
  params: {
    location: location
    tags: tags
    environment: environment
    workloadName: workloadName
    applicationGatewayCertificateKeyName: applicationGatewayCertificateKeyName
    applicationGatewayFqdn: applicationGatewayFqdn
    applicationGatewayPrimaryBackendEndFqdn: apps.outputs.webFrontenFqdn
    applicationGatewaySubnetId: applicationGatewaySubnetId
    enableApplicationGatewayCertificate: enableApplicationGatewayCertificate
    keyVaultId: keyVaultId
    deployZoneRedundantResources: deployZoneRedundantResources
    ddosProtectionMode: ddosProtectionMode
    applicationGatewayLogAnalyticsId: logAnalyticsWsId
  }
}

*/


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


output AZURE_FORMRECOGNIZER_SERVICE string = appDepedencies.outputs.documentIntelligenceName
output AZURE_FORMRECOGNIZER_RESOURCE_GROUP string = appDepedencies.outputs.documentIntelligenceNameGroup

output AZURE_SEARCH_INDEX string = searchIndexName
output AZURE_SEARCH_SERVICE string = appDepedencies.outputs.azureSearchService
output AZURE_SEARCH_SERVICE_RESOURCE_GROUP string = spokeResourceGroupName

output AZURE_STORAGE_ACCOUNT string = appDepedencies.outputs.azureStorageAccount
output AZURE_STORAGE_CONTAINER string = storageContainerName
output AZURE_STORAGE_RESOURCE_GROUP string = spokeResourceGroupName


output AZURE_CONTAINER_ENVIRONMENT_NAME string = acaLza.outputs.containerAppsEnvironmentName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acaLza.outputs.containerRegistryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acaLza.outputs.containerRegistryName
