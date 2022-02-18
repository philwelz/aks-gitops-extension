targetScope='subscription'

// inherited from root module
param rgName string
param tags object
param location string

// create Resource Group
resource coreRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: tags
}
