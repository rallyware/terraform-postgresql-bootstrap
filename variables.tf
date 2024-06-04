variable "extensions" {
  type        = list(string)
  default     = ["pg_stat_statements", "pg_hint_plan"]
  description = "A list of names of the extension to enable."
}

variable "databases" {
  type = list(object(
    {
      name              = string
      owner             = optional(string)
      tablespace_name   = optional(string)
      connection_limit  = optional(number, -1)
      allow_connections = optional(bool, true)
      is_template       = optional(bool, false)
      encoding          = optional(string, "UTF8")
      template          = optional(string, "template1")
      lc_collate        = optional(string, "en_US.UTF-8")
      lc_ctype          = optional(string, "en_US.UTF-8")
    }
  ))
  default     = []
  description = <<-DOC
    A list of databases to create.
      name:
        The name of the database.
			owner:
				The role name of the user who will own the database.
			tablespace_name:
				The name of the tablespace that will be associated with the database.
			connection_limit:
				How many concurrent connections can be established to this database.
			allow_connections:
				If `false` then no one can connect to this database.
			is_template:
				If `true`, then this database can be cloned by any user with `CREATEDB` privileges.
			template:
				The name of the template database from which to create the database. For `non-RDS` should be `template0`.
			encoding:
				Character set encoding to use in the database.
			lc_collate:
				Collation order to use in the database.
			lc_ctype:
				Character classification to use in the database.
  DOC
}

variable "roles" {
  type = list(
    object(
      {
        name                      = string
        database                  = optional(string)
        superuser                 = optional(bool, false)
        create_database           = optional(bool, false)
        create_role               = optional(bool, false)
        inherit                   = optional(bool, true)
        login                     = optional(bool, true)
        replication               = optional(bool, false)
        connection_limit          = optional(number, -1)
        encrypted_password        = optional(bool, true)
        bypass_row_level_security = optional(bool, false)
        valid_until               = optional(string, "infinity")
        roles                     = optional(list(string))
        search_path               = optional(list(string))
        schema                    = optional(string, "public")
        with_grant_option         = optional(string, false)
        database_privileges       = optional(list(string))
        table_privileges          = optional(list(string))
        sequence_privileges       = optional(list(string))
        revoke_public             = optional(bool, true)
        ignore_changes_privileges = optional(list(string), [])
        password_length           = optional(number, 16)
      }
    )
  )

  validation {
    condition = alltrue(
      flatten(
        [for r in var.roles :
          [for p in r.ignore_changes_privileges :
            contains(["table", "sequence"], p)
          ]
        ]
      )
    )
    error_message = "Only table and sequence objects are allowed in ignore_changes_privileges option."
  }

  default = []
  #tfsec:ignore:general-secrets-no-plaintext-exposure
  description = <<-DOC
		A list of roles to create.
			name:
				The role name.
			database:
				The database to grant privileges on for this role.
			superuser:
				Defines whether the role is a `superuser`.
			create_database:
				Defines a role's ability to execute `CREATE DATABASE`.
			create_role:
				Defines a role's ability to execute `CREATE ROLE`.
			inherit:
				Defines whether a role `inherits` the privileges of roles it is a member of.
			login:
				Defines whether role is allowed to log in.
			replication:
				Defines whether a role is allowed to initiate streaming replication or put the system in and out of backup mode.
			bypass_row_level_security:
				Defines whether a role bypasses every row-level security (RLS) policy.
			connection_limit:
				How many concurrent connections the role can establish.
			encrypted_password:
				Defines whether the password is stored encrypted in the system catalogs.
			roles:
				A comma separated list of roles which will be granted to this new role.
			valid_until:
				Defines the date and time after which the role's password is no longer valid.
			schema:
				The database schema to grant privileges on for this role.
			with_grant_option:
				Whether the recipient of these privileges can grant the same privileges to others.
			database_privileges:
				A comma separated list of roles which will be granted to database.
			table_privileges:
				A comma separated list of roles which will be granted to tables.
			sequence_privileges:
				A comma separated list of roles which will be granted to sequence.
			revoke_public:
				Whether to revoke non-granted privileges form the role.
			ignore_changes_privileges:
				List of objects for which privilege changes should be ignored.
			password_length:
			  The length of the password to generate.
	DOC
}
