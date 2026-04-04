// email_templates.dart
// Legal email templates for 15 EU countries in local languages.
// Types: appeal (deportation), legal_aid, labor_complaint.
// Generated for Advocat project.

class EmailTemplate {
  final String country;
  final String type; // 'appeal', 'legal_aid', 'labor_complaint'
  final String subject;
  final String body;
  final String recipientHint;
  final String language;

  const EmailTemplate({
    required this.country,
    required this.type,
    required this.subject,
    required this.body,
    required this.recipientHint,
    required this.language,
  });
}

class EmailTemplateRepository {
  static const List<EmailTemplate> allTemplates = [
    // =========================================================================
    // FINLAND (FI) — Finnish
    // =========================================================================
    EmailTemplate(
      country: 'FI',
      type: 'appeal',
      language: 'fi',
      subject: 'Valitus karkottamispäätöksestä — [Nimi], [Asianumero]',
      recipientHint: 'hallinto-oikeus@oikeus.fi',
      body: '''Hallinto-oikeus
[Hallinto-oikeuden nimi]
[Osoite]

Asia: Valitus Maahanmuuttoviraston päätöksestä
Asianumero: [Asianumero]
Päätöspäivämäärä: [Päivämäärä]

Valittaja:
[Koko nimi]
Syntymäaika: [pp.kk.vvvv]
Osoite: [Osoite Suomessa]
Puhelin: [Puhelinnumero]
Sähköposti: [Sähköposti]

Vaatimukset:

1. Maahanmuuttoviraston päätös [Asianumero] kumotaan.
2. Valittajalle myönnetään oleskelulupa ulkomaalaislain [pykälä] §:n perusteella.
3. Toissijaisesti asia palautetaan Maahanmuuttovirastolle uudelleen käsiteltäväksi.
4. Päätöksen täytäntöönpano kielletään valituksen käsittelyn ajaksi (ulkomaalaislaki 200 §).

Perusteet:

Maahanmuuttoviraston päätös on lainvastainen seuraavilla perusteilla:

1. Perusoikeudet ja ihmisoikeudet
Päätöksessä ei ole otettu riittävästi huomioon Euroopan ihmisoikeussopimuksen 8 artiklaa (oikeus yksityis- ja perhe-elämän kunnioitukseen). Valittajalla on Suomessa [perhesuhteet/siteet], joita päätös loukkaa.

2. Suhteellisuusperiaate
Karkottaminen on suhteetonta ottaen huomioon valittajan olosuhteet: [Kuvaile olosuhteet, esim. perhesiteet, työsuhde, opiskelut, terveydentila, Suomessa asuttu aika].

3. Virheellinen tosiseikkojen arviointi
Maahanmuuttovirasto on arvioinut seuraavat tosiseikat virheellisesti: [Kuvaile virheelliset arvioinnit].

4. Palautuskielto (non-refoulement)
Valittajan palauttaminen [Kohdemaa] olisi vastoin ulkomaalaislain 147 §:ää, koska [Selitä vaara].

Liitteet:
1. Valituksenalainen päätös (kopio)
2. [Luettele muut liitteet: todistukset, lääkärinlausunnot, työtodistukset jne.]

Päiväys: [Päivämäärä]

Kunnioittavasti,

[Allekirjoitus]
[Koko nimi]''',
    ),
    EmailTemplate(
      country: 'FI',
      type: 'legal_aid',
      language: 'fi',
      subject: 'Oikeusapuhakemus — [Nimi]',
      recipientHint: 'oikeusapu@oikeus.fi',
      body: '''Oikeusaputoimisto
[Oikeusaputoimiston nimi]
[Osoite]

Asia: Hakemus oikeusavun myöntämiseksi

Hakija:
[Koko nimi]
Henkilötunnus/syntymäaika: [Henkilötunnus tai pp.kk.vvvv]
Osoite: [Osoite]
Puhelin: [Puhelinnumero]
Sähköposti: [Sähköposti]
Kansalaisuus: [Kansalaisuus]
Oleskelulupa: [Oleskeluluvan tyyppi ja voimassaolo]

Pyydän oikeusapua seuraavaan asiaan:

Asia, johon oikeusapua haetaan:
[Kuvaile asia: esim. valitus karkottamispäätöksestä, oleskelulupa-asia, työsyrjintäasia]

Asian laatu: [Hallinto-oikeudellinen / Siviilioikeudellinen / Rikosoikeudellinen]

Vastapuoli: [Maahanmuuttovirasto / Työnantajan nimi / Muu]

Asian tila: [Kuvaile missä vaiheessa asia on]

Taloudelliset olosuhteet:
- Kuukausitulot (brutto): [Euroa]
- Kuukausitulot (netto): [Euroa]
- Omaisuus: [Kuvaile]
- Velat: [Kuvaile]
- Elatusvelvollisuudet: [Kuvaile]
- Asumismenot: [Euroa/kk]

Liitän hakemukseen seuraavat asiakirjat:
1. Kopio päätöksestä, jota asia koskee
2. Selvitys tuloista (palkkatodistus / Kelan päätös / muu)
3. Selvitys varallisuudesta
4. [Muut liitteet]

Huomautus: Hakijana olen ulkomaan kansalainen ja haen oikeusapua oikeusapulain 2 §:n perusteella. EU-kansalaisilla ja Suomessa asuvilla on oikeus oikeusapuun samoin edellytyksin kuin Suomen kansalaisilla.

Päiväys: [Päivämäärä]

Kunnioittavasti,

[Allekirjoitus]
[Koko nimi]''',
    ),
    EmailTemplate(
      country: 'FI',
      type: 'labor_complaint',
      language: 'fi',
      subject: 'Valitus työnantajasta — [Työnantajan nimi], [Nimi]',
      recipientHint: 'tyosuojelu@avi.fi',
      body: '''Aluehallintovirasto
Työsuojelun vastuualue
[Aluehallintoviraston nimi]
[Osoite]

Asia: Valitus työnantajan lainvastaisesta menettelystä

Valituksen tekijä:
[Koko nimi]
Syntymäaika: [pp.kk.vvvv]
Osoite: [Osoite]
Puhelin: [Puhelinnumero]
Sähköposti: [Sähköposti]
Ammatti/tehtävänimike: [Tehtävänimike]

Työnantaja:
Yrityksen nimi: [Työnantajan nimi]
Y-tunnus: [Y-tunnus]
Osoite: [Työnantajan osoite]
Toimiala: [Toimiala]

Työsuhteen tiedot:
Työsuhteen alkamispäivä: [Päivämäärä]
Työsuhteen päättymispäivä (jos päättynyt): [Päivämäärä]
Työsopimuksen tyyppi: [Toistaiseksi voimassa oleva / Määräaikainen]
Sovellettava työehtosopimus: [TES:n nimi]

Valituksen perusteet:

1. Palkkasaatavat
Työnantaja ei ole maksanut palkkaa työsopimuslain ja sovellettavan työehtosopimuksen mukaisesti. Maksamatta olevat saatavat:
- [Kuvaile maksamattomat palkat, ylityökorvaukset, lomarahat jne.]
- Yhteensä: [Euroa]

2. Työaikalainsäädännön rikkominen
[Kuvaile: liiallinen ylityö, lepoaikojen noudattamatta jättäminen, työaikakirjanpidon puutteet]

3. Työturvallisuuspuutteet
[Kuvaile: puutteet työturvallisuudessa, suojavarusteiden puute, vaaralliset työolosuhteet]

4. Syrjintä/epäasiallinen kohtelu
[Kuvaile: ulkomaalaistaustaan perustuva syrjintä, häirintä, epäasiallinen kohtelu]

5. Laiton irtisanominen / työsuhteen päättäminen
[Kuvaile: lainvastainen irtisanominen, perusteettomuus, menettelyvirheet]

Vaatimukset:
1. Työsuojelutarkastuksen suorittaminen työnantajan toimipaikassa.
2. Työnantajan velvoittaminen maksamaan saatavat korkoineen.
3. Mahdollisten hallinnollisten seuraamusten määrääminen.

Liitteet:
1. Työsopimus (kopio)
2. Palkkakuitit
3. Työaikakirjanpito (jos saatavilla)
4. Kirjeenvaihto työnantajan kanssa
5. [Muut todisteet]

Päiväys: [Päivämäärä]

Kunnioittavasti,

[Allekirjoitus]
[Koko nimi]''',
    ),

    // =========================================================================
    // ESTONIA (EE) — Estonian
    // =========================================================================
    EmailTemplate(
      country: 'EE',
      type: 'appeal',
      language: 'et',
      subject: 'Vaie väljasaatmisotsuse peale — [Nimi], [Toimiku number]',
      recipientHint: 'info@halduskohus.ee',
      body: '''Tallinna Halduskohus
[Kohtu aadress]

Kaebus haldusakti tühistamiseks

Kaebuse esitaja (kaebaja):
[Täisnimi]
Isikukood/sünniaeg: [Isikukood või sünniaeg]
Aadress: [Aadress Eestis]
Telefon: [Telefoninumber]
E-post: [E-posti aadress]
Kodakondsus: [Kodakondsus]

Vastustaja:
Politsei- ja Piirivalveamet
Pärnu mnt 139, 15060 Tallinn

Vaidlustatav haldusakt:
Politsei- ja Piirivalveameti otsus nr [Otsuse number], [Kuupäev], millega otsustati kaebaja väljasaatmine Eesti Vabariigist.

Kaebaja nõuded:
1. Tühistada Politsei- ja Piirivalveameti otsus nr [Otsuse number] kui õigusvastane.
2. Kohustada Politsei- ja Piirivalveametit andma kaebajale elamisluba [alus].
3. Peatada vaidlustatud otsuse täitmine kuni kohtuotsuse jõustumiseni (HKMS § 249).

Kaebuse põhjendus:

1. Eraelu ja pereelu kaitse
Otsus rikub Euroopa inimõiguste ja põhivabaduste kaitse konventsiooni artiklit 8 ning Eesti Vabariigi põhiseaduse §-i 26. Kaebajal on Eestis [perekondlikud sidemed, töö, õpingud], mis nõuavad kaitset.

2. Proportsionaalsuse põhimõtte rikkumine
Väljasaatmine on ebaproportsionaalne meede, arvestades kaebaja isiklikke asjaolusid: [Kirjeldage asjaolusid].

3. Faktiliste asjaolude vale hindamine
PPA on hinnanud järgmisi asjaolusid valesti: [Kirjeldage].

4. Non-refoulement põhimõte
Kaebaja tagasisaatmine [Sihtriik] oleks vastuolus välismaalaste seaduse §-ga 171, kuna [Selgitage ohtu].

Lisad:
1. Vaidlustatud otsuse koopia
2. [Loetlege muud lisad: tõendid, arstitõendid, töölepingud jne.]
3. Riigilõivu tasumise tõend

Kuupäev: [Kuupäev]

Lugupidamisega,

[Allkiri]
[Täisnimi]''',
    ),
    EmailTemplate(
      country: 'EE',
      type: 'legal_aid',
      language: 'et',
      subject: 'Riigi õigusabi taotlus — [Nimi]',
      recipientHint: 'info@kohus.ee',
      body: '''[Kohtu nimi]
[Kohtu aadress]

Riigi õigusabi taotlus

Taotleja:
[Täisnimi]
Isikukood/sünniaeg: [Isikukood või sünniaeg]
Aadress: [Aadress]
Telefon: [Telefoninumber]
E-post: [E-posti aadress]
Kodakondsus: [Kodakondsus]
Elamisloa staatus: [Elamisloa tüüp ja kehtivus]

Taotlen riigi õigusabi järgmises asjas:

Asi, milles õigusabi taotletakse:
[Kirjeldage asi: nt kaebus väljasaatmisotsuse peale, elamisloa asi, töövaidlus]

Asja liik: [Haldusasi / Tsiviilasi / Kriminaalasi]

Vastaspool: [Politsei- ja Piirivalveamet / Tööandja nimi / Muu]

Asja staadium: [Kirjeldage, millises staadiumis asi on]

Majanduslik olukord:
- Igakuine sissetulek (bruto): [Eurot]
- Igakuine sissetulek (neto): [Eurot]
- Vara: [Kirjeldage]
- Võlad: [Kirjeldage]
- Ülalpeetavad: [Kirjeldage]
- Eluasemekulud: [Eurot/kuus]

Riigi õigusabi taotlemise alus:
Vastavalt riigi õigusabi seaduse §-le 6 ei ole taotleja võimeline tasuma õigusteenuse eest oma majanduslikust olukorrast tulenevalt. Ilma riigi õigusabita ei ole taotlejal võimalik oma õigusi kaitsta.

Lisad:
1. Vaidlustatava otsuse koopia
2. Sissetulekut tõendav dokument
3. Varalise seisundi tõend
4. [Muud lisad]

Kuupäev: [Kuupäev]

Lugupidamisega,

[Allkiri]
[Täisnimi]''',
    ),
    EmailTemplate(
      country: 'EE',
      type: 'labor_complaint',
      language: 'et',
      subject: 'Kaebus tööandja vastu — [Tööandja nimi], [Nimi]',
      recipientHint: 'info@ti.ee',
      body: '''Tööinspektsioon
Gonsiori 29, 10147 Tallinn

Kaebus tööandja õigusvastase tegevuse kohta

Kaebuse esitaja:
[Täisnimi]
Isikukood/sünniaeg: [Isikukood või sünniaeg]
Aadress: [Aadress]
Telefon: [Telefoninumber]
E-post: [E-posti aadress]
Amet/ametinimetus: [Ametinimetus]

Tööandja:
Ettevõtte nimi: [Tööandja nimi]
Registrikood: [Registrikood]
Aadress: [Tööandja aadress]
Tegevusala: [Tegevusala]

Töösuhte andmed:
Töösuhte algus: [Kuupäev]
Töösuhte lõpp (kui lõppenud): [Kuupäev]
Töölepingu tüüp: [Tähtajatu / Tähtajaline]

Kaebuse sisu:

1. Palgavõlgnevus
Tööandja ei ole maksnud töötasu töölepingu seaduse ja kehtiva kollektiivlepingu kohaselt.
- [Kirjeldage maksmata palgad, ületunnitasud, puhkusetasud jne.]
- Kokku: [Eurot]

2. Tööajaseaduse rikkumine
[Kirjeldage: ülemäärane ületunnitöö, puhkeaja nõuete rikkumine, tööajakirjanpidamise puudumine]

3. Tööohutuse ja töötervishoiu nõuete rikkumine
[Kirjeldage: puudused tööohutuses, kaitsevahendite puudumine, ohtlikud töötingimused]

4. Diskrimineerimine/ebavõrdne kohtlemine
[Kirjeldage: päritolul põhinev diskrimineerimine, ahistamine, ebavõrdne kohtlemine]

5. Ebaseaduslik töölepingu ülesütlemine
[Kirjeldage: seadusevastane ülesütlemine, aluse puudumine, menetlusvead]

Nõuded:
1. Tööinspektsiooni järelevalvemenetluse algatamine.
2. Tööandja kohustamine tasuma võlgnevused koos intressidega.
3. Vajadusel ettekirjutuse tegemine tööandjale.

Lisad:
1. Töölepingu koopia
2. Palgalehed
3. Tööajakirjanpidamise andmed (kui olemas)
4. Kirjavahetus tööandjaga
5. [Muud tõendid]

Kuupäev: [Kuupäev]

Lugupidamisega,

[Allkiri]
[Täisnimi]''',
    ),

    // =========================================================================
    // GERMANY (DE) — German
    // =========================================================================
    EmailTemplate(
      country: 'DE',
      type: 'appeal',
      language: 'de',
      subject: 'Klage gegen Abschiebungsbescheid — [Name], Az. [Aktenzeichen]',
      recipientHint: 'verwaltungsgericht@justiz.de',
      body: '''An das
Verwaltungsgericht [Stadt]
[Adresse]

Klage

des/der [Vollständiger Name], geboren am [Geburtsdatum],
wohnhaft: [Adresse in Deutschland],
Staatsangehörigkeit: [Staatsangehörigkeit],

— Kläger/in —

Prozessbevollmächtigte/r: [Anwalt, falls vorhanden]

gegen

die Bundesrepublik Deutschland, vertreten durch das
Bundesamt für Migration und Flüchtlinge (BAMF),
[Adresse des zuständigen BAMF]

— Beklagte —

wegen: Abschiebungsandrohung / Ausweisungsverfügung

Aktenzeichen des Bescheids: [Aktenzeichen]
Bescheiddatum: [Datum]
Zustellungsdatum: [Datum]

Anträge:

1. Der Bescheid des Bundesamtes für Migration und Flüchtlinge vom [Datum], Az. [Aktenzeichen], wird aufgehoben.
2. Die Beklagte wird verpflichtet, dem Kläger/der Klägerin eine Aufenthaltserlaubnis gemäß § [Paragraph] AufenthG zu erteilen.
3. Hilfsweise wird die Beklagte verpflichtet, den Antrag unter Beachtung der Rechtsauffassung des Gerichts neu zu bescheiden.
4. Es wird die aufschiebende Wirkung der Klage gemäß § 80 Abs. 5 VwGO angeordnet.

Begründung:

I. Sachverhalt
[Darstellung des Sachverhalts: Einreise, Aufenthalt, familiäre Situation, berufliche Situation, bisheriges Verfahren]

II. Rechtliche Würdigung

1. Verstoß gegen Art. 8 EMRK (Recht auf Privat- und Familienleben)
Der angefochtene Bescheid verletzt das Recht des Klägers/der Klägerin auf Achtung des Privat- und Familienlebens. [Begründung: familiäre Bindungen, Integration, Aufenthaltsdauer]

2. Verstoß gegen den Grundsatz der Verhältnismäßigkeit
Die Abschiebung ist unverhältnismäßig, da [Begründung: persönliche Umstände, Integration, Härtefall].

3. Fehlerhafte Sachverhaltsermittlung
Die Behörde hat folgende Tatsachen nicht oder fehlerhaft berücksichtigt: [Darstellung].

4. Abschiebungsverbote gemäß § 60 AufenthG
Es bestehen Abschiebungsverbote, da dem Kläger/der Klägerin im Zielstaat [Gefahr/Bedrohung] droht.

III. Eilantrag
Es wird beantragt, die aufschiebende Wirkung der Klage anzuordnen, da bei Vollziehung der Abschiebung irreversible Nachteile drohen.

Anlagen:
1. Angefochtener Bescheid (Kopie)
2. [Weitere Anlagen: Nachweise, ärztliche Atteste, Arbeitsverträge usw.]

[Ort], den [Datum]

Mit freundlichen Grüßen,

[Unterschrift]
[Vollständiger Name]''',
    ),
    EmailTemplate(
      country: 'DE',
      type: 'legal_aid',
      language: 'de',
      subject: 'Antrag auf Prozesskostenhilfe — [Name]',
      recipientHint: 'verwaltungsgericht@justiz.de',
      body: '''An das
Verwaltungsgericht [Stadt]
[Adresse]

Antrag auf Bewilligung von Prozesskostenhilfe

Antragsteller/in:
[Vollständiger Name]
Geboren am: [Geburtsdatum]
Adresse: [Adresse]
Telefon: [Telefonnummer]
E-Mail: [E-Mail-Adresse]
Staatsangehörigkeit: [Staatsangehörigkeit]
Aufenthaltsstatus: [Art und Gültigkeit]

In der Verwaltungsstreitsache [Aktenzeichen, falls bekannt]

beantrage ich die Bewilligung von Prozesskostenhilfe gemäß §§ 166 VwGO i.V.m. §§ 114 ff. ZPO und die Beiordnung eines Rechtsanwalts.

Gegenstand des Verfahrens:
[Beschreibung: z.B. Klage gegen Abschiebungsbescheid, Aufenthaltserlaubnisverfahren, arbeitsrechtlicher Streit]

Gegner: [Bundesamt für Migration und Flüchtlinge / Arbeitgeber / Sonstige]

Verfahrensstand: [Beschreibung des aktuellen Stands]

Begründung der Erfolgsaussichten:
Die beabsichtigte Rechtsverfolgung hat hinreichende Aussicht auf Erfolg, da [kurze Begründung der Erfolgsaussichten].

Persönliche und wirtschaftliche Verhältnisse:
- Monatliches Bruttoeinkommen: [Euro]
- Monatliches Nettoeinkommen: [Euro]
- Vermögen: [Beschreibung]
- Schulden: [Beschreibung]
- Unterhaltspflichten: [Beschreibung]
- Wohnkosten: [Euro/Monat]
- Sonstige Belastungen: [Beschreibung]

Ich bin aufgrund meiner persönlichen und wirtschaftlichen Verhältnisse nicht in der Lage, die Kosten der Prozessführung aufzubringen. Ohne Prozesskostenhilfe wäre ich nicht in der Lage, meine Rechte wahrzunehmen.

Anlagen:
1. Erklärung über die persönlichen und wirtschaftlichen Verhältnisse (Formular)
2. Einkommensnachweise der letzten 3 Monate
3. Mietvertrag / Wohnkostennachweis
4. Kopie des angefochtenen Bescheids
5. [Weitere Anlagen]

[Ort], den [Datum]

Mit freundlichen Grüßen,

[Unterschrift]
[Vollständiger Name]''',
    ),
    EmailTemplate(
      country: 'DE',
      type: 'labor_complaint',
      language: 'de',
      subject: 'Beschwerde gegen Arbeitgeber — [Arbeitgebername], [Name]',
      recipientHint: 'poststelle@arbeitsschutz.de',
      body: '''Gewerbeaufsichtsamt / Amt für Arbeitsschutz
[Zuständige Behörde]
[Adresse]

Beschwerde wegen Verstößen gegen arbeitsrechtliche Vorschriften

Beschwerdeführer/in:
[Vollständiger Name]
Geboren am: [Geburtsdatum]
Adresse: [Adresse]
Telefon: [Telefonnummer]
E-Mail: [E-Mail-Adresse]
Beruf/Tätigkeit: [Berufsbezeichnung]

Arbeitgeber:
Firma: [Arbeitgebername]
Handelsregisternummer: [HRB-Nummer]
Adresse: [Adresse des Arbeitgebers]
Branche: [Branche]

Angaben zum Arbeitsverhältnis:
Beginn des Arbeitsverhältnisses: [Datum]
Ende des Arbeitsverhältnisses (falls beendet): [Datum]
Art des Arbeitsvertrags: [Unbefristet / Befristet]
Anwendbarer Tarifvertrag: [Tarifvertrag]

Gegenstand der Beschwerde:

1. Lohnrückstände
Der Arbeitgeber hat den Lohn nicht gemäß Arbeitsvertrag und geltendem Tarifvertrag gezahlt.
- [Beschreibung der ausstehenden Löhne, Überstundenvergütungen, Urlaubsgeld usw.]
- Gesamtbetrag: [Euro]

2. Verstöße gegen das Arbeitszeitgesetz
[Beschreibung: übermäßige Überstunden, Nichteinhaltung der Ruhezeiten, fehlende Arbeitszeiterfassung]

3. Verstöße gegen den Arbeitsschutz
[Beschreibung: Mängel im Arbeitsschutz, fehlende Schutzausrüstung, gefährliche Arbeitsbedingungen]

4. Diskriminierung / Benachteiligung
[Beschreibung: Diskriminierung aufgrund der Herkunft, Belästigung, Benachteiligung gem. AGG]

5. Rechtswidrige Kündigung
[Beschreibung: gesetzeswidrige Kündigung, fehlende Begründung, Verfahrensfehler]

Forderungen:
1. Durchführung einer Betriebsinspektion beim Arbeitgeber.
2. Verpflichtung des Arbeitgebers zur Zahlung der Rückstände nebst Zinsen.
3. Verhängung geeigneter Sanktionen bei festgestellten Verstößen.

Anlagen:
1. Arbeitsvertrag (Kopie)
2. Gehaltsabrechnungen
3. Arbeitszeitnachweis (falls vorhanden)
4. Schriftverkehr mit dem Arbeitgeber
5. [Weitere Nachweise]

[Ort], den [Datum]

Mit freundlichen Grüßen,

[Unterschrift]
[Vollständiger Name]''',
    ),

    // =========================================================================
    // SWEDEN (SE) — Swedish
    // =========================================================================
    EmailTemplate(
      country: 'SE',
      type: 'appeal',
      language: 'sv',
      subject: 'Överklagande av utvisningsbeslut — [Namn], [Diarienummer]',
      recipientHint: 'migrationsdomstolen@dom.se',
      body: '''Migrationsdomstolen vid
Förvaltningsrätten i [Stad]
[Adress]

Överklagande

Klagande:
[Fullständigt namn]
Personnummer/födelsedatum: [Personnummer eller födelsedatum]
Adress: [Adress i Sverige]
Telefon: [Telefonnummer]
E-post: [E-postadress]
Medborgarskap: [Medborgarskap]

Motpart:
Migrationsverket
[Adress till aktuellt kontor]

Överklagat beslut:
Migrationsverkets beslut den [Datum], diarienummer [Diarienummer], avseende avvisning/utvisning.

Yrkanden:

1. Migrationsverkets beslut den [Datum] upphävs.
2. Klaganden beviljas uppehållstillstånd enligt [kapitel och paragraf] utlänningslagen (2005:716).
3. I andra hand återförvisas ärendet till Migrationsverket för ny prövning.
4. Inhibition begärs, dvs. att beslutet inte verkställs under tiden överklagandet prövas (utlänningslagen 12 kap. 12 §).

Grunder:

1. Rätten till privat- och familjeliv
Beslutet strider mot artikel 8 i Europakonventionen om de mänskliga rättigheterna. Klaganden har i Sverige [familjeband/anknytning] som kräver skydd.

2. Proportionalitetsprincipen
Utvisningen är oproportionerlig med hänsyn till klagandens personliga omständigheter: [Beskriv omständigheter: familjeband, arbete, studier, hälsotillstånd, tid i Sverige].

3. Felaktig bedömning av sakförhållandena
Migrationsverket har felaktigt bedömt följande omständigheter: [Beskriv].

4. Verkställighetshinder (non-refoulement)
Ett återsändande av klaganden till [Destinationsland] skulle strida mot utlänningslagen 12 kap. 1-3 §§, eftersom [Förklara fara/hot].

Bilagor:
1. Kopia av överklagat beslut
2. [Lista övriga bilagor: intyg, läkarutlåtanden, anställningsbevis m.m.]

Datum: [Datum]

Med vänlig hälsning,

[Underskrift]
[Fullständigt namn]''',
    ),
    EmailTemplate(
      country: 'SE',
      type: 'legal_aid',
      language: 'sv',
      subject: 'Ansökan om rättshjälp — [Namn]',
      recipientHint: 'rattshjalpsmyndigheten@dom.se',
      body: '''Rättshjälpsmyndigheten / [Domstolens namn]
[Adress]

Ansökan om rättshjälp

Sökande:
[Fullständigt namn]
Personnummer/födelsedatum: [Personnummer eller födelsedatum]
Adress: [Adress]
Telefon: [Telefonnummer]
E-post: [E-postadress]
Medborgarskap: [Medborgarskap]
Uppehållstillstånd: [Typ och giltighetstid]

Jag ansöker om rättshjälp enligt rättshjälpslagen (1996:1619) i följande ärende:

Ärendet som rättshjälp söks för:
[Beskriv ärendet: t.ex. överklagande av utvisningsbeslut, uppehållstillståndsärende, arbetsrättsligt ärende]

Ärendets karaktär: [Förvaltningsrättsligt / Civilrättsligt / Straffrättsligt]

Motpart: [Migrationsverket / Arbetsgivarens namn / Annan]

Ärendets status: [Beskriv i vilket skede ärendet befinner sig]

Ekonomiska förhållanden:
- Årsinkomst (brutto): [Kronor]
- Årsinkomst (netto): [Kronor]
- Tillgångar: [Beskriv]
- Skulder: [Beskriv]
- Försörjningsplikt: [Beskriv]
- Boendekostnad: [Kronor/månad]

Ekonomiskt underlag:
Mitt ekonomiska underlag understiger 260 000 kr per år. Jag har inte möjlighet att själv bekosta juridiskt ombud. Rättshjälp är nödvändig för att jag ska kunna tillvarata mina rättigheter.

Rättshjälp har inte tidigare beviljats i detta ärende: [Ja/Nej]
Rådgivning enligt 4 § rättshjälpslagen har lämnats: [Ja/Nej, av vem]

Bilagor:
1. Kopia av det beslut som ärendet gäller
2. Inkomstintyg / Skattebesked
3. Förmögenhetsuppgifter
4. [Övriga bilagor]

Datum: [Datum]

Med vänlig hälsning,

[Underskrift]
[Fullständigt namn]''',
    ),
    EmailTemplate(
      country: 'SE',
      type: 'labor_complaint',
      language: 'sv',
      subject: 'Anmälan mot arbetsgivare — [Arbetsgivarens namn], [Namn]',
      recipientHint: 'arbetsmiljoverket@av.se',
      body: '''Arbetsmiljöverket
[Regionalt kontor]
[Adress]

Anmälan om brister i arbetsmiljön / arbetsrättsliga överträdelser

Anmälare:
[Fullständigt namn]
Personnummer/födelsedatum: [Personnummer eller födelsedatum]
Adress: [Adress]
Telefon: [Telefonnummer]
E-post: [E-postadress]
Yrke/befattning: [Befattning]

Arbetsgivare:
Företagsnamn: [Arbetsgivarens namn]
Organisationsnummer: [Organisationsnummer]
Adress: [Arbetsgivarens adress]
Bransch: [Bransch]

Uppgifter om anställningen:
Anställningens start: [Datum]
Anställningens slut (om avslutad): [Datum]
Anställningsform: [Tillsvidareanställning / Visstidsanställning]
Tillämpligt kollektivavtal: [Kollektivavtalets namn]

Anmälans innehåll:

1. Lönefordringar
Arbetsgivaren har inte betalat lön i enlighet med anställningsavtalet och tillämpligt kollektivavtal.
- [Beskriv obetalda löner, övertidsersättning, semesterersättning m.m.]
- Totalt: [Kronor]

2. Överträdelser av arbetstidslagen
[Beskriv: orimlig övertid, bristande efterlevnad av viloperioder, avsaknad av arbetstidsregistrering]

3. Brister i arbetsmiljön
[Beskriv: arbetsmiljöbrister, saknad skyddsutrustning, farliga arbetsförhållanden]

4. Diskriminering/kränkande särbehandling
[Beskriv: diskriminering på grund av etniskt ursprung, trakasserier, kränkande särbehandling]

5. Olaglig uppsägning
[Beskriv: lagstridig uppsägning, saknad saklig grund, formfel]

Yrkanden:
1. Att Arbetsmiljöverket genomför inspektion på arbetsplatsen.
2. Att arbetsgivaren föreläggs att betala innestående lönefordringar jämte ränta.
3. Att lämpliga åtgärder vidtas vid konstaterade överträdelser.

Bilagor:
1. Anställningsavtal (kopia)
2. Lönespecifikationer
3. Arbetstidsregistrering (om tillgänglig)
4. Korrespondens med arbetsgivaren
5. [Övriga bevis]

Datum: [Datum]

Med vänlig hälsning,

[Underskrift]
[Fullständigt namn]''',
    ),

    // =========================================================================
    // FRANCE (FR) — French
    // =========================================================================
    EmailTemplate(
      country: 'FR',
      type: 'appeal',
      language: 'fr',
      subject: 'Recours contre l\'obligation de quitter le territoire — [Nom], [N° de dossier]',
      recipientHint: 'greffe.ta-paris@juradm.fr',
      body: '''Tribunal administratif de [Ville]
[Adresse]

Requête en annulation

Requérant(e) :
[Nom complet]
Né(e) le : [Date de naissance]
Nationalité : [Nationalité]
Adresse : [Adresse en France]
Téléphone : [Numéro de téléphone]
Courriel : [Adresse e-mail]

Défendeur :
Le Préfet de [Département]
[Adresse de la préfecture]

Décision attaquée :
Arrêté du Préfet de [Département] en date du [Date], portant obligation de quitter le territoire français (OQTF), notifié le [Date de notification].
Référence : [Numéro de référence]

Objet : Recours en annulation et demande de suspension (référé-suspension, article L. 521-1 du code de justice administrative)

I. Demandes

1. Annuler l'arrêté du Préfet de [Département] en date du [Date] portant obligation de quitter le territoire français.
2. Enjoindre au Préfet de délivrer au/à la requérant(e) un titre de séjour dans un délai de 15 jours suivant la notification du jugement, sous astreinte de 100 euros par jour de retard.
3. À titre subsidiaire, renvoyer le dossier au Préfet pour réexamen.
4. Suspendre l'exécution de la mesure d'éloignement pendant la durée de l'instance.

II. Exposé des faits
[Exposer les faits : date d'entrée en France, situation familiale, situation professionnelle, démarches administratives, déroulement de la procédure]

III. Discussion

1. Violation de l'article 8 de la Convention européenne des droits de l'homme
La décision attaquée porte une atteinte disproportionnée au droit au respect de la vie privée et familiale du/de la requérant(e). En effet, [expliquer : liens familiaux, durée de résidence, intégration].

2. Violation du principe de proportionnalité
L'éloignement est disproportionné au regard des circonstances personnelles du/de la requérant(e) : [décrire les circonstances].

3. Erreur manifeste d'appréciation
Le Préfet a commis une erreur manifeste dans l'appréciation de la situation du/de la requérant(e), notamment : [décrire les erreurs].

4. Vice de procédure
[Le cas échéant : défaut de motivation, absence d'examen particulier, non-respect du contradictoire]

5. Risques en cas de retour (article 3 CEDH)
Le renvoi du/de la requérant(e) vers [Pays de destination] l'exposerait à des traitements inhumains ou dégradants, en raison de [expliquer les risques].

Pièces jointes :
1. Copie de la décision attaquée
2. [Lister les autres pièces : justificatifs, certificats médicaux, contrats de travail, etc.]
3. Timbre fiscal (35 euros) ou demande d'aide juridictionnelle

Fait à [Ville], le [Date]

Signature :

[Signature]
[Nom complet]''',
    ),
    EmailTemplate(
      country: 'FR',
      type: 'legal_aid',
      language: 'fr',
      subject: 'Demande d\'aide juridictionnelle — [Nom]',
      recipientHint: 'baj.tgi-paris@justice.fr',
      body: '''Bureau d'aide juridictionnelle
Tribunal judiciaire de [Ville]
[Adresse]

Demande d'aide juridictionnelle
(Articles 1 à 75 de la loi n° 91-647 du 10 juillet 1991)

Demandeur/demanderesse :
[Nom complet]
Né(e) le : [Date de naissance]
Nationalité : [Nationalité]
Adresse : [Adresse]
Téléphone : [Numéro de téléphone]
Courriel : [Adresse e-mail]
Titre de séjour : [Type et validité]

Je sollicite le bénéfice de l'aide juridictionnelle pour l'affaire suivante :

Nature de l'affaire :
[Décrire : recours contre OQTF, demande de titre de séjour, litige prud'homal]

Juridiction compétente : [Tribunal administratif / Conseil de prud'hommes / Tribunal judiciaire]

Partie adverse : [Préfecture / Nom de l'employeur / Autre]

État de la procédure : [Décrire l'état d'avancement]

Ressources mensuelles :
- Revenus d'activité : [Euros]
- Allocations (RSA, AAH, etc.) : [Euros]
- Autres ressources : [Euros]
- Total des ressources mensuelles : [Euros]

Charges mensuelles :
- Loyer : [Euros]
- Personnes à charge : [Nombre et lien de parenté]
- Autres charges : [Euros]

Patrimoine :
- Épargne : [Euros]
- Biens immobiliers : [Description]
- Autres biens : [Description]

Remarque : En tant que ressortissant(e) étranger(ère) résidant habituellement en France, je suis éligible à l'aide juridictionnelle dans les mêmes conditions que les ressortissants français (article 3 de la loi du 10 juillet 1991). Pour les contentieux relatifs à l'entrée, au séjour et à l'éloignement, aucune condition de résidence n'est exigée.

Pièces jointes :
1. Formulaire Cerfa n° 15626*02 complété
2. Copie de la pièce d'identité ou du titre de séjour
3. Justificatifs de ressources (3 derniers mois)
4. Justificatif de domicile
5. Copie de la décision contestée
6. [Autres pièces]

Fait à [Ville], le [Date]

Signature :

[Signature]
[Nom complet]''',
    ),
    EmailTemplate(
      country: 'FR',
      type: 'labor_complaint',
      language: 'fr',
      subject: 'Saisine du Conseil de prud\'hommes — [Nom de l\'employeur], [Nom]',
      recipientHint: 'greffe.cph-paris@justice.fr',
      body: '''Conseil de prud'hommes de [Ville]
[Adresse]

Requête aux fins de saisine du Conseil de prud'hommes
(Articles R. 1452-1 et suivants du Code du travail)

Demandeur/demanderesse (salarié(e)) :
[Nom complet]
Né(e) le : [Date de naissance]
Adresse : [Adresse]
Téléphone : [Numéro de téléphone]
Courriel : [Adresse e-mail]
Profession/qualification : [Profession]

Défendeur (employeur) :
Raison sociale : [Nom de l'employeur]
N° SIRET : [Numéro SIRET]
Adresse : [Adresse de l'employeur]
Secteur d'activité : [Secteur]

Données relatives à la relation de travail :
Date d'embauche : [Date]
Date de fin de contrat (le cas échéant) : [Date]
Nature du contrat : [CDI / CDD]
Convention collective applicable : [Nom de la convention]
Rémunération mensuelle brute : [Euros]
Classification : [Catégorie/coefficient]

Objet de la demande :

1. Rappel de salaires
L'employeur n'a pas versé l'intégralité de la rémunération due conformément au contrat de travail et à la convention collective applicable.
- [Détailler : salaires impayés, heures supplémentaires, primes, congés payés, etc.]
- Montant total réclamé : [Euros]

2. Violation de la durée du travail
[Décrire : heures supplémentaires excessives, non-respect des repos obligatoires, absence de suivi du temps de travail]

3. Manquements à l'obligation de sécurité
[Décrire : conditions de travail dangereuses, absence d'équipements de protection, risques psychosociaux]

4. Discrimination / Harcèlement
[Décrire : discrimination fondée sur l'origine, harcèlement moral ou sexuel, inégalité de traitement, en référence aux articles L. 1132-1 et L. 1152-1 du Code du travail]

5. Licenciement abusif / sans cause réelle et sérieuse
[Décrire : irrégularité de la procédure, absence de cause réelle et sérieuse, licenciement discriminatoire]

Demandes chiffrées :
1. Rappel de salaires : [Euros] + congés payés afférents
2. Indemnité pour licenciement sans cause réelle et sérieuse : [Euros]
3. Dommages et intérêts pour préjudice moral : [Euros]
4. Indemnité compensatrice de préavis : [Euros]
5. Remise des documents de fin de contrat sous astreinte

Pièces jointes :
1. Contrat de travail
2. Bulletins de salaire
3. Relevé d'heures (si disponible)
4. Correspondance avec l'employeur
5. Lettre de licenciement (le cas échéant)
6. [Autres pièces justificatives]

Fait à [Ville], le [Date]

Signature :

[Signature]
[Nom complet]''',
    ),

    // =========================================================================
    // ITALY (IT) — Italian
    // =========================================================================
    EmailTemplate(
      country: 'IT',
      type: 'appeal',
      language: 'it',
      subject: 'Ricorso contro decreto di espulsione — [Nome], [N. pratica]',
      recipientHint: 'tribunale@giustizia.it',
      body: '''Al Tribunale Ordinario di [Città]
Sezione specializzata in materia di immigrazione
[Indirizzo]

Ricorso ex art. 18 D.Lgs. 150/2011

Ricorrente:
[Nome completo]
Nato/a il: [Data di nascita]
Cittadinanza: [Cittadinanza]
Residente in: [Indirizzo in Italia]
Telefono: [Numero di telefono]
E-mail: [Indirizzo e-mail]
Codice fiscale: [Codice fiscale, se disponibile]

Resistente:
Ministero dell'Interno — Prefettura di [Provincia]
[Indirizzo della Prefettura]

Provvedimento impugnato:
Decreto di espulsione emesso dal Prefetto di [Provincia] in data [Data], notificato in data [Data di notifica], prot. n. [Numero di protocollo].

Conclusioni:

Si chiede che l'Ill.mo Tribunale voglia:

1. Annullare il decreto di espulsione del Prefetto di [Provincia] del [Data], prot. n. [Numero], in quanto illegittimo.
2. Disporre il rilascio di un permesso di soggiorno ai sensi dell'art. [articolo] del D.Lgs. 286/1998 (Testo Unico sull'Immigrazione).
3. In subordine, rinviare la pratica alla Prefettura per un nuovo esame.
4. Sospendere l'efficacia esecutiva del provvedimento impugnato ai sensi dell'art. 18, comma 8, D.Lgs. 150/2011.

Motivi del ricorso:

1. Violazione dell'art. 8 CEDU (Diritto al rispetto della vita privata e familiare)
Il provvedimento impugnato viola il diritto del ricorrente al rispetto della vita privata e familiare. Il ricorrente ha in Italia [legami familiari/radicamento] che impongono la tutela.

2. Violazione del principio di proporzionalità
L'espulsione è sproporzionata rispetto alle circostanze personali del ricorrente: [Descrivere le circostanze: legami familiari, lavoro, studi, condizioni di salute, durata del soggiorno in Italia].

3. Errore nell'accertamento dei fatti
La Prefettura ha valutato erroneamente i seguenti elementi: [Descrivere].

4. Divieto di respingimento (non-refoulement)
Il rinvio del ricorrente in [Paese di destinazione] sarebbe contrario all'art. 19 del D.Lgs. 286/1998 e all'art. 3 CEDU, in quanto [Spiegare il pericolo].

Documenti allegati:
1. Copia del provvedimento impugnato
2. [Elencare gli altri documenti: certificati, referti medici, contratti di lavoro, ecc.]

[Città], lì [Data]

Con osservanza,

[Firma]
[Nome completo]''',
    ),
    EmailTemplate(
      country: 'IT',
      type: 'legal_aid',
      language: 'it',
      subject: 'Istanza di ammissione al patrocinio a spese dello Stato — [Nome]',
      recipientHint: 'gratuito.patrocinio@giustizia.it',
      body: '''Al Consiglio dell'Ordine degli Avvocati di [Città]
[Indirizzo]

Istanza di ammissione al patrocinio a spese dello Stato
(D.P.R. 30 maggio 2002, n. 115, artt. 74-141)

Istante:
[Nome completo]
Nato/a il: [Data di nascita]
Cittadinanza: [Cittadinanza]
Residente in: [Indirizzo]
Telefono: [Numero di telefono]
E-mail: [Indirizzo e-mail]
Codice fiscale: [Codice fiscale, se disponibile]
Permesso di soggiorno: [Tipo e validità]

Il/La sottoscritto/a chiede di essere ammesso/a al patrocinio a spese dello Stato per il seguente procedimento:

Procedimento per il quale si chiede il patrocinio:
[Descrivere: ricorso contro espulsione, richiesta permesso di soggiorno, controversia di lavoro]

Natura del procedimento: [Amministrativo / Civile / Penale]

Controparte: [Prefettura / Nome del datore di lavoro / Altro]

Stato del procedimento: [Descrivere lo stato di avanzamento]

Dichiarazione sostitutiva dei redditi:
Il/La sottoscritto/a dichiara, ai sensi dell'art. 76, comma 1, del D.P.R. 115/2002, che il reddito annuo imponibile, risultante dall'ultima dichiarazione, non supera la soglia prevista dalla legge (attualmente € 12.838,01).

- Reddito annuo: [Euro]
- Componenti del nucleo familiare: [Numero e relazione]
- Patrimonio immobiliare: [Descrizione]
- Patrimonio mobiliare: [Descrizione]

Nota: I cittadini stranieri che risiedono legalmente in Italia hanno diritto al patrocinio a spese dello Stato alle stesse condizioni dei cittadini italiani (art. 119 D.P.R. 115/2002). Per i procedimenti in materia di immigrazione e asilo, l'ammissione è possibile anche per i cittadini non residenti.

Documenti allegati:
1. Copia del documento di identità o del permesso di soggiorno
2. Autocertificazione dei redditi
3. Copia del provvedimento contestato
4. [Altri documenti]

[Città], lì [Data]

In fede,

[Firma]
[Nome completo]''',
    ),
    EmailTemplate(
      country: 'IT',
      type: 'labor_complaint',
      language: 'it',
      subject: 'Denuncia contro il datore di lavoro — [Nome del datore], [Nome]',
      recipientHint: 'ispettorato@lavoro.gov.it',
      body: '''Ispettorato Territoriale del Lavoro di [Città]
[Indirizzo]

Denuncia per violazione della normativa sul lavoro

Denunciante:
[Nome completo]
Nato/a il: [Data di nascita]
Residente in: [Indirizzo]
Telefono: [Numero di telefono]
E-mail: [Indirizzo e-mail]
Professione/qualifica: [Qualifica]
Codice fiscale: [Codice fiscale]

Datore di lavoro:
Ragione sociale: [Nome del datore di lavoro]
Partita IVA / Codice fiscale: [P.IVA]
Sede legale: [Indirizzo del datore di lavoro]
Settore di attività: [Settore]

Dati relativi al rapporto di lavoro:
Data di assunzione: [Data]
Data di cessazione (se cessato): [Data]
Tipo di contratto: [Tempo indeterminato / Tempo determinato]
CCNL applicabile: [Nome del contratto collettivo]
Retribuzione mensile lorda: [Euro]
Livello/inquadramento: [Livello]

Oggetto della denuncia:

1. Crediti retributivi
Il datore di lavoro non ha corrisposto l'intera retribuzione spettante in base al contratto individuale e al CCNL applicabile.
- [Descrivere: retribuzioni non corrisposte, straordinari, ferie, TFR, ecc.]
- Importo complessivo: [Euro]

2. Violazione della normativa sull'orario di lavoro
[Descrivere: straordinari eccessivi, mancato rispetto dei riposi, assenza di registrazione dell'orario]

3. Violazione delle norme sulla sicurezza sul lavoro
[Descrivere: mancanze nella sicurezza, assenza di dispositivi di protezione, condizioni pericolose, violazioni D.Lgs. 81/2008]

4. Discriminazione / Molestie
[Descrivere: discriminazione per origine etnica, molestie morali o sessuali, trattamento iniquo, in riferimento al D.Lgs. 216/2003]

5. Licenziamento illegittimo
[Descrivere: irregolarità procedurali, assenza di giusta causa o giustificato motivo, licenziamento discriminatorio]

Richieste:
1. Ispezione presso il datore di lavoro.
2. Contestazione delle violazioni accertate e applicazione delle sanzioni previste.
3. Diffida accertativa per le somme dovute al lavoratore ai sensi dell'art. 12 D.Lgs. 124/2004.

Documenti allegati:
1. Contratto di lavoro (copia)
2. Buste paga
3. Registro presenze (se disponibile)
4. Corrispondenza con il datore di lavoro
5. [Altre prove]

[Città], lì [Data]

Con osservanza,

[Firma]
[Nome completo]''',
    ),

    // =========================================================================
    // SPAIN (ES) — Spanish
    // =========================================================================
    EmailTemplate(
      country: 'ES',
      type: 'appeal',
      language: 'es',
      subject: 'Recurso contra resolución de expulsión — [Nombre], [N° expediente]',
      recipientHint: 'juzgado.contencioso@justicia.es',
      body: '''Al Juzgado de lo Contencioso-Administrativo de [Ciudad]
[Dirección]

Recurso contencioso-administrativo

Recurrente:
[Nombre completo]
Fecha de nacimiento: [Fecha]
Nacionalidad: [Nacionalidad]
Domicilio: [Dirección en España]
Teléfono: [Número de teléfono]
Correo electrónico: [Correo electrónico]
NIE: [Número de Identidad de Extranjero]

Administración demandada:
Delegación/Subdelegación del Gobierno en [Provincia]
[Dirección]

Resolución impugnada:
Resolución de la Delegación/Subdelegación del Gobierno en [Provincia] de fecha [Fecha], expediente n.º [Número], por la que se acuerda la expulsión del territorio nacional, notificada el [Fecha de notificación].

Suplico:

1. Que se anule y deje sin efecto la resolución de expulsión de fecha [Fecha], expediente n.º [Número], por ser contraria a Derecho.
2. Que se reconozca el derecho del/de la recurrente a obtener autorización de residencia conforme al artículo [artículo] de la Ley Orgánica 4/2000 (LOEX).
3. Subsidiariamente, que se retrotraigan las actuaciones para una nueva resolución.
4. Que se acuerde la suspensión cautelar de la ejecución de la expulsión durante la tramitación del recurso (art. 129 y ss. LJCA).

Fundamentos de Derecho:

1. Vulneración del artículo 8 del CEDH (Derecho al respeto de la vida privada y familiar)
La resolución impugnada vulnera el derecho del recurrente al respeto de su vida privada y familiar. El recurrente tiene en España [vínculos familiares/arraigo] que merecen protección.

2. Vulneración del principio de proporcionalidad
La expulsión resulta desproporcionada atendiendo a las circunstancias personales del recurrente: [Describir: vínculos familiares, situación laboral, estudios, estado de salud, tiempo de residencia en España].

3. Error en la valoración de los hechos
La Administración ha valorado erróneamente las siguientes circunstancias: [Describir].

4. Arraigo social, familiar o laboral
El recurrente acredita arraigo en España conforme al artículo 68.3 del Reglamento de Extranjería: [Describir arraigo].

5. Prohibición de devolución (non-refoulement)
La devolución del recurrente a [País de destino] vulneraría el artículo 3 del CEDH y el artículo 58.2 LOEX, dado que [Explicar riesgo].

Documentos adjuntos:
1. Copia de la resolución impugnada
2. [Enumerar demás documentos: certificados, informes médicos, contratos de trabajo, etc.]

En [Ciudad], a [Fecha]

Atentamente,

[Firma]
[Nombre completo]''',
    ),
    EmailTemplate(
      country: 'ES',
      type: 'legal_aid',
      language: 'es',
      subject: 'Solicitud de asistencia jurídica gratuita — [Nombre]',
      recipientHint: 'justicia.gratuita@abogacia.es',
      body: '''Comisión de Asistencia Jurídica Gratuita
[Colegio de Abogados de Ciudad / Comunidad Autónoma]
[Dirección]

Solicitud de reconocimiento del derecho a la asistencia jurídica gratuita
(Ley 1/1996, de 10 de enero, de Asistencia Jurídica Gratuita)

Solicitante:
[Nombre completo]
Fecha de nacimiento: [Fecha]
Nacionalidad: [Nacionalidad]
Domicilio: [Dirección]
Teléfono: [Número de teléfono]
Correo electrónico: [Correo electrónico]
NIE: [Número de Identidad de Extranjero]
Permiso de residencia: [Tipo y vigencia]

Solicito el reconocimiento del derecho a la asistencia jurídica gratuita para el siguiente asunto:

Asunto para el que se solicita:
[Describir: recurso contra expulsión, solicitud de residencia, conflicto laboral]

Tipo de procedimiento: [Contencioso-administrativo / Laboral / Civil / Penal]

Parte contraria: [Delegación del Gobierno / Nombre del empleador / Otro]

Estado del procedimiento: [Describir el estado actual]

Situación económica:
- Ingresos mensuales brutos: [Euros]
- Ingresos mensuales netos: [Euros]
- Patrimonio: [Describir]
- Deudas: [Describir]
- Personas a cargo: [Describir]
- Gastos de vivienda: [Euros/mes]

Base de cálculo:
Mis ingresos anuales no superan el doble del IPREM (actualmente [cantidad] euros anuales), por lo que cumplo el requisito económico para el reconocimiento del derecho a la asistencia jurídica gratuita.

Nota: Los ciudadanos extranjeros que residan legalmente en España tienen derecho a la asistencia jurídica gratuita en igualdad de condiciones que los españoles. En procedimientos de expulsión y asilo, este derecho se reconoce con independencia de la situación administrativa (art. 22 LOEX).

Documentos adjuntos:
1. Formulario oficial cumplimentado
2. Copia del documento de identidad / NIE / pasaporte
3. Justificantes de ingresos (3 últimos meses)
4. Declaración de la Renta (si procede)
5. Copia de la resolución impugnada
6. [Otros documentos]

En [Ciudad], a [Fecha]

Atentamente,

[Firma]
[Nombre completo]''',
    ),
    EmailTemplate(
      country: 'ES',
      type: 'labor_complaint',
      language: 'es',
      subject: 'Denuncia ante la Inspección de Trabajo — [Nombre del empleador], [Nombre]',
      recipientHint: 'inspeccion.trabajo@mites.gob.es',
      body: '''Inspección de Trabajo y Seguridad Social
[Provincia]
[Dirección]

Denuncia por infracción de la normativa laboral

Denunciante:
[Nombre completo]
Fecha de nacimiento: [Fecha]
Domicilio: [Dirección]
Teléfono: [Número de teléfono]
Correo electrónico: [Correo electrónico]
NIE: [NIE]
Profesión/categoría: [Categoría profesional]

Empresa denunciada:
Razón social: [Nombre del empleador]
CIF/NIF: [CIF]
Domicilio social: [Dirección del empleador]
Sector de actividad: [Sector]

Datos de la relación laboral:
Fecha de inicio: [Fecha]
Fecha de fin (si ha finalizado): [Fecha]
Tipo de contrato: [Indefinido / Temporal]
Convenio colectivo aplicable: [Nombre del convenio]
Salario mensual bruto: [Euros]
Categoría profesional: [Categoría]

Hechos denunciados:

1. Deudas salariales
La empresa no ha abonado la totalidad del salario debido conforme al contrato de trabajo y al convenio colectivo de aplicación.
- [Detallar: salarios impagados, horas extraordinarias, pagas extras, vacaciones no disfrutadas, etc.]
- Importe total reclamado: [Euros]

2. Infracción de la normativa sobre jornada laboral
[Describir: exceso de horas extraordinarias, incumplimiento de descansos, ausencia de registro de jornada conforme al art. 34.9 ET]

3. Incumplimiento de la normativa de prevención de riesgos laborales
[Describir: deficiencias en seguridad, falta de equipos de protección, condiciones peligrosas, incumplimiento de la Ley 31/1995]

4. Discriminación / Acoso
[Describir: discriminación por origen, acoso laboral (mobbing), acoso sexual, trato desigual]

5. Despido improcedente / nulo
[Describir: irregularidades en el despido, ausencia de causa, vulneración de derechos fundamentales]

Solicito:
1. La realización de una visita de inspección al centro de trabajo.
2. El levantamiento de acta de infracción en caso de constatarse las irregularidades denunciadas.
3. El requerimiento a la empresa para el abono de las cantidades adeudadas.

Documentos adjuntos:
1. Contrato de trabajo (copia)
2. Nóminas
3. Registro de jornada (si disponible)
4. Correspondencia con la empresa
5. [Otras pruebas]

En [Ciudad], a [Fecha]

Atentamente,

[Firma]
[Nombre completo]''',
    ),

    // =========================================================================
    // NETHERLANDS (NL) — Dutch
    // =========================================================================
    EmailTemplate(
      country: 'NL',
      type: 'appeal',
      language: 'nl',
      subject: 'Beroep tegen uitzettingsbesluit — [Naam], [Zaaknummer]',
      recipientHint: 'info@rechtspraak.nl',
      body: '''Rechtbank [Stad]
Sector Bestuursrecht / Vreemdelingenkamer
[Adres]

Beroepschrift

Indiener (appellant):
[Volledige naam]
Geboortedatum: [Geboortedatum]
Nationaliteit: [Nationaliteit]
Adres: [Adres in Nederland]
Telefoonnummer: [Telefoonnummer]
E-mail: [E-mailadres]
V-nummer: [V-nummer]

Verweerder:
De Staatssecretaris van Justitie en Veiligheid
Immigratie- en Naturalisatiedienst (IND)
[Adres]

Bestreden besluit:
Besluit van de IND van [Datum], kenmerk [Kenmerk/Zaaknummer], waarbij het verzoek om een verblijfsvergunning is afgewezen en een terugkeerbesluit is uitgevaardigd, bekendgemaakt op [Datum].

Verzoek:

1. Het bestreden besluit van [Datum], kenmerk [Kenmerk], te vernietigen wegens strijd met het recht.
2. De verweerder op te dragen aan appellant een verblijfsvergunning te verlenen op grond van artikel [artikel] van de Vreemdelingenwet 2000.
3. Subsidiair: de verweerder op te dragen een nieuw besluit te nemen met inachtneming van de uitspraak van de rechtbank.
4. Een voorlopige voorziening te treffen inhoudende dat uitzetting achterwege blijft totdat op het beroep is beslist (artikel 8:81 Awb).

Gronden van het beroep:

1. Schending van artikel 8 EVRM (Recht op eerbiediging van privé- en familieleven)
Het bestreden besluit maakt een onevenredige inbreuk op het recht van appellant op eerbiediging van het privé- en familieleven. Appellant heeft in Nederland [gezinsband/worteling] die bescherming verdient.

2. Schending van het evenredigheidsbeginsel
De uitzetting is onevenredig gelet op de persoonlijke omstandigheden van appellant: [Omschrijf: gezinsband, werk, studie, gezondheidstoestand, duur verblijf in Nederland].

3. Onjuiste feitenvaststelling
De IND heeft de volgende feiten onjuist beoordeeld: [Omschrijf].

4. Refoulementverbod
Terugkeer van appellant naar [Land van bestemming] zou in strijd zijn met artikel 3 EVRM en artikel 29 van de Vreemdelingenwet 2000, omdat [Leg het gevaar uit].

Bijlagen:
1. Kopie van het bestreden besluit
2. [Opsomming overige bijlagen: bewijsstukken, medische verklaringen, arbeidscontracten, enz.]
3. Bewijs van betaling griffierecht

Datum: [Datum]

Hoogachtend,

[Handtekening]
[Volledige naam]''',
    ),
    EmailTemplate(
      country: 'NL',
      type: 'legal_aid',
      language: 'nl',
      subject: 'Aanvraag gesubsidieerde rechtsbijstand — [Naam]',
      recipientHint: 'info@rvr.org',
      body: '''Raad voor Rechtsbijstand
[Vestiging]
[Adres]

Aanvraag gesubsidieerde rechtsbijstand (toevoeging)

Aanvrager:
[Volledige naam]
Geboortedatum: [Geboortedatum]
Adres: [Adres]
Telefoonnummer: [Telefoonnummer]
E-mail: [E-mailadres]
Nationaliteit: [Nationaliteit]
Verblijfsstatus: [Type en geldigheid]
BSN: [Burgerservicenummer, indien beschikbaar]

Ik verzoek om een toevoeging (gesubsidieerde rechtsbijstand) voor de volgende zaak:

Zaak waarvoor rechtsbijstand wordt gevraagd:
[Omschrijf: beroep tegen uitzettingsbesluit, verblijfsvergunningzaak, arbeidsgeschil]

Aard van de zaak: [Bestuursrecht / Civielrecht / Strafrecht]

Wederpartij: [IND / Naam werkgever / Overig]

Stand van zaken: [Omschrijf in welk stadium de zaak zich bevindt]

Financiële gegevens:
- Jaarinkomen (bruto): [Euro]
- Jaarinkomen (netto): [Euro]
- Vermogen: [Omschrijf]
- Schulden: [Omschrijf]
- Personen ten laste: [Omschrijf]
- Woonlasten: [Euro/maand]

Toelichting:
Mijn inkomen en vermogen liggen onder de wettelijke grens voor gesubsidieerde rechtsbijstand. Zonder toevoeging ben ik niet in staat de kosten van juridische bijstand te dragen en kan ik mijn rechten niet effectief verdedigen.

Opmerking: Buitenlandse staatsburgers die rechtmatig in Nederland verblijven, komen in aanmerking voor gesubsidieerde rechtsbijstand onder dezelfde voorwaarden als Nederlandse staatsburgers. In asiel- en uitzettingszaken geldt een ruimere toegang.

Bijlagen:
1. Kopie identiteitsdocument / verblijfsdocument
2. Inkomensgegevens (jaaropgave / salarisstroken)
3. Vermogensoverzicht
4. Kopie van het bestreden besluit
5. [Overige bijlagen]

Datum: [Datum]

Hoogachtend,

[Handtekening]
[Volledige naam]''',
    ),
    EmailTemplate(
      country: 'NL',
      type: 'labor_complaint',
      language: 'nl',
      subject: 'Klacht tegen werkgever — [Werkgeversnaam], [Naam]',
      recipientHint: 'info@nlarbeidsinspectie.nl',
      body: '''Nederlandse Arbeidsinspectie
[Adres]

Klacht wegens overtreding van arbeidsrechtelijke voorschriften

Klager:
[Volledige naam]
Geboortedatum: [Geboortedatum]
Adres: [Adres]
Telefoonnummer: [Telefoonnummer]
E-mail: [E-mailadres]
Beroep/functie: [Functie]
BSN: [Burgerservicenummer]

Werkgever:
Bedrijfsnaam: [Werkgeversnaam]
KVK-nummer: [KVK-nummer]
Adres: [Adres van werkgever]
Sector: [Sector]

Gegevens dienstverband:
Datum indiensttreding: [Datum]
Datum uitdiensttreding (indien van toepassing): [Datum]
Soort arbeidsovereenkomst: [Onbepaalde tijd / Bepaalde tijd]
Toepasselijke CAO: [Naam CAO]
Brutomaandloon: [Euro]

Inhoud van de klacht:

1. Loonvorderingen
De werkgever heeft het loon niet volledig betaald conform de arbeidsovereenkomst en de toepasselijke CAO.
- [Omschrijf: achterstallig loon, overwerk, vakantiegeld, vakantiedagen, enz.]
- Totaal gevorderd bedrag: [Euro]

2. Overtredingen van de Arbeidstijdenwet
[Omschrijf: overmatig overwerk, niet-naleving van rusttijden, ontbreken van urenregistratie]

3. Overtredingen van de Arbeidsomstandighedenwet
[Omschrijf: tekortkomingen in de veiligheid, ontbreken van beschermingsmiddelen, gevaarlijke werkomstandigheden]

4. Discriminatie / Ongewenst gedrag
[Omschrijf: discriminatie op grond van afkomst, pesten, seksuele intimidatie, ongelijke behandeling]

5. Onrechtmatig ontslag
[Omschrijf: ontslag zonder geldige reden, procedurefouten, niet-naleving van opzegtermijn]

Verzoeken:
1. Het uitvoeren van een inspectie bij de werkgever.
2. Het opleggen van handhavingsmaatregelen bij geconstateerde overtredingen.
3. Het vorderen van achterstallige betalingen ten behoeve van de werknemer.

Bijlagen:
1. Arbeidsovereenkomst (kopie)
2. Loonstroken
3. Urenregistratie (indien beschikbaar)
4. Correspondentie met de werkgever
5. [Overig bewijsmateriaal]

Datum: [Datum]

Hoogachtend,

[Handtekening]
[Volledige naam]''',
    ),

    // =========================================================================
    // POLAND (PL) — Polish
    // =========================================================================
    EmailTemplate(
      country: 'PL',
      type: 'appeal',
      language: 'pl',
      subject: 'Odwołanie od decyzji o zobowiązaniu do powrotu — [Imię i nazwisko], [Nr sprawy]',
      recipientHint: 'wojewodzkisad@wsa.gov.pl',
      body: '''Wojewódzki Sąd Administracyjny w [Miasto]
[Adres]

za pośrednictwem:
Szef Urzędu do Spraw Cudzoziemców
[Adres]

Skarga na decyzję administracyjną

Skarżący:
[Imię i nazwisko]
Data urodzenia: [Data]
Obywatelstwo: [Obywatelstwo]
Adres zamieszkania: [Adres w Polsce]
Telefon: [Numer telefonu]
E-mail: [Adres e-mail]
Nr PESEL/paszportu: [Numer]

Organ, którego działanie jest zaskarżane:
Szef Urzędu do Spraw Cudzoziemców
ul. Koszykowa 16, 00-564 Warszawa

Zaskarżona decyzja:
Decyzja Szefa Urzędu do Spraw Cudzoziemców z dnia [Data], nr [Numer decyzji], zobowiązująca skarżącego do powrotu do kraju pochodzenia, doręczona w dniu [Data doręczenia].

Wnioski:

1. Uchylenie zaskarżonej decyzji z dnia [Data], nr [Numer], w całości jako niezgodnej z prawem.
2. Zobowiązanie organu do wydania skarżącemu zezwolenia na pobyt na podstawie art. [artykuł] ustawy z dnia 12 grudnia 2013 r. o cudzoziemcach.
3. Ewentualnie: przekazanie sprawy organowi do ponownego rozpatrzenia.
4. Wstrzymanie wykonania zaskarżonej decyzji na czas trwania postępowania sądowego (art. 61 § 3 ustawy Prawo o postępowaniu przed sądami administracyjnymi).

Uzasadnienie:

1. Naruszenie art. 8 Europejskiej Konwencji Praw Człowieka
Zaskarżona decyzja narusza prawo skarżącego do poszanowania życia prywatnego i rodzinnego. Skarżący posiada w Polsce [więzi rodzinne/zakorzenienie], które wymagają ochrony.

2. Naruszenie zasady proporcjonalności
Zobowiązanie do powrotu jest nieproporcjonalne w stosunku do okoliczności osobistych skarżącego: [Opisać: więzi rodzinne, praca, nauka, stan zdrowia, czas pobytu w Polsce].

3. Błędne ustalenie stanu faktycznego
Organ błędnie ocenił następujące okoliczności: [Opisać].

4. Zakaz refoulement (zakaz zawracania)
Powrót skarżącego do [Kraj docelowy] stanowiłby naruszenie art. 3 EKPC oraz art. 303 ustawy o cudzoziemcach, ponieważ [Wyjaśnić zagrożenie].

Załączniki:
1. Kopia zaskarżonej decyzji
2. [Wymienić inne załączniki: zaświadczenia, dokumentacja medyczna, umowy o pracę itp.]
3. Dowód uiszczenia wpisu sądowego

Data: [Data]

Z poważaniem,

[Podpis]
[Imię i nazwisko]''',
    ),
    EmailTemplate(
      country: 'PL',
      type: 'legal_aid',
      language: 'pl',
      subject: 'Wniosek o przyznanie prawa pomocy — [Imię i nazwisko]',
      recipientHint: 'pomoc.prawna@ms.gov.pl',
      body: '''Wojewódzki Sąd Administracyjny w [Miasto]
[Adres]

Wniosek o przyznanie prawa pomocy
(art. 243-263 ustawy z dnia 30 sierpnia 2002 r. — Prawo o postępowaniu przed sądami administracyjnymi)

Wnioskodawca:
[Imię i nazwisko]
Data urodzenia: [Data]
Obywatelstwo: [Obywatelstwo]
Adres zamieszkania: [Adres]
Telefon: [Numer telefonu]
E-mail: [Adres e-mail]
Nr PESEL/paszportu: [Numer]
Zezwolenie na pobyt: [Rodzaj i ważność]

Wnoszę o przyznanie prawa pomocy w zakresie całkowitym / częściowym, obejmującym:
- zwolnienie od kosztów sądowych
- ustanowienie adwokata/radcy prawnego

w następującej sprawie:

Sprawa, w której wnioskowane jest prawo pomocy:
[Opisać: skarga na decyzję o zobowiązaniu do powrotu, sprawa pobytowa, spór pracowniczy]

Rodzaj postępowania: [Administracyjne / Cywilne / Karne]

Strona przeciwna: [Szef Urzędu do Spraw Cudzoziemców / Nazwa pracodawcy / Inny]

Stan postępowania: [Opisać aktualny stan sprawy]

Sytuacja majątkowa i rodzinna:
- Dochody miesięczne (brutto): [PLN]
- Dochody miesięczne (netto): [PLN]
- Majątek: [Opisać]
- Zobowiązania/długi: [Opisać]
- Osoby na utrzymaniu: [Opisać]
- Koszty mieszkania: [PLN/miesiąc]
- Inne stałe wydatki: [Opisać]

Uzasadnienie:
Nie jestem w stanie ponieść kosztów postępowania sądowego oraz kosztów zastępstwa procesowego bez uszczerbku dla utrzymania koniecznego siebie i rodziny. Moja sytuacja materialna uniemożliwia mi skuteczne dochodzenie swoich praw bez pomocy prawnej.

Uwaga: Cudzoziemcy przebywający na terytorium Rzeczypospolitej Polskiej mają prawo do pomocy prawnej na zasadach określonych w ustawie. W sprawach dotyczących zobowiązania do powrotu i ochrony międzynarodowej prawo do pomocy przysługuje niezależnie od sytuacji pobytowej.

Załączniki:
1. Formularz PPF (formularz urzędowy)
2. Oświadczenie o stanie rodzinnym, majątku, dochodach i źródłach utrzymania
3. Zaświadczenia o dochodach
4. Kopia zaskarżonej decyzji
5. [Inne załączniki]

Data: [Data]

Z poważaniem,

[Podpis]
[Imię i nazwisko]''',
    ),
    EmailTemplate(
      country: 'PL',
      type: 'labor_complaint',
      language: 'pl',
      subject: 'Skarga na pracodawcę — [Nazwa pracodawcy], [Imię i nazwisko]',
      recipientHint: 'kancelaria@pip.gov.pl',
      body: '''Państwowa Inspekcja Pracy
Okręgowy Inspektorat Pracy w [Miasto]
[Adres]

Skarga na naruszenie przepisów prawa pracy

Składający skargę:
[Imię i nazwisko]
Data urodzenia: [Data]
Adres zamieszkania: [Adres]
Telefon: [Numer telefonu]
E-mail: [Adres e-mail]
Zawód/stanowisko: [Stanowisko]
Nr PESEL/paszportu: [Numer]

Pracodawca:
Nazwa firmy: [Nazwa pracodawcy]
NIP: [NIP]
REGON: [REGON]
Adres: [Adres pracodawcy]
Branża: [Branża]

Dane dotyczące stosunku pracy:
Data rozpoczęcia pracy: [Data]
Data zakończenia pracy (jeśli zakończony): [Data]
Rodzaj umowy: [Umowa na czas nieokreślony / określony / zlecenie / o dzieło]
Wynagrodzenie brutto: [PLN]

Przedmiot skargi:

1. Zaległości płacowe
Pracodawca nie wypłacił wynagrodzenia zgodnie z umową o pracę i obowiązującymi przepisami.
- [Opisać: niewypłacone wynagrodzenie, nadgodziny, premie, ekwiwalent za urlop itp.]
- Łączna kwota: [PLN]

2. Naruszenie przepisów o czasie pracy
[Opisać: nadmierne godziny nadliczbowe, brak zachowania odpoczynku dobowego/tygodniowego, brak ewidencji czasu pracy]

3. Naruszenie przepisów BHP
[Opisać: braki w bezpieczeństwie, brak środków ochrony indywidualnej, niebezpieczne warunki pracy, brak szkoleń BHP]

4. Dyskryminacja / Mobbing
[Opisać: dyskryminacja ze względu na pochodzenie, mobbing, molestowanie, nierówne traktowanie — w odniesieniu do art. 94³ i art. 18³a Kodeksu pracy]

5. Bezprawne rozwiązanie umowy o pracę
[Opisać: rozwiązanie umowy bez uzasadnionej przyczyny, naruszenie procedury wypowiedzenia, brak konsultacji ze związkami zawodowymi]

Wnioski:
1. Przeprowadzenie kontroli u pracodawcy.
2. Nakazanie pracodawcy wypłaty zaległych należności wraz z odsetkami.
3. Zastosowanie odpowiednich środków prawnych w przypadku stwierdzenia naruszeń.

Załączniki:
1. Umowa o pracę (kopia)
2. Paski wynagrodzeń / potwierdzenia przelewów
3. Ewidencja czasu pracy (jeśli dostępna)
4. Korespondencja z pracodawcą
5. [Inne dowody]

Proszę o nieujawnianie moich danych pracodawcy (art. 44 ust. 3 ustawy o Państwowej Inspekcji Pracy).

Data: [Data]

Z poważaniem,

[Podpis]
[Imię i nazwisko]''',
    ),

    // =========================================================================
    // ROMANIA (RO) — Romanian
    // =========================================================================
    EmailTemplate(
      country: 'RO',
      type: 'appeal',
      language: 'ro',
      subject: 'Contestație împotriva deciziei de returnare — [Nume], [Nr. dosar]',
      recipientHint: 'registratura@tribunalul.ro',
      body: '''Tribunalul [Oraș]
Secția de contencios administrativ și fiscal
[Adresa]

Contestație

Contestatar:
[Numele complet]
Data nașterii: [Data]
Cetățenia: [Cetățenia]
Domiciliul: [Adresa în România]
Telefon: [Număr de telefon]
E-mail: [Adresa de e-mail]

Intimat:
Inspectoratul General pentru Imigrări
Str. Lt. col. Marinescu Constantin nr. 7A, Sector 5, București

Actul administrativ contestat:
Decizia de returnare emisă de Inspectoratul General pentru Imigrări nr. [Număr] din data de [Data], comunicată la data de [Data comunicării].

Solicit:

1. Anularea deciziei de returnare nr. [Număr] din data de [Data] ca nelegală și netemeinică.
2. Obligarea intimatului la emiterea unui permis de ședere în favoarea contestatarului, în temeiul art. [articol] din O.U.G. nr. 194/2002 privind regimul străinilor în România.
3. În subsidiar, trimiterea cauzei spre rejudecare pentru o nouă analiză.
4. Suspendarea executării deciziei contestate până la soluționarea definitivă a cauzei (art. 14 și 15 din Legea nr. 554/2004).

Motive de nelegalitate:

1. Încălcarea art. 8 din Convenția Europeană a Drepturilor Omului
Decizia contestată aduce atingere dreptului contestatarului la respectarea vieții private și de familie. Contestatarul are în România [legături familiale/integrare] care necesită protecție.

2. Încălcarea principiului proporționalității
Returnarea este disproporționată în raport cu circumstanțele personale ale contestatarului: [Descrieți: legături familiale, situația profesională, studii, starea de sănătate, durata șederii în România].

3. Stabilirea eronată a situației de fapt
Autoritatea a apreciat în mod eronat următoarele circumstanțe: [Descrieți].

4. Principiul nereturnării (non-refoulement)
Returnarea contestatarului în [Țara de destinație] ar încălca art. 3 din CEDO și art. 82 din O.U.G. nr. 194/2002, deoarece [Explicați pericolul].

Documente anexate:
1. Copia deciziei contestate
2. [Enumerați alte documente: certificate, acte medicale, contracte de muncă etc.]
3. Dovada achitării taxei judiciare de timbru

Data: [Data]

Cu stimă,

[Semnătura]
[Numele complet]''',
    ),
    EmailTemplate(
      country: 'RO',
      type: 'legal_aid',
      language: 'ro',
      subject: 'Cerere de asistență juridică gratuită — [Nume]',
      recipientHint: 'barou@unbr.ro',
      body: '''Baroul [Județul]
[Adresa]

Cerere de acordare a asistenței juridice gratuite
(O.U.G. nr. 51/2008 privind ajutorul public judiciar în materie civilă)

Solicitant:
[Numele complet]
Data nașterii: [Data]
Cetățenia: [Cetățenia]
Domiciliul: [Adresa]
Telefon: [Număr de telefon]
E-mail: [Adresa de e-mail]
Document de identitate: [Tip și număr]
Permis de ședere: [Tip și valabilitate]

Solicit acordarea asistenței juridice gratuite pentru următoarea cauză:

Cauza pentru care se solicită asistența:
[Descrieți: contestație împotriva deciziei de returnare, cerere de permis de ședere, litigiu de muncă]

Natura cauzei: [Contencios administrativ / Civil / Penal / Litigiu de muncă]

Partea adversă: [Inspectoratul General pentru Imigrări / Numele angajatorului / Alt]

Stadiul cauzei: [Descrieți stadiul actual]

Situația materială:
- Venituri lunare brute: [Lei]
- Venituri lunare nete: [Lei]
- Bunuri: [Descrieți]
- Datorii: [Descrieți]
- Persoane în întreținere: [Descrieți]
- Cheltuieli de locuire: [Lei/lună]

Justificare:
Venitul mediu net lunar pe membru de familie nu depășește [suma] lei, situându-se sub plafonul prevăzut de lege. Nu sunt în măsură să suport costurile asistenței juridice fără a-mi pune în pericol întreținerea proprie și a familiei.

Notă: Cetățenii străini care au domiciliul sau reședința obișnuită în România beneficiază de ajutor public judiciar în aceleași condiții ca și cetățenii români (art. 2 alin. 2 din O.U.G. nr. 51/2008).

Documente anexate:
1. Copie act de identitate / permis de ședere
2. Adeverințe de venit
3. Declarație pe propria răspundere privind situația materială
4. Copia actului contestat
5. [Alte documente]

Data: [Data]

Cu stimă,

[Semnătura]
[Numele complet]''',
    ),
    EmailTemplate(
      country: 'RO',
      type: 'labor_complaint',
      language: 'ro',
      subject: 'Plângere împotriva angajatorului — [Numele angajatorului], [Nume]',
      recipientHint: 'itm@inspectiamuncii.ro',
      body: '''Inspectoratul Teritorial de Muncă [Județul]
[Adresa]

Plângere privind încălcarea legislației muncii

Petiționar:
[Numele complet]
Data nașterii: [Data]
Domiciliul: [Adresa]
Telefon: [Număr de telefon]
E-mail: [Adresa de e-mail]
Profesia/funcția: [Funcția]
CNP/Nr. pașaport: [Număr]

Angajator:
Denumirea societății: [Numele angajatorului]
CUI: [CUI]
Sediul social: [Adresa angajatorului]
Domeniul de activitate: [Domeniul]

Date privind raportul de muncă:
Data angajării: [Data]
Data încetării (dacă este cazul): [Data]
Tipul contractului: [Nedeterminat / Determinat]
Salariul brut lunar: [Lei]
Funcția: [Funcția]

Obiectul plângerii:

1. Restanțe salariale
Angajatorul nu a achitat salariul integral conform contractului individual de muncă și legislației în vigoare.
- [Descrieți: salarii neachitate, ore suplimentare, concediu neefectuat etc.]
- Suma totală: [Lei]

2. Încălcarea normelor privind timpul de muncă
[Descrieți: ore suplimentare excesive, nerespectarea repausului zilnic/săptămânal, lipsa evidenței timpului de muncă]

3. Încălcarea normelor de securitate și sănătate în muncă
[Descrieți: deficiențe în securitatea muncii, lipsa echipamentelor de protecție, condiții periculoase de muncă]

4. Discriminare / Hărțuire
[Descrieți: discriminare pe criterii de origine, hărțuire morală, tratament inegal — cu referire la Legea nr. 202/2002 și O.G. nr. 137/2000]

5. Concediere abuzivă
[Descrieți: concediere nelegală, lipsa motivării, nerespectarea procedurii prevăzute de Codul muncii]

Solicit:
1. Efectuarea unui control la angajator.
2. Obligarea angajatorului la plata drepturilor salariale restante, cu dobânzile aferente.
3. Aplicarea sancțiunilor contravenționale prevăzute de lege.

Documente anexate:
1. Contractul individual de muncă (copie)
2. Fluturaș de salariu / extras de cont
3. Evidența timpului de muncă (dacă este disponibilă)
4. Corespondența cu angajatorul
5. [Alte dovezi]

Data: [Data]

Cu stimă,

[Semnătura]
[Numele complet]''',
    ),

    // =========================================================================
    // AUSTRIA (AT) — German (Austrian)
    // =========================================================================
    EmailTemplate(
      country: 'AT',
      type: 'appeal',
      language: 'de',
      subject: 'Beschwerde gegen Rückkehrentscheidung — [Name], GZ [Geschäftszahl]',
      recipientHint: 'einlaufstelle@bvwg.gv.at',
      body: '''Bundesverwaltungsgericht
Erdbergstraße 192–196
1030 Wien

eingebracht über:
Bundesamt für Fremdenwesen und Asyl (BFA)
[Regionaldirektion]
[Adresse]

Beschwerde gemäß Art. 130 Abs. 1 Z 1 B-VG

Beschwerdeführer/in:
[Vollständiger Name]
Geboren am: [Geburtsdatum]
Staatsangehörigkeit: [Staatsangehörigkeit]
Wohnadresse: [Adresse in Österreich]
Telefon: [Telefonnummer]
E-Mail: [E-Mail-Adresse]
IFA-Zahl: [IFA-Zahl]

Belangte Behörde:
Bundesamt für Fremdenwesen und Asyl
[Regionaldirektion]
[Adresse]

Angefochtener Bescheid:
Bescheid des BFA vom [Datum], GZ [Geschäftszahl], zugestellt am [Zustelldatum], mit welchem eine Rückkehrentscheidung gemäß § 52 FPG erlassen wurde.

Anträge:

1. Der angefochtene Bescheid wird zur Gänze behoben.
2. Dem/Der Beschwerdeführer/in wird ein Aufenthaltstitel gemäß § [Paragraph] NAG / AsylG erteilt.
3. In eventu wird die Angelegenheit zur Erlassung eines neuen Bescheides an das BFA zurückverwiesen.
4. Der Beschwerde wird die aufschiebende Wirkung zuerkannt (§ 18 Abs. 5 BFA-VG).

Beschwerdegründe:

1. Verletzung des Art. 8 EMRK (Recht auf Achtung des Privat- und Familienlebens)
Der angefochtene Bescheid verletzt das Recht des/der Beschwerdeführers/in auf Achtung des Privat- und Familienlebens. Der/Die Beschwerdeführer/in verfügt in Österreich über [familiäre Bindungen/Integration], die schutzbedürftig sind.

2. Verletzung des Verhältnismäßigkeitsgrundsatzes
Die Rückkehrentscheidung ist unverhältnismäßig angesichts der persönlichen Umstände des/der Beschwerdeführers/in: [Darstellung: familiäre Bindungen, Beschäftigung, Ausbildung, Gesundheitszustand, Aufenthaltsdauer in Österreich].

3. Mangelhafte Sachverhaltsermittlung
Das BFA hat die folgenden Umstände nicht oder fehlerhaft ermittelt: [Darstellung].

4. Abschiebungsverbote (§ 50 FPG, § 8 AsylG)
Die Abschiebung des/der Beschwerdeführers/in nach [Zielstaat] würde gegen Art. 3 EMRK sowie § 50 FPG verstoßen, da [Begründung der Gefahr].

Beilagen:
1. Kopie des angefochtenen Bescheides
2. [Weitere Beilagen: Nachweise, ärztliche Befunde, Dienstverträge usw.]

[Ort], am [Datum]

Mit vorzüglicher Hochachtung,

[Unterschrift]
[Vollständiger Name]''',
    ),
    EmailTemplate(
      country: 'AT',
      type: 'legal_aid',
      language: 'de',
      subject: 'Antrag auf Verfahrenshilfe — [Name]',
      recipientHint: 'einlaufstelle@bvwg.gv.at',
      body: '''Bundesverwaltungsgericht
Erdbergstraße 192–196
1030 Wien

Antrag auf Bewilligung der Verfahrenshilfe
(§ 8a VwGVG i.V.m. §§ 63 ff. ZPO)

Antragsteller/in:
[Vollständiger Name]
Geboren am: [Geburtsdatum]
Staatsangehörigkeit: [Staatsangehörigkeit]
Wohnadresse: [Adresse]
Telefon: [Telefonnummer]
E-Mail: [E-Mail-Adresse]
Aufenthaltsstatus: [Art und Gültigkeit]

Ich beantrage die Bewilligung der Verfahrenshilfe im Umfang der Befreiung von der Eingabengebühr und der Beigebung eines Rechtsanwalts/einer Rechtsanwältin für folgendes Verfahren:

Verfahrensgegenstand:
[Beschreibung: Beschwerde gegen Rückkehrentscheidung, Aufenthaltstitelverfahren, arbeitsrechtliche Streitigkeit]

Gegenpartei: [BFA / Arbeitgeber / Sonstige]

Verfahrensstand: [Beschreibung des aktuellen Stands]

Einkommens- und Vermögensverhältnisse:
- Monatliches Nettoeinkommen: [Euro]
- Vermögen: [Beschreibung]
- Verbindlichkeiten: [Beschreibung]
- Sorgepflichten: [Beschreibung]
- Wohnkosten: [Euro/Monat]
- Sonstige fixe Ausgaben: [Beschreibung]

Begründung:
Ich bin außerstande, die Kosten der Führung des Verfahrens ohne Beeinträchtigung des notwendigen Unterhalts zu bestreiten. Ohne Verfahrenshilfe wäre es mir nicht möglich, meine Rechte effektiv wahrzunehmen.

Die beabsichtigte Rechtsverfolgung erscheint nicht als offenbar mutwillig oder aussichtslos, da [kurze Begründung der Erfolgsaussichten].

Beilagen:
1. Vermögensbekenntnis (Formular ZPForm 1)
2. Einkommensnachweise
3. Kopie des angefochtenen Bescheides
4. [Weitere Beilagen]

[Ort], am [Datum]

Mit vorzüglicher Hochachtung,

[Unterschrift]
[Vollständiger Name]''',
    ),
    EmailTemplate(
      country: 'AT',
      type: 'labor_complaint',
      language: 'de',
      subject: 'Beschwerde gegen Arbeitgeber — [Arbeitgebername], [Name]',
      recipientHint: 'post@arbeitsinspektion.gv.at',
      body: '''Arbeitsinspektorat [Region]
[Adresse]

Beschwerde wegen Verstößen gegen das Arbeitsrecht

Beschwerdeführer/in:
[Vollständiger Name]
Geboren am: [Geburtsdatum]
Wohnadresse: [Adresse]
Telefon: [Telefonnummer]
E-Mail: [E-Mail-Adresse]
Beruf/Tätigkeit: [Berufsbezeichnung]
Sozialversicherungsnummer: [SV-Nummer]

Arbeitgeber:
Firma: [Arbeitgebername]
Firmenbuchnummer: [FN-Nummer]
Adresse: [Adresse des Arbeitgebers]
Branche: [Branche]

Angaben zum Arbeitsverhältnis:
Beginn des Arbeitsverhältnisses: [Datum]
Ende des Arbeitsverhältnisses (falls beendet): [Datum]
Art des Dienstvertrages: [Unbefristet / Befristet]
Anwendbarer Kollektivvertrag: [KV-Bezeichnung]
Bruttomonatsentgelt: [Euro]
Einstufung: [Verwendungsgruppe/Stufe]

Gegenstand der Beschwerde:

1. Entgeltrückstände
Der Arbeitgeber hat das Entgelt nicht vollständig gemäß Dienstvertrag und dem anwendbaren Kollektivvertrag geleistet.
- [Beschreibung: ausständige Löhne/Gehälter, Überstundenentgelt, Urlaubsersatzleistung, Sonderzahlungen usw.]
- Gesamtbetrag: [Euro]

2. Verstöße gegen das Arbeitszeitgesetz (AZG)
[Beschreibung: übermäßige Überstunden, Nichteinhaltung der Ruhezeiten, fehlende Arbeitszeitaufzeichnungen]

3. Verstöße gegen das ArbeitnehmerInnenschutzgesetz (ASchG)
[Beschreibung: Mängel im Arbeitsschutz, fehlende Schutzausrüstung, gefährliche Arbeitsbedingungen, fehlende Unterweisung]

4. Diskriminierung / Belästigung
[Beschreibung: Diskriminierung aufgrund der Herkunft gem. GlBG, Mobbing, Belästigung]

5. Rechtswidrige Kündigung/Entlassung
[Beschreibung: ungerechtfertigte Entlassung, Motivkündigung, Verfahrensfehler]

Anträge:
1. Durchführung einer Kontrolle im Betrieb des Arbeitgebers.
2. Aufforderung an den Arbeitgeber zur Nachzahlung der ausstehenden Entgelte.
3. Einleitung eines Verwaltungsstrafverfahrens bei festgestellten Verstößen.

Beilagen:
1. Dienstvertrag (Kopie)
2. Lohn-/Gehaltsabrechnungen
3. Arbeitszeitaufzeichnungen (falls vorhanden)
4. Schriftverkehr mit dem Arbeitgeber
5. [Weitere Nachweise]

[Ort], am [Datum]

Mit vorzüglicher Hochachtung,

[Unterschrift]
[Vollständiger Name]''',
    ),

    // =========================================================================
    // BELGIUM (BE) — French (Belgian)
    // =========================================================================
    EmailTemplate(
      country: 'BE',
      type: 'appeal',
      language: 'fr',
      subject: 'Recours contre l\'ordre de quitter le territoire — [Nom], [N° dossier]',
      recipientHint: 'info@rvv-cce.be',
      body: '''Conseil du Contentieux des Étrangers
Rue Gaucheret 92-94
1030 Bruxelles

Requête en annulation

Partie requérante :
[Nom complet]
Né(e) le : [Date de naissance]
Nationalité : [Nationalité]
Domicile : [Adresse en Belgique]
Téléphone : [Numéro de téléphone]
Courriel : [Adresse e-mail]
N° de dossier OE : [Numéro]

Partie adverse :
L'État belge, représenté par le Secrétaire d'État à l'Asile et la Migration
Office des Étrangers
Chaussée d'Anvers 59B, 1000 Bruxelles

Décision attaquée :
Ordre de quitter le territoire (OQT) / Décision de refus de séjour, prise par l'Office des Étrangers le [Date], notifiée le [Date], sous le n° [Numéro].

Demandes :

1. Annuler la décision attaquée du [Date] comme étant contraire à la loi et aux traités internationaux.
2. Subsidiairement, suspendre l'exécution de la mesure d'éloignement en extrême urgence (article 39/82 de la loi du 15 décembre 1980).

Moyens :

Premier moyen : Violation de l'article 8 de la Convention européenne des droits de l'homme
La décision attaquée porte atteinte de manière disproportionnée au droit de la partie requérante au respect de sa vie privée et familiale. La partie requérante a en Belgique [liens familiaux/ancrage] nécessitant protection.

Deuxième moyen : Violation du principe de proportionnalité et erreur manifeste d'appréciation
L'éloignement est disproportionné au regard des circonstances personnelles : [Décrire : liens familiaux, situation professionnelle, études, état de santé, durée du séjour en Belgique].

Troisième moyen : Violation de l'obligation de motivation (loi du 29 juillet 1991)
La décision est insuffisamment motivée en ce qu'elle ne prend pas en considération [éléments non pris en compte].

Quatrième moyen : Violation du principe de non-refoulement
Le renvoi de la partie requérante vers [Pays de destination] l'exposerait à un risque réel de traitement inhumain ou dégradant, en violation de l'article 3 de la CEDH et de l'article 48/4 de la loi du 15 décembre 1980.

Pièces :
1. Copie de la décision attaquée
2. [Lister les autres pièces : justificatifs, certificats médicaux, contrats de travail, etc.]
3. Preuve du paiement du droit de rôle (186 €)

Fait à [Ville], le [Date]

Signature :

[Signature]
[Nom complet]''',
    ),
    EmailTemplate(
      country: 'BE',
      type: 'legal_aid',
      language: 'fr',
      subject: 'Demande d\'aide juridique de deuxième ligne — [Nom]',
      recipientHint: 'baj@barreau.be',
      body: '''Bureau d'aide juridique
Barreau de [Ville]
[Adresse]

Demande d'aide juridique de deuxième ligne
(Loi du 23 novembre 1998 et Code judiciaire, art. 508/1 et suivants)

Demandeur/demanderesse :
[Nom complet]
Né(e) le : [Date de naissance]
Nationalité : [Nationalité]
Domicile : [Adresse]
Téléphone : [Numéro de téléphone]
Courriel : [Adresse e-mail]
Titre de séjour : [Type et validité]

Je sollicite la désignation d'un avocat dans le cadre de l'aide juridique de deuxième ligne (gratuité totale / partiellement gratuite) pour l'affaire suivante :

Affaire pour laquelle l'aide est demandée :
[Décrire : recours contre un ordre de quitter le territoire, demande de séjour, litige de travail]

Nature de l'affaire : [Administrative / Civile / Pénale / Sociale]

Partie adverse : [Office des Étrangers / Nom de l'employeur / Autre]

État de la procédure : [Décrire l'état d'avancement]

Situation financière :
- Revenus mensuels nets : [Euros]
- Revenus du conjoint/cohabitant : [Euros]
- Allocations sociales : [Euros]
- Patrimoine : [Décrire]
- Charges : [Décrire]
- Personnes à charge : [Nombre]

Catégorie (cocher si applicable) :
☐ Bénéficiaire du revenu d'intégration sociale (RIS)
☐ Bénéficiaire de l'aide sociale (CPAS)
☐ Demandeur d'asile
☐ Personne en séjour illégal (pour les procédures relatives au séjour)
☐ Autres : revenus inférieurs au seuil légal

Remarque : Les personnes étrangères en Belgique, y compris celles en séjour irrégulier, ont droit à l'aide juridique de deuxième ligne pour les procédures relatives à leur séjour, leur éloignement ou leur asile.

Pièces jointes :
1. Copie du titre d'identité / titre de séjour
2. Preuve des revenus
3. Attestation du CPAS (si applicable)
4. Copie de la décision contestée
5. [Autres pièces]

Fait à [Ville], le [Date]

Signature :

[Signature]
[Nom complet]''',
    ),
    EmailTemplate(
      country: 'BE',
      type: 'labor_complaint',
      language: 'fr',
      subject: 'Plainte contre l\'employeur — [Nom de l\'employeur], [Nom]',
      recipientHint: 'info@emploi.belgique.be',
      body: '''Contrôle des lois sociales
Direction régionale de [Ville]
SPF Emploi, Travail et Concertation sociale
[Adresse]

Plainte pour infraction à la législation sociale

Plaignant(e) :
[Nom complet]
Né(e) le : [Date de naissance]
Domicile : [Adresse]
Téléphone : [Numéro de téléphone]
Courriel : [Adresse e-mail]
Profession/fonction : [Fonction]
N° de registre national : [Numéro]

Employeur :
Dénomination : [Nom de l'employeur]
N° d'entreprise (BCE) : [Numéro]
Siège social : [Adresse de l'employeur]
Secteur d'activité : [Secteur]
Commission paritaire : [Numéro CP]

Données relatives à la relation de travail :
Date d'entrée en service : [Date]
Date de fin (le cas échéant) : [Date]
Type de contrat : [CDI / CDD]
Convention collective applicable : [Numéro CP et CCT]
Rémunération mensuelle brute : [Euros]

Objet de la plainte :

1. Arriérés de rémunération
L'employeur n'a pas versé la rémunération intégrale due conformément au contrat de travail et aux conventions collectives applicables.
- [Détailler : salaires impayés, heures supplémentaires, pécule de vacances, prime de fin d'année, etc.]
- Montant total : [Euros]

2. Infractions à la réglementation sur le temps de travail
[Décrire : heures supplémentaires excessives, non-respect des repos, absence de système d'enregistrement du temps de travail]

3. Infractions à la réglementation sur le bien-être au travail
[Décrire : manquements à la sécurité, absence d'équipements de protection, conditions dangereuses, non-respect de la loi du 4 août 1996]

4. Discrimination / Harcèlement
[Décrire : discrimination fondée sur l'origine, harcèlement moral ou sexuel, traitement inégal — réf. lois du 10 mai 2007]

5. Licenciement abusif
[Décrire : licenciement manifestement déraisonnable (CCT n° 109), non-respect du préavis, absence de motivation]

Demandes :
1. Réalisation d'une inspection sur le lieu de travail.
2. Constatation des infractions et établissement d'un procès-verbal.
3. Mise en demeure de l'employeur pour le paiement des arriérés.

Pièces jointes :
1. Contrat de travail (copie)
2. Fiches de paie
3. Relevé des prestations (si disponible)
4. Correspondance avec l'employeur
5. [Autres preuves]

Fait à [Ville], le [Date]

Signature :

[Signature]
[Nom complet]''',
    ),

    // =========================================================================
    // IRELAND (IE) — English
    // =========================================================================
    EmailTemplate(
      country: 'IE',
      type: 'appeal',
      language: 'en',
      subject: 'Appeal against Deportation Order — [Name], [Reference Number]',
      recipientHint: 'info@ipat.ie',
      body: '''International Protection Appeals Tribunal / High Court
[Address]

Notice of Appeal / Application for Leave to Apply for Judicial Review

Appellant/Applicant:
[Full name]
Date of birth: [Date]
Nationality: [Nationality]
Address: [Address in Ireland]
Telephone: [Phone number]
Email: [Email address]
GNIB/IRP Reference: [Reference number]

Respondent:
The Minister for Justice
Department of Justice
51 St Stephen's Green, Dublin 2

Decision under appeal:
Deportation Order made by the Minister for Justice on [Date], reference number [Reference], notified on [Date of notification].

Relief sought:

1. That the Deportation Order dated [Date], reference [Reference], be revoked pursuant to Section 3(11) of the Immigration Act 1999.
2. That the applicant be granted leave to remain in the State pursuant to Section 3 of the Immigration Act 1999.
3. In the alternative, that the matter be remitted to the Minister for reconsideration.
4. That the execution of the Deportation Order be stayed pending determination of these proceedings.

Grounds of appeal:

1. Breach of Article 8 of the European Convention on Human Rights
The Deportation Order constitutes a disproportionate interference with the applicant's right to respect for private and family life under Article 8 ECHR, as given effect by the European Convention on Human Rights Act 2003. The applicant has in Ireland [family ties/connections] requiring protection.

2. Breach of the principle of proportionality
The deportation is disproportionate having regard to the applicant's personal circumstances: [Describe: family ties, employment, education, health, duration of residence in Ireland].

3. Failure to consider relevant factors
The Minister failed to properly consider the following factors as required under Section 3(6) of the Immigration Act 1999: [Describe].

4. Prohibition of refoulement
The deportation of the applicant to [Destination country] would contravene Section 5 of the Refugee Act 1996 and Article 3 ECHR, as [Explain risk].

5. Rights of the child (if applicable)
The best interests of the applicant's child(ren), who are Irish citizens / resident in Ireland, have not been adequately considered, contrary to Article 42A of the Constitution.

Supporting documents:
1. Copy of the Deportation Order
2. [List additional documents: certificates, medical reports, employment contracts, etc.]

Date: [Date]

Yours faithfully,

[Signature]
[Full name]''',
    ),
    EmailTemplate(
      country: 'IE',
      type: 'legal_aid',
      language: 'en',
      subject: 'Application for Legal Aid — [Name]',
      recipientHint: 'info@legalaidboard.ie',
      body: '''Legal Aid Board
[Law Centre name and address]

Application for Legal Aid
(Civil Legal Aid Act 1995)

Applicant:
[Full name]
Date of birth: [Date]
Nationality: [Nationality]
Address: [Address]
Telephone: [Phone number]
Email: [Email address]
PPS Number: [PPS number, if available]
Immigration status: [Type and validity]

I wish to apply for legal aid and/or legal advice in the following matter:

Matter for which legal aid is sought:
[Describe: appeal against deportation order, application for leave to remain, employment dispute]

Nature of proceedings: [Immigration / Employment / Family / Civil]

Opposing party: [Minister for Justice / Employer name / Other]

Current status of proceedings: [Describe current stage]

Financial circumstances:
- Disposable income (annual): [Euro]
- Disposable capital: [Euro]
- Employment status: [Employed / Unemployed / Social welfare recipient]
- Social welfare payments: [Type and amount per week]
- Dependants: [Number and relationship]
- Housing costs: [Euro per month]

I declare that my disposable income does not exceed the prescribed limit (currently EUR 18,000 per annum) and my disposable capital does not exceed EUR 100,000.

Note: Non-Irish nationals residing in Ireland are entitled to apply for civil legal aid on the same basis as Irish citizens. For immigration matters, including deportation, the Legal Aid Board provides services regardless of immigration status in certain circumstances.

Enclosed documents:
1. Proof of identity (passport / national ID / IRP card)
2. Proof of income (social welfare statements / payslips)
3. Proof of address
4. Copy of the relevant decision
5. [Other documents]

Date: [Date]

Yours faithfully,

[Signature]
[Full name]''',
    ),
    EmailTemplate(
      country: 'IE',
      type: 'labor_complaint',
      language: 'en',
      subject: 'Complaint to the Workplace Relations Commission — [Employer name], [Name]',
      recipientHint: 'info@workplacerelations.ie',
      body: '''Workplace Relations Commission
O'Brien Road
Carlow, R93 E920

Complaint under Employment Legislation

Complainant:
[Full name]
Date of birth: [Date]
Address: [Address]
Telephone: [Phone number]
Email: [Email address]
PPS Number: [PPS number]
Occupation: [Occupation]

Respondent (Employer):
Company name: [Employer name]
Company registration number: [CRO number]
Address: [Employer address]
Sector: [Sector]

Employment details:
Start date of employment: [Date]
End date of employment (if applicable): [Date]
Contract type: [Permanent / Fixed-term]
Weekly hours: [Hours]
Gross weekly pay: [Euro]

Legislation under which complaint is made:
[Select applicable: Payment of Wages Act 1991 / Organisation of Working Time Act 1997 / Employment Equality Acts 1998-2015 / Unfair Dismissals Acts 1977-2015 / Terms of Employment (Information) Acts 1994-2014 / National Minimum Wage Act 2000 / Safety, Health and Welfare at Work Act 2005]

Details of complaint:

1. Non-payment / underpayment of wages
The employer has failed to pay wages in accordance with the contract of employment and applicable legislation.
- [Detail: unpaid wages, overtime, holiday pay, public holiday entitlements, etc.]
- Total amount claimed: [Euro]

2. Breach of working time regulations
[Describe: excessive working hours, failure to provide rest breaks/periods, absence of records as required under the Organisation of Working Time Act 1997]

3. Breach of health and safety obligations
[Describe: safety deficiencies, lack of protective equipment, dangerous working conditions, failure to comply with Safety, Health and Welfare at Work Act 2005]

4. Discrimination / Harassment
[Describe: discrimination on grounds of race/nationality, harassment, victimisation — under the Employment Equality Acts 1998-2015]

5. Unfair dismissal
[Describe: dismissal without fair grounds, procedural unfairness, failure to follow fair procedures — under the Unfair Dismissals Acts 1977-2015]

Redress sought:
1. Compensation for financial loss: [Euro]
2. Compensation for distress / effects of discrimination: [Euro]
3. Reinstatement / re-engagement (if applicable)
4. Such other order as the Adjudication Officer deems appropriate

Note: This complaint is submitted within the 6-month time limit prescribed by the Workplace Relations Act 2015 (or within 12 months where reasonable cause is shown).

Enclosed documents:
1. Contract of employment (copy)
2. Payslips
3. Time records (if available)
4. Correspondence with employer
5. [Other evidence]

Date: [Date]

Yours faithfully,

[Signature]
[Full name]''',
    ),

    // =========================================================================
    // DENMARK (DK) — Danish
    // =========================================================================
    EmailTemplate(
      country: 'DK',
      type: 'appeal',
      language: 'da',
      subject: 'Klage over udvisningsafgørelse — [Navn], [Sagsnummer]',
      recipientHint: 'telefonisk@telefonisk.dk',
      body: '''Flygtningenævnet / Udlændingenævnet
[Adresse]

Klage

Klager:
[Fulde navn]
Fødselsdato: [Fødselsdato]
Nationalitet: [Nationalitet]
Adresse: [Adresse i Danmark]
Telefon: [Telefonnummer]
E-mail: [E-mailadresse]
Udlændingenummer: [Nummer]

Indklagede:
Udlændingestyrelsen
Ryesgade 53
2100 København Ø

Påklaget afgørelse:
Udlændingestyrelsens afgørelse af [Dato], journalnummer [Sagsnummer], hvorved klageren er meddelt afslag på opholdstilladelse og pålagt at udrejse af Danmark, meddelt den [Dato for meddelelse].

Påstande:

1. Udlændingestyrelsens afgørelse af [Dato], j.nr. [Sagsnummer], ophæves som ulovlig.
2. Klageren meddeles opholdstilladelse i henhold til udlændingelovens § [paragraf].
3. Subsidiært hjemvises sagen til Udlændingestyrelsen til fornyet behandling.
4. Udrejsefristen udsættes, indtil klagen er afgjort.

Anbringender:

1. Krænkelse af artikel 8 i Den Europæiske Menneskerettighedskonvention
Den påklagede afgørelse udgør et uforholdsmæssigt indgreb i klagerens ret til respekt for privat- og familieliv. Klageren har i Danmark [familiemæssig tilknytning] der kræver beskyttelse.

2. Tilsidesættelse af proportionalitetsprincippet
Udvisningen er uforholdsmæssig henset til klagerens personlige omstændigheder: [Beskriv: familiemæssig tilknytning, beskæftigelse, uddannelse, helbredstilstand, opholdets varighed i Danmark].

3. Fejlagtig vurdering af de faktiske omstændigheder
Udlændingestyrelsen har fejlagtigt vurderet følgende omstændigheder: [Beskriv].

4. Non-refoulement-princippet
Udsendelse af klageren til [Destinationsland] ville være i strid med udlændingelovens § 31 og artikel 3 i EMRK, idet [Forklar risikoen].

Bilag:
1. Kopi af den påklagede afgørelse
2. [Angiv øvrige bilag: dokumentation, lægeerklæringer, ansættelseskontrakter mv.]

Dato: [Dato]

Med venlig hilsen,

[Underskrift]
[Fulde navn]''',
    ),
    EmailTemplate(
      country: 'DK',
      type: 'legal_aid',
      language: 'da',
      subject: 'Ansøgning om fri proces — [Navn]',
      recipientHint: 'telefonisk@telefonisk.dk',
      body: '''Civilstyrelsen / Statsforvaltningen
[Adresse]

Ansøgning om fri proces
(Retsplejelovens kapitel 31, §§ 325-336)

Ansøger:
[Fulde navn]
Fødselsdato: [Fødselsdato]
Nationalitet: [Nationalitet]
Adresse: [Adresse]
Telefon: [Telefonnummer]
E-mail: [E-mailadresse]
Opholdsstatus: [Type og gyldighed]

Jeg ansøger om fri proces i følgende sag:

Sag, hvortil der søges fri proces:
[Beskriv: klage over udvisningsafgørelse, opholdstilladelsessag, arbejdsretlig tvist]

Sagens art: [Forvaltningsretlig / Civilretlig / Strafferetlig]

Modpart: [Udlændingestyrelsen / Arbejdsgiverens navn / Anden]

Sagens stade: [Beskriv, hvilket stadie sagen befinder sig i]

Økonomiske forhold:
- Årlig indkomst (brutto): [DKK]
- Årlig indkomst (netto): [DKK]
- Formue: [Beskriv]
- Gæld: [Beskriv]
- Forsørgerpligt: [Beskriv]
- Boligudgifter: [DKK/måned]

Indkomstgrundlag:
Min personlige indkomst med tillæg af positiv kapitalindkomst ligger under den fastsatte grænse (aktuelt [beløb] DKK for enlige / [beløb] DKK for samlevende). Jeg er ikke i stand til selv at afholde udgifterne til en retssag.

Bemærkning: Udenlandske statsborgere med bopæl i Danmark har ret til fri proces på samme vilkår som danske statsborgere. I sager om udvisning og asyl gælder en udvidet adgang til fri proces.

Bilag:
1. Kopi af legitimation / opholdstilladelse
2. Årsopgørelse fra SKAT / lønsedler
3. Dokumentation for formueforhold
4. Kopi af den relevante afgørelse
5. [Øvrige bilag]

Dato: [Dato]

Med venlig hilsen,

[Underskrift]
[Fulde navn]''',
    ),
    EmailTemplate(
      country: 'DK',
      type: 'labor_complaint',
      language: 'da',
      subject: 'Klage over arbejdsgiver — [Arbejdsgiverens navn], [Navn]',
      recipientHint: 'telefonisk@telefonisk.dk',
      body: '''Arbejdstilsynet
[Regionalt kontor]
[Adresse]

Klage over overtrædelse af arbejdsmiljølovgivningen

Klager:
[Fulde navn]
Fødselsdato: [Fødselsdato]
Adresse: [Adresse]
Telefon: [Telefonnummer]
E-mail: [E-mailadresse]
Stilling: [Stillingsbetegnelse]
CPR-nummer: [CPR-nummer]

Arbejdsgiver:
Virksomhedens navn: [Arbejdsgiverens navn]
CVR-nummer: [CVR-nummer]
Adresse: [Arbejdsgiverens adresse]
Branche: [Branche]

Oplysninger om ansættelsesforholdet:
Ansættelsens start: [Dato]
Ansættelsens ophør (hvis ophørt): [Dato]
Ansættelsesform: [Fastansat / Tidsbegrænset]
Overenskomst: [Overenskomstens navn]
Bruttomånedsløn: [DKK]

Klagepunkter:

1. Lønrestancer
Arbejdsgiveren har ikke betalt løn i overensstemmelse med ansættelsesaftalen og gældende overenskomst.
- [Beskriv: manglende løn, overarbejdsbetaling, feriepenge, pension mv.]
- Samlet beløb: [DKK]

2. Overtrædelse af arbejdstidsregler
[Beskriv: overdrevent overarbejde, manglende overholdelse af hviletid, manglende registrering af arbejdstid]

3. Overtrædelse af arbejdsmiljølovgivningen
[Beskriv: mangler i arbejdsmiljøet, manglende værnemidler, farlige arbejdsforhold, manglende APV]

4. Forskelsbehandling / chikane
[Beskriv: forskelsbehandling på grund af national oprindelse, mobning, chikane — med henvisning til forskelsbehandlingsloven]

5. Uberettiget opsigelse/bortvisning
[Beskriv: usaglig opsigelse, manglende begrundelse, formelle fejl]

Anmodninger:
1. Gennemførelse af tilsyn hos arbejdsgiveren.
2. Påbud til arbejdsgiveren om at rette op på de konstaterede overtrædelser.
3. Eventuelle sanktioner ved alvorlige overtrædelser.

Bilag:
1. Ansættelseskontrakt (kopi)
2. Lønsedler
3. Arbejdstidsregistrering (hvis tilgængelig)
4. Korrespondance med arbejdsgiveren
5. [Øvrig dokumentation]

Dato: [Dato]

Med venlig hilsen,

[Underskrift]
[Fulde navn]''',
    ),

    // =========================================================================
    // CZECH REPUBLIC (CZ) — Czech
    // =========================================================================
    EmailTemplate(
      country: 'CZ',
      type: 'appeal',
      language: 'cs',
      subject: 'Žaloba proti rozhodnutí o správním vyhoštění — [Jméno], [Č.j.]',
      recipientHint: 'podatelna@ksoud.cz',
      body: '''Krajský soud v [Město]
[Adresa]

Žaloba proti rozhodnutí správního orgánu
(§ 65 a násl. zákona č. 150/2002 Sb., soudní řád správní)

Žalobce:
[Celé jméno]
Datum narození: [Datum]
Státní příslušnost: [Státní příslušnost]
Adresa pobytu: [Adresa v ČR]
Telefon: [Telefonní číslo]
E-mail: [E-mailová adresa]
Číslo pasu: [Číslo]

Žalovaný:
Ředitelství služby cizinecké policie
Olšanská 2, 130 51 Praha 3

Napadené rozhodnutí:
Rozhodnutí Ředitelství služby cizinecké policie ze dne [Datum], č.j. [Číslo jednací], kterým bylo žalobci uloženo správní vyhoštění z území České republiky, doručené dne [Datum doručení].

Petit (návrh):

1. Napadené rozhodnutí ze dne [Datum], č.j. [Číslo jednací], se zrušuje pro nezákonnost.
2. Žalovanému se ukládá povinnost vydat žalobci povolení k pobytu podle § [paragraf] zákona č. 326/1999 Sb., o pobytu cizinců.
3. Eventuálně se věc vrací žalovanému k novému projednání.
4. Žalobce navrhuje přiznání odkladného účinku žaloby (§ 73 s.ř.s.).

Žalobní body:

1. Porušení článku 8 Evropské úmluvy o ochraně lidských práv
Napadené rozhodnutí porušuje právo žalobce na respektování soukromého a rodinného života. Žalobce má v České republice [rodinné vazby/zakořenění], které vyžadují ochranu.

2. Porušení zásady přiměřenosti
Správní vyhoštění je nepřiměřené s ohledem na osobní okolnosti žalobce: [Popište: rodinné vazby, zaměstnání, studium, zdravotní stav, délka pobytu v ČR].

3. Nesprávné zjištění skutkového stavu
Správní orgán nesprávně posoudil následující skutečnosti: [Popište].

4. Zásada non-refoulement
Navrácení žalobce do [Cílová země] by bylo v rozporu s § 120a a § 179 zákona o pobytu cizinců a čl. 3 EÚLP, neboť [Vysvětlete ohrožení].

Přílohy:
1. Kopie napadeného rozhodnutí
2. [Uveďte další přílohy: doklady, lékařské zprávy, pracovní smlouvy apod.]
3. Doklad o zaplacení soudního poplatku

Datum: [Datum]

S úctou,

[Podpis]
[Celé jméno]''',
    ),
    EmailTemplate(
      country: 'CZ',
      type: 'legal_aid',
      language: 'cs',
      subject: 'Žádost o ustanovení advokáta / osvobození od soudních poplatků — [Jméno]',
      recipientHint: 'podatelna@ksoud.cz',
      body: '''Krajský soud v [Město]
[Adresa]

Žádost o ustanovení zástupce z řad advokátů a osvobození od soudních poplatků
(§ 35 odst. 10 s.ř.s. a § 36 odst. 3 s.ř.s.)

Žadatel:
[Celé jméno]
Datum narození: [Datum]
Státní příslušnost: [Státní příslušnost]
Adresa pobytu: [Adresa]
Telefon: [Telefonní číslo]
E-mail: [E-mailová adresa]
Pobytové oprávnění: [Typ a platnost]

Žádám o ustanovení zástupce z řad advokátů a osvobození od soudních poplatků v následující věci:

Věc, ve které je právní pomoc žádána:
[Popište: žaloba proti správnímu vyhoštění, pobytové řízení, pracovněprávní spor]

Druh řízení: [Správní / Civilní / Trestní]

Protistrana: [Ředitelství služby cizinecké policie / Jméno zaměstnavatele / Jiný]

Stav řízení: [Popište aktuální stav věci]

Majetkové a osobní poměry:
- Měsíční příjem (hrubý): [CZK]
- Měsíční příjem (čistý): [CZK]
- Majetek: [Popište]
- Dluhy: [Popište]
- Vyživovací povinnosti: [Popište]
- Náklady na bydlení: [CZK/měsíc]

Odůvodnění:
Nemám dostatečné prostředky k úhradě nákladů soudního řízení a zastupování advokátem, aniž by tím bylo ohroženo zajištění nezbytných životních potřeb mých a mé rodiny. Bez právní pomoci bych nebyl/a schopen/schopna účinně hájit svá práva.

Zamýšlené uplatnění práva není zjevně bezúspěšné, neboť [stručné odůvodnění].

Poznámka: Cizinci s pobytem na území České republiky mají právo na právní pomoc za stejných podmínek jako občané ČR. V řízeních o správním vyhoštění a mezinárodní ochraně je právo na právní pomoc zaručeno zákonem.

Přílohy:
1. Prohlášení o osobních, majetkových a výdělkových poměrech (formulář)
2. Doklady o příjmech
3. Kopie napadeného rozhodnutí
4. [Další přílohy]

Datum: [Datum]

S úctou,

[Podpis]
[Celé jméno]''',
    ),
    EmailTemplate(
      country: 'CZ',
      type: 'labor_complaint',
      language: 'cs',
      subject: 'Podnět k provedení kontroly u zaměstnavatele — [Název zaměstnavatele], [Jméno]',
      recipientHint: 'podatelna@suip.cz',
      body: '''Oblastní inspektorát práce pro [Kraj]
[Adresa]

Podnět ke kontrole dodržování pracovněprávních předpisů

Podatel:
[Celé jméno]
Datum narození: [Datum]
Adresa: [Adresa]
Telefon: [Telefonní číslo]
E-mail: [E-mailová adresa]
Pracovní zařazení: [Pozice]
Číslo pasu/rodné číslo: [Číslo]

Zaměstnavatel:
Název firmy: [Název zaměstnavatele]
IČO: [IČO]
Sídlo: [Adresa zaměstnavatele]
Obor činnosti: [Obor]

Údaje o pracovním poměru:
Datum vzniku pracovního poměru: [Datum]
Datum skončení (pokud skončil): [Datum]
Druh pracovního poměru: [Na dobu neurčitou / Na dobu určitou / DPP / DPČ]
Hrubá měsíční mzda: [CZK]

Předmět podnětu:

1. Mzdové nedoplatky
Zaměstnavatel nevyplatil mzdu v souladu s pracovní smlouvou a platnými právními předpisy.
- [Popište: nevyplacené mzdy, příplatky za přesčasy, náhrada za dovolenou, odstupné apod.]
- Celková částka: [CZK]

2. Porušení předpisů o pracovní době
[Popište: nadměrné přesčasy, nedodržování dob odpočinku, chybějící evidence pracovní doby — viz zákoník práce §§ 78-100]

3. Porušení předpisů o bezpečnosti a ochraně zdraví při práci (BOZP)
[Popište: nedostatky v bezpečnosti, chybějící ochranné pomůcky, nebezpečné pracovní podmínky, chybějící školení BOZP]

4. Diskriminace / Šikana (mobbing)
[Popište: diskriminace z důvodu národnosti, šikana na pracovišti, nerovné zacházení — s odkazem na antidiskriminační zákon č. 198/2009 Sb.]

5. Neplatné rozvázání pracovního poměru
[Popište: nezákonná výpověď, okamžité zrušení bez důvodu, formální vady — s odkazem na §§ 50-73 zákoníku práce]

Žádám:
1. Provedení kontroly u zaměstnavatele.
2. V případě zjištění porušení uložení opatření k nápravě.
3. Případné uložení pokuty za zjištěná porušení.

Žádám o zachování anonymity podnětu v souladu s § 4 zákona č. 251/2005 Sb., o inspekci práce.

Přílohy:
1. Pracovní smlouva (kopie)
2. Výplatní pásky
3. Evidence pracovní doby (pokud je k dispozici)
4. Korespondence se zaměstnavatelem
5. [Další důkazy]

Datum: [Datum]

S úctou,

[Podpis]
[Celé jméno]''',
    ),
  ];

