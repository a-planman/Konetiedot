#!/bin/bash

set -e

DIKI="$HOME/diki"
DESKTOP="$HOME/Työpöytä"

echo "Aloitetaan DiKi-koneen tiedot -asennus"
echo "Nykyinen hakemisto:"
pwd
echo "--------------------------------"

echo "Tarkistetaan lähdetiedostot..."

if [ ! -f "ohjelmat/konetiedot.py" ]; then
    echo "VIRHE: ohjelmat/konetiedot.py puuttuu"
    exit 1
fi

if [ ! -f "kuvat/diki-logo.png" ]; then
    echo "VIRHE: kuvat/diki-logo.png puuttuu"
    exit 1
fi

if [ ! -f "tiedot/perustiedot.json" ]; then
    echo "VIRHE: tiedot/perustiedot.json puuttuu"
    exit 1
fi

echo "Lähdetiedostot löytyivät."
echo "--------------------------------"

echo "Asennetaan tarvittavat paketit..."
sudo apt update
sudo apt install -y python3 python3-gi gir1.2-gtk-3.0 python3-cairo python3-reportlab hardinfo dmidecode

echo "--------------------------------"
echo "Luodaan DiKi-kansiot..."

mkdir -p "$DIKI/ohjelmat"
mkdir -p "$DIKI/kuvat"
mkdir -p "$DIKI/tiedot"
mkdir -p "$DIKI/tulokset"
mkdir -p "$DIKI/kaynnistimet"

echo "Kansiot luotu."
echo "--------------------------------"

echo "Kopioidaan tiedostot..."

cp -v ohjelmat/konetiedot.py "$DIKI/ohjelmat/"
cp -v kuvat/diki-logo.png "$DIKI/kuvat/"
cp -v tiedot/perustiedot.json "$DIKI/tiedot/"

echo "--------------------------------"
echo "Haetaan koneen sarjanumero järjestelmästä..."

SARJANUMERO=""

SARJANUMERO=$(sudo dmidecode -s system-serial-number 2>/dev/null || true)

if [ -z "$SARJANUMERO" ] || [ "$SARJANUMERO" = "None" ] || [ "$SARJANUMERO" = "Unknown" ] || [ "$SARJANUMERO" = "To Be Filled By O.E.M." ]; then
    SARJANUMERO=$(sudo cat /sys/class/dmi/id/product_serial 2>/dev/null || true)
fi

if [ -z "$SARJANUMERO" ] || [ "$SARJANUMERO" = "None" ] || [ "$SARJANUMERO" = "Unknown" ] || [ "$SARJANUMERO" = "To Be Filled By O.E.M." ]; then
    SARJANUMERO=$(sudo cat /sys/class/dmi/id/board_serial 2>/dev/null || true)
fi

if [ -n "$SARJANUMERO" ]; then
    echo "Sarjanumero löytyi: $SARJANUMERO"
    echo "Tallennetaan sarjanumero perustiedot.json-tiedostoon..."

    python3 - <<EOF
import json
from pathlib import Path

polku = Path("$DIKI/tiedot/perustiedot.json")

with open(polku, "r", encoding="utf-8") as f:
    data = json.load(f)

data["sarjanumero"] = "$SARJANUMERO"

with open(polku, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=4)
EOF

else
    echo "Sarjanumeroa ei löytynyt automaattisesti."
    echo "perustiedot.json säilytetään muuten ennallaan."
fi

echo "--------------------------------"
echo "Tarkistetaan kopioinnin tulos..."

ls -l "$DIKI/ohjelmat/konetiedot.py"
ls -l "$DIKI/kuvat/diki-logo.png"
ls -l "$DIKI/tiedot/perustiedot.json"

echo "--------------------------------"
echo "Luodaan yhteinen käynnistyskomento..."

sudo tee /usr/local/bin/konetiedot > /dev/null <<EOF
#!/bin/bash
python3 "\$HOME/diki/ohjelmat/konetiedot.py"
EOF

sudo chmod +x /usr/local/bin/konetiedot

echo "--------------------------------"
echo "Luodaan työpöydän käynnistimet..."

mkdir -p "$DESKTOP"

cat > "$DESKTOP/konetiedot.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DiKi-koneen tiedot
Comment=Näyttää DiKi-koneen tiedot
Exec=konetiedot
Icon=$DIKI/kuvat/diki-logo.png
Terminal=false
Categories=Utility;
EOF

chmod +x "$DESKTOP/konetiedot.desktop"

cat > "$DESKTOP/hardinfo.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Kattava HardInfo
Comment=Näyttää koneen kattavat tekniset tiedot
Exec=hardinfo
Icon=hardinfo
Terminal=false
Categories=System;
EOF

chmod +x "$DESKTOP/hardinfo.desktop"

echo "--------------------------------"
echo "Asennus valmis."
echo "Käynnistimet on luotu työpöydälle:"
echo "  - DiKi-koneen tiedot"
echo "  - Kattava HardInfo"
echo
echo "Voit kokeilla päätteessä komennoilla:"
echo
echo "  konetiedot"
echo "  hardinfo"
echo
echo "Sarjanumero on tallennettu tiedostoon:"
echo "  $DIKI/tiedot/perustiedot.json"