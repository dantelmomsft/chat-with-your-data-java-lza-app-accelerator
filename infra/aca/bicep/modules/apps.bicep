targetScope = 'resourceGroup'

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


@description('The name of the Azure AI search service')
param searchServiceName string

param searchIndexName string
param searchQueryLanguage string
param searchQuerySpeller string


param storageContainerName string = 'content'
param storageAccountName string

param documentIntelligenceName string

param chatGptDeploymentName string // Set in main.parameters.json

param chatGptModelName string = 'gpt-35-turbo'

param embeddingDeploymentName string // Set in main.parameters.json

param embeddingModelName string = 'text-embedding-ada-002'


@description('The name of the servicebus namespace')
param serviceBusNamespaceName string
@description('The name of the queue where event grid will publish the blob notifications')
param queueName string = 'documents-queue'


@description('Id of the user to assign application roles for CLI to ingest documents')
param userPrincipalId string = ''

@description('The name of the Azure Open AI created in LZA.')
param openAIAccountName string

@description('The name of the app insights created in LZA. Apps will be attached to such instance.')
param applicationInsightsName string

@description('The name of the containers enviroment where the apps will be deployed')
param containerAppsEnvironmentName string
    
@description('The name of the container registry where the apps images will be pulled from')
param containerRegistryName string

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('Must be set to true the first time the deployment is run. It must be set to false after the first run.')
param apiAppExists bool = false

@description('Must be set to true the first time the deployment is run. It must be set to false after the first run.')
param webAppExists bool = false

@description('Must be set to true the first time the deployment is run. It must be set to false after the first run.')
param indexerAppExists bool = false


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


//Api backend
module api './app/api.bicep' = {
  name: 'api'
  scope: resourceGroup()
  params: {
    name: 'api-backend'
    location: location
    tags: tags
    identityName: '${naming.outputs.resourceTypeAbbreviations.managedIdentity}-api-backend'
    applicationInsightsName: applicationInsightsName
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    corsAcaUrl: ''
    exists: apiAppExists
    env: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccountName
      }
      {
        name: 'AZURE_STORAGE_CONTAINER'
        value: storageContainerName
      }
      {
        name: 'AZURE_SEARCH_INDEX'
        value: searchIndexName
      }
      {
        name: 'AZURE_SEARCH_SERVICE'
        value: searchServiceName

      }
      {
        name: 'AZURE_SEARCH_QUERY_LANGUAGE'
        value: searchQueryLanguage
      }
      {
        name: 'AZURE_SEARCH_QUERY_SPELLER'
        value: searchQuerySpeller
      }
      {
        name: 'AZURE_OPENAI_SERVICE'
        value: openAIAccountName
      }
      {
        name: 'AZURE_OPENAI_EMB_MODEL_NAME'
        value: embeddingModelName
      }
      {
        name: 'AZURE_OPENAI_CHATGPT_MODEL'
        value: chatGptModelName
      }
      {
        name: 'AZURE_OPENAI_CHATGPT_DEPLOYMENT'
        value: chatGptDeploymentName
      }
      {
        name: 'AZURE_OPENAI_EMB_DEPLOYMENT'
        value: embeddingDeploymentName
      }
    ]
  }
}

// Indexer backend
module indexer './app/indexer.bicep' = {
  name: 'indexer'
  scope: resourceGroup()
  params: {
    name: 'indexer-backend'
    location: location
    tags: tags
    identityName: '${naming.outputs.resourceTypeAbbreviations.managedIdentity}-indexer-backend'
    applicationInsightsName: applicationInsightsName
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    exists: indexerAppExists
    env: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccountName
      }
      {
        name: 'AZURE_STORAGE_CONTAINER'
        value: storageContainerName
      }
      {
        name: 'AZURE_SEARCH_INDEX'
        value: searchIndexName
      }
      {
        name: 'AZURE_SEARCH_SERVICE'
        value: searchServiceName

      }
      {
        name: 'AZURE_FORMRECOGNIZER_SERVICE'
        value: documentIntelligenceName
      }
      {
        name: 'AZURE_OPENAI_SERVICE'
        value: openAIAccountName
      }
      {
        name: 'AZURE_OPENAI_EMB_MODEL_NAME'
        value: embeddingModelName
      }
     
