# Introduction

Demonstrate how to split a file into multiple output files
with [Bicep](https://learn.microsoft.com/fr-fr/azure/azure-resource-manager/bicep/overview?WT.mc_id=AZ-MVP-5003548).

For more details, you can consult the following
article [Azure Data Factory: How to split a file into multiple output files with Bicep](https://medium.com/@jamesdld23/azure-data-factory-how-to-split-a-file-into-multiple-output-files-with-bicep-37fba80be252)
.

# Clone the sample repository

Download the sample repository, run the following command in your local terminal window:

```
git https://github.com/JamesDLD/bicep-data-factory-data-flow-split-file.git .
```

# Prerequisite
1. An Azure Data Factory connected to an Azure Storage Account is available. The following repository demonstrate how to have all of those prerequisites met through Bicep: [Quickstart: Create an Azure Data Factory using Bicep](https://learn.microsoft.com/en-us/azure/data-factory/quickstart-create-data-factory-bicep?WT.mc_id=DP-MVP-5003548).

I have clone the mentioned repository, you can deploy it through the following script.
```
#variable
location=westeurope
resourceGroupName=myDataFactoryResourceGroup

#create an Azure resource group
az group create --name $resourceGroupName --location $location

#create an Azure Data Factory connected to Azure Storage Account
##use the 'what-if' option to see what the code will try to create or update
az deployment group what-if                                         \
                --resource-group $resourceGroupName                 \
                --template-file data-factory-prerequisite-1.bicep          
##deploy
az deployment group create                                          \
                --name function_app                                 \
                --resource-group $resourceGroupName                 \
                --template-file data-factory-prerequisite-1.bicep 
```
When the deployment finishes, you should see a message indicating the deployment succeeded.


2. Upload the file that will be split
```
blabla
```

# Create the Azure Data Flow that will split a file into multiple output files

Deploy the Bicep files using Azure CLI.

```
#variable
location=westeurope
resourceGroupName=myDataFactoryResourceGroup

#create an Azure resource group
az group create --name $resourceGroupName --location $location

#create an Azure Storage Account
az group create --name $resourceGroupName --location $location

#create an Azure Data Factory Data Flow with it's Pipeline 

##use the 'what-if' option to see what the code will try to create or update
az deployment group what-if                                 \
                --resource-group $resourceGroupName         \
                --template-file function_app.bicep          \
                --parameters appInsightsLocation=$location 
##deploy
az deployment group create                                  \
                --name function_app                         \
                --resource-group $resourceGroupName         \
                --template-file function_app.bicep          \
                --parameters appInsightsLocation=$location

```

When the deployment finishes, you should see a message indicating the deployment succeeded.

# Validate the deployment

Use Azure CLI to validate the deployment.

```
az resource list --resource-group $resourceGroupName
```

# Clean up resources

```
az group delete --name $resourceGroupName
```
