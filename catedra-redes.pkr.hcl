packer {
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source = "github.com/hashicorp/virtualbox"
    }
  }
}

source "virtualbox-ovf" "catedra-redes" {
  source_path  = "output-catedra-base/Debian-Catedra-Base.ovf"
  vm_name      = "Redes y Comunicaciones v22.1"
  ssh_username = "root"
  ssh_password = "packer"
  shutdown_command = "echo 'packer'|sudo -S shutdown -P now"
}

build {

  sources = ["source.virtualbox-ovf.catedra-redes"]

  provisioner "ansible-local" {

    playbook_file   = "./ansible/redes.yml"
    clean_staging_directory = false
    staging_directory = "/tmp/ansible-packer-redes"
  }

}
