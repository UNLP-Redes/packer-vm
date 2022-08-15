packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.0.4"
      source = "github.com/hashicorp/virtualbox"
    }
  }
}


locals {
  vm_name   = "Debian-Catedra-Base"
  vm_domain = "redes.unlp.edu.ar"
  boot_wait = "5s"
  root_password = "packer"
  ssh_username  = "root"
  ssh_password  = local.root_password
  ssh_port      = 22
  ssh_timeout   = "60m"
  memory    = 2048
  cpus      = 2
  disk_size = "15G"
  iso_file  = "./iso/debian-11.4.0-amd64-netinst.iso"
  iso_checksum = "sha256:d490a35d36030592839f24e468a5b818c919943967012037d6ab3d65d030ef7f"
  preseed_file = "preseed.cfg"
  shutdown_cmd = "echo 'packer'|sudo -S shutdown -P now"
  system_clock_in_utc = true
  country  = "AR"
  keyboard = "es"
  locale   = "en_AR.UTF-8"
  language = "en"
  mirror   = "deb.debian.org"
  timezone = "America/Argentina/Buenos_Aires"
  boot_cmd = [
    "<esc><wait>auto preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<enter>"
  ]
}

variable "ssh_key" {
  type = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDRvPrOkNMLPBT8KZWPyXX+VwF+y4yaA3xgzFFOoMx2KhLdMwQhMd7Irg96hqc8rKYvFpiPM7MhTSZtH83KlAA9di1kHgxi/X7qTJI447kVtsEiWpiipF6Ffu6Ej8D6GXGe4vz019WsATVcle8pWVeOw+ztFGkLgSwLEuskWPvPOmZrS4WfivyeCfChXHhDvdsxZ0bHzKWMlk2S/Xb9w8GrOrhvM7uTt7tZj4ln20XFVDfK/XBRH2tk2OfROT0aHVV5moohe5Go5gxGE+UrnTTD0a3/Am3jfOc1jqEBg8WB4tpjAQ74avJm5fSYOYUzq4ZyVpCgm/hRyiynYQDgb/QeuqUEElmqxCZmMas6PVNUa9fTksI2Ta0x05CBRc1iuYqUY8PQem+JC/HBYexFIg/sQ+xa8F19Y4W8NKGQvhal8/tfjFY1IuBy0ezMBO2vmQsd5c5UujKjE023JVOumSwiWDLCOy45cE4644Hs7sy23pM1PKs7wkHdsfd17Im4mJPNvePUfANpfKBkt7op5pBHACn+69xiLr1IBDQ04o93B2nEAEsKudY89QBjYrj31HELjx8bNL5qDnJiVZhc/TqzOgg67VulxhJultwCNqimZ/IsI7NOVyomn7lIYBgUJy4dM0ipYnKkUfqhhhR49PyNlsvFtB2SC6JiU0lOcUIuow== mati@centuripe"
}


source "virtualbox-iso" "catedra-base" {
  vm_name              = local.vm_name
  guest_os_type        = "Debian_64"
  iso_url              = local.iso_file
  iso_checksum         = local.iso_checksum
  shutdown_command     = local.shutdown_cmd
  boot_command         = local.boot_cmd
  boot_wait            = local.boot_wait


  guest_additions_mode  = "upload"
  memory    = local.memory
  cpus      = local.cpus

  ssh_username = local.ssh_username
  ssh_password = local.ssh_password
  ssh_port     = local.ssh_port
  ssh_timeout  = local.ssh_timeout

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{.Name}}", "--vram", "128"],
    ["modifyvm", "{{.Name}}", "--acpi", "on"],
    ["modifyvm", "{{.Name}}", "--ioapic", "on"],
    ["modifyvm", "{{.Name}}", "--rtcuseutc", "on"]
  ]

  http_content = {
      "/preseed.cfg" = templatefile("preseed.pkrtpl", {
        language = local.language,
        country = local.country,
        timezone = local.timezone,
        locale = local.locale,
        keyboard = local.keyboard,
        vm_name = local.vm_name,
        vm_domain = local.vm_domain,
        mirror = local.mirror,
        system_clock_in_utc = local.system_clock_in_utc,
        ssh_password = local.root_password,
        ssh_key = var.ssh_key
      }),
  }
}

build {

  sources = [
    "source.virtualbox-iso.catedra-base",
  ]

  provisioner "shell" {
    inline = [
      "sleep 30",
      "apt-get update",
      "apt-get -y upgrade",
      "apt-get -y dist-upgrade",
      "apt-get -y install build-essential dkms linux-headers-$(uname -r) python3 python3-pip python3-apt libc6-dev gcc python3-dev",
      "pip3 install ansible",
      "mount -o loop /root/VBoxGuestAdditions.iso /mnt",
      "/mnt/VBoxLinuxAdditions.run || true"
    ]
  }
  provisioner "ansible-local" {

    playbook_file   = "./ansible/base/main.yml"
    playbook_dir    = "./ansible/"
    clean_staging_directory = true
    staging_directory = "/tmp/ansible-packer"
  }

}
