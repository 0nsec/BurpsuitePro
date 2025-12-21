#!/bin/bash
# Github: github.com/denoyey/BurpsuitePro.git
# This script installs Burp Suite Pro on Linux (supports Debian/Ubuntu and Arch Linux)

clear
CLONED_REPO_DIR="$(pwd)"

ascii_art="
╔──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╗
│  /$$$$$$                                                                                                         │
│ /$$$_  $$                                                                                                        │
│| $$$$\ $$ /$$$$$$$   /$$$$$$$  /$$$$$$   /$$$$$$$                                                                │
│| $$ $$ $$| $$__  $$ /$$_____/ /$$__  $$ /$$_____/       /$$$$$$                                                  │
│| $$\ $$$$| $$  \ $$|  $$$$$$ | $$$$$$$$| $$            |______/                                                  │
│| $$ \ $$$| $$  | $$ \____  $$| $$_____/| $$                                                                      │
│|  $$$$$$/| $$  | $$ /$$$$$$$/|  $$$$$$$|  $$$$$$$                                                                │
│ \______/ |__/  |__/|_______/  \_______/ \_______/                                                                │
│                                                                                                                  │
│                                                                                                                  │
│                                                                                                                  │
│ /$$$$$$$                                 /$$$$$$            /$$   /$$               /$$$$$$$                     │
│| $$__  $$                               /$$__  $$          |__/  | $$              | $$__  $$                    │
│| $$  \ $$ /$$   /$$  /$$$$$$   /$$$$$$ | $$  \__/ /$$   /$$ /$$ /$$$$$$    /$$$$$$ | $$  \ $$  /$$$$$$   /$$$$$$ │
│| $$$$$$$ | $$  | $$ /$$__  $$ /$$__  $$|  $$$$$$ | $$  | $$| $$|_  $$_/   /$$__  $$| $$$$$$$/ /$$__  $$ /$$__  $$│
│| $$__  $$| $$  | $$| $$  \__/| $$  \ $$ \____  $$| $$  | $$| $$  | $$    | $$$$$$$$| $$____/ | $$  \__/| $$  \ $$│
│| $$  \ $$| $$  | $$| $$      | $$  | $$ /$$  \ $$| $$  | $$| $$  | $$ /$$| $$_____/| $$      | $$      | $$  | $$│
│| $$$$$$$/|  $$$$$$/| $$      | $$$$$$$/|  $$$$$$/|  $$$$$$/| $$  |  $$$$/|  $$$$$$$| $$      | $$      |  $$$$$$/│
│|_______/  \______/ |__/      | $$____/  \______/  \______/ |__/   \___/   \_______/|__/      |__/       \______/ │
│                              | $$                                                                                │
│                              | $$                                                                                │
│                              |__/                                                                                │
╚──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╝                                                                                                           
    Github: github.com/0nsec/BurpsuitePro
"
echo -e "$ascii_art"

# Install dependencies (supports apt and pacman)
echo -e "\n[*] Installing dependencies..."
if [ -f /etc/debian_version ]; then
  sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y
  sudo apt-get install -y git axel curl unzip
elif [ -f /etc/arch-release ] || grep -qi "arch" /etc/os-release 2>/dev/null; then
  sudo pacman -Syu --noconfirm
  sudo pacman -S --noconfirm git curl unzip jre-openjdk axel
else
  echo "[!] Unsupported distro detected; attempting apt-get installs"
  sudo apt-get update && sudo apt-get install -y git axel curl unzip || true
fi

echo -e "\n$(printf '%0.s=' {1..70})"


echo -e "\n[*] Check the latest STABLE version at:"
echo -e "    https://portswigger.net/burp/releases/professional/latest"
echo -e "\n[!] Please use only a STABLE version (not Early Adopter or Beta)\n"
while true; do
  read -p "    >> Enter version (e.g., 2025.10.7): " version_input
  version_clean="${version_input//[\/.]/-}"
  version_folder="${version_input//\//.}"
  latest_stable="https://portswigger.net/burp/releases/professional-community-$version_clean?requestededition=professional"
  echo -e "\n[*] Checking URL: $latest_stable"
  status_code=$(curl -s -o /dev/null -w "%{http_code}" "$latest_stable")
  if [[ "$status_code" == "200" ]]; then
    echo -e "\n[*] Version $version_input is valid."
    break
  else
    echo -e "\n[!] Version $version_input is NOT valid. Please try again.\n"
  fi
