provider "databricks" {
  version = "0.2.9"
  azure_auth = {
    workspace_name         = var.databricks_workspace.name
    resource_group         = var.databricks_workspace.resource_group_name
    managed_resource_group = var.databricks_workspace.managed_resource_group_name
    azure_region           = var.databricks_workspace.location
  }
}

locals {
  databricks_host = format("%s%s", "https://", var.databricks_workspace.workspace_url)

  #Upload whl locals
  whl_upload_script_path  = var.whl_upload_script_path == "" ? "${path.module}/scripts/whls_to_dbfs.sh" : var.whl_upload_script_path
  packages                = join(", ", var.cluster_default_packages)
  upload_whl_dbfs_command = join(" ", [local.whl_upload_script_path, "\"${local.packages}\"", var.data_lake_name, local.libraries_mount])

  #Upload Notebook locals
  notebook_upload_script_path = "${path.module}/scripts/upload_notebook.sh"
  notebook_content_path       = var.notebook_path
  upload_notebook_command     = join(" ", [local.notebook_upload_script_path, local.databricks_host, "\"/${var.notebook_name}\"", local.notebook_content_path])

  #Mount locals
  libraries_mount = "libraries"
  data_mount      = "data"
}

module "naming" {
  source = "git::https://github.com/Azure/terraform-azurerm-naming"
  suffix = var.suffix
  prefix = var.prefix
}

# Hack required to avoid errors resulting from premature reporting
# from Azure API that Azure Databricks workspace setup is complete
resource "time_sleep" "wait" {
  depends_on      = [var.databricks_workspace]
  create_duration = "300s" # 5 minutes
}

resource "databricks_token" "upload_auth_token" {
  lifetime_seconds = 3600 # 1 hour
  comment          = "DBFS auth for custom package upload"
}

resource "databricks_token" "notebook_invoke_token" {
  lifetime_seconds = 10800 # deployed API will be authorised for 3 hours
  comment          = "Temporary auth token for notebook job invocation API"
}

resource "databricks_secret_scope" "mount_scope" {
  name                     = "terraform"
  initial_manage_principal = "users"
}

resource "databricks_secret" "mount_service_principal_key" {
  key          = "mounting_service_principal_key"
  string_value = var.service_principal_secret
  scope        = databricks_secret_scope.mount_scope.name
}

resource "databricks_cluster" "mounting_cluster" {
  cluster_name            = "utility_mounting_cluster"
  spark_version           = "6.4.x-scala2.11"
  node_type_id            = "Standard_DS3_v2"
  autotermination_minutes = 15
  depends_on              = [time_sleep.wait]
  num_workers             = 1
}

resource "databricks_azure_adls_gen2_mount" "libraries_mount" {
  container_name         = var.libraries_container_name
  storage_account_name   = var.data_lake_name
  mount_name             = local.libraries_mount
  tenant_id              = data.azurerm_client_config.current.tenant_id
  client_id              = data.azurerm_client_config.current.client_id
  client_secret_scope    = databricks_secret_scope.mount_scope.name
  client_secret_key      = databricks_secret.mount_service_principal_key.key
  cluster_id             = databricks_cluster.mounting_cluster.id
  initialize_file_system = true
}

resource "databricks_azure_adls_gen2_mount" "data_mount" {
  container_name         = var.data_container_name
  storage_account_name   = var.data_lake_name
  mount_name             = local.data_mount
  tenant_id              = data.azurerm_client_config.current.tenant_id
  client_id              = data.azurerm_client_config.current.client_id
  client_secret_scope    = databricks_secret_scope.mount_scope.name
  client_secret_key      = databricks_secret.mount_service_principal_key.key
  cluster_id             = databricks_cluster.mounting_cluster.id
  initialize_file_system = true
}

resource "null_resource" "upload_whl" {
  provisioner "local-exec" {
    command = local.upload_whl_dbfs_command
  }
  count      = join(", ", var.cluster_default_packages) != "" ? 1 : 0
  depends_on = [databricks_azure_adls_gen2_mount.libraries_mount]
}

resource "databricks_cluster" "standard_cluster" {
  cluster_name            = module.naming.databricks_standard_cluster.name
  spark_version           = "6.4.x-scala2.11"
  node_type_id            = "Standard_DS13_v2"
  autotermination_minutes = 30
  autoscale {
    min_workers = 1
    max_workers = 3
  }
  library {
    whl = "dbfs:/mnt/libraries/defaultpackages.wheelhouse.zip"
  }
  depends_on = [time_sleep.wait, databricks_azure_adls_gen2_mount.libraries_mount, null_resource.upload_whl]
}

