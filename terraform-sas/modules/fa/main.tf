variable "project" {
  type = string
}

variable "location" {
  type = string
}

variable "os" {
  type = string
}

variable "hosting_plan" {
  type = string
}

variable "archive_file" {
  
}

resource "azurerm_resource_group" "resource_group" {
  name = "${var.project}-resource-group"
  location = var.location
}

resource "azurerm_storage_account" "storage_account" {
  name = "${replace(var.project, "-", "")}strg"
  resource_group_name = azurerm_resource_group.resource_group.name
  location = var.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "storage_container" {
    name = "${var.project}-storage-container-functions"
    storage_account_name = azurerm_storage_account.storage_account.name
    container_access_type = "private"
}

data "azurerm_storage_account_blob_container_sas" "storage_account_blob_container_sas" {
  connection_string = azurerm_storage_account.storage_account.primary_connection_string
  container_name    = azurerm_storage_container.storage_container.name

  start = "2021-01-01T00:00:00Z"
  expiry = "2022-01-01T00:00:00Z"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.project}-app-service-plan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  kind                = var.hosting_plan == "premium" ? "elastic" : "FunctionApp"
  reserved            = var.os == "linux"
  sku {
    tier = var.hosting_plan == "premium" ? "ElasticPremium" : "Dynamic"
    size = var.hosting_plan == "premium" ? "EP1" : "Y1"
  }
}

resource "azurerm_storage_blob" "storage_blob" {
    name = "${filesha256(var.archive_file.output_path)}.zip"
    storage_account_name = azurerm_storage_account.storage_account.name
    storage_container_name = azurerm_storage_container.storage_container.name
    type = "Block"
    source = var.archive_file.output_path
}

resource "azurerm_function_app" "function_app" {
  name                       = "${var.project}-function-app"
  resource_group_name        = azurerm_resource_group.resource_group.name
  location                   = var.location
  app_service_plan_id        = azurerm_app_service_plan.app_service_plan.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = "https://${azurerm_storage_account.storage_account.name}.blob.core.windows.net/${azurerm_storage_container.storage_container.name}/${azurerm_storage_blob.storage_blob.name}${data.azurerm_storage_account_blob_container_sas.storage_account_blob_container_sas.sas}",
    "FUNCTIONS_WORKER_RUNTIME" = "node",
    "AzureWebJobsDisableHomepage" = "true",
    "WEBSITE_NODE_DEFAULT_VERSION": var.os == "windows" ? "~14" : null
  }
  os_type = var.os == "linux" ? "linux" : null
  site_config {
    linux_fx_version          = var.os == "linux" ? "node|14" : null
    use_32_bit_worker_process = false
  }
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  version                    = "~3"
}

output "function_app_default_hostname" {
  value = azurerm_function_app.function_app.default_hostname
}
