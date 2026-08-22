# Folder layout for the tenant0 org node.
# prj-host-network (Phase 1) and per-tenant projects (Phase 2, via Crossplane)
# also land under this folder; only the spine's own projects are created here.
#
# Sibling of fldr-t0x-mgmt (folders/29731629541), which is scoped only to the
# manually-created state-bootstrap project (a one-time documented exception)
#, this folder holds everything else.

resource "google_folder" "tenant0" {
  display_name = "tenant0"
  parent       = "organizations/${var.org_id}"
}
