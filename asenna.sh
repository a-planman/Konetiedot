#!/bin/bash

echo "DiKi Konetiedot - asennus alkaa"
echo "--------------------------------"

if [ "$EUID" -eq 0 ]; then
    echo "Älä aja tätä komentoa sudolla."
    echo "Käytä: ./asenna.sh"
    exit 1
fi

DIKI="$HOME/diki"

echo "Luodaan kansiorakenne..."

mkdir -p "$DIKI/ohjelmat"
mkdir -p "$DIKI/kuvat"
mkdir -p "$DIKI/tiedot"
mkdir -p "$DIKI/tulokset"

echo "Asennetaan tarvittavat paketit..."

sudo apt update
sudo apt install -y python3 python3-gi gir1.2-gtk-3.0 python3-cairo python3-reportlab hardinfo dmidecode

echo "Kopioidaan tiedostot paikoilleen..."

cp ohjelmat/konetiedot.py "$DIKI/ohjelmat./"
cp kuvat/diki-logo.png "$DIKI/kuvat/"
cp tiedot/perustiedot.json "$DIKI/tiedot/"

echo "Luodaan yhteinen käynnistyskomento..."

sudo tee /usr/local/bin/konetiedot > /dev/null << 'EOF'
#!/bin/bash
python3 "$HOME/diki/ohjelmat/konetiedot.py"
EOF

sudo chmod +x /usr/local/bin/konetiedot

echo "Luodaan työpöydän käynnistin..."

TYOPOYTA="$HOME/Työpöytä"

if [ ! -d "$TYOPOYTA" ]; then
    TYOPOYTA="$HOME/Desktop"
fi

cat > "$TYOPOYTA/konetiedot.desktop" << EOF
[Desktop Entry]
Type=Application
Name=DiKi Koneen tiedot
Comment=Näytä tämän tietokoneen tiedot
Exec=konetiedot
Icon=$HOME/diki/kuvat/diki-logo.png
Terminal=false
Categories=Utility;
EOF

chmod +x "$TYOPOYTA/konetiedot.desktop"

echo "Haetaan koneen sarjanumero..."

SARJANUMERO=$(sudo dmidecode -s system-serial-number 2>/dev/null)

if [ -z "$SARJANUMERO" ]; then
    SARJANUMERO="ei_tiedossa"
fi

echo "Tallennetaan sarjanumero perustiedot.json-tiedostoon..."

python3 - << EOF
import json
from pathlib import Path

polku = Path.home() / "diki" / "tiedot" / "perustiedot.json"

with open(polku, "r", encoding="utf-8") as f:
    tiedot = json.load(f)

tiedot["sarjanumero"] = "$SARJANUMERO"

with open(polku, "w", encoding="utf-8") as f:
    json.dump(tiedot, f, ensure_ascii=False, indent=4)
EOF

echo "--------------------------------"
echo "Asennus valmis."
echo "Käynnistin on luotu työpöydälle."
echo "Voit kokeilla myös päätteessä komennolla:"
echo
echo "konetiedot"