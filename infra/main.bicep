targetScope = 'subscription'


// ================ //
// App Parameters   //
// ================ //

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param appServicePlanName string = ''
param backendServiceName string = ''
param resourceGroupName string = ''

param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param logAnalyticsName string = ''

param searchServiceName string = ''
param searchServiceResourceGroupName string = ''
param searchServiceLocation string = ''
// The free tier does not support managed identity (required) or semantic search (optional)
@allowed(['basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param searchServiceSkuName string // Set in main.parameters.json
param searchIndexName string // Set in main.parameters.json
param searchQueryLanguage string // Set in main.parameters.json
param searchQuerySpeller string // Set in main.parameters.json

param storageAccountName string = ''
param storageResourceGroupName string = ''
param storageResourceGroupLocation string = location
param storageContainerName string = 'content'
param storageSkuName string // Set in main.parameters.json

@allowed(['azure', 'openai'])
param openAiHost string // Set in main.parameters.json

param openAiServiceName string = ''
param openAiResourceGroupName string = ''
@description('Location for the OpenAI resource group')
@allowed(['canadaeast', 'eastus', 'eastus2', 'francecentral', 'switzerlandnorth', 'uksouth', 'japaneast', 'northcentralus', 'australiaeast', 'swedencentral'])
@metadata({
  azd: {
    type: 'location'
  }
})
param openAiResourceGroupLocation string

param openAiSkuName string = 'S0'

param openAiApiKey string = ''
param openAiApiOrganization string = ''

param formRecognizerServiceName string = ''
param formRecognizerResourceGroupName string = ''
param formRecognizerResourceGroupLocation string = location

param formRecognizerSkuName string = 'S0'

param chatGptDeploymentName string // Set in main.parameters.json
param chatGptDeploymentCapacity int = 30
param chatGptModelName string = (openAiHost == 'azure') ? 'gpt-35-turbo' : 'gpt-3.5-turbo'
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
param principalId string = ''

@description('Use Application Insights for monitoring and performance tracing')
param useApplicationInsights bool = false



// ====================================== //
// App Service Landing Zones Parameters   //
// ===================================== //
@maxLength(10)
@description('suffix (max 10 characters long) that will be used to name the resources in a pattern like <resourceAbbreviation>-<workloadName>')
param workloadName string =  'appsvc${ take( uniqueString( subscription().id), 4) }'

@description('Required. The name of the environmentName (e.g. "dev", "test", "prod", "preprod", "staging", "uat", "dr", "qa"). Up to 8 characters long.')
@maxLength(8)
param lzaEnvironmentName string = 'test'

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
param webAppBaseOs string = 'Windows'

@description('mandatory, the username of the admin user of the jumpbox VM')
param adminUsername string = 'azureuser'

@description('mandatory, the password of the admin user of the jumpbox VM ')
@secure()
param adminPassword string

@description('Conditional. The Azure Active Directory (AAD) administrator authentication. Required if no `sqlAdminLogin` & `sqlAdminPassword` is provided.')
param sqlServerAdministrators object = {}

@description('Conditional. If sqlServerAdministrators is given, this is not required. ')
param sqlAdminLogin string = 'sqluser'

@description('Conditional. If sqlServerAdministrators is given, this is not required -check password policy: https://learn.microsoft.com/en-us/sql/relational-databases/security/password-policy?view=azuresqldb-current')
@secure()
param sqlAdminPassword string = newGuid()


@description('set to true if you want to deploy a jumpbox/devops VM')
param deployJumpHost bool = true

// post deployment specific parameters for the jumpBox
@description('The URL of the Github repository to use for the Github Actions Runner. This parameter is optional. If not provided, the Github Actions Runner will not be installed. If this parameter is provided, then github_token must also be provided.')
param githubRepository string = '' 

@description('The token to use for the Github Actions Runner. This parameter is optional. If not provided, the Github Actions Runner will not be installed. If this parameter is provided, then github_repository must also be provided.')
param githubToken string = '' 

@description('The URL of the Azure DevOps organization to use for the Azure DevOps Agent. This parameter is optional. If not provided, the Github Azure DevOps will not be installed. If this parameter is provided, then ado_token must also be provided.')
param adoOrganization string = '' 

@description('The PAT token to use for the Azure DevOps Agent. This parameter is optional. If not provided, the Github Azure DevOps will not be installed. If this parameter is provided, then ado_organization must also be provided.')
param adoToken string = '' 


var tags = union({
  'azd-env-name': environmentName
}, resourceTags)


module appServiceLza 'appservice-landing-zone-accelerator/scenarios/secure-baseline-multitenant/bicep/main.bicep' = {
  name: 'app-service-lza'
  params: {
    location: location
    workloadName: environmentName
    environmentName: 'azd'
    numericSuffix: numericSuffix
    resourceTags: tags
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
    adminUsername: adminUsername
    adminPassword: adminPassword
    sqlServerAdministrators: sqlServerAdministrators
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
    enableEgressLockdown: false
    deployRedis: false
    deployAzureSql: false
    deployAppConfig: false
    deployJumpHost: deployJumpHost
    githubRepository: githubRepository
    githubToken: githubToken
    adoOrganization: adoOrganization
    adoToken: adoToken
    installClis: false
    installSsms: false
    autoApproveAfdPrivateEndpoint: false

  }
}

/*
module appSupportingServices 'app-supporting-services/app-supporting-services-main.bicep' = {
  name: 'app-supporting-services'
  params: {
    environmentName: environmentName
    location: location
    resourceGroupName: resourceGroupName
    applicationInsightsDashboardName: applicationInsightsDashboardName
    applicationInsightsName: applicationInsightsName
    logAnalyticsName: logAnalyticsName
    searchServiceName: searchServiceName
    searchServiceResourceGroupName: searchServiceResourceGroupName
    searchServiceLocation: searchServiceLocation
    searchServiceSkuName: searchServiceSkuName
    searchIndexName: searchIndexName
    searchQueryLanguage: searchQueryLanguage
    searchQuerySpeller: searchQuerySpeller
    storageAccountName: storageAccountName
    storageResourceGroupName: storageResourceGroupName
    storageResourceGroupLocation: storageResourceGroupLocation
    storageContainerName: storageContainerName
    storageSkuName: storageSkuName
    openAiHost: openAiHost
    openAiServiceName: openAiServiceName
    openAiResourceGroupName: openAiResourceGroupName
    openAiResourceGroupLocation: openAiResourceGroupLocation
    openAiSkuName: openAiSkuName
    openAiApiKey: openAiApiKey
    openAiApiOrganization: openAiApiOrganization
    formRecognizerServiceName: formRecognizerServiceName
    formRecognizerResourceGroupName: formRecognizerResourceGroupName
    formRecognizerResourceGroupLocation: formRecognizerResourceGroupLocation
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
    useApplicationInsights: useApplicationInsights
  }
}
*/

