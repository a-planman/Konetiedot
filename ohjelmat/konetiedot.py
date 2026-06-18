#!/usr/bin/env python3
import subprocess
import json
from pathlib import Path
from datetime import datetime

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GdkPixbuf

from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas


HOME = Path.home()
DIKI = HOME / "diki"
LOGO = DIKI / "kuvat" / "diki-logo.png"
PERUSDATA = DIKI / "tiedot" / "perustiedot.json"
TULOKSET = DIKI / "tulokset"


def aja(komento):
    try:
        return subprocess.check_output(
            komento, shell=True, text=True, stderr=subprocess.DEVNULL
        ).strip()
    except Exception:
        return ""


def lue_tiedosto(polku):
    try:
        return Path(polku).read_text().strip()
    except Exception:
        return ""


def lue_perusdata():
    try:
        with open(PERUSDATA, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def tieto(arvo):
    return arvo if arvo else "Ei tiedossa"


def hae_muisti_gb():
    rivi = aja("free -g | awk '/Mem:/ {print $2}'")
    try:
        return int(rivi)
    except Exception:
        return 0


def hae_muisti():
    return tieto(aja("free -h | awk '/Mem:/ {print $2}'"))


def hae_levy():
    return tieto(aja("df -h / | awk 'NR==2 {print $2}'"))


def hae_levy_vapaa():
    return tieto(aja("df -h / | awk 'NR==2 {print $4}'"))


def hae_akku():
    akut = list(Path("/sys/class/power_supply").glob("BAT*"))
    if not akut:
        return "Ei akkua", "Ei akkua", "Ei akkua", None

    akku = akut[0]

    tila = lue_tiedosto(akku / "status")
    kapasiteetti = lue_tiedosto(akku / "capacity")

    if tila and kapasiteetti:
        akun_tilanne = f"{tila}, {kapasiteetti} %"
    elif kapasiteetti:
        akun_tilanne = f"{kapasiteetti} %"
    else:
        akun_tilanne = "Ei tiedossa"

    energy_full = lue_tiedosto(akku / "energy_full") or lue_tiedosto(akku / "charge_full")
    energy_design = lue_tiedosto(akku / "energy_full_design") or lue_tiedosto(akku / "charge_full_design")

    akun_kunto_pros = None
    try:
        akun_kunto_pros = round(int(energy_full) / int(energy_design) * 100)
        akun_kunto = f"{akun_kunto_pros} % alkuperäisestä"
    except Exception:
        akun_kunto = "Ei tiedossa"

    energy_now = lue_tiedosto(akku / "energy_now") or lue_tiedosto(akku / "charge_now")
    power_now = lue_tiedosto(akku / "power_now") or lue_tiedosto(akku / "current_now")

    try:
        tunnit = int(energy_now) / int(power_now)
        h = int(tunnit)
        minuutit = round((tunnit - h) * 60)
        kayttoaika = f"noin {h} h {minuutit} min"
    except Exception:
        kayttoaika = "Ei tiedossa"

    return akun_tilanne, akun_kunto, kayttoaika, akun_kunto_pros


def arvioi_kaytettavyys(muisti_gb, akun_kunto_pros):
    if muisti_gb >= 8:
        arvio = "Hyvä Linux-kone peruskäyttöön."
    elif muisti_gb >= 4:
        arvio = "Käyttökelpoinen Linux-kone kevyeen peruskäyttöön."
    elif muisti_gb >= 2:
        arvio = "Välttävä Linux-kone vain kevyeen käyttöön."
    else:
        arvio = "Heikko Linux-kone nykykäyttöön."

    if akun_kunto_pros is None:
        kayttoika = "Turvallinen käyttöikä: arviolta 1–2 vuotta, tarkista akku erikseen."
    elif akun_kunto_pros >= 70:
        kayttoika = "Turvallinen käyttöikä: arviolta 2–4 vuotta."
    elif akun_kunto_pros >= 50:
        kayttoika = "Turvallinen käyttöikä: arviolta 1–2 vuotta, akku alkaa olla kulunut."
    else:
        kayttoika = "Turvallinen käyttöikä: arviolta enintään 1 vuosi, akun kunto vaatii huomiota."

    return arvio, kayttoika


def hae_tiedot():
    perusdata = lue_perusdata()
    akun_tilanne, akun_kunto, kayttoaika, akun_kunto_pros = hae_akku()
    muisti_gb = hae_muisti_gb()
    arvio, kayttoika = arvioi_kaytettavyys(muisti_gb, akun_kunto_pros)

    tiedot = [
        ("Laitetunnus:", tieto(perusdata.get("laitetunnus"))),
        ("Hostname:", tieto(perusdata.get("hostname") or aja("hostname"))),
        ("Valmistaja:", tieto(lue_tiedosto("/sys/class/dmi/id/sys_vendor"))),
        ("Malli:", tieto(lue_tiedosto("/sys/class/dmi/id/product_name"))),
        ("Sarjanumero:", tieto(perusdata.get("sarjanumero"))),
        ("Omistaja:", tieto(perusdata.get("omistaja"))),
        ("Käyttäjä:", tieto(perusdata.get("kayttaja"))),
        ("Sijainti:", tieto(perusdata.get("sijainti"))),
        ("Käyttötarkoitus:", tieto(perusdata.get("kayttotarkoitus"))),
        ("Status:", tieto(perusdata.get("status"))),
        ("Valmistusvuosi:", tieto(perusdata.get("valmistusvuosi"))),
        ("Hankintavuosi:", tieto(perusdata.get("hankintavuosi"))),
        ("Kokoonpano:", tieto(perusdata.get("kokoonpano"))),
        ("Huomautukset:", tieto(perusdata.get("huomautukset"))),
        ("BIOS-päivä:", tieto(lue_tiedosto("/sys/class/dmi/id/bios_date"))),
        ("Muisti:", hae_muisti()),
        ("Levy:", hae_levy()),
        ("Levyä vapaana:", hae_levy_vapaa()),
        ("Akun tilanne:", akun_tilanne),
        ("Akun kunto:", akun_kunto),
        ("Arvioitu käyttöaika:", kayttoaika),
    ]

    return tiedot, arvio, kayttoika


def tallenna_pdf(tiedot, arvio, kayttoika):
    TULOKSET.mkdir(parents=True, exist_ok=True)

    laitetunnus = "tuntematon"
    for nimi, arvo in tiedot:
        if nimi == "Laitetunnus:" and arvo != "Ei tiedossa":
            laitetunnus = arvo

    pvm = datetime.now().strftime("%Y-%m-%d")
    tiedostonimi = f"konekortti-{laitetunnus}-{pvm}.pdf"
    polku = TULOKSET / tiedostonimi

    c = canvas.Canvas(str(polku), pagesize=A4)
    leveys, korkeus = A4
    y = korkeus - 60

    if LOGO.exists():
        c.drawImage(str(LOGO), 230, y - 55, width=120, height=60, preserveAspectRatio=True, mask="auto")
        y -= 90

    c.setFont("Helvetica-Bold", 18)
    c.drawString(70, y, "DiKi-koneen tiedot")
    y -= 35

    c.setFont("Helvetica", 11)
    c.drawString(70, y, f"Tulostuspäivä: {pvm}")
    y -= 30

    for nimi, arvo in tiedot:
        c.setFont("Helvetica-Bold", 11)
        c.drawString(70, y, nimi)
        c.setFont("Helvetica", 11)
        c.drawString(210, y, str(arvo))
        y -= 20

        if y < 70:
            c.showPage()
            y = korkeus - 60

    y -= 15
    c.setFont("Helvetica-Bold", 12)
    c.drawString(70, y, "Arvio")
    y -= 22

    c.setFont("Helvetica", 11)
    c.drawString(70, y, arvio)
    y -= 18
    c.drawString(70, y, kayttoika)

    c.save()
    return polku


class Ikkuna(Gtk.Window):
    def __init__(self):
        super().__init__(title="DiKi - koneen tiedot")
        self.set_default_size(700, 760)
        self.set_border_width(20)

        self.tiedot, self.arvio, self.kayttoika = hae_tiedot()

        laatikko = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.add(laatikko)

        if LOGO.exists():
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                str(LOGO), width=120, height=80, preserve_aspect_ratio=True
            )
            logo = Gtk.Image.new_from_pixbuf(pixbuf)
            laatikko.pack_start(logo, False, False, 0)

        otsikko = Gtk.Label()
        otsikko.set_markup("<span size='x-large' weight='bold'>DiKi-koneen tiedot</span>")
        laatikko.pack_start(otsikko, False, False, 0)

        ruudukko = Gtk.Grid()
        ruudukko.set_column_spacing(25)
        ruudukko.set_row_spacing(8)
        laatikko.pack_start(ruudukko, False, False, 0)

        for rivi, (nimi, arvo) in enumerate(self.tiedot):
            nimi_label = Gtk.Label(label=nimi)
            nimi_label.set_xalign(0)

            arvo_label = Gtk.Label(label=str(arvo))
            arvo_label.set_xalign(0)
            arvo_label.set_selectable(True)

            ruudukko.attach(nimi_label, 0, rivi, 1, 1)
            ruudukko.attach(arvo_label, 1, rivi, 1, 1)

        arvio_label = Gtk.Label()
        arvio_label.set_xalign(0)
        arvio_label.set_line_wrap(True)
        arvio_label.set_markup(
            f"<b>Arvio:</b> {self.arvio}\n<b>{self.kayttoika}</b>"
        )
        laatikko.pack_start(arvio_label, False, False, 10)

        nappi = Gtk.Button(label="Tallenna PDF-konekortti")
        nappi.connect("clicked", self.tallenna_pdf_painettu)
        laatikko.pack_start(nappi, False, False, 5)

    def tallenna_pdf_painettu(self, painike):
        try:
            polku = tallenna_pdf(self.tiedot, self.arvio, self.kayttoika)
            viesti = f"PDF tallennettu:\n{polku}"
            tyyppi = Gtk.MessageType.INFO
        except Exception as virhe:
            viesti = f"PDF-tallennus epäonnistui:\n{virhe}"
            tyyppi = Gtk.MessageType.ERROR

        ilmoitus = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=tyyppi,
            buttons=Gtk.ButtonsType.OK,
            text=viesti,
        )
        ilmoitus.run()
        ilmoitus.destroy()


ikkuna = Ikkuna()
ikkuna.connect("destroy", Gtk.main_quit)
ikkuna.show_all()
Gtk.main()