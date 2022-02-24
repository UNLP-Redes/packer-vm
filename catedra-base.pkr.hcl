packer {
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "boot_wait" {
  type    = string
  default = "5s"
}

variable "ssh_key" {
  type = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDRvPrOkNMLPBT8KZWPyXX+VwF+y4yaA3xgzFFOoMx2KhLdMwQhMd7Irg96hqc8rKYvFpiPM7MhTSZtH83KlAA9di1kHgxi/X7qTJI447kVtsEiWpiipF6Ffu6Ej8D6GXGe4vz019WsATVcle8pWVeOw+ztFGkLgSwLEuskWPvPOmZrS4WfivyeCfChXHhDvdsxZ0bHzKWMlk2S/Xb9w8GrOrhvM7uTt7tZj4ln20XFVDfK/XBRH2tk2OfROT0aHVV5moohe5Go5gxGE+UrnTTD0a3/Am3jfOc1jqEBg8WB4tpjAQ74avJm5fSYOYUzq4ZyVpCgm/hRyiynYQDgb/QeuqUEElmqxCZmMas6PVNUa9fTksI2Ta0x05CBRc1iuYqUY8PQem+JC/HBYexFIg/sQ+xa8F19Y4W8NKGQvhal8/tfjFY1IuBy0ezMBO2vmQsd5c5UujKjE023JVOumSwiWDLCOy45cE4644Hs7sy23pM1PKs7wkHdsfd17Im4mJPNvePUfANpfKBkt7op5pBHACn+69xiLr1IBDQ04o93B2nEAEsKudY89QBjYrj31HELjx8bNL5qDnJiVZhc/TqzOgg67VulxhJultwCNqimZ/IsI7NOVyomn7lIYBgUJy4dM0ipYnKkUfqhhhR49PyNlsvFtB2SC6JiU0lOcUIuow== mati@centuripe"
}

variable "root_password" {
  type = string
  default = "packer"
  sensitive = true
}

variable "vm_name" {
  type    = string
  default = "debian-11.2.0-amd64"
}

variable "vm_domain" {
  type    = string
  default = "redes.unlp.edu.ar"
}

variable "iso_file" {
  type    = string
  default = "./iso/debian-11.2.0-amd64-netinst.iso"
}

variable "preseed_file" {
  type    = string
  default = "preseed.cfg"
}

variable "system_clock_in_utc" {
  type    = string
  default = "true"
}

variable "country" {
  type    = string
  default = "AR"
}

variable "keyboard" {
  type    = string
  default = "es"
}

variable "locale" {
  type    = string
  default = "en_AR.UTF-8"
}

variable "language" {
  type    = string
  default = "en"
}

variable "mirror" {
  type    = string
  default = "deb.debian.org"
}

variable "timezone" {
  type    = string
  default = "America/Argentina/Buenos_Aires"
}

source "virtualbox-iso" "catedra-base" {
  vm_name              = "Debian-Catedra-Base"
  guest_os_type        = "Debian_64"
  iso_url              = "./iso/debian-11.2.0-amd64-netinst.iso"
  iso_checksum         = "sha256:45c9feabba213bdc6d72e7469de71ea5aeff73faea6bfb109ab5bad37c3b43bd"
  shutdown_command     = "echo 'packer'|sudo -S shutdown -P now"
  boot_command = [
    "<esc><wait>auto preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg<enter>"
  ]
  boot_wait            = var.boot_wait
  memory               = 2048
  cpus                 = 2

  guest_additions_mode  = "upload"

  ssh_password = var.root_password
  ssh_username = "root"
  ssh_port     = 22
  ssh_timeout  = "60m"

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{.Name}}", "--vram", "128"],
    ["modifyvm", "{{.Name}}", "--acpi", "on"],
    ["modifyvm", "{{.Name}}", "--ioapic", "on"],
    ["modifyvm", "{{.Name}}", "--rtcuseutc", "on"]
  ]

  http_content = {
      "/preseed.cfg" = templatefile("preseed.pkrtpl", {
        language = var.language,
        country = var.country,
        timezone = var.timezone,
        locale = var.locale,
        keyboard = var.keyboard,
        vm_name = var.vm_name,
        vm_domain = var.vm_domain,
        mirror = var.mirror,
        system_clock_in_utc = var.system_clock_in_utc,
        ssh_password = var.root_password,
        ssh_key = var.ssh_key
      }),
  }
}

build {

  sources = ["source.virtualbox-iso.catedra-base"]
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

    playbook_file   = "./ansible/base.yml"
    clean_staging_directory = false
    staging_directory = "/tmp/ansible-packer"
  }

}