done
version="$version_clean"
echo -e "\n[*] Using version: $version"

echo -e "\n$(printf '%0.s=' {1..70})"


echo -e "\n[*] Preparing installation directory..."
version="$version_clean"
RUNTIME_DIR="$HOME/BurpsuitePro_v$version_folder"
jar_name="burpsuite_pro_v$version.jar"
jar_path="$RUNTIME_DIR/$jar_name"
if [[ -d "$RUNTIME_DIR" ]]; then
  echo -e "\n[!] Directory already exists: [$RUNTIME_DIR]"
  read -p "    >> Do you want to delete and recreate it? (y/n): " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm -rf "$RUNTIME_DIR"
    echo -e "\n[*] Deleted existing directory."
    mkdir -p "$RUNTIME_DIR"
  else
    echo -e "\n[*] Keeping existing directory."
    if [[ -f "$jar_path" ]]; then
      echo -e "\n[*] Detected existing BurpSuitePro JAR file for version $version_input. Skipping download."
    else
      echo -e "\n[*] No JAR file found for version $version_input. Proceeding to download..."
    fi
  fi
else
  echo -e "\n[*] Creating runtime directory at $RUNTIME_DIR..."
  mkdir -p "$RUNTIME_DIR"
fi
cd "$RUNTIME_DIR" || {
  echo "[!] Failed to enter directory."; exit 1;
}

echo -e "\n$(printf '%0.s=' {1..70})"


for pkg in openjdk-21-jre openjdk-17-jre; do
  if apt-cache show "$pkg" &>/dev/null; then
    echo "[*] Installing available Java package: $pkg"
    sudo apt install -y "$pkg"
    break
  fi
done

echo -e "\n$(printf '%0.s=' {1..70})"

# Download BurpSuitePro
echo -e "\n[*] Checking BurpsuitePro..."
if [[ ! -f "$jar_name" ]]; then
  echo -e "\n[*] Downloading BurpSuitePro for version $version_input..."
  url="https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar&version=$version_folder"
  if axel "$url" -o "$jar_name"; then
    echo -e "\n[*] Download complete: $jar_name"
  else
    echo -e "\n[!] Download failed!"; exit 1;
  fi
else
  echo -e "\n[*] BurpSuitePro file already exists: $jar_name"
  echo -e "    Skipping download."
fi

echo -e "\n$(printf '%0.s=' {1..70})"

# Download loader (prefer loader-zero_nsec.jar) — prefer repo loader folder and install into $RUNTIME_DIR/loader
echo -e "\n[*] Checking license loader..."
LOADER_SRC_DIR="$CLONED_REPO_DIR/burp-files/loader"
LOADER_INSTALL_DIR="$RUNTIME_DIR/loader"
FOUND_LOADER=""
# 1) Prefer loader from repo loader folder
if [[ -f "$LOADER_SRC_DIR/loader-zero_nsec.jar" ]]; then
  mkdir -p "$LOADER_INSTALL_DIR"
  cp -f "$LOADER_SRC_DIR/loader-zero_nsec.jar" "$LOADER_INSTALL_DIR/loader-zero_nsec.jar"
  FOUND_LOADER="$LOADER_INSTALL_DIR/loader-zero_nsec.jar"
elif [[ -f "$LOADER_SRC_DIR/loader.jar" ]]; then
  mkdir -p "$LOADER_INSTALL_DIR"
  cp -f "$LOADER_SRC_DIR/loader.jar" "$LOADER_INSTALL_DIR/loader.jar"
  FOUND_LOADER="$LOADER_INSTALL_DIR/loader.jar"
else
  # 2) check runtime dir
  for L in "${LOADER_CANDIDATES[@]}"; do
    if [[ -f "$L" ]]; then
      mkdir -p "$LOADER_INSTALL_DIR"
      cp -f "$L" "$LOADER_INSTALL_DIR/"
      FOUND_LOADER="$LOADER_INSTALL_DIR/$(basename "$L")"
      break
    fi
  done
fi

