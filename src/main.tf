provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "example"
  location = "West Europe"
}

resource "azurerm_kusto_cluster" "example" {
  name                = "jeffbejo"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku {
    name     = "Dev(No SLA)_Standard_D11_v2"
    capacity = 1
  }
}

resource "azurerm_kusto_database" "example" {
  name                = "jeff"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  cluster_name        = azurerm_kusto_cluster.example.name
}

resource "azurerm_storage_account" "example" {
  name                     = "esteraw"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "example" {
  name                  = "setup-files"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "example" {
  name                   = "script.txt"
  storage_account_name   = azurerm_storage_account.example.name
  storage_container_name = azurerm_storage_container.example.name
  type                   = "Block"
  source_content         = ".create table MyTable (Level:string, Timestamp:datetime, UserId:string, TraceId:string, Message:string, ProcessId:int32)"
}

data "azurerm_storage_account_blob_container_sas" "example" {
  connection_string = azurerm_storage_account.example.primary_connection_string
  container_name    = azurerm_storage_container.example.name
  https_only        = true

  start  = "2017-03-21"
  expiry = "2022-03-21"

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = false
    list   = true
  }
}

resource "azurerm_kusto_script" "example" {
  name                               = "jediss"
  database_id                        = azurerm_kusto_database.example.id
  url                                = azurerm_storage_blob.example.id
  sas_token                          = data.azurerm_storage_account_blob_container_sas.example.sas
  //sas_token                          = "sp=r&st=2022-06-10T12:28:36Z&se=2022-06-10T20:28:36Z&spr=https&sv=2020-08-04&sr=c&sig=EPQ6PkOoUUpczCcGLKLKLmpyWSFINYEa9ndylr7%2FQiw%3D"
  continue_on_errors_enabled         = true
  force_an_update_when_value_changed = "first"
}