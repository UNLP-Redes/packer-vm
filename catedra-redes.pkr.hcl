packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.0.4"
      source = "github.com/hashicorp/virtualbox"
    }
  }
}

source "virtualbox-ovf" "catedra-redes" {
  source_path  = "output-catedra-base/Debian-Catedra-Base.ovf"
  vm_name      = "Redes y Comunicaciones v22.2"
  ssh_username = "root"
  ssh_password = "packer"
  shutdown_command = "echo 'packer'|sudo -S shutdown -P now"
}

build {

  sources = ["source.virtualbox-ovf.catedra-redes"]

  provisioner "ansible-local" {

    playbook_file   = "./ansible/redes/main.yml"
    playbook_dir    = "./ansible/"
    clean_staging_directory = true
    staging_directory = "/tmp/ansible-packer-redes"
  }

}