# 3) As a strict policy: do NOT download - only use existing loader files
if [[ -z "$FOUND_LOADER" ]]; then
  echo "[*] Checking project root and current directory for loader jars..."
  LOADER_CANDIDATES=("$CLONED_REPO_DIR/loader-zero_nsec.jar" "$CLONED_REPO_DIR/loader.jar" "./loader-zero_nsec.jar" "./loader.jar")
  for L in "${LOADER_CANDIDATES[@]}"; do
    if [[ -f "$L" ]]; then
      mkdir -p "$LOADER_INSTALL_DIR"
      cp -f "$L" "$LOADER_INSTALL_DIR/"
      FOUND_LOADER="$LOADER_INSTALL_DIR/$(basename "$L")"
      break
    fi
  done
fi

if [[ -z "$FOUND_LOADER" ]]; then
  echo -e "\n[!] Failed to obtain a loader JAR. Please provide loader-zero_nsec.jar or loader.jar in $LOADER_SRC_DIR or this directory."
  exit 1
fi

echo "[*] Using loader: $FOUND_LOADER"
# Validate that the loader contains a Premain-Class manifest attribute
MANIFEST_PREMAIN=$(unzip -p "$FOUND_LOADER" META-INF/MANIFEST.MF 2>/dev/null | grep -i "Premain-Class" || true)
if [[ -z "$MANIFEST_PREMAIN" ]]; then
  echo "[!] Warning: Premain-Class not found in $FOUND_LOADER manifest. Java agent may fail to load."
  echo "    Attempting to inject Premain-Class and Main-Class into the jar's manifest..."
  cat > /tmp/manifest.tmp <<EOF_MAN
Manifest-Version: 1.0
Premain-Class: com.zero_nsec.burploaderkeygen.Loader
Main-Class: com.zero_nsec.burploaderkeygen.KeygenForm
EOF_MAN
  if jar umf /tmp/manifest.tmp "$FOUND_LOADER" 2>/dev/null; then
    echo "[*] Updated manifest in $FOUND_LOADER with Premain-Class and Main-Class." 
    # re-check
    MANIFEST_PREMAIN=$(unzip -p "$FOUND_LOADER" META-INF/MANIFEST.MF 2>/dev/null | grep -i "Premain-Class" || true)
    if [[ -z "$MANIFEST_PREMAIN" ]]; then
      echo "[!] Failed to add Premain-Class automatically. Please provide a proper agent jar." 
    fi
  else
    echo "[!] Could not update manifest automatically (jar tool may not be available). Please update the loader jar manually." 
  fi
fi

echo -e "\n$(printf '%0.s=' {1..70})"

# Download logo.png if not present
echo -e "\n[*] Checking BurpSuitePro logo..."
if [[ ! -f logo.png ]]; then
  echo "[*] logo.png not found. Downloading from GitHub..."
  curl -L -o logo.png "https://github.com/0nsec/BurpsuitePro/blob/main/burp-files/img/logo.png?raw=true"
  if [[ ! -f logo.png ]]; then
    echo -e "\n[!] Failed to download logo.png. Please check the URL or your connection."
    exit 1
  fi
else
  echo "[*] logo.png already exists. Skipping download."
fi

echo -e "\n$(printf '%0.s=' {1..70})"

# Create launcher script in installation folder
echo -e "\n[*] Checking existing launcher script..."
LAUNCHER_FILE="burpsuitepro"
EXPECTED_JAR_LINE="-jar \"\$DIR/$jar_name\" &"
if [[ -f $LAUNCHER_FILE ]]; then
  echo -e "[*] Found existing launcher script: $LAUNCHER_FILE"
  if grep -q -- "$EXPECTED_JAR_LINE" "$LAUNCHER_FILE"; then
    echo -e "[*] Launcher script already points to correct version ('$jar_name'). Skipping creation."
  else
    echo -e "[!] Existing launcher script points to a different version. Replacing it..."
    rm -f "$LAUNCHER_FILE"
    CREATE_LAUNCHER=true
  fi
else
  CREATE_LAUNCHER=true
fi
if [[ "$CREATE_LAUNCHER" == true ]]; then
  echo -e "[*] Creating launcher script..."
  cat <<'EOF' > $LAUNCHER_FILE
#!/bin/bash
# Github: https://github.com/0nsec/BurpsuitePro
# Burp Suite Pro Launcher Script 

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# prefer loader-zero_nsec.jar, fall back to loader.jar
if [ -f "$DIR/loader/loader-zero_nsec.jar" ]; then
  LOADER_JAR="$DIR/loader/loader-zero_nsec.jar"