     {
        name: 'AZURE_OPENAI_EMB_DEPLOYMENT'
        value: embeddingDeploymentName
      }
      {
        name: 'AZURE_SERVICEBUS_NAMESPACE'
        value: serviceBusNamespaceName
      }
      {
        name: 'AZURE_SERVICEBUS_QUEUE_NAME'
        value: queueName
      }
    ]
  }
}

// Web frontend
module web './app/web.bicep' = {
  name: 'web'
  scope: resourceGroup()
  params: {
    name: 'web-frontend'
    location: location
    tags: tags
    identityName: '${naming.outputs.resourceTypeAbbreviations.managedIdentity}-frontend'
    apiBaseUrl:  api.outputs.SERVICE_API_URI
    applicationInsightsName: applicationInsightsName
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    exists: webAppExists
  }
}

/******* ROLE ASSIGNMENT ********/

resource openAIAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAIAccountName
}

resource documentIntelligenceAccout 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: documentIntelligenceName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusNamespaceName
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' existing = {
  name: queueName
  parent: serviceBusNamespace
}


resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageAccountName
}

resource azureAISearch 'Microsoft.Search/searchServices@2021-04-01-preview' existing = {
  name: searchServiceName
}

var cognitiveServicesOpenAIUSerRoleId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908'
var storageBlobDataReader = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
var storageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var searchIndexDataReader = '1407120a-92aa-4202-b7e9-c0e197c71c8f'
var searchIndexDataContributor = '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
var searchServiceContributor = '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
var azureServiceBusDataReceiver = '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'

// USER ROLES

module openAIUserRoleAssignmentUser '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('openAIUserRoleAssignmentDeployment-${deployment().name}', 64)
  params: {
    principalType: 'User'
    name: 'ra-openAIUserRoleAssignmentDeployment-user'
    principalId: userPrincipalId
    resourceId: openAIAccount.id
    roleDefinitionId: cognitiveServicesOpenAIUSerRoleId
  }
}

module documentIntelligenceRoleAssignmentUser '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('documentIntelligenceRoleAssignmentDeployment-${deployment().name}', 64)
  params: {
    principalType: 'User'
    name: 'ra-documentIntelligenceRoleAssignmentDeployment-user'
    principalId: userPrincipalId
    resourceId: documentIntelligenceAccout.id
    roleDefinitionId: cognitiveServicesUserRoleId
  }
}

module blobDataReaderRoleAssignmentUser '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('blobDataReaderRoleAssignmentDeployment-${deployment().name}', 64)
  params: {
    principalType: 'User'
    name: 'ra-blobDataReaderRoleAssignmentDeployment-user'
    principalId: userPrincipalId
    resourceId: storageAccount.id
    roleDefinitionId: storageBlobDataReader
  }
}

module blobDataContributorRoleAssignmentUser '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('blobDataContributorRoleAssignmentDeployment-${deployment().name}', 64)
  params: {
    principalType: 'User'
    name: 'ra-blobDataContributorRoleAssignmentDeployment-user'
    principalId: userPrincipalId
    resourceId: storageAccount.id
    roleDefinitionId: storageBlobDataContributor
  }
}

module searchIndexDataReaderRoleAssignmentUser '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('searchIndexDataReaderRoleAssignmentDeployment-${deployment().name}', 64)
  params: {
    principalType: 'User'
    name: 'ra-searchIndexDataReaderRoleAssignmentDeployment-user'
    principalId: userPrincipalId
    resourceId: azureAISearch.id
    roleDefinitionId: searchIndexDataReader
  }
}

