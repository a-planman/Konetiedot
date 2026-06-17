#!/bin/bash

echo "DiKi Konetiedot - asennus alkaa"
echo "--------------------------------"

# Varmistetaan, että komento ajetaan tavallisena käyttäjänä
if [ "$EUID" -eq 0 ]; then
    echo "Älä aja tätä komentoa sudolla."
    echo "Käytä: ./asenna.sh"
    exit 1
fi

# Peruskansiot
DIKI="$HOME/diki"

echo "Luodaan kansiorakenne..."

mkdir -p "$DIKI/sovellukset"
mkdir -p "$DIKI/kuvat"
mkdir -p "$DIKI/tiedot"
mkdir -p "$DIKI/tulokset"
mkdir -p "$DIKI/kaynnistimet"

echo "Asennetaan tarvittavat paketit..."

sudo apt update
sudo apt install -y python3 python3-gi gir1.2-gtk-3.0 python3-cairo python3-reportlab hardinfo

echo "Kopioidaan tiedostot paikoilleen..."

# Oletus: asenna.sh ajetaan puretun diki-kansion sisältä
cp sovellus/konetiedot.py "$DIKI/sovellukset/"
cp kuvat/diki-logo.png "$DIKI/kuvat/"
cp tiedot/perustiedot.json "$DIKI/tiedot/"
cp kaynnistimet/konetiedot.desktop "$DIKI/kaynnistimet/"

echo "Luodaan yhteinen käynnistyskomento..."

sudo tee /usr/local/bin/konetiedot > /dev/null << 'EOF'
#!/bin/bash
python3 "$HOME/diki/sovellukset/konetiedot.py"
EOF

sudo chmod +x /usr/local/bin/konetiedot

echo "Kopioidaan käynnistin työpöydälle..."

cp "$DIKI/kaynnistimet/konetiedot.desktop" "$HOME/Työpöytä/" 2>/dev/null || \
cp "$DIKI/kaynnistimet/konetiedot.desktop" "$HOME/Desktop/"

chmod +x "$HOME/Työpöytä/konetiedot.desktop" 2>/dev/null
chmod +x "$HOME/Desktop/konetiedot.desktop" 2>/dev/null

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
echo "Kokeile käynnistintä työpöydältä tai kirjoita päätteeseen:"
echo
echo "konetiedot"