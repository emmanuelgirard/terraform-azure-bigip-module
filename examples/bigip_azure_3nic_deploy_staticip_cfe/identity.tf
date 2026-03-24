data "azurerm_subscription" "current" {
}

resource "azurerm_user_assigned_identity" "user_identity" {
  name                = format("%s-ident-%s", var.prefix, random_id.id.hex)
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags = merge(var.common_tags, {
    Name = format("%s-ident-%s", var.prefix, random_id.id.hex)
    }
  )
}

resource "azurerm_role_assignment" "rg1" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.user_identity.principal_id
}

resource "azurerm_role_assignment" "rg2" {
  scope              = azurerm_resource_group.rg.id
  role_definition_id = azurerm_role_definition.rg.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.user_identity.principal_id
}

resource "azurerm_role_definition" "rg" {
  name        = format("%s-role-%s", var.prefix, random_id.id.hex)
  scope       = data.azurerm_subscription.current.id
  description = "This is a custom role created via Terraform"

  permissions {
    actions = [
      "Microsoft.Network/*/join/action",
      "Microsoft.Network/networkInterfaces/write",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/routeTables/*/read",
      "Microsoft.Network/routeTables/*/write",
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/write",
      "Microsoft.Authorization/*/read",
      "Microsoft.Compute/locations/*/read",
      "Microsoft.Compute/virtualMachines/*/read",
      "Microsoft.Compute/virtualMachineScaleSets/*/read",
      "Microsoft.Compute/virtualMachineScaleSets/networkInterfaces/read",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "*/read",
      "Microsoft.Compute/virtualMachines/extensions/*",
      "Microsoft.HybridCompute/machines/extensions/write",
      "Microsoft.Insights/alertRules/*",
      "Microsoft.Insights/diagnosticSettings/*",
      "Microsoft.Insights/Register/Action",
      "Microsoft.OperationalInsights/*",
      "Microsoft.OperationsManagement/*",
      "Microsoft.Resources/deployments/*",
      "Microsoft.Resources/subscriptions/read",
      "Microsoft.Resources/subscriptions/resourceGroups/deployments/*",
      "Microsoft.Storage/storageAccounts/listKeys/action",
      "Microsoft.Support/*",
    ]
    data_actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write",
      "Microsoft.Insights/Metrics/Write",
      "Microsoft.Insights/Telemetry/Write",
    ]
    not_actions      = []
    not_data_actions = []
  }
  assignable_scopes = [
    data.azurerm_subscription.current.id,
  ]
}
