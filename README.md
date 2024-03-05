# Chat With You Data with Java and Azure Open AI - LZA App Accelerator
This is a PoC about automating apps deployment on production ready environment provided by [Azure Landing Zones](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/ready).

We are going to deploy the [Azure Open AI Java reference template](https://learn.microsoft.com/en-us/azure/developer/intro/azure-ai-for-developers?pivots=java#azure-ai-reference-templates) on top of the [App Service LZA](https://github.com/Azure/appservice-landing-zone-accelerator) or [ACA LZA](https://github.com/Azure/aca-landing-zone-accelerator) using the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview)

The java reference template supports different architectural styles. It can be deployed as standalone app on top of Azure App Service or as a microservice event driven architecture with web frontend, AI orchestration and document ingestion apps hosted by Azure Container Apps or Azure Kubernetes Service.

- For automated deployment on top of  **Azure App Service LZA**, see [here](docs/app-service/README-App-Service.md).
- For automated deployment on top of  **Azure Container Apps LZA**, see [here](docs/aca/README-ACA.md).