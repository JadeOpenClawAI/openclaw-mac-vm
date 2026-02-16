packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
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
  vm_name      = "${var.macos_version}-base"

  cpu_count    = 2
  memory_gb    = 8
  disk_size_gb = 50
  headless     = true

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
brew install --cask bluebubbles
# Optional extension path:
# brew install --cask openclaw
EOF
    ]
    inline_shebang = "/bin/zsh -e -l"
  }

  # Keep Messages responsive in long-running/headless setups
  provisioner "shell" {
    inline = [<<EOF
mkdir -p "$HOME/Scripts"
cat > "$HOME/Scripts/poke-messages.scpt" <<'SCPT'
try
  tell application "Messages"
    if not running then
      launch
    end if
    set _chatCount to (count of chats)
  end tell
on error
end try
SCPT

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$HOME/Library/LaunchAgents/com.user.poke-messages.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.user.poke-messages</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-lc</string>
    <string>/usr/bin/osascript &quot;$HOME/Scripts/poke-messages.scpt&quot;</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>300</integer>
  <key>StandardOutPath</key>
  <string>/tmp/poke-messages.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/poke-messages.err</string>
</dict>
</plist>
PLIST

launchctl unload "$HOME/Library/LaunchAgents/com.user.poke-messages.plist" 2>/dev/null || true
launchctl load "$HOME/Library/LaunchAgents/com.user.poke-messages.plist"

# Needed by some private-API helper workflows
sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true
EOF
    ]
    inline_shebang = "/bin/zsh -e -l"
  }
}