  /// Get all templates for a specific country.
  static List<EmailTemplate> getByCountry(String countryCode) {
    return allTemplates
        .where((t) => t.country == countryCode.toUpperCase())
        .toList();
  }

  /// Get all templates of a specific type across all countries.
  static List<EmailTemplate> getByType(String type) {
    return allTemplates.where((t) => t.type == type).toList();
  }

  /// Get a specific template by country and type.
  static EmailTemplate? get(String countryCode, String type) {
    try {
      return allTemplates.firstWhere(
        (t) => t.country == countryCode.toUpperCase() && t.type == type,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all available country codes.
  static List<String> get availableCountries {
    return allTemplates.map((t) => t.country).toSet().toList()..sort();
  }

  /// Get all available template types.
  static List<String> get availableTypes {
    return allTemplates.map((t) => t.type).toSet().toList()..sort();
  }

  /// Get the language for a given country code.
  static String? getLanguageForCountry(String countryCode) {
    try {
      return allTemplates
          .firstWhere((t) => t.country == countryCode.toUpperCase())
          .language;
    } catch (_) {
      return null;
    }
  }

  /// Fill template placeholders with actual values.
  /// [placeholders] is a map of placeholder text (without brackets) to values.
  /// E.g., {'Nimi': 'John Doe', 'Päivämäärä': '01.01.2025'}
  static EmailTemplate? fillTemplate(
    String countryCode,
    String type,
    Map<String, String> placeholders,
  ) {
    final template = get(countryCode, type);
    if (template == null) return null;

    String filledSubject = template.subject;
    String filledBody = template.body;

    for (final entry in placeholders.entries) {
      final placeholder = '[${entry.key}]';
      filledSubject = filledSubject.replaceAll(placeholder, entry.value);
      filledBody = filledBody.replaceAll(placeholder, entry.value);
    }

    return EmailTemplate(
      country: template.country,
      type: template.type,
      subject: filledSubject,
      body: filledBody,
      recipientHint: template.recipientHint,
      language: template.language,
    );
  }
}
