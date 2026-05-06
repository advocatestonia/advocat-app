// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get about => 'Tietoa sovelluksesta';

  @override
  String get aboutSection => 'TIETOJA';

  @override
  String get accidents => 'Onnettomuudet';

  @override
  String get active => 'Aktiiviset';

  @override
  String get activeCases => 'Aktiiviset asiat';

  @override
  String get addedToAppeal => 'Lisätty valitukseen';

  @override
  String get agreeToTerms => 'Hyväksyn ';

  @override
  String get aiAnalysis => 'Tekoälyanalyysi';

  @override
  String get aiAssistant => 'Tekoäly-oikeusavustaja';

  @override
  String get aiChat => 'Tekoälykeskustelu';

  @override
  String get all => 'Kaikki';

  @override
  String get alreadyHaveAccount => 'Onko sinulla jo tili? ';

  @override
  String get analyzing => 'Analysoidaan…';

  @override
  String get aiAnalyzing => 'Tekoäly analysoi';

  @override
  String get speakIntoMicHint =>
      'Puhu mikrofoniin. Varmista, että mikrofonin käyttöoikeus on sallittu.';

  @override
  String get aiErrorRateLimit =>
      'Palvelu on tilapäisesti ylikuormitettu. Yritä 1-2 minuutin kuluttua uudelleen.';

  @override
  String get aiErrorOverload =>
      'Tekoäly on juuri nyt varattu, yritä minuutin kuluttua uudelleen.';

  @override
  String freeLimitReached(int count) {
    return 'Olet käyttänyt kaikki $count ilmaista tekoälyviestiä. Päivitä Oikeusneuvoja-tilaukseen saadaksesi rajattoman tekoälyavun!';
  }

  @override
  String get andWord => ' ja ';

  @override
  String get appTitle => 'Advocat — Oikeudellinen tietotyökalu';

  @override
  String get appVersion => 'Sovelluksen versio';

  @override
  String get appealFiled => 'Valitus jätetty';

  @override
  String get areYouAbsolutelySure => 'Oletko aivan varma?';

  @override
  String get askAboutCase => 'Kysy asiastasi';

  @override
  String get asylum => 'Turvapaikka';

  @override
  String get back => 'Takaisin';

  @override
  String get basic => 'Perus';

  @override
  String get beforeYouBuy => 'Ennen ostoa';

  @override
  String get beforeYouWork => 'Ennen yhteistyötä';

  @override
  String get camera => 'Kamera';

  @override
  String get cancel => 'Peruuta';

  @override
  String get caseDescription => 'Asian kuvaus';

  @override
  String get caseDetail => 'Asian tiedot';

  @override
  String get caseOverview => 'Asioiden yhteenveto';

  @override
  String get caseTitle => 'Asian otsikko';

  @override
  String get caseUpdated => 'Asia päivitetty';

  @override
  String get cases => 'Asiat';

  @override
  String get checkCompany => 'Tarkista yritys';

  @override
  String get checkDeadlines => 'Tarkista määräajat';

  @override
  String get checkVehicle => 'Tarkista ajoneuvo';

  @override
  String get checkerTitle => 'Tarkistaja';

  @override
  String get checkingErrors => 'Tarkistetaan virheitä…';

  @override
  String get choosePlan => 'Valitse paketti';

  @override
  String get closed => 'Suljetut';

  @override
  String get companyName => 'Yrityksen nimi tai y-tunnus';

  @override
  String get completed => 'Valmis';

  @override
  String get confirm => 'Vahvista';

  @override
  String get confirmPassword => 'Vahvista salasana';

  @override
  String get connectEmail => 'Yhdistä sähköposti';

  @override
  String get connectGmail => 'Yhdistä Gmail';

  @override
  String get connectOutlook => 'Yhdistä Outlook';

  @override
  String get connected => 'Yhdistetty';

  @override
  String get contactSupport => 'Ota yhteyttä tukeen';

  @override
  String get continueWithGoogle => 'Jatka Googlella';

  @override
  String get copyText => 'Kopioi teksti';

  @override
  String get correspondence => 'Kirjeenvaihto';

  @override
  String get couldNotLoadCases => 'Asioiden lataaminen epäonnistui';

  @override
  String get country => 'Maa';

  @override
  String get createAccount => 'Luo tili';

  @override
  String get createCase => 'Luo asia';

  @override
  String get criminalCase => 'Rikosasia';

  @override
  String get critical => 'Kriittinen';

  @override
  String get currentPlan => 'Nykyinen paketti';

  @override
  String get dataAndPrivacy => 'TIEDOT JA YKSITYISYYS';

  @override
  String get dataExportRequested =>
      'Tietojen vienti pyydetty. Tarkista sähköpostisi.';

  @override
  String daysRemaining(int count) {
    return '$count päivää';
  }

  @override
  String get deadlineReminders => 'Määräaikamuistutukset';

  @override
  String get deadlineRemindersDesc =>
      'Saat ilmoituksen ennen määräaikojen umpeutumista';

  @override
  String get deadlines => 'Määräajat';

  @override
  String get debtCollection => 'Perintä';

  @override
  String get deleteAccount => 'Poista tili';

  @override
  String get deleteAccountDesc => 'Poista tilisi ja kaikki tietosi pysyvästi';

  @override
  String get deleteAccountDialogContent =>
      'Tämä toiminto on pysyvä eikä sitä voi peruuttaa. Kaikki tietosi, asiat ja asiakirjat poistetaan lopullisesti.';

  @override
  String get deleteConfirm =>
      'Haluatko varmasti poistaa tilisi? Tätä toimintoa ei voi peruuttaa.';

  @override
  String get demoHint => 'Demo: kokeile rekisterinumeroa ”908FBT”';

  @override
  String get demoModeDesc => 'Tutustu sovellukseen ilman rekisteröitymistä';

  @override
  String get deportation => 'Käännyttäminen';

  @override
  String get disclaimer =>
      'Vain tekoälyn ohjausta — ei oikeudellista neuvontaa. Konsultoi aina lakimiestä.';

  @override
  String get disclaimerFull =>
      'Tämä asiakirja on luotu tekoälyn avulla ja on tarkoitettu ainoastaan ohjaavaksi tueksi. Se ei ole oikeudellinen neuvo. Suosittelemme aina konsultoimaan lakimiestä ennen valituksen jättämistä.';

  @override
  String get disconnect => 'Katkaise yhteys';

  @override
  String get discrimination => 'Syrjintä';

  @override
  String get doNotBuy => 'Älä osta';

  @override
  String get documents => 'Asiakirjat';

  @override
  String documentsCount(int count) {
    return '$count asiakirjaa';
  }

  @override
  String get draftAppeal => 'Laadi valitus';

  @override
  String get editDraft => 'Muokkaa luonnosta';

  @override
  String get editProfile => 'Muokkaa profiilia';

  @override
  String get email => 'Sähköposti';

  @override
  String get emailConnected => 'Sähköposti yhdistetty';

  @override
  String get emailDisconnected => 'Sähköposti irrotettu';

  @override
  String get emailIntegration => 'SÄHKÖPOSTI-INTEGRAATIO';

  @override
  String get emailInvalid => 'Syötä kelvollinen sähköpostiosoite';

  @override
  String get emailPrivacyNote =>
      'Luemme vain oikeudellisiin asioihin liittyvät viestit. Yksityisyytesi on suojattu.';

  @override
  String get emailRequired => 'Sähköposti on pakollinen';

  @override
  String get emergencyShield => 'Hätäsuoja';

  @override
  String get error => 'Virhe';

  @override
  String get exportDataDesc => 'Lataa kaikki tietosi JSON-muodossa';

  @override
  String get exportDataDialogContent =>
      'Valmistelemme ladattavaksi kaikki tietosi, mukaan lukien asiat, asiakirjat ja kirjeenvaihdon. Saat sähköpostin, kun se on valmis.';

  @override
  String get exportMyData => 'Vie omat tiedot';

  @override
  String get exportPdf => 'Vie PDF-tiedostona';

  @override
  String get familyReunification => 'Perheen yhdistäminen';

  @override
  String get forgotPassword => 'Unohditko salasanan?';

  @override
  String get free => 'Ilmainen';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Koko nimi';

  @override
  String get gallery => 'Galleria';

  @override
  String get generateAppeal => 'Luo valitus';

  @override
  String get getStarted => 'Aloita';

  @override
  String goodAfternoon(String name) {
    return 'Hyvää iltapäivää, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Hyvää iltaa, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Hyvää huomenta, $name';
  }

  @override
  String goodNight(String name) {
    return 'Hyvää yötä, $name';
  }

  @override
  String get home => 'Koti';

  @override
  String get important => 'Tärkeä';

  @override
  String get inProgress => 'Käsittelyssä';

  @override
  String get informational => 'Tiedoksi';

  @override
  String get inspection => 'Katsastus';

  @override
  String get insurance => 'Vakuutus';

  @override
  String issuesFound(int count) {
    return '$count ongelmaa löydetty';
  }

  @override
  String get laborDispute => 'Työriidat';

  @override
  String get langEnglish => 'Englanti';

  @override
  String get langFinnish => 'Suomi';

  @override
  String get langRussian => 'Venäjä';

  @override
  String get language => 'Kieli';

  @override
  String lastActivity(String time) {
    return 'Viimeinen toiminta: $time';
  }

  @override
  String get legalFighter => 'Oikeustaisto';

  @override
  String get legalSection => 'OIKEUDELLINEN';

  @override
  String get licensePlate => 'Rekisterinumero';

  @override
  String get loading => 'Ladataan…';

  @override
  String get logIn => 'Kirjaudu sisään';

  @override
  String get loginFailed =>
      'Virheellinen sähköposti tai salasana. Yritä uudelleen.';

  @override
  String get lost => 'Hävitty';

  @override
  String get markComplete => 'Merkitse valmiiksi';

  @override
  String get mileage => 'Mittarilukema';

  @override
  String get myCases => 'Omat asiat';

  @override
  String get nameRequired => 'Koko nimi on pakollinen';

  @override
  String get newCase => 'Uusi asia';

  @override
  String get next => 'Seuraava';

  @override
  String get noAccount => 'Eikö sinulla ole tiliä? ';

  @override
  String get noCases => 'Ei vielä asioita';

  @override
  String get noCasesYet => 'Ei vielä asioita';

  @override
  String get noDeadlines => 'Ei määräaikoja';

  @override
  String get noRecentActivity => 'Ei viimeaikaista toimintaa';

  @override
  String get notifications => 'ILMOITUKSET';

  @override
  String get onboardingDesc1 =>
      'Advocat auttaa sinua ymmärtämään oikeudellista tilannettasi. Tekoälytyökalut analysoivat asiakirjoja, tunnistavat mahdollisia ongelmia ja valmistelevat asiakirjaluonnoksia tarkistettavaksesi. Ei lakitoimisto — teknologiatyökalu asiasi tueksi.';

  @override
  String get onboardingDesc2 =>
      'Kuvaa mikä tahansa oikeudellinen asiakirja. Tekoäly lukee sen useilla kielillä, poimii keskeiset tiedot ja vertaa EU-direktiiveihin ja kansallisiin lakeihin mahdollisten ongelmien varalta.';

  @override
  String get onboardingDesc3 =>
      'Tekoälytyökalumme tarkistavat yli 40 menettelyvaatimusta. Tekoälyanalyysi voi tunnistaa huomiota vaativia asioita — kuten tiedoksiantokielen, menettelyvaiheet ja oikeudelliset määräajat. Tarkista aina pätevän asianajajan kanssa.';

  @override
  String get onboardingDesc4 =>
      'Tekoäly valmistelee valitus-, kantelu- ja kirjeluonnoksia lakiviittauksineen tarkistettavaksesi. Sinä päätät, mitä lähetetään. Jokainen asiakirja tulisi tarkistuttaa pätevällä oikeudellisella ammattilaisella ennen jättämistä.';

  @override
  String get onboardingNext => 'Seuraava';

  @override
  String get onboardingSkip => 'Ohita';

  @override
  String get onboardingTitle1 => 'Tekoälypohjainen oikeudellinen tieto';

  @override
  String get onboardingTitle2 => 'Skannaa ja analysoi asiakirjoja';

  @override
  String get onboardingTitle3 => 'Tekoäly tarkistaa mahdolliset ongelmat';

  @override
  String get onboardingTitle4 => 'Asiakirjaluonnokset tarkistettavaksesi';

  @override
  String get openACase => 'Avaa tapaus';

  @override
  String get optional => 'Valinnainen';

  @override
  String get orDivider => 'tai';

  @override
  String get other => 'Muu';

  @override
  String get overdue => 'Myöhässä';

  @override
  String get owners => 'Edelliset omistajat';

  @override
  String get password => 'Salasana';

  @override
  String get passwordRequired => 'Salasana on pakollinen';

  @override
  String get passwordStrengthMedium => 'Keskiverto';

  @override
  String get passwordStrengthStrong => 'Vahva';

  @override
  String get passwordStrengthWeak => 'Heikko';

  @override
  String get passwordTooShort => 'Salasanan on oltava vähintään 8 merkkiä';

  @override
  String get passwordsDoNotMatch => 'Salasanat eivät täsmää';

  @override
  String get pendingDecision => 'Odottaa päätöstä';

  @override
  String get perCheck => 'per tarkistus';

  @override
  String get permanentlyDelete => 'Poista pysyvästi';

  @override
  String get policeMisconduct => 'Poliisin toiminta';

  @override
  String get popular => 'Suosittu';

  @override
  String get preferences => 'ASETUKSET';

  @override
  String get preferredLanguage => 'Kieli';

  @override
  String get pricePerCheck => '4,99 € per tarkistus';

  @override
  String get privacyPolicy => 'Tietosuojakäytäntö';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Push-ilmoitukset';

  @override
  String get rateUs => 'Arvostele sovellus';

  @override
  String get rateAppComingSoon => 'Tulossa pian sovelluskauppoihin!';

  @override
  String get dataCopiedToClipboard => 'Tiedot kopioitu leikepöydälle';

  @override
  String get readingDocument => 'Luetaan asiakirjaa…';

  @override
  String get recentActivity => 'Viimeaikainen toiminta';

  @override
  String get referenceNumber => 'Viitenumero';

  @override
  String get registerFailed => 'Rekisteröinti epäonnistui. Yritä uudelleen.';

  @override
  String get reportFraud => 'Ilmoita petoksesta';

  @override
  String get requestExport => 'Pyydä vientiä';

  @override
  String get researchingLaw => 'Tutkitaan lainsäädäntöä…';

  @override
  String get resetPasswordFailed =>
      'Linkin lähettäminen epäonnistui. Yritä uudelleen.';

  @override
  String get resetPasswordSent =>
      'Salasanan nollauslinkki lähetetty sähköpostiisi.';

  @override
  String get residencePermit => 'Oleskelulupa';

  @override
  String get manageSubscription => 'Hallitse tilausta';

  @override
  String get restorePurchases => 'Palauta ostokset';

  @override
  String get retry => 'Yritä uudelleen';

  @override
  String get reviewWarning => 'Tarkista ennen lähettämistä';

  @override
  String get riskHigh => 'Korkea riski — vältä';

  @override
  String get riskLow => 'Turvallinen yhteistyöhön';

  @override
  String get riskMedium => 'Etene varoen';

  @override
  String get safeToBuy => 'Turvallinen ostaa';

  @override
  String get saveAndAnalyze => 'Tallenna ja analysoi';

  @override
  String get saveDraft => 'Tallenna luonnos';

  @override
  String get saveWithAnnual => 'Säästä vuositilauksella';

  @override
  String get scan => 'Skannaa';

  @override
  String get scanDocument => 'Skannaa asiakirja';

  @override
  String get searchCases => 'Hae asioita';

  @override
  String get selectCountry => 'Valitse maa';

  @override
  String get selectLanguage => 'Valitse kieli';

  @override
  String get sendViaEmail => 'Lähetä sähköpostilla';

  @override
  String get settings => 'Asetukset';

  @override
  String get signIn => 'Kirjaudu sisään';

  @override
  String get signInLink => 'Kirjaudu sisään';

  @override
  String get signInSubtitle => 'Kirjaudu päästäksesi asioihisi';

  @override
  String get signOut => 'Kirjaudu ulos';

  @override
  String get signOutConfirm => 'Haluatko varmasti kirjautua ulos?';

  @override
  String get signUp => 'Luo tili';

  @override
  String get signUpLink => 'Rekisteröidy';

  @override
  String get socialBenefits => 'Sosiaalietuudet';

  @override
  String get someConcerns => 'Joitain huolenaiheita';

  @override
  String get startFirstCase => 'Luo ensimmäinen asiasi';

  @override
  String step(int current, int total) {
    return 'Vaihe $current/$total';
  }

  @override
  String get stolen => 'Varastettu-tarkistus';

  @override
  String get subscription => 'Tilaus';

  @override
  String get syncLegalCorrespondence => 'Synkronoi oikeudellinen kirjeenvaihto';

  @override
  String get syncNow => 'Synkronoi nyt';

  @override
  String get tenantRights => 'Vuokralaisen oikeudet';

  @override
  String get termsOfService => 'Käyttöehdot';

  @override
  String get termsRequired => 'Sinun on hyväksyttävä käyttöehdot';

  @override
  String get timeline => 'Aikajana';

  @override
  String get tryDemoMode => 'Kokeile demotilaa';

  @override
  String get typeDeleteToConfirm =>
      'Kirjoita DELETE vahvistaaksesi tilin pysyvän poistamisen.';

  @override
  String get typeMessage => 'Kirjoita viesti…';

  @override
  String get upcoming => 'Tulossa';

  @override
  String get uploadDocument => 'Lataa asiakirja';

  @override
  String urgentDeadline(String title) {
    return 'Kiireellinen: $title';
  }

  @override
  String get useInAppeal => 'Käytä valituksessa';

  @override
  String get vehicleChecker => 'Ajoneuvon tarkistaja';

  @override
  String get vehicleChecks => 'Tilatarkistukset';

  @override
  String get vehicleColor => 'Väri';

  @override
  String get vehicleMake => 'Merkki';

  @override
  String get vehicleModel => 'Malli';

  @override
  String get vehicleYear => 'Vuosi';

  @override
  String get version => 'Versio';

  @override
  String get victimSupport => 'Uhrien tuki';

  @override
  String get viewAll => 'Näytä kaikki';

  @override
  String get vinNumber => 'VIN-numero';

  @override
  String get welcomeBack => 'Tervetuloa takaisin';

  @override
  String get whatAreMyOptions => 'Mitkä ovat vaihtoehtoni?';

  @override
  String get won => 'Voitettu';

  @override
  String get documentVault => 'Asiakirjaholvi';

  @override
  String get secureDocumentStorage => 'Turvallinen asiakirjatallennus';

  @override
  String get secureDocumentStorageDesc =>
      'Tallenna tärkeät oikeudelliset asiakirjat turvallisesti. Kaikki tiedostot on salattu.';

  @override
  String get addDocument => 'Lisää asiakirja';

  @override
  String get chooseHowToAdd => 'Valitse lisäystapa';

  @override
  String get uploadFile => 'Lataa tiedosto';

  @override
  String get uploadFileDesc => 'Valitse PDF tai kuva laitteeltasi';

  @override
  String get scanDocumentDesc => 'Ota valokuva asiakirjasta';

  @override
  String get createNote => 'Luo muistiinpano';

  @override
  String get createNoteDesc =>
      'Kirjoita muistiinpano tai tallenna tärkeitä tietoja';

  @override
  String get knowYourRights => 'Tunne oikeutesi';

  @override
  String get stoppedByPolice => 'Poliisi pysäyttää';

  @override
  String get stoppedByPoliceDesc => 'Oikeutesi poliisikohtaamisessa';

  @override
  String get deportationNotice => 'Käännyttämispäätös';

  @override
  String get deportationNoticeDesc =>
      'Vaiheet käännyttämispäätöksen valittamiseksi';

  @override
  String get workplaceRights => 'Työoikeudet';

  @override
  String get workplaceRightsDesc => 'Työlainsäädännön suoja Suomessa';

  @override
  String get tenantRightsDesc => 'Asumisen ja vuokrauksen suoja';

  @override
  String get immigrationDetention => 'Maahanmuuttosäilö';

  @override
  String get immigrationDetentionDesc => 'Oikeudet viranomaisten pidättäessä';

  @override
  String get discriminationDesc =>
      'Miten ilmoittaa syrjinnästä ja taistella sitä vastaan';

  @override
  String get scenarioNotFound => 'Skenaariota ei löytynyt';

  @override
  String get youHaveRightTo => 'Sinulla on oikeus:';

  @override
  String get youMust => 'Sinun täytyy:';

  @override
  String get immediateSteps => 'Välittömät toimet:';

  @override
  String get yourRights => 'Oikeutesi:';

  @override
  String get basicRights => 'Perusoikeudet:';

  @override
  String get yourRightsAsTenant => 'Oikeutesi vuokralaisena:';

  @override
  String get yourRightsInDetention => 'Oikeutesi säilössä:';

  @override
  String get howToAct => 'Miten toimia:';

  @override
  String get rightKnowWhyStopped => 'Tietää miksi sinut pysäytettiin';

  @override
  String get rightRemainSilent => 'Pysyä hiljaa (sinun on tunnistauduttava)';

  @override
  String get rightAskInterpreter => 'Pyytää tulkkia';

  @override
  String get rightContactLawyer =>
      'Ottaa yhteyttä lakimieheen ennen kuulustelua';

  @override
  String get rightRecordEncounter =>
      'Tallentaa kohtaaminen (julkisilla paikoilla)';

  @override
  String get mustProvideName => 'Ilmoittaa nimesi ja syntymäaikasi';

  @override
  String get mustShowId => 'Näyttää henkilöllisyystodistus jos sinulla on';

  @override
  String get mustNotResist => 'Olla vastustamatta fyysisesti';

  @override
  String get doNotIgnoreNotice =>
      'ÄLÄ jätä ilmoitusta huomiotta — määräajat ovat tiukkoja';

  @override
  String get noteAppealDeadline =>
      'Merkitse muistiin valitusaika (yleensä 30 päivää)';

  @override
  String get contactLawyerImmediately =>
      'Ota välittömästi yhteyttä lakimieheen';

  @override
  String get applyLegalAid => 'Hae oikeusapua tarvittaessa';

  @override
  String get rightAppealAdmin => 'Oikeus valittaa hallinto-oikeuteen';

  @override
  String get rightLegalRep => 'Oikeus oikeudelliseen edustukseen';

  @override
  String get rightInterpreter => 'Oikeus tulkkiin';

  @override
  String get rightStayDuringAppeal =>
      'Oikeus jäädä valituksen ajaksi (useimmissa tapauksissa)';

  @override
  String get minimumWage => 'Vähimmäispalkka työehtosopimuksen mukaan';

  @override
  String get workingTimeLimits => 'Työaikarajat (max 8h/päivä, 40h/viikko)';

  @override
  String get annualLeave =>
      'Vuosiloma (vähintään 2 päivää työskentelykuukaudelta)';

  @override
  String get sickLeave => 'Sairausajan palkka';

  @override
  String get safeWorkingConditions => 'Turvalliset työolosuhteet';

  @override
  String get writtenRentalAgreement => 'Kirjallinen vuokrasopimus vaaditaan';

  @override
  String get securityDeposit => 'Vuokravakuus enintään 3 kuukauden vuokra';

  @override
  String get landlordNotice =>
      'Vuokranantajan on annettava irtisanomisilmoitus (3–6 kuukautta)';

  @override
  String get rightHabitableDwelling => 'Oikeus asuttavaan asuntoon';

  @override
  String get protectionUnjustEviction => 'Suoja perusteettomalta häädöltä';

  @override
  String get rightKnowDetentionReason => 'Oikeus tietää pidätyksen syy';

  @override
  String get rightContactLawyerDetention => 'Oikeus ottaa yhteyttä lakimieheen';

  @override
  String get rightContactEmbassy => 'Oikeus ottaa yhteyttä suurlähetystöösi';

  @override
  String get rightChallengeDetention => 'Oikeus riitauttaa pidätys oikeudessa';

  @override
  String get rightHumaneTreatment =>
      'Oikeus inhimilliseen kohteluun ja sairaanhoitoon';

  @override
  String get documentIncident =>
      'Dokumentoi tapahtuma (päivämäärä, aika, todistajat)';

  @override
  String get fileComplaintOmbudsman =>
      'Tee valitus yhdenvertaisuusvaltuutetulle';

  @override
  String get contactLegalAidOffice => 'Ota yhteyttä oikeusaputoimistoon';

  @override
  String get reportToPolice =>
      'Ilmoita poliisille jos rikos (uhkaus, pahoinpitely)';

  @override
  String get legalAidCalculator => 'Oikeusapulaskuri';

  @override
  String checkEligibility(String country) {
    return 'Tarkista oikeutesi oikeusapuun: $country';
  }

  @override
  String get estimateDisclaimer =>
      'Tämä on vain arvio. Todellisen kelpoisuuden määrittää oikeusaputoimisto.';

  @override
  String get monthlyIncome => 'Kuukausitulot (EUR)';

  @override
  String get totalAssets => 'Varallisuus yhteensä (EUR)';

  @override
  String get numberOfDependents => 'Huollettavien määrä';

  @override
  String get calculateEligibility => 'Laske kelpoisuus';

  @override
  String get likelyEligible => 'Todennäköisesti oikeutettu';

  @override
  String get mayNotQualify => 'Ei ehkä oikeutettu';

  @override
  String get fullFreeLegalAid =>
      'Olet todennäköisesti oikeutettu täyteen ilmaiseen oikeusapuun (ei omavastuuta).';

  @override
  String legalAidWithCopay(String percent) {
    return 'Saatat olla oikeutettu oikeusapuun $percent% omavastuulla.';
  }

  @override
  String get mayNotQualifyDesc =>
      'Tämän arvion perusteella et ehkä ole oikeutettu valtion oikeusapuun. Harkitse yksityisen lakimiehen tai oikeusklinikan konsultointia.';

  @override
  String get couldNotLoadDeadlines => 'Määräaikojen lataus epäonnistui';

  @override
  String get noUpcomingDeadlines => 'Ei tulevia määräaikoja';

  @override
  String get allClearDeadlines =>
      'Kaikki kunnossa! Uudet määräajat näkyvät täällä kun ne asetetaan.';

  @override
  String get nothingOverdue => 'Ei myöhässä olevia';

  @override
  String get greatJobDeadlines => 'Hienoa työtä määräaikojen noudattamisessa.';

  @override
  String get noCompletedDeadlines => 'Ei valmiita määräaikoja';

  @override
  String get completedDeadlinesDesc => 'Valmiit määräajat näkyvät täällä.';

  @override
  String get daysLate => 'päivää myöhässä';

  @override
  String get days => 'päivää';

  @override
  String get fromDocument => 'Asiakirjasta';

  @override
  String get couldNotLoadCase => 'Asian tietojen lataus epäonnistui';

  @override
  String get typeLabel => 'Tyyppi';

  @override
  String get nationality => 'Kansalaisuus';

  @override
  String get migriReference => 'Migri-viite';

  @override
  String get courtCaseNo => 'Oikeusasian nro';

  @override
  String get created => 'Luotu';

  @override
  String get citizenship => 'Kansalaisuus';

  @override
  String get workPermit => 'Työlupa';

  @override
  String get noDocumentsYet => 'Ei vielä asiakirjoja';

  @override
  String get noUpcomingDeadlinesShort => 'Ei tulevia määräaikoja';

  @override
  String get caseCreated => 'Asia luotu';

  @override
  String get decisionReceived => 'Päätös vastaanotettu';

  @override
  String get appealDeadline => 'Valitusmääräaika';

  @override
  String get hearingScheduled => 'Istunto sovittu';

  @override
  String get late => 'myöhässä';

  @override
  String get pending => 'Odottaa';

  @override
  String get processing => 'Käsittelyssä';

  @override
  String get ready => 'Valmis';

  @override
  String get failed => 'Epäonnistui';

  @override
  String get analyzed => 'Analysoitu';

  @override
  String get noDocumentsScanHint => 'Ei vielä asiakirjoja. Skannaa tai lataa.';

  @override
  String get inCourt => 'Oikeudessa';

  @override
  String get appeal => 'Valitus';

  @override
  String get caseTimeline => 'Asian aikajana';

  @override
  String get couldNotLoadTimeline => 'Aikajanan lataus epäonnistui';

  @override
  String get noEventsYet => 'Ei vielä tapahtumia';

  @override
  String get activityWillAppear => 'Toiminta näkyy täällä asian edetessä.';

  @override
  String caseCreatedDesc(String title) {
    return 'Asia ”$title” luotiin.';
  }

  @override
  String get decisionReceivedDesc =>
      'Virallinen päätös vastaanotettiin tässä asiassa.';

  @override
  String get appealDeadlineSet => 'Valitusmääräaika asetettu';

  @override
  String appealDeadlineDesc(String date) {
    return 'Valitus on jätettävä viimeistään $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Oikeudenkäynti sovittu $date.';
  }

  @override
  String get caseInfoUpdated => 'Asian tiedot päivitettiin viimeksi.';

  @override
  String get documentAnalysis => 'Asiakirja-analyysi';

  @override
  String get exportAsPdf => 'Vie PDF-tiedostona';

  @override
  String get pdfExportComingSoon => 'PDF-vienti tulossa pian';

  @override
  String get analysisFailedRetry => 'Analyysi epäonnistui. Yritä uudelleen.';

  @override
  String get somethingWentWrong => 'Jokin meni pieleen';

  @override
  String get retryAnalysis => 'Yritä analyysia uudelleen';

  @override
  String issuesFoundInDocument(int count) {
    return 'Löydettiin $count ongelmaa asiakirjasta';
  }

  @override
  String get severityOverview => 'Vakavuusyhteenveto';

  @override
  String get issuesFoundHeader => 'Löydetyt ongelmat';

  @override
  String generateAppealWithIssues(int count) {
    return 'Luo valitus ($count ongelmaa)';
  }

  @override
  String get analyzingContent => 'Analysoidaan sisältöä…';

  @override
  String get documentProcessedOk => 'Asiakirja käsitelty onnistuneesti';

  @override
  String get noSignificantIssues =>
      'Tässä asiakirjassa ei havaittu merkittäviä ongelmia.';

  @override
  String get cameraPermissionRequired => 'Kameralupa vaaditaan';

  @override
  String get cameraPermissionDesc =>
      'Myönnä kameran käyttöoikeus asiakirjojen skannaamiseen tai käytä galleriaa.';

  @override
  String get openSettings => 'Avaa asetukset';

  @override
  String get alignDocument => 'Kohdista asiakirja kehykseen';

  @override
  String pageCount(int count) {
    return '$count sivua';
  }

  @override
  String get preview => 'Esikatselu';

  @override
  String pageNumber(int number) {
    return 'Sivu $number';
  }

  @override
  String get done => 'Valmis';

  @override
  String get retake => 'Ota uudelleen';

  @override
  String get useThisPhoto => 'Käytä tätä kuvaa';

  @override
  String get addPage => 'Lisää sivu';

  @override
  String uploadingPercent(int percent) {
    return 'Ladataan… $percent%';
  }

  @override
  String get preparingUpload => 'Valmistellaan latausta…';

  @override
  String get documentUploadedSuccess => 'Asiakirja ladattu onnistuneesti';

  @override
  String pagesUploadedSuccess(int count) {
    return '$count sivua ladattu onnistuneesti';
  }

  @override
  String get uploadFailed =>
      'Lataus epäonnistui. Tarkista yhteys ja yritä uudelleen.';

  @override
  String get capturePhotoFailed =>
      'Kuvan ottaminen epäonnistui. Yritä uudelleen.';

  @override
  String get readingText => 'Luetaan tekstiä…';

  @override
  String get draftDocument => 'Asiakirjaluonnos';

  @override
  String get saveChanges => 'Tallenna muutokset';

  @override
  String get editDocument => 'Muokkaa asiakirjaa';

  @override
  String get generatingDraft => 'Luodaan luonnosta…';

  @override
  String get generatingDraftDesc =>
      'Tekoäly valmistelee oikeudellista asiakirjaa asiasi tietojen ja valittujen ongelmien perusteella.';

  @override
  String get failedToGenerateDraft =>
      'Luonnoksen luominen epäonnistui. Yritä uudelleen.';

  @override
  String get changesSaved => 'Muutokset tallennettu';

  @override
  String get copiedToClipboard => 'Kopioitu leikepöydälle';

  @override
  String get emailComingSoon => 'Sähköpostilähetys tulossa pian';

  @override
  String get reviewBeforeSending =>
      'Tarkista huolellisesti ennen lähettämistä. Olet vastuussa asiakirjan sisällöstä.';

  @override
  String get noContentAvailable => 'Sisältöä ei saatavilla';

  @override
  String get save => 'Tallenna';

  @override
  String get edit => 'Muokkaa';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Kopioi';

  @override
  String get appealDraft => 'Valitusluonnos';

  @override
  String selected(int count) {
    return '$count valittu';
  }

  @override
  String get deleteSelected => 'Poista valitut';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Poistetaanko $count asiakirjaa?';
  }

  @override
  String get delete => 'Poista';

  @override
  String get analyzeSelected => 'Analysoi valitut';

  @override
  String get batchAnalysisStarting => 'Eräanalyysi alkaa…';

  @override
  String get switchToList => 'Vaihda listanäkymään';

  @override
  String get switchToGrid => 'Vaihda ruudukkonäkymään';

  @override
  String get scanNew => 'Skannaa uusi';

  @override
  String get noDocumentsYetScan => 'Ei vielä asiakirjoja';

  @override
  String get scanFirstDocumentHint =>
      'Skannaa ensimmäinen asiakirja, jotta tekoäly voi analysoida sen virheiden varalta ja luoda valituksia.';

  @override
  String get failedToLoadDocuments => 'Asiakirjojen lataus epäonnistui';

  @override
  String get emailIntegrationTitle => 'Sähköposti-integraatio';

  @override
  String get connectYourEmail => 'Yhdistä sähköpostisi';

  @override
  String get connectYourEmailDesc =>
      'Yhdistä sähköpostisi tunnistaaksesi ja järjestääksesi automaattisesti tapauksiisi liittyvän oikeudellisen kirjeenvaihdon.';

  @override
  String get legalEmails => 'Oikeudelliset sähköpostit';

  @override
  String get unlinkedEmails => 'Linkittämättömät sähköpostit';

  @override
  String get noLegalEmailsYet => 'Ei vielä oikeudellisia sähköposteja';

  @override
  String get legalEmailsWillAppear =>
      'Oikeudellisiksi luokitellut sähköpostit näkyvät täällä.';

  @override
  String get assignToCase => 'Liitä tapaukseen';

  @override
  String get disconnectEmail => 'Katkaise sähköposti';

  @override
  String get disconnectEmailConfirm =>
      'Automaattinen sähköpostisynkronointi lopetetaan. Aiemmin synkronoidut sähköpostit säilyvät tapauksissasi.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1 lukee postilaatikkoasi laatiakseen vastauksia; voit peruuttaa luvan milloin tahansa. Yhdistä Gmail uudelleen ottaaksesi käyttöön proaktiivisen seulonnan.';

  @override
  String get gmailReauthBannerCta => 'Vahvista uudelleen';

  @override
  String connectedTo(String email) {
    return 'Yhdistetty: $email';
  }

  @override
  String lastSynced(String time) {
    return 'Synkronoitu: $time';
  }

  @override
  String get filterByType => 'Suodata tyypin mukaan';

  @override
  String get noCasesMatchSearch => 'Hakuasi vastaavia tapauksia ei löytynyt';

  @override
  String get failedToLoadCases => 'Tapausten lataus epäonnistui';

  @override
  String get monthly => 'Kuukausittainen';

  @override
  String get annual => 'Vuosittainen';

  @override
  String get saveTwentyFivePercent => 'Säästä 25%';

  @override
  String get mostPopular => 'SUOSITUIN';

  @override
  String get oneCaseActive => '1 aktiivinen tapaus';

  @override
  String get threeCasesActive => '3 aktiivista tapausta';

  @override
  String get unlimitedCases => 'Rajattomat tapaukset';

  @override
  String get threeDocScans => '3 dokumenttiskannausta';

  @override
  String get twentyDocScans => '20 dokumenttiskannausta';

  @override
  String get unlimitedDocScans => 'Rajaton dokumenttiskannaus';

  @override
  String get basicAiAnalysis => 'Perus tekoälyanalyysi';

  @override
  String get fullAiAnalysis => 'Täysi tekoälyanalyysi';

  @override
  String get draftGeneration => 'Luonnosten luonti';

  @override
  String get priorityProcessing => 'Prioriteettikäsittely';

  @override
  String get fiveAiMessagesTotal => '5 tekoälyviestiä (koko käyttöaika)';

  @override
  String get hundredAiMessagesDay => '100 tekoälyviestiä/päivä';

  @override
  String get unlimitedAiMessages => 'Rajattomat tekoälyviestit';

  @override
  String get voiceInput => 'Äänitulo';

  @override
  String get strategyRecommendations => 'Strategiasuositukset';

  @override
  String get foundingMemberNote =>
      'Perustajajäsen: 9,99€/kk ensimmäiset 3 kuukautta';

  @override
  String get saveTwentyPercent => 'Säästä 20%';

  @override
  String get forever => 'ikuisesti';

  @override
  String get perMonth => '/kk';

  @override
  String get perYear => '/v';

  @override
  String get checkingPurchases => 'Tarkistetaan aiempia ostoksia…';

  @override
  String get noPreviousPurchases => 'Aiempia ostoksia ei löytynyt.';

  @override
  String get chatWelcomeMessage =>
      'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?';

  @override
  String get copySummary => 'Kopioi yhteenveto';

  @override
  String get caseSummaryCopied => 'Tapauksen yhteenveto kopioitu';

  @override
  String get openCase => 'Avaa tapaus';

  @override
  String get viewFull => 'Näytä kokonaan';

  @override
  String get draftCopiedToClipboard => 'Luonnos kopioitu leikepöydälle';

  @override
  String get reportMileageFraud => 'Ilmoita mittarilukemapetoksesta';

  @override
  String get reportMileageFraudDesc =>
      'Tämä luo petosraportin ajoneuvon tarkistustietojen perusteella. Voit myös avata oikeudellisen tapauksen.';

  @override
  String get reportAndOpenCase => 'Ilmoita ja avaa tapaus';

  @override
  String get caseCreationComingSoon =>
      'Tapauksen luominen esitäytetyillä tiedoilla tulossa pian';

  @override
  String get failedToCreateCaseRetry =>
      'Tapauksen luominen epäonnistui. Yritä uudelleen.';

  @override
  String get takePhotoInstead => 'Ota kuva';

  @override
  String get deleteCase => 'Poista tapaus';

  @override
  String deleteCaseConfirm(String title) {
    return 'Haluatko varmasti poistaa ”$title”? Toimintoa ei voi kumota.';
  }

  @override
  String get haveQuestionsAi => 'Onko kysyttävää? Kysy tekoälyltä';

  @override
  String get cookiePolicy => 'Evästekäytäntö';

  @override
  String get aiDisclaimer => 'Tekoälylauseke';

  @override
  String get dataPrivacyConsent => 'Tietosuojasuostumus';

  @override
  String get gdprIntro =>
      'Tarjotaksemme tekoälypohjaista oikeusapua käsittelemme tietojasi GDPR:n (EU 2016/679) mukaisesti. Jatkamalla hyväksyt:';

  @override
  String get gdprChat => 'Chattiviestien käsittely tekoälyllä';

  @override
  String get gdprDocs => 'Ladattujen dokumenttien analysointi';

  @override
  String get gdprStorage => 'Tapausten salattu tallennus';

  @override
  String get gdprDelete => 'Oikeus poistaa tietosi milloin tahansa';

  @override
  String get gdprFooter =>
      'Tietosi on salattu eikä niitä jaeta kolmansille osapuolille. Voit peruuttaa suostumuksen ja poistaa kaikki tiedot Asetuksista.';

  @override
  String get gdprConsentAiProcessing =>
      'Hyväksyn tietojeni käsittelyn tekoälypohjaiseen oikeusapuun (pakollinen)';

  @override
  String get gdprConsentAnalytics =>
      'Hyväksyn analytiikan palvelun parantamiseksi (valinnainen)';

  @override
  String get gdprArt9Intro =>
      'Tämä sovellus käsittelee erityisiä henkilötietoja GDPR:n artiklan 9 mukaisesti, mukaan lukien:';

  @override
  String get gdprSpecialLegalCases =>
      'Oikeudenkäyntiasiakirjat ja tapauksesi tiedot';

  @override
  String get gdprSpecialNationality => 'Kansalaisuus ja maahanmuuttostatus';

  @override
  String get gdprConsentLegalData =>
      'Annan suostumukseni oikeudellisten tietojeni, kansalaisuuteni ja maahanmuuttostatukseni käsittelyyn tekoälyllä (pakollinen)';

  @override
  String get gdprConsentVoice =>
      'Annan suostumukseni äänitallenteiden käsittelyyn (valinnainen)';

  @override
  String get gdprViewPrivacyPolicy => 'Näytä tietosuojakäytäntö';

  @override
  String get legalInformation => 'Oikeudellinen tieto';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Rekisterinumero: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'Sähköposti: support@advocat.ee';

  @override
  String get legalRegistry =>
      'Rekisteröity Viron kaupparekisteriin (Äriregister)';

  @override
  String get aiGeneratedDisclaimer =>
      'Tekoälyn luoma • Ei oikeudellista neuvontaa';

  @override
  String get decline => 'Hylkää';

  @override
  String get iAgree => 'Hyväksyn';

  @override
  String get iAgreeToThe => 'Hyväksyn ';

  @override
  String get orWord => 'tai';

  @override
  String get english => 'Englanti';

  @override
  String get russian => 'Venäjä';

  @override
  String get finnish => 'Suomi';

  @override
  String successSubscribed(String plan) {
    return 'Tilaus $plan onnistui!';
  }

  @override
  String paymentFailed(String error) {
    return 'Maksu epäonnistui: $error';
  }

  @override
  String get whatToDo => 'Mitä tehdä';

  @override
  String get getHelp => 'Saa apua';

  @override
  String get share => 'Jaa';

  @override
  String get didYouKnow => 'Tiesitkö?';

  @override
  String get mustKnow => 'Tärkeää tietää';

  @override
  String get goodToKnow => 'Hyvä tietää';

  @override
  String get sentFromAdvocat => 'Lähetetty Advocat-sovelluksesta';

  @override
  String get policeActionStayCalm =>
      'Pysy rauhallisena ja pidä kädet näkyvillä';

  @override
  String get policeActionAskWhy => 'Kysy poliisilta, miksi sinut pysäytettiin';

  @override
  String get policeActionProvideName => 'Ilmoita nimesi ja syntymäaikasi';

  @override
  String get policeActionWantLawyer =>
      'Sano selvästi: ”Haluan asianajajan ennen kysymyksiä”';

  @override
  String get policeActionAskInterpreter => 'Pyydä tarvittaessa tulkki';

  @override
  String get policeActionNoteBadge =>
      'Merkitse muistiin poliisin nimi ja virkamerkki';

  @override
  String get policeFactMustTellReason =>
      'Suomessa poliisin on kerrottava pysäytyksen syy. Jos he eivät kerro, voit kysyä — he ovat lain mukaan velvollisia selittämään.';

  @override
  String get policeFactCanRecord =>
      'Suomessa voit tallentaa poliisikontaktit julkisilla paikoilla. Tämä on suojattu sananvapauden nojalla.';

  @override
  String get contactFinnishLegalAid => 'Suomen oikeusapu';

  @override
  String get contactNonDiscriminationOmbudsman => 'Yhdenvertaisuusvaltuutettu';

  @override
  String get deportationDeadlineAppeal =>
      'Valitus hallinto-oikeuteen — yleensä 30 päivää tiedoksiannosta';

  @override
  String get deportationDeadlineLegalAid => 'Hae oikeusapua — tee se HETI';

  @override
  String get deportationFactStayDuringAppeal =>
      'Suomessa sinulla on yleensä oikeus jäädä maahan valituksen käsittelyn ajaksi. Karkotusta ei voida toteuttaa aktiivisen valituksen aikana useimmissa tapauksissa.';

  @override
  String get contactRefugeeAdviceCentre => 'Pakolaisneuvonta ry';

  @override
  String get contactAdminCourtHelsinki => 'Helsingin hallinto-oikeus';

  @override
  String get workplaceActionKeepContract => 'Säilytä kopiot työsopimuksestasi';

  @override
  String get workplaceActionTrackHours => 'Seuraa työaikojasi itsenäisesti';

  @override
  String get workplaceActionReportUnsafe =>
      'Ilmoita vaarallisista olosuhteista työsuojeluun';

  @override
  String get workplaceActionJoinUnion => 'Liity ammattiliittoon suojaksi';

  @override
  String get workplaceActionContactAuthority =>
      'Ota tarvittaessa yhteyttä työsuojeluviranomaiseen';

  @override
  String get workplaceFactCollectiveWage =>
      'Suomessa työehtosopimukset määrittävät vähimmäispalkat toimialoittain — yhtä kansallista minimipalkkaa ei ole. Työnantajan on noudatettava alasi työehtosopimusta.';

  @override
  String get workplaceFactOralContract =>
      'Ilman kirjallista sopimusta sinulla on täydet työntekijän oikeudet Suomessa. Suullinen sopimus on lain mukaan yhtä sitova.';

  @override
  String get contactOccupationalSafety => 'Työsuojeluviranomainen';

  @override
  String get contactTradeUnionSAK => 'Ammattiliittoneuvonta (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Tee aina kirjallinen vuokrasopimus';

  @override
  String get tenantActionDocumentCondition =>
      'Dokumentoi asunnon kunto muuton yhteydessä (kuvat)';

  @override
  String get tenantActionReportMaintenance =>
      'Ilmoita huoltotarpeista kirjallisesti';

  @override
  String get tenantActionNoIllegalEviction =>
      'Älä koskaan suostu laittomaan häätöön — tuomioistuin päättää';

  @override
  String get tenantActionContactAdvisory =>
      'Ota yhteyttä vuokralaisten neuvontapalveluun riitatilanteissa';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Vuokranantaja ei voi häätää sinua Suomessa ilman tuomioistuimen päätöstä, vaikka vuokrasopimus olisi päättynyt. Lukkojen vaihtaminen tai palvelujen katkaiseminen on laitonta.';

  @override
  String get contactTenantsAssociation => 'Suomen Vuokranantajat ry';

  @override
  String get contactConsumerDisputesBoard => 'Kuluttajariitalautakunta';

  @override
  String get detentionActionAskDecision =>
      'Pyydä kirjallinen säilöönottopäätös välittömästi';

  @override
  String get detentionActionRequestLawyer => 'Pyydä saada yhteys asianajajaan';

  @override
  String get detentionActionContactEmbassy =>
      'Ota yhteyttä suurlähetystöösi tai konsulaattiin';

  @override
  String get detentionActionAskMedical => 'Pyydä tarvittaessa lääkärinhoitoa';

  @override
  String get detentionActionRequestInterpreter =>
      'Vaadi tulkki kaikkiin menettelyihin';

  @override
  String get detentionDeadlineCourtReview =>
      'Käräjäoikeuden on tarkistettava säilöönotto 4 päivän kuluessa';

  @override
  String get detentionDeadlineContinuation =>
      'Tuomioistuin tarkistaa jatkamisen 2 viikon välein';

  @override
  String get detentionFactCourtReview =>
      'Maahanmuuttosäilöönotto Suomessa on tarkistettava käräjäoikeudessa 4 päivän kuluessa. Jos näin ei tehdä, säilöönotto muuttuu laittomaksi.';

  @override
  String get contactParliamentaryOmbudsman => 'Eduskunnan oikeusasiamies';

  @override
  String get discriminationActionWriteDown =>
      'Kirjoita tarkasti mitä tapahtui (päivämäärä, aika, paikka)';

  @override
  String get discriminationActionSaveEvidence =>
      'Tallenna todisteet: viestit, sähköpostit, todistajat';

  @override
  String get discriminationActionFileComplaint =>
      'Tee valitus yhdenvertaisuusvaltuutetulle';

  @override
  String get discriminationActionContactLegalAid =>
      'Ota yhteyttä oikeusaputoimistoon ilmaista neuvontaa varten';

  @override
  String get discriminationActionReportPolice =>
      'Tee rikosilmoitus, jos kyseessä oli uhkaus tai pahoinpitely';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'Suomen yhdenvertaisuuslaki kattaa syrjinnän iän, alkuperän, kansalaisuuden, kielen, uskonnon, terveyden, vammaisuuden, seksuaalisen suuntautumisen ja muiden henkilökohtaisten ominaisuuksien perusteella.';

  @override
  String get contactVictimSupportRIKU => 'Rikosuhripäivystys (RIKU)';

  @override
  String get domesticViolence => 'Perheväkivalta';

  @override
  String get domesticViolenceDesc =>
      'Uhrin oikeudet, hätäapu, lähestymiskiellot';

  @override
  String get rightCallEmergency =>
      'Sinulla on oikeus soittaa 112 missä tahansa hätätilanteessa — poliisi, ambulanssi, palokunta';

  @override
  String get rightVictimProtection =>
      'Uhrina sinulla on oikeus suojeluun, tukeen ja tietoihin asiasi etenemisestä';

  @override
  String get rightRestrainingOrder =>
      'Voit hakea lähestymiskieltoa pitääksesi väkivallantekijän loitolla';

  @override
  String get rightVictimInterpreter =>
      'Sinulla on oikeus tulkkiin kaikissa oikeudellisissa menettelyissä';

  @override
  String get rightMedicalHelp =>
      'Sinulla on oikeus välittömään lääkärinhoitoon ja vammojen dokumentointiin';

  @override
  String get rightShelter =>
      'Sinulla on oikeus hätämajoitukseen — ota yhteyttä turvakotiin tai sosiaalitoimeen';

  @override
  String get mustReportDanger =>
      'Jos joku on välittömässä vaarassa, soita heti 112';

  @override
  String get mustDocumentInjuries =>
      'Dokumentoi kaikki vammat — valokuvat, lääkärintodistukset, kirjalliset muistiinpanot';

  @override
  String get domesticActionCallEmergency =>
      'Soita 112, jos olet välittömässä vaarassa';

  @override
  String get domesticActionGoToSafe =>
      'Mene turvalliseen paikkaan — turvakoti, ystävä, julkinen paikka';

  @override
  String get domesticActionDocumentEverything =>
      'Dokumentoi vammat: ota valokuvia, hanki lääkärintodistukset';

  @override
  String get domesticActionFilePoliceReport =>
      'Tee rikosilmoitus — voit tehdä sen myös myöhemmin';

  @override
  String get domesticActionContactShelter =>
      'Ota yhteyttä turvakotiin tai kriisipuhelimeen';

  @override
  String get domesticActionApplyRestraining =>
      'Hae lähestymiskieltoa poliisin tai tuomioistuimen kautta';

  @override
  String get domesticFactRestrainingOrder =>
      'Suomessa lähestymiskielto voidaan määrätä myös ilman rikosasiaa. Se kieltää henkilöä ottamasta yhteyttä tai lähestymästä sinua.';

  @override
  String get domesticFactVictimDirective =>
      'EU:n uhridirektiivin 2012/29/EU mukaan sinulla on oikeus tulla kohdelluksi kunnioittavasti, saada tietoa ymmärtämälläsi kielellä ja käyttää uhrien tukipalveluja — riippumatta asuinstatuksestasi.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Rikosilmoitus — ei tiukkaa määräaikaa, mutta mitä nopeammin sitä parempi todisteiden kannalta';

  @override
  String get domesticDeadlineRestraining =>
      'Lähestymiskielto — voidaan hakea milloin tahansa';

  @override
  String get contactEmergency => 'Hätänumero';

  @override
  String get contactShelter => 'Turvakoti-puhelin';

  @override
  String get contactCrisisHelpline => 'Kriisipuhelin';

  @override
  String get contactNollaLinja =>
      'Nollalinja — Naisiin kohdistuvan väkivallan auttava puhelin';

  @override
  String get inheritance => 'Perintö';

  @override
  String get inheritanceDesc =>
      'Wills, estate, heirs\' rights, forced heirship, probate';

  @override
  String get rightInheritanceForced =>
      'Forced heirs (children, spouse) are entitled to a compulsory share regardless of the will';

  @override
  String get rightInheritanceWill =>
      'You have the right to make a will disposing of your property — notarized wills have the strongest legal force';

  @override
  String get rightInheritanceRenounce =>
      'You can renounce an inheritance within 3 months of learning about it';

  @override
  String get rightInheritanceInfo =>
      'You have the right to obtain information about the estate from banks and registries';

  @override
  String get rightInheritanceDispute =>
      'You can challenge an unfair will in court within the statutory limitation period';

  @override
  String get mustFileInheritance =>
      'File for succession proceedings at a notary within a reasonable time';

  @override
  String get mustNotifyHeirs =>
      'All known heirs must be notified of the succession proceedings';

  @override
  String get inheritanceActionGatherDocs =>
      'Gather all documents: death certificate, will, property records, bank statements';

  @override
  String get inheritanceActionContactNotary =>
      'Contact a notary to open succession proceedings';

  @override
  String get inheritanceActionCheckDebts =>
      'Check whether the estate has debts before accepting inheritance';

  @override
  String get inheritanceActionFileCourt =>
      'If the will is disputed, file a claim in court';

  @override
  String get inheritanceDeadlineRenounce =>
      '3 months to renounce inheritance after learning of it';

  @override
  String get inheritanceDeadlineDispute =>
      'Statute of limitations for challenging a will: varies by grounds';

  @override
  String get inheritanceFactForced =>
      'In Estonia, descendants and spouse have a right to a compulsory share (1/2 of legal share) even if excluded from the will';

  @override
  String get inheritanceFactNotary =>
      'All succession proceedings in Estonia must go through a notary — you cannot skip this step';

  @override
  String get consumerProtection => 'Kuluttajansuoja';

  @override
  String get consumerProtectionDesc =>
      'Petokset, vialliset tuotteet, palautukset, harhaanjohtavat myyjät';

  @override
  String get rightReturnOnline =>
      'Sinulla on 14 päivää aikaa peruuttaa verkko-ostokset ilman syytä (EU:n peruuttamisoikeus)';

  @override
  String get rightDefectiveProduct =>
      'Jos tuote on viallinen, sinulla on oikeus korjaukseen, vaihtoon tai hyvitykseen';

  @override
  String get rightClearPricing =>
      'Myyjien on näytettävä selkeät hinnat kaikkine maksuineen — piilokulut ovat laittomia';

  @override
  String get rightComplainBoard =>
      'Voit tehdä ilmaisen valituksen kuluttajariitalautakuntaan';

  @override
  String get rightProtectionFraud =>
      'Sinua suojataan sopimattomilta kaupallisilta käytännöiltä ja petoksilta';

  @override
  String get mustKeepReceipts =>
      'Säilytä kaikki kuitit, sopimukset ja viestintä myyjien kanssa';

  @override
  String get mustActTimely =>
      'Ilmoita virheistä myyjälle kohtuullisessa ajassa havaitsemisen jälkeen';

  @override
  String get consumerActionKeepEvidence =>
      'Säilytä kuitit, kuvakaappaukset, sähköpostit ja kaikki ostotodisteet';

  @override
  String get consumerActionContactSeller =>
      'Ota ensin yhteyttä myyjään — selitä ongelma kirjallisesti';

  @override
  String get consumerActionFileComplaint =>
      'Tee valitus kuluttajariitalautakuntaan';

  @override
  String get consumerActionContactAuthority =>
      'Ota yhteyttä kuluttajaneuvontaan saadaksesi ilmaista apua';

  @override
  String get consumerActionReportFraud =>
      'Ilmoita petoksesta poliisille ja kuluttaja-asiamiehelle';

  @override
  String get consumerFactWithdrawal =>
      'EU:n kuluttajaoikeusdirektiivin 2011/83/EU mukaan sinulla on 14 päivää aikaa peruuttaa verkko- tai etäostos — ilman perusteluja. Myyjän on palautettava rahat 14 päivän kuluessa.';

  @override
  String get consumerFactWarranty =>
      'Suomessa myyjä vastaa tuotteen virheistä kohtuullisen ajan (usein 2+ vuotta). Tämä on erillinen valmistajan takuusta.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Verkko-ostoksen peruuttaminen — 14 päivää toimituksesta';

  @override
  String get consumerDeadlineDefect =>
      'Ilmoita virheestä myyjälle — kahden kuukauden kuluessa havaitsemisesta (suositus)';

  @override
  String get contactConsumerAdvisory => 'Kuluttajaneuvonta';

  @override
  String get contactConsumerOmbudsman => 'Kuluttaja-asiamies';

  @override
  String get contactConsumerDisputesBoardDirect => 'Kuluttajariitalautakunta';

  @override
  String get caseTypeStepLabel => 'Tapaustyyppi';

  @override
  String get detailsStepLabel => 'Tiedot';

  @override
  String get documentsStepLabel => 'Asiakirjat';

  @override
  String get whatTypeOfCase => 'Minkä tyyppinen tapaus tämä on?';

  @override
  String get selectCategoryDescription =>
      'Valitse luokka, joka kuvaa parhaiten tilannettasi.';

  @override
  String get tellUsAboutCase => 'Kerro meille tapauksestasi';

  @override
  String get aiHelpsUnderstand =>
      'Nämä tiedot auttavat tekoälyämme ymmärtämään tilanteesi paremmin.';

  @override
  String get caseTitleHint => 'esim. Oleskelulupahakemus 2026';

  @override
  String get countryJurisdiction => 'Maa / Lainkäyttöalue';

  @override
  String get selectCountryHint => 'Valitse maa';

  @override
  String get referenceNumberHint => 'esim. UMA/12345/2026';

  @override
  String get descriptionOptional => 'Kuvaus (valinnainen)';

  @override
  String get descriptionHint =>
      'Kuvaile tilannettasi lyhyesti. Mitä tapahtui? Mikä päätös tehtiin?';

  @override
  String get uploadFirstDocument => 'Lataa ensimmäinen asiakirjasi';

  @override
  String get uploadDocumentDescription =>
      'Lataa päätöskirje tai muu asiakirja. Voit ohittaa tämän vaiheen ja lisätä asiakirjoja myöhemmin.';

  @override
  String get tapToUploadFile => 'Napauta ladataksesi tiedoston';

  @override
  String get fileSizeLimit => 'PDF, JPG, PNG enintään 25 MB';

  @override
  String get addDocumentsLaterHint =>
      'Voit aina lisätä asiakirjoja myöhemmin tapauksen tietosivulta.';

  @override
  String get callAI => 'Soita tekoälylle';

  @override
  String get comingSoon => 'Tulossa pian';

  @override
  String get encrypted => 'Salattu';

  @override
  String get typing => 'Kirjoittaa…';

  @override
  String get online => 'Paikalla';

  @override
  String get chatWelcomeSubtitle =>
      'Analysoin tilanteen, tarkistan asiakirjat, etsin virheitä ja ehdotan, mitä tehdä.';

  @override
  String get tapMicrophoneToSpeak => 'Napauta mikrofonia puhuaksesi';

  @override
  String get categoryEssential => 'Tärkeät';

  @override
  String get categoryPolice => 'Poliisi';

  @override
  String get categoryWork => 'Työ';

  @override
  String get categoryHousing => 'Asuminen';

  @override
  String get categoryConsumer => 'Kuluttaja';

  @override
  String rightsInsideCount(int count) {
    return '$count oikeutta sisällä';
  }

  @override
  String get freeAidThreshold => 'Ilmaisen avun raja';

  @override
  String get partialAidThreshold => 'Osittaisen avun raja';

  @override
  String get assetLimit => 'Omaisuusraja';

  @override
  String get whereToApplyLabel => 'Mistä hakea';

  @override
  String get phoneLabel => 'Puhelin';

  @override
  String get websiteLabel => 'Verkkosivusto';

  @override
  String get disclaimerCollapsed => 'Vain tiedoksi';

  @override
  String get disclaimerExpanded =>
      'Tekoälyavustaja — ei oikeudellista neuvontaa. Tarkista aina pätevältä lakimieheltä.';

  @override
  String get chatDisclaimerBanner =>
      'Tekoälyavustaja tarjoaa oikeudellista tietoa, ei oikeudellista neuvontaa. Ota aina yhteyttä pätevään lakimieheen.';

  @override
  String get categoryChildren => 'Lapset';

  @override
  String get categoryDigital => 'Digitaalinen';

  @override
  String get childrenRights => 'Lapsen oikeudet ja elatusapu';

  @override
  String get childrenRightsDesc => 'Elatusapu, lastensuojelu, valtion takuu';

  @override
  String get cyberbullying => 'Nettikiusaaminen ja häirintä';

  @override
  String get cyberbullyingDesc =>
      'Uhkaukset, yksityisyyden loukkaus, kunnianloukkaus verkossa';

  @override
  String get rightChildSupport =>
      'Molemmat vanhemmat ovat lain mukaan velvollisia elättämään lastaan taloudellisesti (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Vuodesta 2022 vähimmäiselatusapu Virossa on 200 €/kk lasta kohden (hallituksen asettama perussumma). Tuomioistuin voi korottaa vanhemman tulojen perusteella (PKS § 101)';

  @override
  String get rightCourtAlimony =>
      'Elatusapua voi hakea maakohuksen kautta — asianajajaa ei tarvita alle 6 400 € vaatimuksiin';

  @override
  String get rightBailiffEnforcement =>
      'Jos vanhempi kieltäytyy maksamasta, ulosottomies (kohtutäitur) voi panna tuomion täytäntöön palkan ulosmittauksella';

  @override
  String get rightStateAlimonyGuarantee =>
      'Jos vanhempi ei maksa, valtio maksaa elatisabi Sotsiaalkindlustusametin kautta — enintään 100 €/kk lasta kohden';

  @override
  String get rightChildEducation =>
      'Jokaisella lapsella on oikeus koulutukseen, terveydenhuoltoon ja suojeluun (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'Lapsella on oikeus pitää yhteyttä molempiin vanhempiin, ellei tuomioistuin toisin päätä (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'Elatusavun saamiseksi on jätettävä kanne tuomioistuimeen tai sovittava summasta kirjallisesti';

  @override
  String get mustNotifyAddressChange =>
      'Ilmoita Sotsiaalkindlustusametille osoitteen muutoksesta elatisabia saadessasi';

  @override
  String get childrenActionGatherDocs =>
      'Kerää lapsen syntymätodistus, henkilöllisyystodistus ja kulujen todisteet';

  @override
  String get childrenActionFileCourtClaim =>
      'Jätä elatusapukanne maakohukseen — voidaan tehdä verkossa e-toimiku kautta';

  @override
  String get childrenActionApplyElatisabi =>
      'Hae valtion elatisapitakuuta (elatisabi) Sotsiaalkindlustusametista, jos vanhempi ei maksa';

  @override
  String get childrenActionContactBailiff =>
      'Ota yhteyttä ulosottomieheen (kohtutäitur) tuomion täytäntöönpanemiseksi';

  @override
  String get childrenActionCallLasteabi =>
      'Soita Lasteabi-puhelimeen 116 111 — maksuton, 24/7';

  @override
  String get childrenDeadlineElatisabi =>
      'Elatisabin hakeminen — tuomion jälkeen, ei tiukkaa määräaikaa, mutta prosessi vie aikaa';

  @override
  String get childrenDeadlineCourt =>
      'Elatusapua voi vaatia takautuvasti 1 vuotta ennen kanteen jättämistä';

  @override
  String get childrenFactMinimum =>
      'Virossa vähimmäiselatusapu on puolet vähimmäispalkasta lasta kohden. Vanhempi ei voi sopia pienemmästä summasta — edes yhteisellä sopimuksella.';

  @override
  String get childrenFactElatisabi =>
      'Viron valtion elatusaputakuu (elatisabi) otettiin käyttöön 2017 lasten suojelemiseksi, kun vanhempi kieltäytyy maksamasta. Valtio maksaa ja perii summan sitten velalliselta.';

  @override
  String get rightReportCybercrime =>
      'Sinulla on oikeus ilmoittaa poliisille verkkouhkauksista, häirinnästä ja identiteettivarkaudesta (KarS § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Voit vaatia halventavan tai yksityisen sisällön poistamista alustoilta GDPR:n nojalla';

  @override
  String get rightMoralDamageCompensation =>
      'Voit vaatia korvausta nettikiusaamisen aiheuttamasta henkisestä kärsimyksestä (VÕS § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'Yksityiselämäsi on suojattu — kuvien, viestien tai henkilötietojen luvaton jakaminen on laitonta (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Ilmoita tietosuojarikkomuksista Andmekaitse Inspektsioonille';

  @override
  String get rightDefamationAction =>
      'Kunnianloukkaus on siviilioikeudellinen rikkomus — voit vaatia vahingonkorvausta ja oikaisua (VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Kerää ja säilytä kaikki todisteet — kuvakaappaukset, linkit, päivämäärät ja todistajien tiedot';

  @override
  String get mustNotRetaliate =>
      'Älä kosta tai häiritse takaisin — se voi heikentää asemaasi';

  @override
  String get cyberActionScreenshots =>
      'Ota kuvakaappaukset kaikesta häirinnästä — tallenna URL-osoitteet, päivämäärät, käyttäjänimet ja sisältö';

  @override
  String get cyberActionReportPolice =>
      'Tee rikosilmoitus lähimmällä poliisiasemalla tai verkossa politsei.ee-sivustolla';

  @override
  String get cyberActionReportPlatform =>
      'Ilmoita sisällöstä sosiaalisen median alustalle poistamista varten';

  @override
  String get cyberActionContactDPA =>
      'Ota yhteyttä Andmekaitse Inspektsiooniin, jos henkilötietojasi on käytetty väärin';

  @override
  String get cyberActionConsultLawyer =>
      'Neuvottele lakimiehen kanssa siviilikorvauksista — ilmaista oikeusapua on saatavilla Riigi Õigusabin kautta';

  @override
  String get cyberDeadlineCriminal =>
      'Rikosilmoitus — ei tiukkaa määräaikaa, mutta ilmoita viipymättä parhaan tuloksen saamiseksi';

  @override
  String get cyberDeadlineCivil =>
      'Siviilioikeudellinen vahingonkorvausvaatimus — enintään 3 vuotta rikkomuksen havaitsemisesta (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'Virossa intiimikuvien luvaton jakaminen voi johtaa enintään 3 vuoden vankeusrangaistukseen KarS § 157¹ nojalla.';

  @override
  String get cyberFactGDPR =>
      'GDPR:n mukaan sinulla on \'oikeus tulla unohdetuksi\' — alustojen on poistettava henkilötietosi pyynnöstä, jos niiden säilyttämiselle ei ole laillista perustetta.';

  @override
  String get guestUser => 'Vieras';

  @override
  String get howToUse => 'Kuinka käyttää?';

  @override
  String get tutorialStep1Title => 'Tekoäly-lakiavustaja';

  @override
  String get tutorialStep1Desc =>
      'Kysy mikä tahansa oikeudellinen kysymys ja saat välittömät vastaukset Viron lakien perusteella.';

  @override
  String get tutorialStep2Title => 'Tunne oikeutesi';

  @override
  String get tutorialStep2Desc =>
      'Selaa oikeudellista tietoa aiheittain — työ, asuminen, kuluttajaoikeudet ja paljon muuta.';

  @override
  String get tutorialStep3Title => 'Skannaa asiakirjoja';

  @override
  String get tutorialStep3Desc =>
      'Ota kuvia oikeudellisista asiakirjoista tekoälyanalyysiä ja turvallista säilytystä varten.';

  @override
  String get tutorialStep4Title => 'Aloitetaan!';

  @override
  String get tutorialStep4Desc =>
      'Tutustu sovellukseen ja suojaa oikeutesi. Kaikki tiedot pysyvät yksityisinä laitteellasi.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Avaa premium-ominaisuudet';

  @override
  String get voiceDisclaimer =>
      'Ääniavustaja toimii tällä hetkellä vain tietokoneella (Chrome-selain). Mobiilatuki tulossa pian.';

  @override
  String get recommended => 'Suositeltava';

  @override
  String get pleaseLogIn => 'Kirjaudu sisään';

  @override
  String get subscriptionNotFound => 'Tilausta ei löytynyt';

  @override
  String errorWithMessage(String message) {
    return 'Virhe: $message';
  }

  @override
  String get redirectingToPayment => 'Siirrytään maksusivulle…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/kk edullisempi vuositilauksella';
  }

  @override
  String get navigatingTo => 'Avataan';

  @override
  String get stayInChat => 'Pysy chatissa';

  @override
  String get backToChat => 'Takaisin chattiin';

  @override
  String get upgradeBannerTitle => 'Päivitä rajattomiin konsultaatioihin';

  @override
  String get upgradeBannerCta => 'Päivitä';

  @override
  String get paymentSuccessTitle => 'Maksu onnistui';

  @override
  String get paymentSuccessBody => 'Tilauksesi on nyt aktiivinen.';

  @override
  String get commonOk => 'OK';

  @override
  String get feedbackThumbsUpLabel => 'Hyödyllinen';

  @override
  String get feedbackThumbsDownLabel => 'Ei hyödyllinen';

  @override
  String get feedbackCommentPrompt => 'Mikä meni pieleen?';

  @override
  String get feedbackSend => 'Lähetä';

  @override
  String get feedbackCancel => 'Peruuta';

  @override
  String get reasoningPillIdle => 'Ajattelen…';

  @override
  String get reasoningPillSearchingLaw => 'Etsin lakia…';

  @override
  String get reasoningPillSearchingWeb => 'Etsin verkosta…';

  @override
  String get reasoningPillCheckingCompany => 'Tarkistan yritysrekisteriä…';

  @override
  String get reasoningPillCheckingVehicle => 'Tarkistan ajoneuvorekisteriä…';

  @override
  String get reasoningPillReadingDocument => 'Luen dokumenttisi…';

  @override
  String get reasoningPillDrafting => 'Laadin asiakirjaa…';

  @override
  String get reasoningPillPreparingEmail => 'Valmistelen sähköpostia…';

  @override
  String get reasoningPillFindingLawyer => 'Etsin lakimiehiä…';

  @override
  String get reasoningPillThinking => 'Analysoin tapaustasi…';

  @override
  String get reasoningPillFinalising => 'Muotoilen vastausta…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'Pohdin $sec s · $sources lähdettä';
  }

  @override
  String get reasoningExpandHint => 'napauta nähdäksesi vaiheet';

  @override
  String get caseFileTitle => 'Tapauskansio';

  @override
  String get caseFileTimeline => 'Aikajana';

  @override
  String get caseFileParties => 'Osapuolet';

  @override
  String get caseFileDeadlines => 'Määräajat';

  @override
  String get caseFileExportPdf => 'Lataa kansio (PDF)';

  @override
  String get caseFileEmpty =>
      'Keskustele AI:n kanssa tapauksestasi — aikajana rakentuu itsestään.';

  @override
  String get caseFileDisclaimer =>
      'Tämä kansio on automaattisesti poimittu chatistäsi. Se ei ole oikeudellinen neuvo.';

  @override
  String get caseFileTabLabel => 'Kansio';

  @override
  String get refresh => 'Päivitä';

  @override
  String get demoLimitReached =>
      'Demoraja saavutettu. Rekisteröidy ilmaiseksi jatkaaksesi.';

  @override
  String get demoLimitSignUpCta => 'Rekisteröidy';

  @override
  String get freeQuotaExhausted =>
      'Olet käyttänyt kaikki 7 ilmaista viestiä tässä kuussa.';

  @override
  String get upgradeForUnlimited =>
      'Päivitä Pro-tilaan saadaksesi rajattomat viestit';

  @override
  String get upgradeCta => 'Päivitä';

  @override
  String get rateLimitTryAgain =>
      'Lähetät liian nopeasti. Yritä uudelleen muutaman sekunnin kuluttua.';

  @override
  String get quickProfilePrompt =>
      'Jotta voin auttaa tarkemmin: oletko Viron kansalainen, toisen EU-maan kansalainen, vai onko sinulla oleskelulupa?';

  @override
  String get quickProfileChipEstonianCitizen => 'Viron kansalainen';

  @override
  String get quickProfileChipEuCitizen => 'EU-kansalainen (muu)';

  @override
  String get quickProfileChipResidencePermit => 'Oleskelulupa';

  @override
  String get quickProfileSkipBtn => 'Ohita';

  @override
  String get quickProfileSavedAck => 'Selvä. Mikä on kysymyksesi?';

  @override
  String get caseTitleLabel => 'Asian otsikko';

  @override
  String get jurisdictionLabel => 'Lainkäyttöalue';

  @override
  String get caseTypeLabel => 'Asian tyyppi';

  @override
  String get caseLanguageLabel => 'Kieli';

  @override
  String get caseNumbersSection => 'Asianumerot';

  @override
  String get partiesSection => 'Osapuolet';

  @override
  String get authoritiesSection => 'Viranomaiset';

  @override
  String get timelineSection => 'Aikajana';

  @override
  String get openQuestionsSection => 'Avoimet kysymykset';

  @override
  String get nextActionsSection => 'Seuraavat askeleet';

  @override
  String get summarySection => 'Yhteenveto';

  @override
  String get addRow => 'Lisää';

  @override
  String get removeRow => 'Poista';

  @override
  String get archiveCase => 'Arkistoi';

  @override
  String get closeCase => 'Sulje asia';

  @override
  String get continueChatAboutCase => 'Jatka tämän asian keskustelua';

  @override
  String get linkChatToCase => 'Liitä asiaan';

  @override
  String get clearActiveCase => 'Tyhjennä aktiivinen asia';

  @override
  String get caseSavedAck => 'Asia tallennettu';

  @override
  String get caseArchivedAck => 'Asia arkistoitu';

  @override
  String get intakeStep1Title => 'Missä asia on?';

  @override
  String get intakeStep1Subtitle => 'Maa ja viranomainen, jonka kanssa asioit.';

  @override
  String get intakeJurisdictionLabel => 'Maa / lainkäyttöalue';

  @override
  String get intakeAuthorityLabel => 'Viranomaisen tyyppi';

  @override
  String get intakeAuthorityNameLabel => 'Viranomaisen nimi (valinnainen)';

  @override
  String get intakeAuthorityPolice => 'Poliisi';

  @override
  String get intakeAuthorityCourt => 'Tuomioistuin';

  @override
  String get intakeAuthoritySocial => 'Sosiaalitoimi';

  @override
  String get intakeAuthorityEmployer => 'Työnantaja';

  @override
  String get intakeAuthorityLandlord => 'Vuokranantaja';

  @override
  String get intakeAuthorityOpposingParty => 'Vastapuoli';

  @override
  String get intakeAuthorityOther => 'Muu';

  @override
  String get intakeStep2Title => 'Millainen asia?';

  @override
  String get intakeStep2Subtitle =>
      'Valitse lähin tyyppi — voit tarkentaa myöhemmin.';

  @override
  String get intakeCaseTypeCriminal => 'Rikosasia';

  @override
  String get intakeCaseTypeCivil => 'Siviiliasia';

  @override
  String get intakeCaseTypeFamily => 'Perheasia';

  @override
  String get intakeCaseTypeAdmin => 'Hallintoasia';

  @override
  String get intakeCaseTypeImmigration => 'Maahanmuutto';

  @override
  String get intakeCaseTypeLabor => 'Työasia';

  @override
  String get intakeCaseTypeConsumer => 'Kuluttaja-asia';

  @override
  String get intakeCaseTypeInheritance => 'Perintö';

  @override
  String get intakeCaseTypeOther => 'Muu';

  @override
  String get intakeStep3Title => 'Ketä asia koskee?';

  @override
  String get intakeStep3Subtitle => 'Roolisi ja vastapuoli.';

  @override
  String get intakeRoleLabel => 'Roolisi';

  @override
  String get intakeRolePlaintiff => 'Kantaja';

  @override
  String get intakeRoleDefendant => 'Vastaaja';

  @override
  String get intakeRoleVictim => 'Asianomistaja';

  @override
  String get intakeRoleAccused => 'Syytetty';

  @override
  String get intakeRoleWitness => 'Todistaja';

  @override
  String get intakeRoleFamily => 'Perheenjäsen';

  @override
  String get intakeRoleOther => 'Muu';

  @override
  String get intakeOpposingSideLabel => 'Vastapuoli (valinnainen)';

  @override
  String get intakeWitnessesLabel => 'Todistajat (valinnainen)';

  @override
  String get intakeAddWitness => 'Lisää todistaja';

  @override
  String get intakeWitnessHint => 'Nimi tai yhteystieto';

  @override
  String get intakeStep4Title => 'Numerot ja päivämäärät';

  @override
  String get intakeStep4Subtitle =>
      'Mitä jo tiedät. Loput voit jättää tyhjäksi.';

  @override
  String get intakeCaseNumberLabel => 'Asianumero (valinnainen)';

  @override
  String get intakeIncidentDateLabel => 'Tapahtumapäivä (valinnainen)';

  @override
  String get intakeIncidentDatePick => 'Valitse päivä';

  @override
  String get intakeDeadlinesLabel => 'Tunnetut määräajat';

  @override
  String get intakeAddDeadline => 'Lisää määräaika';

  @override
  String get intakeDeadlineWhatHint => 'Mikä';

  @override
  String get intakeStep5Title => 'Asiakirjat';

  @override
  String get intakeStep5Subtitle => 'Lataa kaikki olennainen. Luemme ne.';

  @override
  String get intakeUploadDocsLabel => 'Lataa asiakirjat';

  @override
  String get intakeSkipDocs => 'Ohita — lataan myöhemmin';

  @override
  String get intakeNextBtn => 'Seuraava';

  @override
  String get intakeBackBtn => 'Takaisin';

  @override
  String get intakeFinishBtn => 'Valmis ja avaa keskustelu';

  @override
  String get intakeUrgentBtn => 'Kiireellinen — kysy nyt';

  @override
  String get intakeUrgentDialogTitle => 'Avataanko keskustelu nyt?';

  @override
  String get intakeUrgentDialogBody =>
      'Tallennamme antamasi tiedot luonnokseksi. Voit täydentää lomakkeen asian sivulta milloin tahansa.';

  @override
  String get intakeUrgentConfirm => 'Avaa keskustelu';

  @override
  String get intakeUrgentCancel => 'Jatka täyttöä';

  @override
  String get intakePreparingCase => 'Valmistelen asiaasi…';

  @override
  String get intakeFallbackGreeting =>
      'Näen asiasi. Kerro, mikä on kiireellisintä — käymme sen yhdessä läpi.';

  @override
  String get intakeUrgentGreeting =>
      'Näen, että asia on kiireellinen. Kysy kysymyksesi — täydennän tietoja keskustelun edetessä.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Vaihe $current / $total';
  }

  @override
  String get intakeFieldRequired => 'Pakollinen';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Ladataan $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat ei ole asianajotoimisto. Tämä on tietoa, ei oikeudellista neuvontaa.';

  @override
  String get citationStatusVerifiedBadge => 'Vahvistettu';

  @override
  String get citationStatusUnverifiedBadge => 'Vahvistamaton';

  @override
  String get citationStatusHistoricalBadge => 'Vanha versio';

  @override
  String get citationStatusVerifiedTooltip =>
      'Lainattu lähde löytyi lakikorpuksesta.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'AI lainasi ilman hakua — tarkista ennen käyttöä.';

  @override
  String get citationStatusHistoricalTooltip =>
      'Lainattu kohta ei ole enää voimassa.';

  @override
  String get citationOpenInRiigiTeataja => 'Avaa Riigi Teatajassa';

  @override
  String get citationSnippetExpand => 'Näytä koko teksti';

  @override
  String get citationSnippetCollapse => 'Näytä vähemmän';

  @override
  String get citationUnverifiedSheetNote =>
      'AI lainasi tämän kohdan, mutta sitä ei haettu lakikorpuksesta tällä vuorolla. Tarkista viittaus ennen käyttöä.';

  @override
  String get citationFooterNoneWarning => 'Ei vahvistettuja viittauksia';

  @override
  String citationFooterSummaryTotal(int count) {
    return '$count viittausta';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    return '$count vahvistettu';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    return '$count vahvistamatta';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    return '$count vanhaa';
  }

  @override
  String get deadlineRadarTitle => 'Tulevat määräajat';

  @override
  String get deadlineRadarEmpty => 'Ei tulevia määräaikoja';

  @override
  String get deadlineRadarViewAll => 'Näytä kaikki';

  @override
  String deadlineCardDaysLeft(int count) {
    return '$count päivän päästä';
  }

  @override
  String get deadlineCardTomorrow => 'huomenna';

  @override
  String get deadlineCardToday => 'tänään';

  @override
  String deadlineCardOverdue(int count) {
    return '$count päivää myöhässä';
  }

  @override
  String get deadlineCardMarkComplete => 'Merkitse valmiiksi';

  @override
  String get deadlineCardSnooze => 'Lykkää';

  @override
  String get deadlineCardSnooze3d => 'Lykkää 3 päivää';

  @override
  String get deadlineCardSnooze7d => 'Lykkää 7 päivää';

  @override
  String get deadlineCardSnoozeCustom => 'Valitse päivä';

  @override
  String get deadlineCardEdit => 'Muokkaa';

  @override
  String get deadlineCardDelete => 'Arkistoi';

  @override
  String get deadlineCardSourceLabelPdf => 'PDF-tiedostosta';

  @override
  String get deadlineCardSourceLabelIntake => 'lomakkeesta';

  @override
  String get deadlineCardSourceLabelManual => 'lisätty manuaalisesti';

  @override
  String get deadlineCardSourceLabelEmail => 'sähköpostista';

  @override
  String get deadlineCardSourceLabelHaikuExtract => 'AI-tunnistus';

  @override
  String get deadlineCardSourceLabelStatutoryTemplate => 'lakimalli';

  @override
  String deadlineBannerCritical(String title, String when) {
    return 'Kriittinen määräaika: $title $when';
  }

  @override
  String get deadlineBannerDismiss => 'Sulje';

  @override
  String get deadlineBannerOpen => 'Avaa määräaika';

  @override
  String deadlineHolidayShifted(String original, String reason) {
    return 'Siirretty päivästä $original ($reason)';
  }

  @override
  String get deadlinePermissionAskTitle => 'Salli määräaikamuistutukset?';

  @override
  String get deadlinePermissionAskBody =>
      'Muistutamme 7, 3 ja 1 päivää ennen jokaista lakisääteistä määräaikaa sekä määräaamuna. Ei käytetä markkinointiin.';

  @override
  String get deadlinePermissionAllow => 'Salli';

  @override
  String get deadlinePermissionLater => 'Myöhemmin';

  @override
  String get deadlineSettingsSection => 'Määräaikamuistutukset';

  @override
  String get deadlineSettingsPushChannel => 'Push-ilmoitukset';

  @override
  String get deadlineSettingsEmailChannel => 'Sähköposti (vain kriittiset)';

  @override
  String get deadlineSettingsInAppChannel => 'Sovelluksen sisäiset ilmoitukset';

  @override
  String get deadlineSettingsCriticalBypass =>
      'Kriittiset ohittavat hiljaiset tunnit';

  @override
  String get deadlineSettingsQuietHours => 'Hiljaiset tunnit';

  @override
  String deadlineSettingsQuietHoursBadge(String start, String end) {
    return 'Hiljainen $start–$end';
  }

  @override
  String get deadlineCaseScreenTitle => 'Asian määräajat';

  @override
  String get deadlineAddManualCta => 'Lisää määräaika';

  @override
  String get deadlineFormTitle => 'Otsikko';

  @override
  String get deadlineFormDescription => 'Kuvaus (valinnainen)';

  @override
  String get deadlineFormStatuteTemplate => 'Lakimalli';

  @override
  String get deadlineFormStatuteTemplateNone => 'Ei (manuaalinen)';

  @override
  String get deadlineFormDeadlineAt => 'Määräaikapäivä';

  @override
  String get deadlineFormPriority => 'Prioriteetti';

  @override
  String get deadlineFormSave => 'Tallenna';

  @override
  String get deadlineFormCancel => 'Peruuta';

  @override
  String get deadlineCompletedNotePrompt => 'Lisää muistiinpano (valinnainen)';

  @override
  String get deadlineCompletedNoteSave => 'Tallenna';

  @override
  String get inboxTitle => 'Saapuneet';

  @override
  String get inboxEmptyTitle => 'Ei mitään odottamassa';

  @override
  String get inboxEmptyBody =>
      'Uudet sähköpostit näkyvät täällä triagoinnin jälkeen.';

  @override
  String get inboxApproveSend => 'Hyväksy ja lähetä';

  @override
  String get inboxEditDraft => 'Muokkaa';

  @override
  String get inboxSnooze => 'Torkku';

  @override
  String get inboxArchive => 'Arkistoi';

  @override
  String get inboxFilterAll => 'Kaikki';

  @override
  String get inboxConfirmSendTitle => 'Lähetetäänkö valmisteltu vastaus?';

  @override
  String get inboxConfirmSendBody =>
      'Advocat lähettää AI:n valmisteleman vastauksen yhdistetyn Gmail-tilisi kautta. Voit vielä tarkistaa sisällön seuraavassa näkymässä.';

  @override
  String get inboxSendButton => 'Lähetä';

  @override
  String get inboxSentToast => 'Lähetetty.';

  @override
  String get inboxSnoozedToast => 'Torkku 24 tuntia.';

  @override
  String get inboxArchivedToast => 'Arkistoitu.';

  @override
  String get inboxDraftLoadError => 'Luonnoksen lataaminen epäonnistui.';

  @override
  String get inboxDeadlineToday => 'tänään';

  @override
  String get inboxDeadlineTomorrow => 'huomenna';

  @override
  String inboxDeadlineInDays(int days) {
    return '$days pv kuluttua';
  }

  @override
  String inboxDeadlineOverdue(int days) {
    return 'myöhässä $days pv';
  }

  @override
  String get workspaceTabOverview => 'Yleiskatsaus';

  @override
  String get workspaceTabChat => 'Keskustelu';

  @override
  String get workspaceTabDrafts => 'Luonnokset';

  @override
  String get workspaceOverviewEmpty =>
      'Lisää asiakirjoja yhteenvedon rakentamiseksi.';

  @override
  String get workspaceTimelineEmpty => 'Ei tapahtumia vielä.';

  @override
  String get workspaceDocumentsEmpty =>
      'Ei asiakirjoja. Lataa skannaa-toiminnon kautta.';

  @override
  String get workspaceDraftsEmpty => 'Ei luonnoksia vielä.';

  @override
  String get workspaceInboxEmpty => 'Ei liittyviä sähköposteja.';
}
