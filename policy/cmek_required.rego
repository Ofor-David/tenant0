package main

# SOC 2 CC6.1 / ISO 27001 A.10.1, CMEK (per-tenant KMS key)
# required on data stores. Runs against `tofu show -json <plan>` via conftest.

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "google_sql_database_instance"
	not resource.change.after.encryption_key_name
	msg := sprintf("%s has no encryption_key_name, Cloud SQL instances must use CMEK", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "google_storage_bucket"
	not resource.change.after.encryption
	msg := sprintf("%s has no encryption block, storage buckets holding data must use CMEK", [resource.address])
}