elif [ -f "$DIR/loader/loader.jar" ]; then
  LOADER_JAR="$DIR/loader/loader.jar"
else
  echo "[!] loader JAR not found in $DIR/loader. Please place loader-zero_nsec.jar or loader.jar in the loader folder."
  exit 1
fi

java \
  --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
  --add-opens=java.base/java.lang=ALL-UNNAMED \
  -javaagent:"$LOADER_JAR" \
  -noverify \
  -jar "\$DIR/$jar_name" &
EOF
  chmod +x $LAUNCHER_FILE
  sudo cp $LAUNCHER_FILE /usr/local/bin/burpsuitepro
  echo "[*] CLI launcher installed: /usr/local/bin/burpsuitepro"
fi

echo -e "\n$(printf '%0.s=' {1..70})"

# Create .desktop launcher to show in Linux application menu
echo -e "\n[*] Would you like to create a desktop menu shortcut?"
read -p "    >> Create desktop launcher? (y/n): " create_desktop
DESKTOP_FILE="$HOME/.local/share/applications/burpsuitepro.desktop"
EXPECTED_EXEC_LINE="Exec=$RUNTIME_DIR/burpsuitepro"
if [[ "$create_desktop" =~ ^[Yy]$ ]]; then
  echo -e "\n[*] Checking existing desktop launcher..."
  CREATE_DESKTOP=true
  if [[ -f "$DESKTOP_FILE" ]]; then
    echo "[*] Found existing desktop launcher: $DESKTOP_FILE"
    if grep -q "$EXPECTED_EXEC_LINE" "$DESKTOP_FILE"; then
      echo "[*] Desktop launcher already points to correct version. Skipping creation."
      CREATE_DESKTOP=false
    else
      echo "[!] Desktop launcher points to different version. Replacing..."
      rm -f "$DESKTOP_FILE"
    fi
  fi
  if [[ "$CREATE_DESKTOP" == true ]]; then
    echo "[*] Creating desktop launcher..."
    cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=BurpSuitePro
Comment=Burp Suite Professional Launcher
Exec=$RUNTIME_DIR/burpsuitepro
Icon=$RUNTIME_DIR/logo.png
Terminal=false
Type=Application
Categories=Development;Security;
StartupNotify=true
EOF
    chmod +x "$DESKTOP_FILE"
    echo -e "\n[*] Desktop launcher created at $DESKTOP_FILE"
    echo -e "[*] You can now launch BurpSuitePro from your application menu."
  fi
else
  echo -e "\n[*] Skipping desktop launcher creation."
fi

echo -e "\n$(printf '%0.s=' {1..70})"

# Run license loader & Burpsuite Pro
BURP_PREFS_DIR="$HOME/.java/.userPrefs/burp"
echo -e "\n[*] Removing existing BurpSuitePro license preferences (if any)..."
rm -rf "$BURP_PREFS_DIR"
echo -e "\n[*] Starting license loader..."
java -jar "$FOUND_LOADER" &
echo -e "\n[*] Launching BurpSuitePro..."
./burpsuitepro

echo -e "\n$(printf '%0.s=' {1..70})"

# Display final message
echo -e "\n[*] Installation and setup complete!"
echo -e "    You can now run Burp Suite Professional using the command: burpsuitepro"
echo -e "    or from your application menu if you created a desktop launcher."
echo -e "\n[*] Thank you for using this script!"
echo -e "    For any issues, please report them on the GitHub repository."

echo -e "\n$(printf '%0.s=' {1..70})"

# Setelah aplikasi ditutup, hapus folder hasil git clone
if [[ -d "$CLONED_REPO_DIR" ]]; then
  echo -e "\n[*] Cleaning up cloned repo at: $CLONED_REPO_DIR"
  cd "$CLONED_REPO_DIR/.." || { echo "[!] Failed to cd to parent directory."; exit 1; }
  rm -rf "$CLONED_REPO_DIR"
  echo "[*] Cloned repo removed successfully."
else
  echo -e "\n[!] Cloned repo directory does not exist or already removed: $CLONED_REPO_DIR"
fi

echo -e "\n$(printf '%0.s=' {1..70})"
