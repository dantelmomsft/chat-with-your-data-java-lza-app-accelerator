targetScope = 'resourceGroup'


@description('Name of the Azure Open AI nstance created by the LZA accelerator')
param openAIAccountName string = ''

@description('Name of the Log Analytics Workspace instance created by the LZA accelerator')
param logAnalyticsWsId string

@description('ID of the VNet Hub instance created by the LZA accelerator')
param hubVNetId string

@description('Name of the VNet Hub instance created by the LZA accelerator')
param hubVNetName string

@description('ID of the VNet Spoke instance created by the LZA accelerator')
param spokeVnetId string

@description('Name of the VNet Spoke instance created by the LZA accelerator')
param spokeVnetName string

@description('Name of the private endpoins subnet in the spoke vnet created by the LZA accelerator')
param subnetPrivateEndpointName string

@minLength(1)
@maxLength(8)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environment string

@description('The name of the workload that is being deployed. Up to 10 characters long.')
@minLength(2)
@maxLength(10)
param workloadName string 

@minLength(1)
@description('Primary location for all resources')
param location string = resourceGroup().location


// The free tier does not support managed identity (required) or semantic search (optional)
@allowed(['basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param searchServiceSkuName string 
param searchIndexName string 




param storageContainerName string 
param storageSkuName string 


param formRecognizerSkuName string 

param chatGptDeploymentName string 
param chatGptDeploymentCapacity int
param chatGptModelName string 
param chatGptModelVersion string 
param embeddingDeploymentName string 
param embeddingDeploymentCapacity int 
param embeddingModelName string 
param serviceBusSkuName string 
param queueName string


@description('User-configured naming rules')
module naming '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/naming/naming.module.bicep' = {
  name: take('04-sharedNamingDeployment-${deployment().name}', 64)
  params: {
    uniqueId: uniqueString(resourceGroup().id)
    environment: environment
    workloadName: workloadName
    location: location
  }
}

resource spokeVNet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: spokeVnetName
}

resource spokePrivateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: subnetPrivateEndpointName
  parent: spokeVNet
}


//var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environment }


var virtualNetworkLinks = [
  {
    vnetName: hubVNetName
    vnetId: hubVNetId
    registrationEnabled: false
  }
  {
    vnetName: spokeVnetName
    vnetId: spokeVnetId
    registrationEnabled: false
  }
]



/***************************************************************************************
 * Azure Open AI Models Deployments
 ***************************************************************************************/

 //Add model deployments to the existing OpenAI account created by the LZA accelerator
module openAIModelsDeployment 'ai-services/aoai-modeldeployment.bicep' =  {
  name: 'openai-models-deployment'
  params: {
    name: openAIAccountName
    deployments: [
      {
        name: chatGptDeploymentName
        model: {
          format: 'OpenAI'
          name: chatGptModelName
          version: chatGptModelVersion
        }
        sku: {
          name: 'Standard'
          capacity: chatGptDeploymentCapacity
        }
      }
      {
        name: embeddingDeploymentName
        model: {
          format: 'OpenAI'
          name: embeddingModelName
          version: '2'
        }
        capacity: embeddingDeploymentCapacity
      }
    ]
  }
}


/***************************************************************************************
 * Document Intelligence
 ***************************************************************************************/
var cognitiveServicesDnsZoneName = 'privatelink.cognitiveservices.azure.com' 


module documentIntelligence 'ai-services/cognitive-services.bicep' = {
  name: take('documentIntelligence-${uniqueString(resourceGroup().id)}', 64)
  params: {
    name: naming.outputs.resourcesNames.documentIntelligence
    location: location
    kind: 'FormRecognizer'
    sku: formRecognizerSkuName
    tags: tags
    hasPrivateLinks: true
    diagnosticSettings: [
      {      
        workspaceResourceId: logAnalyticsWsId
      }
    ]
  }
}



module documentIntelligenceNetworking '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/network/private-networking.bicep' = {
  name: take('documentIntelligencePrivateNetworking-${uniqueString(resourceGroup().id)}',64)
  params: {
    location: location
    azServicePrivateDnsZoneName: cognitiveServicesDnsZoneName
    azServiceId: documentIntelligence.outputs.resourceId
    privateEndpointName: naming.outputs.resourcesNames.documentIntelligencePep
    privateEndpointSubResourceName: 'account'
    virtualNetworkLinks: virtualNetworkLinks
    subnetId: spokePrivateEndpointSubnet.id
    vnetHubResourceId: hubVNetId
  }
}


/***************************************************************************************
 * Azure AI Search
 ***************************************************************************************/
var azureAISearchDnsZoneName = 'privatelink.search.windows.net' 

