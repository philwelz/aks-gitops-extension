// ################################
// ########### Common #############
// ################################

targetScope='subscription'

@description('Location for all resources.')
param location string = deployment().location

@description('The prefix of the Managed Cluster resource')
param prefix string = 'gitops'

@description('The environment of the Managed Cluster resource e.g. stg, dev, prd or demo')
@allowed([
  'stg'
  'dev'
  'prd'
  'demo'
])
param stage string = 'dev'

@description('The prefix of the Managed Cluster resource')
param baseName string = '${prefix}-${stage}'

@description('Common tags for all resources')
param tags object = {
  env: stage
  managedBy: 'bicep'
  project: prefix
}

// ################################
// ############# RG ###############
// ################################

@description('The name of the Resource Group')
param rgName string = 'rg-${baseName}'

module rgCore './modules/rg.bicep' = {
  name: rgName
  params: {
    location: location
    rgName: rgName
    tags: tags
  }
}

// ################################
// ############# AKS ##############
// ################################

@description('The Kubernetes Version to use for the AKS Cluster')
param kubernetes_version string = '1.22.6'

@minValue(1)
@maxValue(3)
@description('The number of Nodes that should exist in the System Node Pool')
param node_count int = 3

@description('The default virtual machine size for the Nodes')
param vm_size string = 'Standard_D2s_v3'

module aksCluster './modules/aks.bicep' = {
  name: 'aksCluster'
  scope: resourceGroup(rgCore.name)
  params: {
    location: location
    k8sVersion: kubernetes_version
    basename: baseName
    stage: stage
    tags: tags
    nodeCount: node_count
    vmSize: vm_size
  }
}
