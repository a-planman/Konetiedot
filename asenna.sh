#!/bin/bash

set -e

DIKI="$HOME/diki"

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

echo "Luodaan työpöydän käynnistin..."

cat > "$HOME/Työpöytä/konetiedot.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DiKi-koneen tiedot
Comment=Näyttää DiKi-koneen tiedot
Exec=konetiedot
Icon=$DIKI/kuvat/diki-logo.png
Terminal=false
Categories=Utility;
EOF

chmod +x "$HOME/Työpöytä/konetiedot.desktop"

echo "--------------------------------"
echo "Asennus valmis."
echo "Käynnistin on luotu työpöydälle."
echo "Voit kokeilla myös päätteessä komennolla:"
echo
echo "  konetiedot"
echo