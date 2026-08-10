resource "google_workbench_instance" "instance" {
  name     = var.instance_name
  location = var.zone

  gce_setup {
    # ... suas configs existentes ...

    metadata = {
      startup-script = <<-EOT
        #!/bin/bash

        if command -v R &> /dev/null; then
          echo "R já está instalado. Pulando."
          exit 0
        fi

        apt-get update -y
        apt-get install -y --no-install-recommends \
          software-properties-common \
          dirmngr \
          gnupg \
          apt-transport-https \
          ca-certificates

        wget -qO- https://cloud.r-project.org/bin/linux/debian/marutter_pubkey.asc \
          | gpg --dearmor -o /usr/share/keyrings/r-project.gpg

        echo "deb [signed-by=/usr/share/keyrings/r-project.gpg] https://cloud.r-project.org/bin/linux/debian bookworm-cran40/" \
          > /etc/apt/sources.list.d/r-project.list

        apt-get update -y
        apt-get install -y --no-install-recommends r-base r-base-dev

        echo "R instalado com sucesso: $(R --version | head -1)"
      EOT
    }
  }
}
