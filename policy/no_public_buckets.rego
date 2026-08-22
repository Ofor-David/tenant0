package main

# SOC 2 CC6.1 / ISO 27001 A.8.3, no public storage buckets.
# Runs against `tofu show -json <plan>` via conftest.

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "google_storage_bucket_iam_binding"
	resource.change.after.role == "roles/storage.objectViewer"
	member := resource.change.after.members[_]
	member == "allUsers"
	msg := sprintf("%s grants public read access (allUsers), public buckets are not allowed", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "google_storage_bucket_iam_member"
	resource.change.after.member == "allUsers"
	msg := sprintf("%s grants public access (allUsers), public buckets are not allowed", [resource.address])
}
