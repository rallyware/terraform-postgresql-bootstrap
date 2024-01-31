locals {
  databases_set = {
    for indx, db in var.databases : db.name => merge(
      db,
      {
        index = indx
      }
    )
  }

  roles_set = {
    for indx, role in var.roles : role.name => merge(
      role,
      {
        index = indx
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
  roles                     = each.value.roles != null ? each.value.roles : null
  search_path               = each.value.search_path != null ? each.value.search_path : null
  password                  = random_password.default[each.key].result
}

resource "time_sleep" "role_wait" {
  for_each = local.roles_set

  destroy_duration = format("%ss", sum([2 * each.value.index, 3]))
  create_duration  = format("%ss", sum([2 * each.value.index, 3]))

  triggers = {
    role = postgresql_role.default[each.key].name
  }

  depends_on = [
    postgresql_role.default
  ]
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

  depends_on = [
    postgresql_role.default,
    time_sleep.role_wait
  ]
}

resource "time_sleep" "db_wait" {
  for_each = local.databases_set

  destroy_duration = format("%ss", sum([2 * each.value.index, 3]))
  create_duration  = format("%ss", sum([2 * each.value.index, 3]))

  depends_on = [
    postgresql_database.default
  ]
}

resource "postgresql_grant" "database" {
  for_each = { for k, v in local.roles_set : k => v if v.database_privileges != null }

  database    = each.value.database
  role        = time_sleep.role_wait[each.key].triggers["role"]
  object_type = "database"
  privileges  = each.value.database_privileges

  depends_on = [
    postgresql_role.default,
    time_sleep.db_wait,
    time_sleep.role_wait
  ]
}

resource "time_sleep" "grant_database_wait" {
  for_each = { for k, v in local.roles_set : k => v if v.database_privileges != null }

  destroy_duration = format("%ss", sum([2 * each.value.index, 3]))
  create_duration  = format("%ss", sum([2 * each.value.index, 3]))

  depends_on = [
    postgresql_grant.database
  ]
}

resource "postgresql_grant" "table" {
  for_each = { for k, v in local.roles_set : k => v if v.table_privileges != null && !v.ignore_changes_privileges }

  database    = each.value.database
  role        = time_sleep.role_wait[each.key].triggers["role"]
  schema      = each.value.schema
  object_type = "table"
  privileges  = each.value.table_privileges

  depends_on = [
    postgresql_role.default,
    time_sleep.db_wait,
    time_sleep.role_wait,
    time_sleep.grant_database_wait
  ]
}

resource "postgresql_grant" "table_ignore_changes" {
  for_each = { for k, v in local.roles_set : k => v if v.table_privileges != null && v.ignore_changes_privileges }

  database    = each.value.database
  role        = time_sleep.role_wait[each.key].triggers["role"]
  schema      = each.value.schema
  object_type = "table"
  privileges  = each.value.table_privileges

  lifecycle = {
    ignore_changes = [
      privileges
    ]
  }

  depends_on = [
    postgresql_role.default,
    time_sleep.db_wait,
    time_sleep.role_wait,
    time_sleep.grant_database_wait
  ]
}

resource "time_sleep" "grant_table_wait" {
  for_each = { for k, v in local.roles_set : k => v if v.table_privileges != null }

  destroy_duration = format("%ss", sum([2 * each.value.index, 3]))
  create_duration  = format("%ss", sum([2 * each.value.index, 3]))

  depends_on = [
    postgresql_grant.table,
    postgresql_grant.table_ignore_changes
  ]
}

resource "postgresql_grant" "sequence" {
  for_each = { for k, v in local.roles_set : k => v if v.sequence_privileges != null && !v.ignore_changes_privileges }

  database    = each.value.database
  role        = time_sleep.role_wait[each.key].triggers["role"]
  schema      = each.value.schema
  object_type = "sequence"
  privileges  = each.value.sequence_privileges

  depends_on = [
    postgresql_role.default,
    time_sleep.db_wait,
    time_sleep.role_wait,
    time_sleep.grant_database_wait,
    time_sleep.grant_table_wait
  ]
}


resource "postgresql_grant" "sequence_ignore_changes" {
  for_each = { for k, v in local.roles_set : k => v if v.sequence_privileges != null && v.ignore_changes_privileges }

  database    = each.value.database
  role        = time_sleep.role_wait[each.key].triggers["role"]
  schema      = each.value.schema
  object_type = "sequence"
  privileges  = each.value.sequence_privileges

  lifecycle = {
    ignore_changes = [
      privileges
    ]
  }

  depends_on = [
    postgresql_role.default,
    time_sleep.db_wait,
    time_sleep.role_wait,
    time_sleep.grant_database_wait,
    time_sleep.grant_table_wait
  ]
}

resource "time_sleep" "grant_sequence_wait" {
  for_each = { for k, v in local.roles_set : k => v if v.sequence_privileges != null }

  destroy_duration = format("%ss", sum([2 * each.value.index, 3]))
  create_duration  = format("%ss", sum([2 * each.value.index, 3]))

  depends_on = [
    postgresql_grant.sequence,
    postgresql_grant.sequence_ignore_changes
  ]
}

resource "postgresql_grant" "revoke_public_schema" {
  for_each = { for k, v in local.roles_set : k => v if v.revoke_public }

  database          = each.value.database
  role              = time_sleep.role_wait[each.key].triggers["role"]
  schema            = "public"
  object_type       = "schema"
  privileges        = []
  with_grant_option = true

  depends_on = [
    postgresql_role.default,
    time_sleep.db_wait,
    time_sleep.role_wait,
    time_sleep.grant_database_wait,
    time_sleep.grant_table_wait,
    time_sleep.grant_sequence_wait
  ]
}

resource "time_sleep" "revoke_public_schema_wait" {
  for_each = { for k, v in local.roles_set : k => v if v.revoke_public }

  destroy_duration = format("%ss", sum([2 * each.value.index, 3]))
  create_duration  = format("%ss", sum([2 * each.value.index, 3]))

  depends_on = [
    postgresql_grant.revoke_public_schema
  ]
}

resource "postgresql_grant" "revoke_public_database" {
  for_each = { for k, v in local.roles_set : k => v if v.revoke_public }

  database    = each.value.database
  role        = "public"
  object_type = "database"
  privileges  = []

  depends_on = [
    postgresql_role.default,
    time_sleep.db_wait,
    time_sleep.role_wait,
    time_sleep.grant_database_wait,
    time_sleep.grant_table_wait,
    time_sleep.grant_sequence_wait,
    time_sleep.revoke_public_schema_wait
  ]
}