module searchIndexDataContributorRoleAssignmentUser '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('searchIndexDataContributorRoleAssignmentDeployment-${deployment().name}', 64)
  params: {
    principalType: 'User'
    name: 'ra-searchIndexDataContributorRoleAssignmentDeployment-user'
    principalId: userPrincipalId
    resourceId: azureAISearch.id
    roleDefinitionId: searchIndexDataContributor
  }
}

module searchSvcContribRoleAssignmentUser '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('searchSvcContribRoleAssignmentDeployment-${deployment().name}', 64)
  params: {
    principalType: 'User'
    name: 'ra-searchSvcContribRoleAssignmentDeployment-user'
    principalId: userPrincipalId
    resourceId: azureAISearch.id
    roleDefinitionId: searchServiceContributor
  }
}


// SYSTEM IDENTITIES

module openAIUserRoleAssignmentAPI '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('openAIUserRoleAssignmentAPIDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-openAIUserRoleAssignmentDeployment-api'
    principalId: api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
    resourceId: openAIAccount.id
    roleDefinitionId: cognitiveServicesOpenAIUSerRoleId
  }
}

module openAIUserRoleAssignmentIndexer '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('openAIUserRoleAssignmentIndexerDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-openAIUserRoleAssignmentDeployment-indexer'
    principalId: indexer.outputs.SERVICE_INDEXER_IDENTITY_PRINCIPAL_ID
    resourceId: openAIAccount.id
    roleDefinitionId: cognitiveServicesOpenAIUSerRoleId
  }
}


module blobDataReaderRoleAssignmentAPI '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('blobDataReaderRoleAssignmentAPIDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-blobDataReaderRoleAssignmentDeployment-api'
    principalId: api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
    resourceId: storageAccount.id
    roleDefinitionId: storageBlobDataReader
  }
}

module blobDataContributorRoleAssignmentIndexer '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('blobDataContributorRoleAssignmentIndexerDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-blobDataContributorRoleAssignmentDeployment-indexer'
    principalId: indexer.outputs.SERVICE_INDEXER_IDENTITY_PRINCIPAL_ID
    resourceId: storageAccount.id
    roleDefinitionId: storageBlobDataContributor
  }
}


module searchIndexDataReaderRoleAssignmentAPI '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('searchIndexDataReaderRoleAssignmentAPIDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-searchIndexDataReaderRoleAssignmentDeployment-api'
    principalId: api.outputs.SERVICE_API_IDENTITY_PRINCIPAL_ID
    resourceId: azureAISearch.id
    roleDefinitionId: searchIndexDataReader
  }
}

module searchIndexDataContributorRoleAssignmentIndexer '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('searchIndexDataContributorRoleAssignmentIndexerDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-searchIndexDataContributorRoleAssignmentDeployment-indexer'
    principalId: indexer.outputs.SERVICE_INDEXER_IDENTITY_PRINCIPAL_ID
    resourceId: azureAISearch.id
    roleDefinitionId: searchIndexDataContributor
  }
}

module documentIntelligenceRoleAssignmentIndexer '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('documentIntelligenceRoleAssignmentIndexerDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-documentIntelligenceRoleAssignmentDeployment-indexer'
    principalId: indexer.outputs.SERVICE_INDEXER_IDENTITY_PRINCIPAL_ID
    resourceId: documentIntelligenceAccout.id
    roleDefinitionId: cognitiveServicesUserRoleId
  }
}

module serviceBusQueueRoleAssignmentIndexer '../lza-libs/aca-landing-zone-accelerator/scenarios/shared/bicep/role-assignments/role-assignment.bicep' = {
  name: take('serviceBusQueueRoleAssignmentIndexerDeployment-${deployment().name}', 64)
  params: {
    name: 'ra-serviceBusQueueRoleAssignmentDeployment-indexer'
    principalId: indexer.outputs.SERVICE_INDEXER_IDENTITY_PRINCIPAL_ID
    resourceId: serviceBusQueue.id
    roleDefinitionId: azureServiceBusDataReceiver
  }
}


output webFrontenFqdn  string = web.outputs.SERVICE_WEB_FQDN
