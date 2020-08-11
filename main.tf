provider "databricks" {
  version = "0.2.0"
  azure_auth = {
    workspace_name         = var.databricks_workspace.name
    resource_group         = var.databricks_workspace.resource_group_name
    managed_resource_group = var.databricks_workspace.managed_resource_group_name
    azure_region           = var.databricks_workspace.location
  }
}

locals {
  db_host            = format("%s%s", "https://", var.databricks_workspace.workspace_url)
  upload_script_path = var.whl_upload_script_path == "" ? "${path.module}/scripts/whls_to_dbfs.sh" : var.whl_upload_script_path
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

resource "null_resource" "main" {
  triggers = {
    cluster_default_packages = join(", ", var.cluster_default_packages)
  }
  provisioner "local-exec" {
    command = "${local.upload_script_path} ${path.module} ${join(", ", var.cluster_default_packages)} ${local.db_host} ${databricks_token.upload_auth_token.token_value}"
  }
  count      = join(", ", var.cluster_default_packages) != "" ? 1 : 0
  depends_on = [databricks_token.upload_auth_token]
}

resource "databricks_cluster" "standard_cluster" {
  cluster_name  = module.naming.databricks_standard_cluster.name
  spark_version = "6.4.x-scala2.11"
  node_type_id  = "Standard_DS13_v2"
  autoscale {
    min_workers = 1
    max_workers = 3
  }
  library_whl {
    path = "dbfs:/mnt/libraries/defaultpackages.wheelhouse.zip"
  }
  depends_on = [time_sleep.wait]
}

# Create high concurrency cluster with AAD credential passthrough enabled
resource "databricks_cluster" "high_concurrency_cluster" {
  cluster_name  = module.naming.databricks_high_concurrency_cluster.name
  spark_version = "6.4.x-scala2.11"
  node_type_id  = "Standard_DS13_v2"
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
  library_whl {
    path = "dbfs:/mnt/libraries/defaultpackages.wheelhouse.zip"
  }
  depends_on = [time_sleep.wait]
}

# If notebook_path given, upload local Jupyter notebook on deployment
resource "databricks_notebook" "notebook" {
  count     = var.notebook_path == "" ? 0 : 1
  content   = filebase64("${path.module}/${var.notebook_path}")
  path      = "/${var.notebook_name}"
  mkdirs    = true
  overwrite = false
  format    = "JUPYTER"
}

resource "azurerm_api_management_api" "notebook_api" {
  name                = "invoke_notebook"
  resource_group_name = var.apim.resource_group_name
  api_management_name = var.apim.name
  revision            = "1"
  display_name        = "Notebook invocation API"
  path                = "run"
  protocols           = ["https"]
  service_url         = "${local.db_host}/api/2.0/jobs"
  count     = var.notebook_path == "" ? 0 : 1

  import {
    content_format = "swagger-json"
    content_value  = <<EOT
      {

        "swagger": "2.0",

        "info": {

          "version": "1.0",

          "title": "DatabricksNotebookInvoke",

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

              "task": {

                "notebook_task": {

                  "notebook_path": "/${var.notebook_name}"

                }

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
  depends_on = [
    var.apim,
    databricks_notebook.notebook
  ]
}