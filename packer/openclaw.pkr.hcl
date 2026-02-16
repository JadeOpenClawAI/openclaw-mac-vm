packer {
  required_plugins {
    tart = {
      version = ">= 1.11.1"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "macos_version" {
  type    = string
  default = "tahoe"
}

source "tart-cli" "tart" {
  vm_base_name = "ghcr.io/cirruslabs/macos-${var.macos_version}-base:latest"
  vm_name      = "${var.macos_version}-openclaw"

  cpu_count    = 2
  memory_gb    = 8
  disk_size_gb = 50

  ssh_username = "admin"
  ssh_password = "admin"
  ssh_timeout  = "120s"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [<<EOF
sudo networksetup -setdnsservers "Ethernet" 1.1.1.1 8.8.8.8
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
EOF
    ]
    inline_shebang = "/bin/zsh -e -l"
  }

  provisioner "shell" {
    inline = [<<EOF
brew update
brew install --cask openclaw
# Optional extension path:
# brew install --cask bluebubbles
EOF
    ]
    inline_shebang = "/bin/zsh -e -l"
  }
}
