
// inherited from root module
param basename string
param tags object
param stage string
param k8sVersion string
param location string
param nodeCount int
param vmSize string

// ################################
// ############# AKS ##############
// ################################

// Create AKS
resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-10-01' = {
  name: 'aks-${basename}'
  location: location
  tags: tags

  sku: {
    name: 'Basic'
    tier: 'Free'
  }

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    nodeResourceGroup: 'rg-aks-${basename}'
    kubernetesVersion: k8sVersion
    dnsPrefix: basename

    servicePrincipalProfile: {
      clientId: 'msi'
    }

    agentPoolProfiles: [
      {
        name: 'default'
        mode: 'System'
        count: nodeCount
        vmSize: vmSize
        tags: tags
      }
    ]
  }
}

// ################################
// ############# Flux #############
// ################################

resource flux 'Microsoft.KubernetesConfiguration/extensions@2021-09-01' = {
  name: 'flux'
  scope: aksCluster
  properties: {
    autoUpgradeMinorVersion: true
    configurationProtectedSettings: {}
    configurationSettings: {
      'helm-controller.enabled': 'true' // enabled by default
      'source-controller.enabled': 'true' // enabled by default
      'kustomize-controller.enabled': 'true' // enabled by default
      'notification-controller.enabled': 'true' // enabled by default
      'image-automation-controller.enabled': 'true' // disabled by default
      'image-reflector-controller.enabled': 'true' // disabled by default
    }
    extensionType: 'microsoft.flux'
    scope: {
      cluster: {
        releaseNamespace: 'flux-system'
      }
    }
  }
}

// ################################
// ######### Flux Config ##########
// ################################

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2022-01-01-preview' = {
  name: 'flux-config'
  scope: aksCluster
  dependsOn: [
    flux
  ]
  properties: {
    scope: 'cluster'
    namespace: 'flux-system'
    sourceKind: 'GitRepository'
    suspend: false

    gitRepository: {
      url: 'https://github.com/whiteducksoftware/fluxcd-example'
      timeoutInSeconds: 600
      syncIntervalInSeconds: 600
      repositoryRef: {
        branch: 'main'
      }

    }
    kustomizations: {
      cluster: {
        path: './clusters/${stage}'
        dependsOn: []
        timeoutInSeconds: 600
        syncIntervalInSeconds: 600
        prune: true
      }
    }
  }
}