module azureAISearch 'search/aisearch-services.bicep' = {
  name: take('azureAiSearch-${uniqueString(resourceGroup().id)}', 64)
  params: {
    name: naming.outputs.resourcesNames.azureAiSearch
    location: location
    sku: searchServiceSkuName
    tags: tags
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    hasPrivateLinks: true
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWsId
      }
    ]
  }
}


module azureAISearchNetworking '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/network/private-networking.bicep' = {
  name: take('azureAISearchPrivateNetworking-${uniqueString(resourceGroup().id)}',64)
  params: {
    location: location
    azServicePrivateDnsZoneName: azureAISearchDnsZoneName
    azServiceId: azureAISearch.outputs.resourceId
    privateEndpointName: naming.outputs.resourcesNames.azureAISearchPep
    privateEndpointSubResourceName: 'searchService'
    virtualNetworkLinks: virtualNetworkLinks
    subnetId: spokePrivateEndpointSubnet.id
    vnetHubResourceId: hubVNetId
  }
}


/***************************************************************************************
 * Storage Account
 ***************************************************************************************/
 var storageAccountBlobDnsZoneName = 'privatelink.blob.core.windows.net' 

module storage 'storage/storage-account.bicep' = {
  name: take('storageAccount-${uniqueString(resourceGroup().id)}', 64)
  params: {
    name: naming.outputs.resourcesNames.storageAccount
    location: location
    tags: tags
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    sku: {
      name: storageSkuName
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 2
    }
    containers: [
      {
        name: storageContainerName
        publicAccess: 'None'
      }
    ]
    diagnosticSettings: [
      {        
        workspaceResourceId: logAnalyticsWsId
      }
    ]
  }
}


module azureStorageNetworking '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/network/private-networking.bicep' = {
  name: take('azureStoragePrivateNetworking-${uniqueString(resourceGroup().id)}',64)
  params: {
    location: location
    azServicePrivateDnsZoneName: storageAccountBlobDnsZoneName
    azServiceId: storage.outputs.resourceId
    privateEndpointName: naming.outputs.resourcesNames.storageAccountPep
    privateEndpointSubResourceName: 'blob'
    virtualNetworkLinks: virtualNetworkLinks
    subnetId: spokePrivateEndpointSubnet.id
    vnetHubResourceId: hubVNetId
  }
}

/***************************************************************************************
 * Service Bus
 ***************************************************************************************/
 var serviceBusPrivateDnsZoneName = 'privatelink.servicebus.windows.net'

 module servicebus '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/service-bus.bicep' = {
  name: take('serviceBusQueue-${uniqueString(resourceGroup().id)}', 64)
  params: {
    name: naming.outputs.resourcesNames.serviceBus
    location: location
    tags: tags
    publicNetworkAccess: 'Disabled'
    allowTrustedServicesAccess: true //required to receive events from Event Grid
    workspaceId:logAnalyticsWsId
    queueNames: [ queueName ]
    lockDuration: 'PT3M'
    skuName: serviceBusSkuName
   
  }
}

module serviceBusNetworking '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/network/private-networking.bicep' = {
  name: take('serviceBusPrivateNetworking-${uniqueString(resourceGroup().id)}',64)
  params: {
    location: location
    azServicePrivateDnsZoneName: serviceBusPrivateDnsZoneName
    azServiceId: servicebus.outputs.id
    privateEndpointName: naming.outputs.resourcesNames.serviceBusPep
    privateEndpointSubResourceName: 'namespace'
    virtualNetworkLinks: virtualNetworkLinks
    subnetId: spokePrivateEndpointSubnet.id
    vnetHubResourceId: hubVNetId
  }
}

/***************************************************************************************
 * Event Grid System Topic
 ***************************************************************************************/

module eventGridSubscription 'event/eventgrid-system-topic-subscription.bicep' = {
  name: 'eventGridSubscription'
  params: {
    location: location
    storageAccountName: storage.outputs.name
    serviceBusNamespaceName: servicebus.outputs.name
    queueName: queueName
    subscriptionName: naming.outputs.resourcesNames.eventGridSystemTopic
    systemTopicName:naming.outputs.resourcesNames.EventGridSystemTopic
  }
}







output documentIntelligenceName string = documentIntelligence.outputs.name
output documentIntelligenceNameGroup string = resourceGroup().name

output azureSearchIndex string = searchIndexName
output azureSearchService string = azureAISearch.outputs.name
output azureSearchServiceResourceGroup string = resourceGroup().name

output azureStorageAccount string = storage.outputs.name
output azureStorageContainer string = storageContainerName
output azureStorageResourceGroup string = resourceGroup().name

output serviceBusNamespace string = servicebus.outputs.name

