 resource "google_compute_reservation" "wb_gpu_reservation" {
  for_each = var.compute_reservations_settings

  project     = each.value["project_id"]
  name        = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  zone        = "${each.value.region}-${each.value.zone}"

   specific_reservation {
     count = each.value["count_rv"]

     instance_properties {
       machine_type = each.value["rv_machine_type"]

       guest_accelerators {
         accelerator_type  = each.value["rv_accelerator_type"]
         accelerator_count = each.value["rv_accelerator_count"]
       }
     }
   }

   specific_reservation_required = true
 }
