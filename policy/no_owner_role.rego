package main

# SOC 2 CC6.3 / ISO 27001 A.8.2, no roles/owner in tenant/spine IAM.
# Runs against `tofu show -json <plan>` via conftest.

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type in {"google_project_iam_binding", "google_project_iam_member"}
	resource.change.after.role == "roles/owner"
	msg := sprintf("%s grants roles/owner, this is never allowed via IaC", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "google_organization_iam_binding"
	resource.change.after.role == "roles/owner"
	msg := sprintf("%s grants roles/owner at org level, this is never allowed via IaC", [resource.address])
}
