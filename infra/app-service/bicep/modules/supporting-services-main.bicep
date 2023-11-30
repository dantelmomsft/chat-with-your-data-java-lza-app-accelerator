targetScope = 'resourceGroup'

// reference to the BICEP naming module
param naming object

@description('Name of the Azure Open AI nstance created by the LZA accelerator')
param openAIAccountName string = ''

@description('ID of the App Service identity principal id created by the LZA accelerator')
param appServiceIdentityPrincipalId string

@description('Client ID of the App Service identity created by the LZA accelerator')
param appServiceIdentityClientId string

@description('Name of the App Service instance created by the LZA accelerator')
param appServiceName string

@description('ID of the subnet private endpoint created by the LZA accelerator for app service dependencies')
param subnetPrivateEndpointId string

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

@description(' tags required by azd so that the service is discovered by deploy phase')
param azdServiceTags object = {}

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string = resourceGroup().location


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



//var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

var resourceNames = {
  storageAccount: naming.storageAccount.nameUnique
  documentIntelligence: 'frc-${naming.cognitiveAccount.nameUnique}'
  azureAiSearch: 'srch-${naming.cognitiveAccount.nameUnique}'
}

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

var vnetHubSplitTokens = !empty(hubVNetId) ? split(hubVNetId, '/') : array('')


/***************************************************************************************
 * Azure Open AI account
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
  name: take('${resourceNames.documentIntelligence}-documentIntelligence-Deployment', 64)
  params: {
    name: resourceNames.documentIntelligence
    location: location
    kind: 'FormRecognizer'
    sku: formRecognizerSkuName
    tags: tags
    hasPrivateLinks: !empty(subnetPrivateEndpointId)
    diagnosticSettings: [
      {
        name: 'DocumentIntelligence-Default-Diag'        
        workspaceResourceId: logAnalyticsWsId
      }
    ]
  }
}


module documentIntelligencePrivateDnsZone '../lza-libs/appservice-landing-zone-accelerator/scenarios/shared/bicep/private-dns-zone.bicep' = if ( !empty(subnetPrivateEndpointId) ) {
  // conditional scope is not working: https://github.com/Azure/bicep/issues/7367
  //scope: empty(vnetHubResourceId) ? resourceGroup() : resourceGroup(vnetHubSplitTokens[2], vnetHubSplitTokens[4]) 
  scope: resourceGroup(vnetHubSplitTokens[2], vnetHubSplitTokens[4])
  name: take('${replace(cognitiveServicesDnsZoneName, '.', '-')}-PrivateDnsZoneDeployment', 64)
  params: {
    name: cognitiveServicesDnsZoneName
    virtualNetworkLinks: virtualNetworkLinks
    tags: tags
  }
}

module peDocumentIntelligence '../lza-libs/appservice-landing-zone-accelerator/scenarios/shared/bicep/private-endpoint.bicep' = if ( !empty(subnetPrivateEndpointId) ) {
  name: take('pe-${resourceNames.documentIntelligence}-Deployment', 64)
  params: {
    name: take('pe-${resourceNames.documentIntelligence}', 64)
    location: location
    tags: tags
    privateDnsZonesId: documentIntelligencePrivateDnsZone.outputs.privateDnsZonesId
    privateLinkServiceId: documentIntelligence.outputs.resourceId
    snetId: subnetPrivateEndpointId
    subresource: 'account'
  }
}

/***************************************************************************************
 * Azure AI Search
 ***************************************************************************************/
var azureAISearchDnsZoneName = 'privatelink.search.windows.net' 

module azureAISearch 'search/aisearch-services.bicep' = {
  name: take('${resourceNames.azureAiSearch}-AzureAISearch-Deployment', 64)
  params: {
    name: resourceNames.azureAiSearch
    location: location
    sku: searchServiceSkuName
    tags: tags
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    hasPrivateLinks: !empty(subnetPrivateEndpointId)
    diagnosticSettings: [
      {
        name: 'AzureAISearch-Default-Diag'        
        workspaceResourceId: logAnalyticsWsId
      }
    ]
  }
}


