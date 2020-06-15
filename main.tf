provider "databricks" {
  azure_auth = {
    client_id              = var.sp_client_id
    client_secret          = var.sp_client_secret
    tenant_id              = var.tenant_id
    subscription_id        = var.subscription_id
    workspace_name         = var.databricks_workspace.name
    resource_group         = var.databricks_workspace.resource_group_name
    managed_resource_group = var.databricks_workspace.managed_resource_group_name
    azure_region           = var.databricks_workspace.location
  }
}

locals {
  db_host = var.databricks_workspace.workspace_url
}

resource "databricks_token" "upload_auth_token" {
  lifetime_seconds = 6000
  comment          = "DBFS auth for custom package upload"
}

resource "null_resource" "main" {
  triggers = {
    cluster_default_packages = join(", ", var.cluster_default_packages)
  }
  provisioner "local-exec" {
    command = "${var.whl_upload_script_path} ${join(", ", var.cluster_default_packages)} ${local.db_host} ${databricks_token.upload_auth_token.token_value}"
  }
  count      = join(", ", var.cluster_default_packages) != "" ? 1 : 0
  depends_on = [databricks_token.upload_auth_token]

}

resource "databricks_cluster" "standard_cluster" {
  cluster_name  = "standard-cluster"
  spark_version = "6.4.x-scala2.11"
  node_type_id  = "Standard_DS13_v2"
  autoscale {
    min_workers = 1
    max_workers = 3
  }
  library_whl {
    path = "dbfs:/mnt/libraries/defaultpackages.wheelhouse.zip"
  }
}

# Create high concurrency cluster with AAD credential passthrough enabled
resource "databricks_cluster" "high_concurrency_cluster" {
  cluster_name  = "high-concurrency-cluster"
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
}

resource "databricks_notebook" "notebook" {
  content   = base64encode("# Welcome to your Jupyter notebook")
  path      = "/mynotebook"
  overwrite = false
  mkdirs    = true
  language  = "PYTHON"
  format    = "SOURCE"
}