# Create high concurrency cluster with AAD credential passthrough enabled
resource "databricks_cluster" "high_concurrency_cluster" {
  cluster_name            = module.naming.databricks_high_concurrency_cluster.name
  spark_version           = "6.4.x-scala2.11"
  node_type_id            = "Standard_DS13_v2"
  autotermination_minutes = 30
  autoscale {
    min_workers = 1
    max_workers = 3
  }
  spark_conf = {
    "spark.databricks.cluster.profile" : "serverless"
    "spark.databricks.repl.allowedLanguages" : "python, sql"
    "spark.databricks.passthrough.enabled" : true
    "spark.databricks.pyspark.enableProcessIsolation" : true
  }
  library {
    whl = "dbfs:/mnt/libraries/defaultpackages.wheelhouse.zip"
  }
  depends_on = [time_sleep.wait, databricks_azure_adls_gen2_mount.libraries_mount, null_resource.upload_whl]
}

# If notebook_path given, upload local Jupyter notebook on deployment
resource "null_resource" "upload_notebook" {
  provisioner "local-exec" {
    command = local.upload_notebook_command
    #Passing env variable to avoid token leakage on apply
    environment = {
      DATABRICKS_TOKEN = "${databricks_token.upload_auth_token.token_value}"
    }
  }

  count = var.notebook_path == "" ? 0 : 1
}

resource "azurerm_api_management_api" "create_job_api" {
  name                = "create_notebook_job"
  resource_group_name = var.api_management_resource_group_name
  api_management_name = var.api_management_name
  revision            = "1"
  display_name        = "Create job API"
  path                = "create"
  protocols           = ["https"]
  service_url         = "${local.databricks_host}/api/2.0/jobs"
  count               = var.notebook_path == "" ? 0 : 1

  import {
    content_format = "swagger-json"
    content_value  = <<EOT
      {
        "swagger": "2.0",
        "info": {
          "version": "1.0",
          "title": "DatabricksJobCreate",
          "contact": {}
        },
        "host": "${var.databricks_workspace.workspace_url}",
        "basePath": "/api/2.0/jobs",
        "securityDefinitions": {},
        "schemes": [
          "https"
        ],
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "paths": {
          "/create": {
            "post": {
              "summary": "Databricks notebook task",
              "tags": [
                "Misc"
              ],
              "operationId": "Databricksnotebooktask",
              "deprecated": false,
              "produces": [
                "application/json"
              ],
              "consumes": [
                "application/json"
              ],
              "parameters": [
                {
                  "name": "Authorization",
                  "in": "header",
                  "required": true,
                  "default": "Bearer ${databricks_token.notebook_invoke_token.token_value}",
                  "type": "string"
                },
                {
                  "name": "Content-Type",
                  "in": "header",
                  "required": true,
                  "type": "string",
                  "description": ""
                },
                {
                  "name": "Body",
                  "in": "body",
                  "required": true,
                  "description": "",
                  "schema": {
                    "$ref": "#/definitions/DatabricksnotebooktaskRequest"
                  }
                }
              ],
              "responses": {
                "200": {
                  "description": "",
                  "headers": {}
                }
              }
            }
          }
        },
        "definitions": {
          "DatabricksnotebooktaskRequest": {
            "title": "DatabricksnotebooktaskRequest",
            "example": {
              "name": "Notebook run job",
              "existing_cluster_id": "${databricks_cluster.standard_cluster.id}",
              "notebook_task": {
                "notebook_path": "/${var.notebook_name}"
              }
            },
            "type": "object",
            "properties": {
              "name": {
                "type": "string"
              },
              "existing_cluster_id": {
                "type": "string"
              },
              "task": {
                "$ref": "#/definitions/Task"
              }
            },
            "required": [
              "name",
              "existing_cluster_id",
              "task"
            ]
          },
          "Task": {
            "title": "Task",
            "example": {
              "notebook_task": {
                "notebook_path": "/${var.notebook_name}"
              }
            },
            "type": "object",
            "properties": {
              "notebook_task": {
                "$ref": "#/definitions/NotebookTask"
              }
            },
            "required": [
              "notebook_task"
            ]
          },
          "NotebookTask": {
            "title": "NotebookTask",
            "example": {
              "notebook_path": "/${var.notebook_name}"
            },
            "type": "object",
            "properties": {
              "notebook_path": {
                "type": "string"
              }
            },
            "required": [
              "notebook_path"
            ]
          }
        },
        "tags": [
          {
            "name": "Misc",
            "description": ""
          }
        ]
      }        
      EOT
  }
}

