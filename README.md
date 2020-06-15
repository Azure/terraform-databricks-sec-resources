## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| databricks | n/a |
| null | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_default\_packages | List of uris for any custom Python packages (.whl) to install on clusters by default. | `list(string)` | `[]` | no |
| databricks\_api\_token | A PAT or other valid token to authorise interaction with the Databricks host. | `string` | n/a | yes |
| databricks\_host | URL to the Databricks workspace to interact with. | `string` | n/a | yes |
| whl\_upload\_script\_path | Path to a bash script which downloads the whls in cluster\_default\_packages, and uploads them to dbfs. | `string` | `"./scripts/whls_to_dbfs.sh"` | no |

## Outputs

No output.

