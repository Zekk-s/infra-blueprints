terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.21"
    }
  }
}

variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment where the instance lives."
}

variable "subnet_ocid" {
  type        = string
  description = "Subnet OCID for the primary VNIC."
}

variable "availability_domain" {
  type        = string
  description = "Availability domain (e.g. iAdx:EU-FRA-1-AD-1)."
}

variable "image_ocid" {
  type        = string
  description = "OCID of the OS image (Oracle Linux 8 / Ubuntu 22.04 LTS)."
}

variable "shape" {
  type        = string
  default     = "VM.Standard.E4.Flex"
  description = "Compute shape. Use VM.Standard.* for x86 or BM.* for bare metal."
}

variable "ocpus" {
  type        = number
  default     = 2
  description = "OCPU count for Flex shapes."
}

variable "memory_in_gbs" {
  type        = number
  default     = 16
  description = "Memory (GB) for Flex shapes."
}

variable "display_name" {
  type        = string
  default     = "zekk-s-node"
  description = "Human-readable instance name."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key (single-line openssh format)."
}

resource "oci_core_instance" "this" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = var.display_name
  shape               = var.shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = var.image_ocid
    boot_volume_size_in_gbs = 100
  }

  create_vnic_details {
    subnet_id        = var.subnet_ocid
    assign_public_ip = true
    display_name     = "${var.display_name}-vnic"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

output "instance_id" {
  value = oci_core_instance.this.id
}

output "public_ip" {
  value = oci_core_instance.this.create_vnic_details[0].public_ip
}
