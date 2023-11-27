# Chat With You Data with Java and Azure Open AI - LZA App Accelerator
This is a PoC about automating apps deployment on production ready environment provided by [Azure Landing Zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/ready).

In this example we are going to deploy the [Azure Open AI Java reference template](https://learn.microsoft.com/en-us/azure/developer/intro/azure-ai-for-developers?pivots=java#azure-ai-reference-templates) on top of the [App Service LZA](https://github.com/Azure/appservice-landing-zone-accelerator) using the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview)

## Getting Started

### Deploy the infrastructure
1. Clone this repo. `git clone https://github.com/dantelmomsft/chat-with-your-data-java-lza-app-accelerator.git`
2. Run `cd chat-with-your-data-java-lza-app-accelerator/infra/app-service` 
3. Run `azd auth login` to authenticate with your Azure subscription.
4. Run `azd provision` to provision the infrastructure. Provide an env name and the deployment region. So fat it has been tested with France central. This will take several minutes and will:
    - Download the app service lza code in  the folder `infra/app-service/bicep/lza-libs`.
    - Automatically run the app service lza code.
    - Automatically run the app bicep source code in the folder `chat-with-your-data-java-lza-app-accelerator\infra\app-service\bicep\modules`. This will create the Azure supporting services (Azure AI Search, Azure Document INtelligence, Azure Storage) required by the app on top of the App Service LZA infrastructure.
    -  Automatically create `.azure` folder with azd env configuration. you should see a folder like this: `chat-with-your-data-java-lza-app-accelerator/.azure`
### Deploy the Java app 
1. Connect to the jumpbox, open a command prompt and run `git clone https://github.com/dantelmomsft/chat-with-your-data-java-lza-app-accelerator.git`
2. Run `cd chat-with-your-data-java-lza-app-accelerator` 
3. Run `azd restore`. Provide 'temp' as value for azd env name. It will download the chat-with-your-data-java [source code ](https://github.com/Azure-Samples/azure-search-openai-demo-java)
4. Run cd `chat-with-your-data-java-lza-app-accelerator/infra/app-service` and copy here the .azure folder that has been created on your laptop at the end of [Deploy Infrastructure](#deploy-the-infrastructure)  phase.
5. Run `azd auth login`
6. Run `azd restore`. This is required for this code sample to ingest documents into the Azure AI search index. It will take a couple of minutes.
7. run `azd deploy`. This will build and deploy the java app.
8. From the jumpbox open edge browser and connect to the app service root page: https://<app-service-name>.azurewebsites.net. You should see the app home page.

### Known Issues and gaps
- The jump box installation doesn't properly configure azd and maven. To fix that before running the `azd deploy` command, be sure to run
    - Run the `D:\azd\azd-windows-amd64.msi` installer
    - Add to the PATH env variable the maven bin folder: `C:\Program Files\apache-maven-3.9.5\bin`
- Trying accessing the web app through Azure Front door endpoint return 504 Gateway Timeout.
- Azure Storage, AI search and Document Intelligence are still published like public services. We are working on making them private disabling public access and using private endpoints. 