module azureAISearchPrivateDnsZone '../lza-libs/appservice-landing-zone-accelerator/scenarios/shared/bicep/private-dns-zone.bicep' = if ( !empty(subnetPrivateEndpointId) ) {
  scope: resourceGroup(vnetHubSplitTokens[2], vnetHubSplitTokens[4])
  name: take('${replace(azureAISearchDnsZoneName, '.', '-')}-PrivateDnsZoneDeployment', 64)
  params: {
    name: azureAISearchDnsZoneName
    virtualNetworkLinks: virtualNetworkLinks
    tags: tags
  }
}

module peAzureAISearch '../lza-libs/appservice-landing-zone-accelerator/scenarios/shared/bicep/private-endpoint.bicep' = if ( !empty(subnetPrivateEndpointId) ) {
  name: take('pe-${resourceNames.azureAiSearch}-Deployment', 64)
  params: {
    name: take('pe-${resourceNames.azureAiSearch}', 64)
    location: location
    tags: tags
    privateDnsZonesId: azureAISearchPrivateDnsZone.outputs.privateDnsZonesId
    privateLinkServiceId: azureAISearch.outputs.resourceId
    snetId: subnetPrivateEndpointId
    subresource: 'searchService'
  }
}

/***************************************************************************************
 * Storage Account
 ***************************************************************************************/
 var storageAccountBlobDnsZoneName = 'privatelink.blob.core.windows.net' 

module storage 'storage/storage-account.bicep' = {
  name: take('${resourceNames.storageAccount}-StorageAccount-Deployment', 64)
  params: {
    name: '${resourceNames.storageAccount}'
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
  }
}

module storageAccountBlobPrivateDnsZone '../lza-libs/appservice-landing-zone-accelerator/scenarios/shared/bicep/private-dns-zone.bicep' = if ( !empty(subnetPrivateEndpointId) ) {
  scope: resourceGroup(vnetHubSplitTokens[2], vnetHubSplitTokens[4])
  name: take('${replace(storageAccountBlobDnsZoneName, '.', '-')}-PrivateDnsZoneDeployment', 64)
  params: {
    name: storageAccountBlobDnsZoneName
    virtualNetworkLinks: virtualNetworkLinks
    tags: tags
  }
}

module pestorageAccountBlob '../lza-libs/appservice-landing-zone-accelerator/scenarios/shared/bicep/private-endpoint.bicep' = if ( !empty(subnetPrivateEndpointId) ) {
  name: take('pe-${resourceNames.storageAccount}-Deployment', 64)
  params: {
    name: take('pe-${resourceNames.storageAccount}', 64)
    location: location
    tags: tags
    privateDnsZonesId: storageAccountBlobPrivateDnsZone.outputs.privateDnsZonesId
    privateLinkServiceId: storage.outputs.resourceId
    snetId: subnetPrivateEndpointId
    subresource: 'blob'
  }
}


/***************************************************************************************
 * App Service Extension with tags and app settings
 ***************************************************************************************/

resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}



var existingTags = appService.tags

resource extendAppServiceTags 'Microsoft.Resources/tags@2022-09-01' = {
  name: 'default'
  scope: appService
  properties: {
    tags: union(existingTags, azdServiceTags)
  }
}


  
//Add the sample required java app settings to the existing App Service created by the LZA accelerator
var appServiceSettingsName = '${appService.id}/config/appsettings'
var currentAppSettings = list(appServiceSettingsName, '2020-12-01').properties