resource "azurerm_api_management_api" "invoke_notebook_api" {
  name                = "invoke_notebook"
  resource_group_name = var.api_management_resource_group_name
  api_management_name = var.api_management_name
  revision            = "1"
  display_name        = "Run notebook API"
  path                = "run"
  protocols           = ["https"]
  service_url         = "${local.databricks_host}/api/2.0/jobs"
  count               = var.notebook_path == "" ? 0 : 1

  import {
    content_format = "swagger-json"
    content_value  = <<EOT
      {
        "swagger": "2.0",
        "info": {
          "version": "1.0",
          "title": "DatabricksJobRunNow",
          "contact": {}
        },
        "host": "${var.databricks_workspace.workspace_url}",
        "basePath": "/api/2.0/jobs",
        "securityDefinitions": {},
        "schemes": [
          "https"
        ],
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "paths": {
          "/run-now": {
            "post": {
              "summary": "RunNow",
              "tags": [
                "Misc2"
              ],
              "operationId": "RunNow",
              "deprecated": false,
              "produces": [
                "application/json"
              ],
              "parameters": [
                {
                  "name": "Authorization",
                  "in": "header",
                  "required": true,
                  "default": "Bearer ${databricks_token.notebook_invoke_token.token_value}",
                  "type": "string"
                },
                {
                  "name": "Body",
                  "in": "body",
                  "required": true,
                  "description": "",
                  "schema": {
                    "$ref": "#/definitions/RunNowRequest"
                  }
                }
              ],
              "responses": {
                "200": {
                  "description": "",
                  "headers": {}
                }
              }
            }
          }
        },
        "definitions": {
          "RunNowRequest": {
            "title": "RunNowRequest",
            "example": {
              "job_id": 1,
              "notebook_params": {
                "": ""
              }
            },
            "type": "object",
            "properties": {
              "job_id": {
                "type": "integer",
                "format": "int32"
              },
              "notebook_params": {
                "type": "object"
              }
            },
            "required": [
              "job_id",
              "notebook_params"
            ]
          }
        },
        "tags": [
          {
            "name": "Misc",
            "description": ""
          }
        ]
      }
      EOT
  }
  depends_on = [
    azurerm_api_management_api.create_job_api
  ]
}

resource "azurerm_api_management_api" "notebook_output_api" {
  name                = "get_notebook_output"
  resource_group_name = var.api_management_resource_group_name
  api_management_name = var.api_management_name
  revision            = "1"
  display_name        = "Notebook output API"
  path                = "get-output"
  protocols           = ["https"]
  service_url         = "${local.databricks_host}/api/2.0/jobs/runs"
  count               = var.notebook_path == "" ? 0 : 1

  import {
    content_format = "swagger-json"
    content_value  = <<EOT
      {
        "swagger": "2.0",
        "info": {
          "version": "1.0",
          "title": "DatabricksGetRunOutput",
          "contact": {}
        },
        "host": "${var.databricks_workspace.workspace_url}",
        "basePath": "/api/2.0/jobs/runs",
        "securityDefinitions": {},
        "schemes": [
          "https"
        ],
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "paths": {
          "/get-output": {
            "get": {
              "summary": "DatabricksGetRunOutput",
              "tags": [
                "Misc"
              ],
              "operationId": "DatabricksGetRunOutput",
              "deprecated": false,
              "produces": [
                "application/json"
              ],
              "parameters": [
                {
                  "name": "Authorization",
                  "in": "header",
                  "required": true,
                  "default": "Bearer ${databricks_token.notebook_invoke_token.token_value}",
                  "type": "string"
                },
                {
                  "name": "run_id",
                  "in": "query",
                  "required": true,
                  "type": "integer",
                  "format": "int32",
                  "description": ""
                }
              ],
              "responses": {
                "200": {
                  "description": "",
                  "headers": {}
                }
              }
            }
          }
        },
        "tags": [
          {
            "name": "Misc",
            "description": ""
          }
        ]
      }      
      EOT
  }
  depends_on = [
    azurerm_api_management_api.invoke_notebook_api
  ]
}
