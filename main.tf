provider "databricks" {
  host  = var.databricks_host
  token = var.databricks_api_token
}

resource "null_resource" "main" {
  # TODO: can't trigger on a list of strings
  triggers = {
     cluster_default_packages = join(", ", var.cluster_default_packages)
  }
  provisioner "local-exec" {
    command = "${var.whl_upload_script_path} ${join(", ", var.cluster_default_packages)} ${var.databricks_host} ${var.databricks_api_token}"
  }
}

resource "databricks_cluster" "standard_cluster" {
  cluster_name  = "standard-cluster"
  spark_version = "6.4.x-scala2.11"
  node_type_id = "Standard_DS13_v2"
  autoscale {
    min_workers = 1
    max_workers = 3
  }
  library_whl {
    path = "dbfs:/custom-whls/my_whl.whl"
  }

}

# Create high concurrency cluster with AAD credential passthrough enabled
resource "databricks_cluster" "high_concurrency_cluster" {
  cluster_name  = "high-concurrency-cluster"
  spark_version = "6.4.x-scala2.11"
  node_type_id = "Standard_DS13_v2"
  autoscale {
    min_workers = 1
    max_workers = 3
  }
  spark_conf = {
    "spark.databricks.cluster.profile": "serverless"
    "spark.databricks.repl.allowedLanguages": "python, sql"
    "spark.databricks.passthrough.enabled": true
    "spark.databricks.pyspark.enableProcessIsolation": true
  }
}

 resource "databricks_notebook" "notebook" {
   content = base64encode("# Welcome to your Jupyter notebook")
   path = "/mynotebook"
   overwrite = false
   mkdirs = true
   language = "PYTHON"
   format = "SOURCE"
}
