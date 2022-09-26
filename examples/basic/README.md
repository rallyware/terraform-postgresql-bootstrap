# terraform-postgresql-bootstrap

Terraform module to provision and manage postgresql resources.   

## Usage

```hcl
  module "bootstrap_db" {
    source = "./"

    extensions = ["pg_stat_statements", "pg_hint_plan"]

    databases = [
      {
        name = "test"
      }
    ]

    roles = [
      {
        name                = "test"
        database            = "test"
        database_privileges = "CONNECT,CREATE,TEMPORARY"
        table_privileges    = "SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER"
        sequence_privileges = "USAGE,SELECT,UPDATE"
      },

      {
        name                = "test-ro"
        database            = "test"
        database_privileges = "CONNECT"
        table_privileges    = "SELECT"
        sequence_privileges = "USAGE,SELECT"
      },

      {
        name                = "prometheus-exporter"
        roles               = "pg_read_all_stats,pg_read_all_settings"
        database            = "test"
        database_privileges = "CONNECT"
      }
    ]
  }
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_postgresql"></a> [postgresql](#requirement\_postgresql) | >= 1.14 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.7 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bootstrap_db"></a> [bootstrap\_db](#module\_bootstrap\_db) | ../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS --> 

## License
The Apache-2.0 license