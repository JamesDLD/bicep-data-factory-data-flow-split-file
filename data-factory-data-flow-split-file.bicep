@description('Data Factory Name')
param dataFactoryName string = 'datafactory${uniqueString(resourceGroup().id)}'

@description('Name of the Azure storage account that will contain the file we will split.')
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'

@description('Name of the blob container in the Azure Storage account.')
param blobContainerName string = 'blob${uniqueString(resourceGroup().id)}'

@description('Split the file in n files')
param numberOfPartition string = '5'

@description('The Blob s name that will be splitted')
param blobNameToSplit string = 'file.csv'

@description('The Blob s folder path that will be splitted')
param blobFolderToSplit string = 'input'

@description('The Blob s folder path that will be splitted')
param blobOutputFolder string = 'output'

var dataFactoryLinkedServiceName = 'ArmtemplateStorageLinkedService'
var dataFactoryCsvDatasetOutName = 'ArmtemplateTestCsvDatasetOut'
var pipelineName = 'ArmtemplateSampleSplitFilePipeline'
var cleanupPipelineName = 'ArmtemplateSampleDeletePipeline'
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
        folderPath: blobOutputFolder
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
                linkedService: {
                    referenceName: dataFactoryLinkedService.name
                    type: 'LinkedServiceReference'
                }
                name: 'source'
                description: 'File to split'
            }
        ]
        sinks: [
            {
                linkedService: {
                    referenceName: dataFactoryLinkedService.name
                    type: 'LinkedServiceReference'
                }
                name: 'sink'
                description: 'Splitted data'
            }
        ]
        transformations: []
        scriptLines: [
        'source(useSchema: false,'
        '     allowSchemaDrift: true,'
        '     validateSchema: false,'
        '     ignoreNoFilesFound: false,'
        '     format: \'delimited\','
        '     container: \'${blobContainerName}\','
        '     folderPath: \'${blobFolderToSplit}\','
        '     fileName: \'${blobNameToSplit}\','
        '     columnDelimiter: \',\','
        '     escapeChar: \'\\\\\','
        '     quoteChar:  \'\\\'\','
        '     columnNamesAsHeader: true) ~> source'
        'source sink(allowSchemaDrift: true,'
        '     validateSchema: false,'
        '     format: \'delimited\','
        '     container: \'${blobContainerName}\','
        '     folderPath: \'output\','
        '     columnDelimiter: \',\','
        '     escapeChar: \'\\\\\','
        '     quoteChar:  \'\\\'\','
        '     columnNamesAsHeader: true,'
        '     filePattern:(concat(\'${blobNameToSplit}\', toString(currentTimestamp(),\'yyyyMMddHHmmss\'),\'-[n].csv\')),'
        '     skipDuplicateMapInputs: true,'
        '     skipDuplicateMapOutputs: true,'
        '     partitionBy(\'${partitionType}\', ${numberOfPartition})) ~> sink'
        ]
    }
  }
}

resource dataFactoryPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: dataFactory
  name: pipelineName
  properties: {
    activities: [
      {
        name: 'MyDataflowActivity'
        type: 'ExecuteDataFlow'
        typeProperties: {
          traceLevel: 'Fine'
          dataFlow: {
            referenceName: dataFactoryDataFlow.name
            type: 'DataFlowReference'
          }
          compute: {
            computeType: 'General'
            coreCount: 8
          }
        }
        policy: {
            retry: 0
            retryIntervalInSeconds: 30
            secureInput: false
            secureOutput: false
            timeout: '0.12:00:00'
        }
      }
    ]
  }
}

resource dataFactoryCleanupPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: dataFactory
  name: cleanupPipelineName
  properties: {
    activities: [
      {
        name: 'MyDataflowDeleteActivity'
        type: 'Delete'
        typeProperties: {
          dataset: {
            referenceName: dataFactoryCsvDatasetOut.name
            type: 'DatasetReference'
          }
          enableLogging: false
          storeSettings: {
            type: 'AzureBlobStorageReadSettings'
            recursive: true
            enablePartitionDiscovery: false
          }
        }
        policy: {
            retry: 0
            retryIntervalInSeconds: 30
            secureInput: false
            secureOutput: false
            timeout: '0.12:00:00'
        }
      }
    ]
  }
}
