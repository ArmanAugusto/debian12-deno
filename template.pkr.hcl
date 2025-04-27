packer {
  required_plugins {
    qemu = {
      version       = ">=1.0.0"
      source        = "github.com/hashicorp/qemu"
    }
    ansible         = {
      version       = ">= 1.0.0"
      source        = "github.com/hashicorp/ansible"
    }
  }
}

variable "ssh_username" {
  default           = "devuser"
}

variable "ssh_password" {
  default           = "devpassword"
}

source "qemu" "debian" {
  iso_url           = "debian12-10.iso"
  iso_checksum      = "ee8d8579128977d7dc39d48f43aec5ab06b7f09e1f40a9d98f2a9d149221704a"
  output_directory  = "output-debian12-deno"
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"
  communicator      = "ssh"
  ssh_username      = var.ssh_username
  ssh_password      = var.ssh_password
  ssh_timeout       = "20m"
  disk_interface    = "virtio"
  disk_size         = "100000"
  memory            = "8192"
  cpus              = "2"
  format            = "qcow2"
  headless          = false
  display           = "sdl"
  accelerator       = "kvm"
  boot_wait         = "5s"

  http_directory    = "http"
  boot_command      = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "debian-installer=en_US auto locale=en_US.UTF-8",
    "kbd-chooser/method=us ",
    "keyboard-configuration/xkb-keymap=us ",
    "netcfg/get_hostname=debian ",
    "fb=false debconf/frontend=noninteractive ",
    "<enter>"
  ]
}

build {
  sources = ["source.qemu.debian"]

  provisioner "ansible" {
    playbook_file   = "ansible/playbook.yml"
    extra_arguments = ["--extra-vars", "ansible_python_interpreter=/usr/bin/python3"]
  } 
  
  post-processor "shell-local" {
    inline          = [
      "mkdir -p builds",
      "mv output-debian12-deno/packer-debian builds/debian12-deno-raw.qcow2",
      "qemu-img convert -O qcow2 -c builds/debian12-deno-raw.qcow2 builds/debian12-deno.qcow2",
      "rm builds/debian12-deno-raw.qcow2",
      "rm -rf output-debian12-deno"
    ]  
  }
}

