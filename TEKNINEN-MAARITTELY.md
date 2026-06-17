# Konetiedot-projekti

## Tekninen määrittely v0.1
## Ahti Planman 17.6.2026

### Tavoite

Konetiedot-projektin tarkoituksena on helpottaa DiKi ry:n käytössä olevien Linux Mint -tietokoneiden kortistointia ja ylläpitoa.

Ohjelma:

- näyttää koneen keskeiset tekniset tiedot
- näyttää ylläpidon perustiedot
- muodostaa PDF-muotoisen konekortin
- toimii tavallisella käyttäjätunnuksella
- voidaan siirtää helposti uudelle koneelle

---

## Hakemistorakenne

Asennuksen jälkeen käyttäjän kotihakemistossa sijaitsee kansio:

```text
~/diki
```

Sen rakenne:

```text
diki/
├── ohjelmat/
│   └── konetiedot.py
├── kuvat/
│   └── diki-logo.png
├── tiedot/
│   └── perustiedot.json
└── tulokset/
```

---

## Tiedostojen tarkoitus

### konetiedot.py

Varsinainen GTK-sovellus.

Tehtävät:

- kerää järjestelmätiedot
- näyttää tiedot käyttäjälle
- muodostaa PDF-konekortin

### perustiedot.json

Ylläpidon ylläpitämä tiedosto.

Sisältää esimerkiksi:

- laitetunnus
- koneen nimi
- hankintavuosi
- käyttötarkoitus
- status

Asennuksen yhteydessä ohjelma täydentää tiedostoon koneen sarjanumeron.

---

## Käynnistys

Työpöydälle luodaan automaattisesti käynnistin:

```text
DiKi Koneen tiedot
```

Käynnistin suorittaa komennon:

```text
konetiedot
```

---

## Yhteinen käynnistyskomento

Asennus luo tiedoston:

```text
/usr/local/bin/konetiedot
```

Sisältö:

```bash
#!/bin/bash
python3 "$HOME/diki/ohjelmat/konetiedot.py"
```

Ratkaisu poistaa tarpeen käyttää käyttäjänimeä työpöydän käynnistimessä.

---

## Asennusohjelma

Asennus suoritetaan komennolla:

```bash
chmod +x asenna.sh
./asenna.sh
```

Asennusohjelma:

1. luo kansiorakenteen
2. asentaa tarvittavat paketit
3. kopioi tiedostot oikeisiin paikkoihin
4. luo työpöydän käynnistimen
5. luo yhteisen käynnistyskomennon
6. hakee sarjanumeron
7. tallettaa sarjanumeron perustietoihin

---

## Asennettavat paketit

```text
python3
python3-gi
gir1.2-gtk-3.0
python3-cairo
python3-reportlab
hardinfo
dmidecode
```

---

## Asennuspaketin rakenne

Asennuspaketti sisältää seuraavat tiedostot:

```text
diki/
├── asenna.sh
├── ohjelmat/
│   └── konetiedot.py
├── kuvat/
│   └── diki-logo.png
└── tiedot/
    └── perustiedot.json
```

Työpöydän käynnistin luodaan automaattisesti asennuksen aikana eikä sitä säilytetä asennuspaketissa.

---

## Jatkokehitys

### Vaihe 2

Asennusohjelma kysyy käyttäjältä:

- laitetunnuksen
- koneen nimen
- hankintavuoden
- käyttötarkoituksen

ja päivittää perustiedot automaattisesti.

### Vaihe 3

Täysin automaattinen käyttöönotto:

1. käyttäjä purkaa diki-paketin
2. suorittaa komennon `./asenna.sh`
3. kone on käyttövalmis

---

## Muutoshistoria

### v0.1

Ensimmäinen tekninen määrittely.

Sisältää:

- hakemistorakenteen
- asennusohjelman periaatteen
- käynnistinratkaisun
- yhteisen käynnistyskomennon
- riippuvuuksien asennuksen
- sarjanumeron automaattisen tallennuksen