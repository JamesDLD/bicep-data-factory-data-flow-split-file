@description('Data Factory Name')
param dataFactoryName string = 'datafactory${uniqueString(resourceGroup().id)}'

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'

@description('Name of the blob container in the Azure Storage account.')
param blobContainerName string = 'blob${uniqueString(resourceGroup().id)}'

@description('Split the file each n lines')
param partitionEachNLines string = '5'

var dataFactoryLinkedServiceName = 'ArmtemplateStorageLinkedService'
var dataFactoryCsvDatasetInName = 'ArmtemplateTestCsvDatasetIn'
var dataFactoryCsvDatasetOutName = 'ArmtemplateTestCsvDatasetOut'
var pipelineName = 'ArmtemplateSampleCopyPipeline'
var dataFactoryDataFlowName = 'ArmtemplateSampleDataFlowSplitFile'
var partitionType = 'roundRobin'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${storageAccount.name}/default/${blobContainerName}'
}

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
}

resource dataFactoryLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  name: dataFactoryLinkedServiceName
  properties: {
    type: 'AzureBlobStorage'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
    }
  }
}

resource dataFactoryCsvDatasetIn 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: dataFactoryCsvDatasetInName
  properties: {
    linkedServiceName: {
      referenceName: dataFactoryLinkedService.name
      type: 'LinkedServiceReference'
    }
    type: 'DelimitedText'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        container: blobContainerName
        folderPath: 'input'
      }
    }
  }
}

resource dataFactoryCsvDatasetOut 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: dataFactoryCsvDatasetOutName
  properties: {
    linkedServiceName: {
      referenceName: dataFactoryLinkedService.name
      type: 'LinkedServiceReference'
    }
    type: 'DelimitedText'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        container: blobContainerName
        folderPath: 'output'
      }
    }
  }
}

resource dataFactoryDataFlow 'Microsoft.DataFactory/factories/dataflows@2018-06-01' = {
  parent: dataFactory
  name: dataFactoryDataFlowName
  properties: {
    type: 'MappingDataFlow'
    typeProperties: {
        sources: [
            {
                dataset: {
                    referenceName: dataFactoryCsvDatasetIn.name
                    type: 'DatasetReference'
                }
                name: 'source'
                description: 'File to split'
            }
        ]
        sinks: [
            {
                dataset: {
                    referenceName: dataFactoryCsvDatasetOut.name
                    type: 'DatasetReference'
                }
                name: 'sink'
                description: 'Split data'
            }
        ]
        transformations: []
        scriptLines: [
        'source(allowSchemaDrift: true,'
        '     validateSchema: false,'
        '     ignoreNoFilesFound: true) ~> source'
        'source sink(allowSchemaDrift: true,'
        '     validateSchema: false,'
        '     skipDuplicateMapInputs: true,'
        '     skipDuplicateMapOutputs: true,'
        '     partitionBy("${partitionType}", ${partitionEachNLines})) ~> sink'
        ]
    }
  }
}

/*
resource dataFactoryPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: dataFactory
  name: pipelineName
  properties: {
    activities: [
      {
        name: 'MyCopyActivity'
        type: 'Copy'
        typeProperties: {
          source: {
            type: 'BinarySource'
            storeSettings: {
              type: 'AzureBlobStorageReadSettings'
              recursive: true
            }
          }
          sink: {
            type: 'BinarySink'
            storeSettings: {
              type: 'AzureBlobStorageWriteSettings'
            }
          }
          enableStaging: false
        }
        inputs: [
          {
            referenceName: dataFactoryCsvDatasetIn.name
            type: 'DatasetReference'
          }
        ]
        outputs: [
          {
            referenceName: dataFactoryCsvDatasetOut.name
            type: 'DatasetReference'
          }
        ]
      }
    ]
  }
}

output dataFactoryName string = dataFactory.name
output storageAccountName string = storageAccount.name
output blobContainerName string = blobContainerName
*/