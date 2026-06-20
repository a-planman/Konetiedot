#!/bin/bash

set -e

PAKETTI_NIMI="konetiedot-asennus"
JAKELU="jakelu"
PAKETTI="$JAKELU/$PAKETTI_NIMI"
ZIP_TIEDOSTO="$JAKELU/$PAKETTI_NIMI.zip"

echo "Luodaan jakelupaketti..."
echo "--------------------------------"

echo "Tarkistetaan tarvittavat tiedostot..."

[ -f "asenna.sh" ] || { echo "VIRHE: asenna.sh puuttuu"; exit 1; }
[ -f "ohjelmat/konetiedot.py" ] || { echo "VIRHE: ohjelmat/konetiedot.py puuttuu"; exit 1; }
[ -f "kuvat/diki-logo.png" ] || { echo "VIRHE: kuvat/diki-logo.png puuttuu"; exit 1; }
[ -f "tiedot/perustiedot.json" ] || { echo "VIRHE: tiedot/perustiedot.json puuttuu"; exit 1; }

echo "Kaikki tarvittavat tiedostot löytyivät."
echo "--------------------------------"

echo "Poistetaan vanha jakelukansio ja zip-tiedosto..."

rm -rf "$PAKETTI"
rm -f "$ZIP_TIEDOSTO"

echo "Luodaan puhdas pakettirakenne..."

mkdir -p "$PAKETTI/ohjelmat"
mkdir -p "$PAKETTI/kuvat"
mkdir -p "$PAKETTI/tiedot"
mkdir -p "$PAKETTI/tulokset"

echo "Kopioidaan tiedostot pakettiin..."

cp -v asenna.sh "$PAKETTI/"
cp -v ohjelmat/konetiedot.py "$PAKETTI/ohjelmat/"
cp -v kuvat/diki-logo.png "$PAKETTI/kuvat/"
cp -v tiedot/perustiedot.json "$PAKETTI/tiedot/"

echo "Luodaan README.txt..."

cat > "$PAKETTI/README.txt" <<EOF
DiKi-koneen tiedot
==================

Tämä paketti asentaa DiKi-koneen tiedot -ohjelman Linux Mint -koneelle.

Asennusohje
-----------

1. Pura zip-tiedosto.

2. Avaa purettu kansio:

   konetiedot-asennus

3. Avaa pääte kyseisessä kansiossa:

   - Napsauta hiiren oikealla kansiossa olevaa tyhjää kohtaa.
   - Valitse "Avaa päätteessä".

4. Anna asennusskriptille suoritusoikeus:

   chmod +x asenna.sh

5. Suorita asennus:

   ./asenna.sh

6. Asennuksen jälkeen työpöydälle tulee kuvakkeet:

   - DiKi-koneen tiedot
   - Kattava HardInfo

7. Ohjelman voi käynnistää myös päätteessä:

   konetiedot

PDF-konekortit
--------------

PDF-konekortit tallentuvat kansioon:

   ~/diki/tulokset/

Vinkki
------

Jos et ole aiemmin käyttänyt Linuxin päätettä, helpoin tapa
on avata ensin haluttu kansio ja valita hiiren oikealla:

   "Avaa päätteessä"

Tällöin ei tarvitse kirjoittaa cd-komentoja eikä etsiä
kansion sijaintia käsin.

DiKi ry
EOF

echo "--------------------------------"
echo "Tarkistetaan paketin sisältö..."

find "$PAKETTI" -maxdepth 3 -type f -o -type d

echo "--------------------------------"
echo "Pakataan zip-tiedostoksi..."

cd "$JAKELU"
zip -r "$PAKETTI_NIMI.zip" "$PAKETTI_NIMI"
cd ..

echo "--------------------------------"
echo "Jakelupaketti valmis:"
echo "$ZIP_TIEDOSTO"
echo
echo "Tämä zip-tiedosto voidaan siirtää Google Driveen."