var newAppSettings = {
  AZURE_STORAGE_ACCOUNT: storage.outputs.name
  AZURE_STORAGE_CONTAINER: storageContainerName
  AZURE_SEARCH_INDEX: searchIndexName
  AZURE_SEARCH_SERVICE: azureAISearch.outputs.name
  AZURE_SEARCH_QUERY_LANGUAGE: searchQueryLanguage
  AZURE_SEARCH_QUERY_SPELLER: searchQuerySpeller
  AZURE_OPENAI_EMB_MODEL_NAME: embeddingModelName
  AZURE_OPENAI_CHATGPT_MODEL: chatGptModelName
  // Specific to Azure OpenAI
  AZURE_OPENAI_SERVICE: openAIAccountName
  AZURE_OPENAI_CHATGPT_DEPLOYMENT: chatGptDeploymentName
  AZURE_OPENAI_EMB_DEPLOYMENT: embeddingDeploymentName

  // Optional login and document level access control system
  AZURE_USE_AUTHENTICATION: useAuthentication
  AZURE_SERVER_APP_ID: serverAppId
  AZURE_SERVER_APP_SECRET: serverAppSecret
  AZURE_CLIENT_APP_ID: clientAppId
  AZURE_TENANT_ID: tenant().tenantId
  // CORS support, for frontends on other hosts
  ALLOWED_ORIGIN: allowedOrigin

  //APP INSIGHTS FOR JAVA
  XDT_MicrosoftApplicationInsights_Java: '1'

  //SETUP the use of user assigned managed identity
  AZURE_CLIENT_ID: appServiceIdentityClientId
}



module expandedAppSettings 'host/appservice-appsettings.bicep' = {
  name: 'expandedAppSettings'
  params: {
    name: appServiceName
    appSettings: union(currentAppSettings,newAppSettings)
  }
}


resource existingOpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAIAccountName
}

// USER ROLES assignment required to run the data ingestion process during post-provision hook
//TODO Refactor the role.bicep in order to accept the scope parameter
resource openAiRoleUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, userPrincipalId, '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
  properties: {
    principalId: userPrincipalId
    principalType: 'User'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions','5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
  }
  scope:existingOpenAI
}



module formRecognizerRoleUser 'security/role.bicep' = {
  name: 'formrecognizer-role-user'
  params: {
    principalId: userPrincipalId
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908'
    principalType: 'User'
  }
}

module storageRoleUser 'security/role.bicep' = {
  name: 'storage-role-user'
  params: {
    principalId: userPrincipalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: 'User'
  }
}

module storageContribRoleUser 'security/role.bicep' = {
  name: 'storage-contribrole-user'
  params: {
    principalId: userPrincipalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: 'User'
  }
}

module searchRoleUser 'security/role.bicep' = {
  name: 'search-role-user'
  params: {
    principalId: userPrincipalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: 'User'
  }
}

module searchContribRoleUser 'security/role.bicep' = {
  name: 'search-contrib-role-user'
  params: {
    principalId: userPrincipalId
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    principalType: 'User'
  }
}

module searchSvcContribRoleUser 'security/role.bicep' = {
  name: 'search-svccontrib-role-user'
  params: {
    principalId: userPrincipalId
    roleDefinitionId: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
    principalType: 'User'
  }
}


// SYSTEM IDENTITIES required by the application at runtime
//TODO Refactor the role.bicep in order to accept the scope parameter
resource role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, appServiceIdentityPrincipalId, '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
  properties: {
    principalId: appServiceIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions','5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
  }
  scope:existingOpenAI
}

//TODO Assign roles to appServiceManagedIdentityId for Azure AI search and storage
module storageRoleBackend 'security/role.bicep' = {
  name: 'storage-role-backend'
  params: {
    principalId: appServiceIdentityPrincipalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: 'ServicePrincipal'
  }
}

module searchRoleBackend 'security/role.bicep' = {
  name: 'search-role-backend'
  params: {
    principalId: appServiceIdentityPrincipalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: 'ServicePrincipal'
  }
}



output formRecognizerService string = documentIntelligence.outputs.name
output formRecognizerResourceGroup string = resourceGroup().name

output azureSearchIndex string = searchIndexName
output azureSearchService string = azureAISearch.outputs.name
output azureSearchServiceResourceGroup string = resourceGroup().name

output azureStorageAccount string = storage.outputs.name
output azureStorageContainer string = storageContainerName
output azureStorageResourceGroup string = resourceGroup().name
