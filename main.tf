locals {
  databases_set = {
    for db in var.databases : db.name => defaults(db,
      {
        owner             = ""
        tablespace_name   = ""
        connection_limit  = -1
        allow_connections = true
        is_template       = false
        template          = "template0"
        encoding          = "UTF8"
        lc_collate        = "en_US.UTF-8"
        lc_ctype          = "en_US.UTF-8"
      }
    )
  }

  roles_set = {
    for role in var.roles : role.name => defaults(role,
      {
        database                  = ""
        superuser                 = false
        create_database           = false
        create_role               = false
        inherit                   = true
        login                     = true
        replication               = false
        bypass_row_level_security = false
        connection_limit          = -1
        encrypted_password        = true
        valid_until               = "infinity"
        roles                     = ""
        search_path               = ""
        schema                    = "public"
        with_grant_option         = false
        database_privileges       = ""
        table_privileges          = ""
        sequence_privileges       = ""
      }
    )
  }
}

resource "random_password" "default" {
  for_each = local.roles_set

  length  = 16
  special = false
}

resource "postgresql_extension" "default" {
  for_each = toset(var.extensions)

  name   = each.value
  schema = each.value == "pg_hint_plan" ? null : "public"
}

resource "postgresql_database" "default" {
  for_each = local.databases_set

  name              = each.value.name
  owner             = each.value.owner
  tablespace_name   = each.value.tablespace_name
  connection_limit  = each.value.connection_limit
  allow_connections = each.value.allow_connections
  is_template       = each.value.is_template
  template          = each.value.template
  encoding          = each.value.encoding
  lc_collate        = each.value.lc_collate
  lc_ctype          = each.value.lc_ctype
}

resource "time_sleep" "default" {
  destroy_duration = "30s"
  create_duration  = "30s"

  depends_on = [
    postgresql_role.default
  ]
}

resource "postgresql_role" "default" {
  for_each = local.roles_set

  name                      = each.value.name
  superuser                 = each.value.superuser
  create_database           = each.value.create_database
  create_role               = each.value.create_role
  inherit                   = each.value.inherit
  login                     = each.value.login
  replication               = each.value.replication
  bypass_row_level_security = each.value.bypass_row_level_security
  valid_until               = each.value.valid_until
  roles                     = length(each.value.roles) > 0 ? split(",", each.value.roles) : null
  search_path               = length(each.value.search_path) > 0 ? split(",", each.value.search_path) : null
  password                  = random_password.default[each.key].result
}

resource "postgresql_grant" "database" {
  for_each = { for k, v in local.roles_set : k => v if length(v.database_privileges) > 0 }

  database    = each.value.database
  role        = postgresql_role.default[each.key].name
  object_type = "database"
  privileges  = split(",", each.value.database_privileges)

  depends_on = [
    postgresql_database.default
  ]
}

resource "postgresql_grant" "table" {
  for_each = { for k, v in local.roles_set : k => v if length(v.table_privileges) > 0 }

  database    = each.value.database
  role        = postgresql_role.default[each.key].name
  schema      = each.value.schema
  object_type = "table"
  privileges  = split(",", each.value.table_privileges)

  depends_on = [
    postgresql_database.default
  ]
}

resource "postgresql_grant" "sequence" {
  for_each = { for k, v in local.roles_set : k => v if length(v.sequence_privileges) > 0 }

  database    = each.value.database
  role        = postgresql_role.default[each.key].name
  schema      = each.value.schema
  object_type = "sequence"
  privileges  = split(",", each.value.sequence_privileges)

  depends_on = [
    postgresql_database.default
  ]
}
