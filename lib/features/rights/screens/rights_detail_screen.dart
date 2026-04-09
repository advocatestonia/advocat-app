import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Severity levels for color-coding rights items
// ---------------------------------------------------------------------------
enum _Severity { critical, important, info }

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class _RightItem {
  const _RightItem(
    this.text, {
    this.severity = _Severity.info,
    this.legalRef,
    this.legalUrl,
  });
  final String text;
  final _Severity severity;
  final String? legalRef;
  final String? legalUrl;
}

class _ActionItem {
  const _ActionItem(this.text);
  final String text;
}

class _DeadlineItem {
  const _DeadlineItem(this.text, {this.isUrgent = false});
  final String text;
  final bool isUrgent;
}

class _HelpContact {
  const _HelpContact({
    required this.name,
    this.phone,
    this.email,
    this.url,
  });
  final String name;
  final String? phone;
  final String? email;
  final String? url;
}

class _DidYouKnow {
  const _DidYouKnow(this.text);
  final String text;
}

class _ScenarioData {
  const _ScenarioData({
    required this.title,
    required this.tagline,
    required this.icon,
    required this.color,
    this.rights = const [],
    this.obligations = const [],
    this.actions = const [],
    this.deadlines = const [],
    this.helpContacts = const [],
    this.didYouKnow = const [],
  });
  final String title;
  final String tagline;
  final IconData icon;
  final Color color;
  final List<_RightItem> rights;
  final List<_RightItem> obligations;
  final List<_ActionItem> actions;
  final List<_DeadlineItem> deadlines;
  final List<_HelpContact> helpContacts;
  final List<_DidYouKnow> didYouKnow;
}

// ---------------------------------------------------------------------------
// Country-specific legal reference data
// ---------------------------------------------------------------------------

class _CountryLegalData {
  const _CountryLegalData({
    required this.emergencyAct,
    required this.emergencyActUrl,
    required this.restrainingOrderAct,
    required this.restrainingOrderActUrl,
    required this.languageAct,
    required this.languageActUrl,
    required this.criminalCodeAssault,
    required this.criminalCodeAssaultUrl,
    required this.shelterAct,
    required this.shelterActUrl,
    required this.policeAct,
    required this.policeActUrl,
    required this.constitution,
    required this.constitutionUrl,
    required this.criminalProcedureAct,
    required this.criminalProcedureActUrl,
    required this.aliensAct,
    required this.aliensActUrl,
    required this.aliensActLegalRep,
    required this.aliensActStay,
    required this.aliensActDetention,
    required this.aliensActChallengeDetention,
    required this.employmentAct,
    required this.employmentActUrl,
    required this.workingTimeAct,
    required this.workingTimeActUrl,
    required this.annualHolidaysAct,
    required this.annualHolidaysActUrl,
    required this.sickLeaveRef,
    required this.occupationalSafetyAct,
    required this.occupationalSafetyActUrl,
    required this.residentialLeaseAct,
    required this.residentialLeaseActUrl,
    required this.residentialLeaseDeposit,
    required this.residentialLeaseNotice,
    required this.residentialLeaseHabitable,
    required this.residentialLeaseEviction,
    required this.nonDiscriminationAct,
    required this.nonDiscriminationActUrl,
    required this.criminalCodeDiscrimination,
    required this.criminalCodeDiscriminationUrl,
    required this.consumerProtectionAct,
    required this.consumerProtectionActUrl,
    required this.consumerProtectionPricing,
    required this.consumerProtectionUnfair,
    required this.consumerDisputesAct,
    required this.consumerDisputesActUrl,
    required this.domesticContactsFn,
    required this.policeContactsFn,
    required this.deportationContactsFn,
    required this.workplaceContactsFn,
    required this.tenantContactsFn,
    required this.detentionContactsFn,
    required this.discriminationContactsFn,
    required this.consumerContactsFn,
  });

  final String emergencyAct;
  final String emergencyActUrl;
  final String restrainingOrderAct;
  final String restrainingOrderActUrl;
  final String languageAct;
  final String languageActUrl;
  final String criminalCodeAssault;
  final String criminalCodeAssaultUrl;
  final String shelterAct;
  final String shelterActUrl;
  final String policeAct;
  final String policeActUrl;
  final String constitution;
  final String constitutionUrl;
  final String criminalProcedureAct;
  final String criminalProcedureActUrl;
  final String aliensAct;
  final String aliensActUrl;
  final String aliensActLegalRep;
  final String aliensActStay;
  final String aliensActDetention;
  final String aliensActChallengeDetention;
  final String employmentAct;
  final String employmentActUrl;
  final String workingTimeAct;
  final String workingTimeActUrl;
  final String annualHolidaysAct;
  final String annualHolidaysActUrl;
  final String sickLeaveRef;
  final String occupationalSafetyAct;
  final String occupationalSafetyActUrl;
  final String residentialLeaseAct;
  final String residentialLeaseActUrl;
  final String residentialLeaseDeposit;
  final String residentialLeaseNotice;
  final String residentialLeaseHabitable;
  final String residentialLeaseEviction;
  final String nonDiscriminationAct;
  final String nonDiscriminationActUrl;
  final String criminalCodeDiscrimination;
  final String criminalCodeDiscriminationUrl;
  final String consumerProtectionAct;
  final String consumerProtectionActUrl;
  final String consumerProtectionPricing;
  final String consumerProtectionUnfair;
  final String consumerDisputesAct;
  final String consumerDisputesActUrl;

  final List<_HelpContact> Function(AppLocalizations) domesticContactsFn;
  final List<_HelpContact> Function(AppLocalizations) policeContactsFn;
  final List<_HelpContact> Function(AppLocalizations) deportationContactsFn;
  final List<_HelpContact> Function(AppLocalizations) workplaceContactsFn;
  final List<_HelpContact> Function(AppLocalizations) tenantContactsFn;
  final List<_HelpContact> Function(AppLocalizations) detentionContactsFn;
  final List<_HelpContact> Function(AppLocalizations) discriminationContactsFn;
  final List<_HelpContact> Function(AppLocalizations) consumerContactsFn;

  List<_HelpContact> domesticViolenceContacts(AppLocalizations l10n) =>
      domesticContactsFn(l10n);
  List<_HelpContact> policeStopContacts(AppLocalizations l10n) =>
      policeContactsFn(l10n);
  List<_HelpContact> deportationContacts(AppLocalizations l10n) =>
      deportationContactsFn(l10n);
  List<_HelpContact> workplaceContacts(AppLocalizations l10n) =>
      workplaceContactsFn(l10n);
  List<_HelpContact> tenantContacts(AppLocalizations l10n) =>
      tenantContactsFn(l10n);
  List<_HelpContact> detentionContacts(AppLocalizations l10n) =>
      detentionContactsFn(l10n);
  List<_HelpContact> discriminationContacts(AppLocalizations l10n) =>
      discriminationContactsFn(l10n);
  List<_HelpContact> consumerContacts(AppLocalizations l10n) =>
      consumerContactsFn(l10n);

  // ── Estonia ──────────────────────────────────────────────────────────
  factory _CountryLegalData.estonia() => _CountryLegalData(
        emergencyAct: 'Hädaolukorra seadus',
        emergencyActUrl: 'https://www.riigiteataja.ee/akt/117032011008',
        restrainingOrderAct: 'Karistusseadustik § 1201 (Lähenemiskeeld)',
        restrainingOrderActUrl:
            'https://www.riigiteataja.ee/akt/184411',
        languageAct: 'Keeleseadus',
        languageActUrl: 'https://www.riigiteataja.ee/akt/118032011001',
        criminalCodeAssault: 'Karistusseadustik § 121 (Kehaline väärkohtlemine)',
        criminalCodeAssaultUrl:
            'https://www.riigiteataja.ee/akt/184411',
        shelterAct: 'Ohvriabi seadus',
        shelterActUrl:
            'https://www.riigiteataja.ee/akt/OhsS',
        policeAct: 'Korrakaitseseadus § 30',
        policeActUrl:
            'https://www.riigiteataja.ee/akt/KorS',
        constitution: 'Eesti Vabariigi põhiseadus § 21',
        constitutionUrl:
            'https://www.riigiteataja.ee/akt/PS',
        criminalProcedureAct: 'Kriminaalmenetluse seadustik 2. peatükk',
        criminalProcedureActUrl:
            'https://www.riigiteataja.ee/akt/KrMS',
        aliensAct: 'Välismaalaste seadus § 281',
        aliensActUrl:
            'https://www.riigiteataja.ee/akt/VMS',
        aliensActLegalRep: 'Välismaalaste seadus § 10',
        aliensActStay: 'Välismaalaste seadus § 283',
        aliensActDetention: 'Välismaalaste seadus § 23',
        aliensActChallengeDetention: 'Välismaalaste seadus § 24',
        employmentAct: 'Töölepingu seadus',
        employmentActUrl:
            'https://www.riigiteataja.ee/akt/TLS',
        workingTimeAct: 'Töölepingu seadus § 43 (Tööaeg)',
        workingTimeActUrl:
            'https://www.riigiteataja.ee/akt/TLS',
        annualHolidaysAct: 'Töölepingu seadus § 54 (Puhkus)',
        annualHolidaysActUrl:
            'https://www.riigiteataja.ee/akt/TLS',
        sickLeaveRef: 'Töölepingu seadus § 62 (Haigushüvitis)',
        occupationalSafetyAct: 'Töötervishoiu ja tööohutuse seadus',
        occupationalSafetyActUrl:
            'https://www.riigiteataja.ee/akt/TTOS',
        residentialLeaseAct:
            'Võlaõigusseadus 15. peatükk (Üürileping)',
        residentialLeaseActUrl:
            'https://www.riigiteataja.ee/akt/VOS',
        residentialLeaseDeposit: 'Võlaõigusseadus § 308 (Tagatisraha)',
        residentialLeaseNotice: 'Võlaõigusseadus § 312 (Ülesütlemine)',
        residentialLeaseHabitable:
            'Võlaõigusseadus § 276 (Lepingule vastavus)',
        residentialLeaseEviction:
            'Võlaõigusseadus §§ 312-319 (Ülesütlemise kaitse)',
        nonDiscriminationAct:
            'Võrdse kohtlemise seadus § 19',
        nonDiscriminationActUrl:
            'https://www.riigiteataja.ee/akt/VoKoS',
        criminalCodeDiscrimination:
            'Karistusseadustik § 152 (Vaenu õhutamine)',
        criminalCodeDiscriminationUrl:
            'https://www.riigiteataja.ee/akt/184411',
        consumerProtectionAct:
            'Võlaõigusseadus 5. peatükk (Tarbijaleping)',
        consumerProtectionActUrl:
            'https://www.riigiteataja.ee/akt/VOS',
        consumerProtectionPricing:
            'Tarbijakaitseseadus § 4 (Hinnateave)',
        consumerProtectionUnfair:
            'Tarbijakaitseseadus § 12 (Ebaausad kaubandustavad)',
        consumerDisputesAct:
            'Tarbijakaitseseadus § 36 (Tarbijavaidluste komisjon)',
        consumerDisputesActUrl:
            'https://www.riigiteataja.ee/akt/TKS',
        domesticContactsFn: (l10n) => [
          _HelpContact(name: l10n.contactEmergency, phone: '112'),
          const _HelpContact(
            name: 'Ohvriabi kriisitelefon',
            phone: '116 006',
            url: 'https://www.sotsiaalkindlustusamet.ee/ohvriabi',
          ),
          const _HelpContact(
            name: 'Naiste tugikeskus',
            phone: '1492',
            url: 'https://naistetugi.ee',
          ),
          const _HelpContact(
            name: 'Lasteabi telefon',
            phone: '116 111',
          ),
        ],
        policeContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Riigi Õigusabi',
            phone: '631 4222',
            url: 'https://www.rik.ee/oigusabi',
          ),
          const _HelpContact(
            name: 'Õiguskantsler',
            phone: '693 8400',
            url: 'https://www.oiguskantsler.ee',
          ),
        ],
        deportationContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Eesti Pagulasabi',
            email: 'info@pagulasabi.ee',
            url: 'https://www.pagulasabi.ee',
          ),
          const _HelpContact(
            name: 'Riigi Õigusabi',
            phone: '631 4222',
            url: 'https://www.rik.ee/oigusabi',
          ),
          const _HelpContact(
            name: 'Halduskohus',
            phone: '628 2740',
            url: 'https://www.kohus.ee',
          ),
        ],
        workplaceContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Tööinspektsioon',
            phone: '640 6000',
            url: 'https://www.ti.ee',
          ),
          const _HelpContact(
            name: 'Eesti Ametiühingute Keskliit (EAKL)',
            phone: '641 2886',
            url: 'https://www.eakl.ee',
          ),
        ],
        tenantContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Tarbijakaitse ja Tehnilise Järelevalve Amet',
            phone: '667 2000',
            url: 'https://www.ttja.ee',
          ),
          const _HelpContact(
            name: 'Tarbijavaidluste komisjon',
            phone: '667 2000',
            url: 'https://komisjon.ee',
          ),
        ],
        detentionContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Eesti Pagulasabi',
            email: 'info@pagulasabi.ee',
            url: 'https://www.pagulasabi.ee',
          ),
          const _HelpContact(
            name: 'Õiguskantsler',
            phone: '693 8400',
            url: 'https://www.oiguskantsler.ee',
          ),
        ],
        discriminationContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Soolise võrdõiguslikkuse ja võrdse kohtlemise volinik',
            phone: '626 9059',
            url: 'https://volinik.ee',
          ),
          const _HelpContact(
            name: 'Ohvriabi',
            phone: '116 006',
            url: 'https://www.sotsiaalkindlustusamet.ee/ohvriabi',
          ),
        ],
        consumerContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Tarbijakaitse ja Tehnilise Järelevalve Amet (TTJA)',
            phone: '667 2000',
            url: 'https://www.ttja.ee',
          ),
          const _HelpContact(
            name: 'Tarbijavaidluste komisjon',
            phone: '667 2000',
            url: 'https://komisjon.ee',
          ),
        ],
      );

  // ── Finland ──────────────────────────────────────────────────────────
  factory _CountryLegalData.finland() => _CountryLegalData(
        emergencyAct: 'Hätäkeskuslaki (692/2010)',
        emergencyActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/2010/20100692',
        restrainingOrderAct: 'Laki lähestymiskiellosta (898/1998)',
        restrainingOrderActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/1998/19980898',
        languageAct: 'Kielilaki (423/2003)',
        languageActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/2003/20030423',
        criminalCodeAssault: 'Rikoslaki (39/1889) 21 luku — Pahoinpitely § 5',
        criminalCodeAssaultUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/1889/18890039001',
        shelterAct: 'Laki valtion varoista maksettavasta korvauksesta turvakotipalvelun tuottajalle (1354/2014)',
        shelterActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/2014/20141354',
        policeAct: 'Poliisilaki (872/2011) 2 §',
        policeActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/2011/20110872',
        constitution: 'Suomen perustuslaki (731/1999) 21 §',
        constitutionUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/1999/19990731',
        criminalProcedureAct: 'Laki oikeudenkäynnistä rikosasioissa, 2 luku',
        criminalProcedureActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/1997/19970689',
        aliensAct: 'Ulkomaalaislaki (301/2004) 190 §',
        aliensActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/2004/20040301',
        aliensActLegalRep: 'Ulkomaalaislaki 9 §',
        aliensActStay: 'Ulkomaalaislaki 200 §',
        aliensActDetention: 'Ulkomaalaislaki 123 §',
        aliensActChallengeDetention: 'Ulkomaalaislaki 127 §',
        employmentAct: 'Työsopimuslaki (55/2001)',
        employmentActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/2001/20010055',
        workingTimeAct: 'Työaikalaki (872/2019)',
        workingTimeActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/2019/20190872',
        annualHolidaysAct: 'Vuosilomalaki (162/2005)',
        annualHolidaysActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/2005/20050162',
        sickLeaveRef: 'Työsopimuslaki 2 luku, 11 §',
        occupationalSafetyAct:
            'Työturvallisuuslaki (738/2002)',
        occupationalSafetyActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/2002/20020738',
        residentialLeaseAct:
            'Laki asuinhuoneiston vuokrauksesta (481/1995) 1 luku',
        residentialLeaseActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/1995/19950481',
        residentialLeaseDeposit:
            'Laki asuinhuoneiston vuokrauksesta 8 §',
        residentialLeaseNotice:
            'Laki asuinhuoneiston vuokrauksesta 52 §',
        residentialLeaseHabitable:
            'Laki asuinhuoneiston vuokrauksesta 20 §',
        residentialLeaseEviction:
            'Laki asuinhuoneiston vuokrauksesta 51-55 §',
        nonDiscriminationAct:
            'Yhdenvertaisuuslaki (1325/2014) 19 §',
        nonDiscriminationActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/2014/20141325',
        criminalCodeDiscrimination: 'Rikoslaki 11 luku',
        criminalCodeDiscriminationUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/1889/18890039001',
        consumerProtectionAct:
            'Kuluttajansuojalaki (38/1978) 5 luku',
        consumerProtectionActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/1978/19780038',
        consumerProtectionPricing:
            'Kuluttajansuojalaki 2 luku',
        consumerProtectionUnfair:
            'Kuluttajansuojalaki 2 luku — Sopimaton menettely',
        consumerDisputesAct:
            'Laki kuluttajariitalautakunnasta (8/2007)',
        consumerDisputesActUrl:
            'https://www.finlex.fi/fi/laki/ajantasa/2007/20070008',
        domesticContactsFn: (l10n) => [
          _HelpContact(name: l10n.contactEmergency, phone: '112'),
          _HelpContact(
            name: l10n.contactNollaLinja,
            phone: '080 005 005',
            url: 'https://nollalinja.fi',
          ),
          _HelpContact(
            name: l10n.contactShelter,
            phone: '0800 161 323',
            url: 'https://turvakoti.fi',
          ),
          _HelpContact(
            name: l10n.contactCrisisHelpline,
            phone: '09 2525 0111',
          ),
          _HelpContact(
            name: l10n.contactVictimSupportRIKU,
            phone: '116 006',
            url: 'https://www.riku.fi',
          ),
        ],
        policeContactsFn: (l10n) => [
          _HelpContact(
            name: l10n.contactFinnishLegalAid,
            phone: '0295 390 390',
            url: 'https://oikeus.fi/oikeusapu/fi/',
          ),
          _HelpContact(
            name: l10n.contactNonDiscriminationOmbudsman,
            phone: '0295 666 817',
            email: 'yvv@oikeus.fi',
          ),
        ],
        deportationContactsFn: (l10n) => [
          _HelpContact(
            name: l10n.contactRefugeeAdviceCentre,
            phone: '09 2313 9300',
            email: 'info@pakolaisneuvonta.fi',
          ),
          _HelpContact(
            name: l10n.contactAdminCourtHelsinki,
            phone: '029 564 2000',
            url: 'https://oikeus.fi/hallintooikeudet/fi/',
          ),
          _HelpContact(
            name: l10n.contactFinnishLegalAid,
            phone: '0295 390 390',
          ),
        ],
        workplaceContactsFn: (l10n) => [
          _HelpContact(
            name: l10n.contactOccupationalSafety,
            phone: '0295 016 620',
            url: 'https://www.tyosuojelu.fi/fi',
          ),
          _HelpContact(
            name: l10n.contactTradeUnionSAK,
            phone: '020 774 0100',
          ),
        ],
        tenantContactsFn: (l10n) => [
          _HelpContact(
            name: l10n.contactTenantsAssociation,
            phone: '09 4767 0100',
            url: 'https://vuokralaiset.fi',
          ),
          _HelpContact(
            name: l10n.contactConsumerDisputesBoard,
            phone: '029 566 5200',
          ),
        ],
        detentionContactsFn: (l10n) => [
          _HelpContact(
            name: l10n.contactRefugeeAdviceCentre,
            phone: '09 2313 9300',
            email: 'info@pakolaisneuvonta.fi',
          ),
          _HelpContact(
            name: l10n.contactParliamentaryOmbudsman,
            phone: '09 4321',
            url: 'https://www.oikeusasiamies.fi/fi',
          ),
        ],
        discriminationContactsFn: (l10n) => [
          _HelpContact(
            name: l10n.contactNonDiscriminationOmbudsman,
            phone: '0295 666 817',
            email: 'yvv@oikeus.fi',
          ),
          _HelpContact(
            name: l10n.contactVictimSupportRIKU,
            phone: '116 006',
            url: 'https://www.riku.fi',
          ),
        ],
        consumerContactsFn: (l10n) => [
          _HelpContact(
            name: l10n.contactConsumerAdvisory,
            phone: '029 505 3050',
            url: 'https://www.kkv.fi/kuluttajaneuvonta/',
          ),
          const _HelpContact(
            name: 'Kuluttaja-asiamies',
            url: 'https://www.kkv.fi/kuluttaja-asiamies/',
          ),
          _HelpContact(
            name: l10n.contactConsumerDisputesBoardDirect,
            phone: '029 566 5200',
            url: 'https://www.kuluttajariita.fi/fi/',
          ),
        ],
      );

  // ── Germany ──────────────────────────────────────────────────────────
  factory _CountryLegalData.germany() => _CountryLegalData(
        emergencyAct: 'Notrufverordnung',
        emergencyActUrl:
            'https://www.gesetze-im-internet.de/notrufv/',
        restrainingOrderAct: 'Gewaltschutzgesetz (GewSchG)',
        restrainingOrderActUrl:
            'https://www.gesetze-im-internet.de/gewschg/',
        languageAct: 'Gerichtsverfassungsgesetz (GVG) § 185',
        languageActUrl:
            'https://www.gesetze-im-internet.de/gvg/__185.html',
        criminalCodeAssault:
            'Strafgesetzbuch (StGB) § 223 (Körperverletzung)',
        criminalCodeAssaultUrl:
            'https://www.gesetze-im-internet.de/stgb/__223.html',
        shelterAct: 'Sozialgesetzbuch (SGB) VIII',
        shelterActUrl:
            'https://www.gesetze-im-internet.de/sgb_8/',
        policeAct: 'Polizeigesetz',
        policeActUrl:
            'https://www.gesetze-im-internet.de/bpolg/',
        constitution: 'Grundgesetz (GG) Art. 103',
        constitutionUrl:
            'https://www.gesetze-im-internet.de/gg/art_103.html',
        criminalProcedureAct:
            'Strafprozessordnung (StPO) § 137',
        criminalProcedureActUrl:
            'https://www.gesetze-im-internet.de/stpo/__137.html',
        aliensAct: 'Aufenthaltsgesetz (AufenthG) § 59',
        aliensActUrl:
            'https://www.gesetze-im-internet.de/aufenthg_2004/',
        aliensActLegalRep: 'AufenthG § 14',
        aliensActStay: 'AufenthG § 81',
        aliensActDetention: 'AufenthG § 62',
        aliensActChallengeDetention: 'AufenthG § 62a',
        employmentAct: 'Bürgerliches Gesetzbuch (BGB) § 611a',
        employmentActUrl:
            'https://www.gesetze-im-internet.de/bgb/__611a.html',
        workingTimeAct: 'Arbeitszeitgesetz (ArbZG)',
        workingTimeActUrl:
            'https://www.gesetze-im-internet.de/arbzg/',
        annualHolidaysAct: 'Bundesurlaubsgesetz (BUrlG)',
        annualHolidaysActUrl:
            'https://www.gesetze-im-internet.de/burlg/',
        sickLeaveRef:
            'Entgeltfortzahlungsgesetz (EntgFG)',
        occupationalSafetyAct:
            'Arbeitsschutzgesetz (ArbSchG)',
        occupationalSafetyActUrl:
            'https://www.gesetze-im-internet.de/arbschg/',
        residentialLeaseAct: 'BGB §§ 535-580a (Mietrecht)',
        residentialLeaseActUrl:
            'https://www.gesetze-im-internet.de/bgb/__535.html',
        residentialLeaseDeposit: 'BGB § 551 (Kaution)',
        residentialLeaseNotice: 'BGB § 573 (Kündigung)',
        residentialLeaseHabitable:
            'BGB § 536 (Mietminderung)',
        residentialLeaseEviction:
            'BGB §§ 573-574c (Kündigungsschutz)',
        nonDiscriminationAct:
            'Allgemeines Gleichbehandlungsgesetz (AGG) § 13',
        nonDiscriminationActUrl:
            'https://www.gesetze-im-internet.de/agg/',
        criminalCodeDiscrimination:
            'StGB § 130 (Volksverhetzung)',
        criminalCodeDiscriminationUrl:
            'https://www.gesetze-im-internet.de/stgb/__130.html',
        consumerProtectionAct:
            'BGB §§ 474-479 (Verbrauchsgüterkauf)',
        consumerProtectionActUrl:
            'https://www.gesetze-im-internet.de/bgb/__474.html',
        consumerProtectionPricing:
            'Preisangabenverordnung (PAngV)',
        consumerProtectionUnfair:
            'Gesetz gegen den unlauteren Wettbewerb (UWG)',
        consumerDisputesAct:
            'Verbraucherstreitbeilegungsgesetz (VSBG)',
        consumerDisputesActUrl:
            'https://www.gesetze-im-internet.de/vsbg/',
        domesticContactsFn: (l10n) => [
          _HelpContact(name: l10n.contactEmergency, phone: '112'),
          const _HelpContact(
            name: 'Hilfetelefon Gewalt gegen Frauen',
            phone: '0800 011 6016',
            url: 'https://www.hilfetelefon.de',
          ),
          const _HelpContact(
            name: 'Weisser Ring (Opferhilfe)',
            phone: '116 006',
            url: 'https://weisser-ring.de',
          ),
        ],
        policeContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Rechtsanwaltskammer',
            url: 'https://www.brak.de',
          ),
          const _HelpContact(
            name: 'Antidiskriminierungsstelle',
            phone: '030 18555 1855',
            url: 'https://www.antidiskriminierungsstelle.de',
          ),
        ],
        deportationContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Pro Asyl',
            phone: '069 242 314 0',
            url: 'https://www.proasyl.de',
          ),
          const _HelpContact(
            name: 'Beratungshilfe (Rechtsantragstelle)',
            url: 'https://www.bmj.de',
          ),
        ],
        workplaceContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Gewerbeaufsicht / Arbeitsschutz',
            url: 'https://www.baua.de',
          ),
          const _HelpContact(
            name: 'DGB (Deutscher Gewerkschaftsbund)',
            phone: '030 24060 0',
            url: 'https://www.dgb.de',
          ),
        ],
        tenantContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Deutscher Mieterbund',
            phone: '030 223 230',
            url: 'https://www.mieterbund.de',
          ),
          const _HelpContact(
            name: 'Verbraucherzentrale',
            url: 'https://www.verbraucherzentrale.de',
          ),
        ],
        detentionContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Pro Asyl',
            phone: '069 242 314 0',
            url: 'https://www.proasyl.de',
          ),
          const _HelpContact(
            name: 'UNHCR Deutschland',
            url: 'https://www.unhcr.org/dach/de/',
          ),
        ],
        discriminationContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Antidiskriminierungsstelle des Bundes',
            phone: '030 18555 1855',
            url: 'https://www.antidiskriminierungsstelle.de',
          ),
          const _HelpContact(
            name: 'Weisser Ring',
            phone: '116 006',
            url: 'https://weisser-ring.de',
          ),
        ],
        consumerContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Verbraucherzentrale',
            url: 'https://www.verbraucherzentrale.de',
          ),
          const _HelpContact(
            name: 'Schlichtungsstellen',
            url: 'https://www.bmj.de',
          ),
        ],
      );

  // ── Sweden ───────────────────────────────────────────────────────────
  factory _CountryLegalData.sweden() => _CountryLegalData(
        emergencyAct: 'Lagen om skydd mot olyckor (2003:778)',
        emergencyActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/lag-2003778-om-skydd-mot-olyckor_sfs-2003-778/',
        restrainingOrderAct: 'Lagen om kontaktförbud (1988:688)',
        restrainingOrderActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/lag-1988688-om-kontaktforbud_sfs-1988-688/',
        languageAct: 'Språklagen (2009:600)',
        languageActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/spraklag-2009600_sfs-2009-600/',
        criminalCodeAssault:
            'Brottsbalken (1962:700) 3 kap. — Misshandel',
        criminalCodeAssaultUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/brottsbalk-1962700_sfs-1962-700/',
        shelterAct: 'Socialtjänstlagen (2001:453)',
        shelterActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/socialtjanstlag-2001453_sfs-2001-453/',
        policeAct: 'Polislagen (1984:387) 10 §',
        policeActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/polislag-1984387_sfs-1984-387/',
        constitution:
            'Regeringsformen (1974:152) 2 kap. 9 §',
        constitutionUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/kungorelse-1974152-om-beslutad-ny-regeringsform_sfs-1974-152/',
        criminalProcedureAct:
            'Rättegångsbalken 21 kap.',
        criminalProcedureActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/rattegangsbalk-1942740_sfs-1942-740/',
        aliensAct: 'Utlänningslagen (2005:716)',
        aliensActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/utlanningslag-2005716_sfs-2005-716/',
        aliensActLegalRep: 'Utlänningslagen 18 kap.',
        aliensActStay: 'Utlänningslagen 12 kap.',
        aliensActDetention: 'Utlänningslagen 10 kap.',
        aliensActChallengeDetention: 'Utlänningslagen 10 kap. 9 §',
        employmentAct:
            'Lag om anställningsskydd (1982:80) (LAS)',
        employmentActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/lag-198280-om-anstallningsskydd_sfs-1982-80/',
        workingTimeAct: 'Arbetstidslagen (1982:673)',
        workingTimeActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/arbetstidslag-1982673_sfs-1982-673/',
        annualHolidaysAct: 'Semesterlagen (1977:480)',
        annualHolidaysActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/semesterlag-1977480_sfs-1977-480/',
        sickLeaveRef: 'Lag om sjuklön (1991:1047)',
        occupationalSafetyAct:
            'Arbetsmiljölagen (1977:1160)',
        occupationalSafetyActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/arbetsmiljolag-19771160_sfs-1977-1160/',
        residentialLeaseAct:
            'Jordabalken (1970:994) 12 kap. (Hyreslagen)',
        residentialLeaseActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/jordabalk-1970994_sfs-1970-994/',
        residentialLeaseDeposit: 'Jordabalken 12 kap. 28 §',
        residentialLeaseNotice: 'Jordabalken 12 kap. 4 §',
        residentialLeaseHabitable:
            'Jordabalken 12 kap. 9 §',
        residentialLeaseEviction:
            'Jordabalken 12 kap. 42-44 §',
        nonDiscriminationAct:
            'Diskrimineringslagen (2008:567)',
        nonDiscriminationActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/diskrimineringslag-2008567_sfs-2008-567/',
        criminalCodeDiscrimination:
            'Brottsbalken 16 kap. (Hets mot folkgrupp)',
        criminalCodeDiscriminationUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/brottsbalk-1962700_sfs-1962-700/',
        consumerProtectionAct:
            'Konsumentköplagen (2022:260)',
        consumerProtectionActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/konsumentkoplag-2022260_sfs-2022-260/',
        consumerProtectionPricing:
            'Prisinformationslagen (2004:347)',
        consumerProtectionUnfair:
            'Marknadsföringslagen (2008:486)',
        consumerDisputesAct:
            'Lag om alternativ tvistlösning (2015:671)',
        consumerDisputesActUrl:
            'https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/lag-2015671-om-alternativ-tvistlosning-i_sfs-2015-671/',
        domesticContactsFn: (l10n) => [
          _HelpContact(name: l10n.contactEmergency, phone: '112'),
          const _HelpContact(
            name: 'Kvinnofridslinjen',
            phone: '020-50 50 50',
            url: 'https://kvinnofridslinjen.se',
          ),
          const _HelpContact(
            name: 'Brottsofferjouren',
            phone: '116 006',
            url: 'https://www.brottsofferjouren.se',
          ),
        ],
        policeContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Rättshjälpsmyndigheten',
            url: 'https://www.rattshjalp.se',
          ),
          const _HelpContact(
            name: 'Diskrimineringsombudsmannen (DO)',
            phone: '08-120 20 700',
            url: 'https://www.do.se',
          ),
        ],
        deportationContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Asylrättscentrum',
            url: 'https://sweref.org',
          ),
          const _HelpContact(
            name: 'Rättshjälpsmyndigheten',
            url: 'https://www.rattshjalp.se',
          ),
        ],
        workplaceContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Arbetsmiljöverket',
            phone: '010-730 90 00',
            url: 'https://www.av.se',
          ),
          const _HelpContact(
            name: 'LO (Landsorganisationen)',
            url: 'https://www.lo.se',
          ),
        ],
        tenantContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Hyresgästföreningen',
            phone: '0771-443 443',
            url: 'https://www.hyresgastforeningen.se',
          ),
          const _HelpContact(
            name: 'ARN (Allmänna reklamationsnämnden)',
            url: 'https://www.arn.se',
          ),
        ],
        detentionContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Asylrättscentrum',
            url: 'https://sweref.org',
          ),
          const _HelpContact(
            name: 'JO (Justitieombudsmannen)',
            phone: '08-786 51 00',
            url: 'https://www.jo.se',
          ),
        ],
        discriminationContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Diskrimineringsombudsmannen (DO)',
            phone: '08-120 20 700',
            url: 'https://www.do.se',
          ),
          const _HelpContact(
            name: 'Brottsofferjouren',
            phone: '116 006',
            url: 'https://www.brottsofferjouren.se',
          ),
        ],
        consumerContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Konsumentverket',
            url: 'https://www.konsumentverket.se',
          ),
          const _HelpContact(
            name: 'ARN (Allmänna reklamationsnämnden)',
            url: 'https://www.arn.se',
          ),
        ],
      );

  // ── Latvia ───────────────────────────────────────────────────────────
  factory _CountryLegalData.latvia() => _CountryLegalData(
        emergencyAct: 'Likums par policiju',
        emergencyActUrl: 'https://likumi.lv/ta/id/67957',
        restrainingOrderAct:
            'Civilprocesa likums 305. pants (Pagaidu aizsardziba)',
        restrainingOrderActUrl: 'https://likumi.lv/ta/id/50500',
        languageAct: 'Valsts valodas likums',
        languageActUrl: 'https://likumi.lv/ta/id/14740',
        criminalCodeAssault:
            'Kriminallikums 130. pants (Tisa miesas bojajumi)',
        criminalCodeAssaultUrl: 'https://likumi.lv/ta/id/88966',
        shelterAct: 'Socialas aizsardzibas likums',
        shelterActUrl: 'https://likumi.lv/ta/id/45905',
        policeAct: 'Likums par policiju 12. pants',
        policeActUrl: 'https://likumi.lv/ta/id/67957',
        constitution: 'Latvijas Republikas Satversme 92. pants',
        constitutionUrl: 'https://likumi.lv/ta/id/57980',
        criminalProcedureAct:
            'Kriminalprocesa likums 11. nodala',
        criminalProcedureActUrl: 'https://likumi.lv/ta/id/107820',
        aliensAct: 'Imigracijas likums',
        aliensActUrl: 'https://likumi.lv/ta/id/68522',
        aliensActLegalRep: 'Imigracijas likums 46. pants',
        aliensActStay: 'Imigracijas likums 51. pants',
        aliensActDetention: 'Imigracijas likums 54. pants',
        aliensActChallengeDetention: 'Imigracijas likums 55. pants',
        employmentAct: 'Darba likums',
        employmentActUrl: 'https://likumi.lv/ta/id/26019',
        workingTimeAct: 'Darba likums 131. pants (Darba laiks)',
        workingTimeActUrl: 'https://likumi.lv/ta/id/26019',
        annualHolidaysAct:
            'Darba likums 149. pants (Ikgadejais atvalinajums)',
        annualHolidaysActUrl: 'https://likumi.lv/ta/id/26019',
        sickLeaveRef:
            'Darba likums 73. pants (Slimibas pabalsts)',
        occupationalSafetyAct:
            'Darba aizsardzibas likums',
        occupationalSafetyActUrl: 'https://likumi.lv/ta/id/26020',
        residentialLeaseAct:
            'Dzivokla ires likums',
        residentialLeaseActUrl: 'https://likumi.lv/ta/id/309844',
        residentialLeaseDeposit:
            'Dzivokla ires likums 10. pants',
        residentialLeaseNotice:
            'Dzivokla ires likums 25. pants',
        residentialLeaseHabitable:
            'Dzivokla ires likums 14. pants',
        residentialLeaseEviction:
            'Dzivokla ires likums 28.-32. pants',
        nonDiscriminationAct:
            'Darba likums 29. pants (Diskriminacijas aizliegums)',
        nonDiscriminationActUrl: 'https://likumi.lv/ta/id/26019',
        criminalCodeDiscrimination:
            'Kriminallikums 150. pants (Naida kurinasana)',
        criminalCodeDiscriminationUrl: 'https://likumi.lv/ta/id/88966',
        consumerProtectionAct:
            'Pateretaju tiesibu aizsardzibas likums',
        consumerProtectionActUrl: 'https://likumi.lv/ta/id/23309',
        consumerProtectionPricing:
            'Pateretaju tiesibu aizsardzibas likums 12. pants',
        consumerProtectionUnfair:
            'Negodiga komercprakses aizlieguma likums',
        consumerDisputesAct:
            'Pateretaju arpastejas rikojumu komisija',
        consumerDisputesActUrl: 'https://likumi.lv/ta/id/23309',
        domesticContactsFn: (l10n) => [
          _HelpContact(name: l10n.contactEmergency, phone: '112'),
          const _HelpContact(
            name: 'Krizu un konsultaciju centrs "Skalbes"',
            phone: '67 222 922',
            url: 'https://www.skalbes.lv',
          ),
          const _HelpContact(
            name: 'Valsts policija',
            phone: '110',
          ),
        ],
        policeContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Juridiskas palidzibas administracija',
            phone: '67 514 208',
            url: 'https://www.jpa.gov.lv',
          ),
          const _HelpContact(
            name: 'Tiesibudsargs',
            phone: '67 686 768',
            url: 'https://www.tiesibsargs.lv',
          ),
        ],
        deportationContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Latvijas Cilvektiesibu centrs',
            url: 'https://cilvektiesibas.org.lv',
          ),
          const _HelpContact(
            name: 'Juridiskas palidzibas administracija',
            phone: '67 514 208',
            url: 'https://www.jpa.gov.lv',
          ),
        ],
        workplaceContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Valsts darba inspekcija',
            phone: '67 021 704',
            url: 'https://www.vdi.gov.lv',
          ),
          const _HelpContact(
            name: 'LBAS (Arodbiedribu savieniba)',
            url: 'https://www.lbas.lv',
          ),
        ],
        tenantContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Pateretaju tiesibu aizsardzibas centrs',
            phone: '65 452 554',
            url: 'https://www.ptac.gov.lv',
          ),
        ],
        detentionContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Latvijas Cilvektiesibu centrs',
            url: 'https://cilvektiesibas.org.lv',
          ),
          const _HelpContact(
            name: 'Tiesibudsargs',
            phone: '67 686 768',
            url: 'https://www.tiesibsargs.lv',
          ),
        ],
        discriminationContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Tiesibudsargs',
            phone: '67 686 768',
            url: 'https://www.tiesibsargs.lv',
          ),
        ],
        consumerContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Pateretaju tiesibu aizsardzibas centrs (PTAC)',
            phone: '65 452 554',
            url: 'https://www.ptac.gov.lv',
          ),
        ],
      );

  // ── Lithuania ─────────────────────────────────────────────────────────
  factory _CountryLegalData.lithuania() => _CountryLegalData(
        emergencyAct: 'Priesgaisrines saugos ir gelbejimo istatymas',
        emergencyActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.77316',
        restrainingOrderAct:
            'Apsaugos nuo smurto artimoje aplinkoje istatymas',
        restrainingOrderActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.400989',
        languageAct: 'Valstybines kalbos istatymas',
        languageActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.15211',
        criminalCodeAssault:
            'Baudziamasis kodeksas 138 str. (Nesunkus sveikatos sutrikdymas)',
        criminalCodeAssaultUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.111555',
        shelterAct: 'Socialines paslaugos istatymas',
        shelterActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.270342',
        policeAct: 'Policijos veiklos istatymas 18 str.',
        policeActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.153695',
        constitution: 'Lietuvos Respublikos Konstitucija 31 str.',
        constitutionUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.21892',
        criminalProcedureAct:
            'Baudziamojo proceso kodeksas 44 str.',
        criminalProcedureActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.163482',
        aliensAct: 'Uzsienieciu teisines padeties istatymas',
        aliensActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.232378',
        aliensActLegalRep: 'Uzsienieciu istatymas 5 str.',
        aliensActStay: 'Uzsienieciu istatymas 128 str.',
        aliensActDetention: 'Uzsienieciu istatymas 113 str.',
        aliensActChallengeDetention: 'Uzsienieciu istatymas 115 str.',
        employmentAct: 'Darbo kodeksas',
        employmentActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.291049',
        workingTimeAct: 'Darbo kodeksas 112 str. (Darbo laikas)',
        workingTimeActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.291049',
        annualHolidaysAct:
            'Darbo kodeksas 126 str. (Kasmetines atostogos)',
        annualHolidaysActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.291049',
        sickLeaveRef: 'Darbo kodeksas 133 str. (Ligos ismokos)',
        occupationalSafetyAct:
            'Darbuotoju saugos ir sveikatos istatymas',
        occupationalSafetyActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.152080',
        residentialLeaseAct:
            'Civilinis kodeksas 6.577-6.619 str. (Gyvenamosios patalpos nuoma)',
        residentialLeaseActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.107687',
        residentialLeaseDeposit: 'CK 6.584 str. (Uzstatas)',
        residentialLeaseNotice: 'CK 6.609 str. (Sutarties nutraukimas)',
        residentialLeaseHabitable:
            'CK 6.582 str. (Tinkamumo reikalavimai)',
        residentialLeaseEviction:
            'CK 6.611-6.614 str. (Ikeldininimo apsauga)',
        nonDiscriminationAct:
            'Lygiu galimybiu istatymas',
        nonDiscriminationActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.222522',
        criminalCodeDiscrimination:
            'BK 170 str. (Kurstymas pries grupes)',
        criminalCodeDiscriminationUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.111555',
        consumerProtectionAct:
            'Vartotoju teisiu apsaugos istatymas',
        consumerProtectionActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.104400',
        consumerProtectionPricing:
            'Vartotoju teisiu apsaugos istatymas 6 str.',
        consumerProtectionUnfair:
            'Nesaziningos komercines veiklos vartotojams draudimo istatymas',
        consumerDisputesAct:
            'Vartotoju teisiu apsaugos istatymas 27 str.',
        consumerDisputesActUrl:
            'https://e-seimas.lrs.lt/portal/legalAct/lt/TAD/TAIS.104400',
        domesticContactsFn: (l10n) => [
          _HelpContact(name: l10n.contactEmergency, phone: '112'),
          const _HelpContact(
            name: 'Pagalbos moterim linija',
            phone: '8 800 66 366',
            url: 'https://www.specializuotospaslaugos.lt',
          ),
          const _HelpContact(
            name: 'Vaiku linija',
            phone: '116 111',
          ),
        ],
        policeContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Valstybine garantuojama teisine pagalba',
            phone: '8 700 00 211',
            url: 'https://www.teisinepagalba.lt',
          ),
          const _HelpContact(
            name: 'Lygiu galimybiu kontrolieriaus tarnyba',
            url: 'https://www.lygybe.lt',
          ),
        ],
        deportationContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Lietuvos Raudonasis Kryžius (pabegelu programa)',
            url: 'https://www.redcross.lt',
          ),
          const _HelpContact(
            name: 'Valstybine garantuojama teisine pagalba',
            phone: '8 700 00 211',
            url: 'https://www.teisinepagalba.lt',
          ),
        ],
        workplaceContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Valstybine darbo inspekcija',
            phone: '8 5 213 9772',
            url: 'https://www.vdi.lt',
          ),
          const _HelpContact(
            name: 'Lietuvos profesines sajungos',
            url: 'https://www.lpsk.lt',
          ),
        ],
        tenantContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Valstybine vartotoju teisiu apsaugos tarnyba',
            phone: '8 5 262 6760',
            url: 'https://www.vvtat.lt',
          ),
        ],
        detentionContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Lietuvos Raudonasis Kryžius',
            url: 'https://www.redcross.lt',
          ),
          const _HelpContact(
            name: 'Seimo kontrolieriu staiga',
            phone: '8 5 266 5105',
            url: 'https://www.lrski.lt',
          ),
        ],
        discriminationContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Lygiu galimybiu kontrolieriaus tarnyba',
            url: 'https://www.lygybe.lt',
          ),
        ],
        consumerContactsFn: (l10n) => [
          const _HelpContact(
            name: 'Valstybine vartotoju teisiu apsaugos tarnyba (VVTAT)',
            phone: '8 5 262 6760',
            url: 'https://www.vvtat.lt',
          ),
        ],
      );

  // ── EU default ───────────────────────────────────────────────────────
  factory _CountryLegalData.eu() => _CountryLegalData(
        emergencyAct: 'EU Emergency Number 112',
        emergencyActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32002D0733',
        restrainingOrderAct:
            'EU Victims\' Directive 2012/29/EU, Art. 18-24',
        restrainingOrderActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32012L0029',
        languageAct: 'ECHR Article 6 (Right to an interpreter)',
        languageActUrl:
            'https://www.echr.coe.int/documents/d/echr/convention_ENG',
        criminalCodeAssault: 'ECHR Article 3 (Prohibition of torture)',
        criminalCodeAssaultUrl:
            'https://www.echr.coe.int/documents/d/echr/convention_ENG',
        shelterAct: 'EU Victims\' Directive 2012/29/EU, Art. 8-9',
        shelterActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32012L0029',
        policeAct: 'ECHR Article 5 (Right to liberty)',
        policeActUrl:
            'https://www.echr.coe.int/documents/d/echr/convention_ENG',
        constitution: 'EU Charter of Fundamental Rights, Art. 47',
        constitutionUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A12012P%2FTXT',
        criminalProcedureAct:
            'EU Directive 2013/48/EU (Right of access to a lawyer)',
        criminalProcedureActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32013L0048',
        aliensAct: 'EU Return Directive 2008/115/EC',
        aliensActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32008L0115',
        aliensActLegalRep: 'Return Directive Art. 13 (Legal remedies)',
        aliensActStay: 'Return Directive Art. 13(2)',
        aliensActDetention: 'Return Directive Art. 15',
        aliensActChallengeDetention: 'Return Directive Art. 15(2)',
        employmentAct:
            'EU Directive 2019/1152 (Transparent working conditions)',
        employmentActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32019L1152',
        workingTimeAct: 'EU Working Time Directive 2003/88/EC',
        workingTimeActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32003L0088',
        annualHolidaysAct:
            'Working Time Directive Art. 7 (Annual leave)',
        annualHolidaysActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32003L0088',
        sickLeaveRef: 'EU Charter Art. 31 (Fair working conditions)',
        occupationalSafetyAct:
            'EU Framework Directive 89/391/EEC',
        occupationalSafetyActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A31989L0391',
        residentialLeaseAct:
            'EU Charter Art. 34(3) (Housing assistance)',
        residentialLeaseActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A12012P%2FTXT',
        residentialLeaseDeposit:
            'National law applies (deposit)',
        residentialLeaseNotice:
            'National law applies (notice period)',
        residentialLeaseHabitable:
            'National law applies (habitability)',
        residentialLeaseEviction:
            'ECHR Protocol 1, Art. 1 (Property)',
        nonDiscriminationAct:
            'EU Equal Treatment Directive 2000/78/EC',
        nonDiscriminationActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32000L0078',
        criminalCodeDiscrimination:
            'EU Framework Decision 2008/913/JHA (Racism)',
        criminalCodeDiscriminationUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32008F0913',
        consumerProtectionAct:
            'EU Consumer Rights Directive 2011/83/EU',
        consumerProtectionActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32011L0083',
        consumerProtectionPricing:
            'EU Directive 98/6/EC (Price Indication)',
        consumerProtectionUnfair:
            'EU Unfair Commercial Practices Directive 2005/29/EC',
        consumerDisputesAct:
            'EU Directive 2013/11/EU (ADR for consumer disputes)',
        consumerDisputesActUrl:
            'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32013L0011',
        domesticContactsFn: (l10n) => [
          _HelpContact(name: l10n.contactEmergency, phone: '112'),
          const _HelpContact(
            name: 'EU Victim Support Helpline',
            phone: '116 006',
            url: 'https://victim-support.eu',
          ),
        ],
        policeContactsFn: (l10n) => [
          const _HelpContact(
            name: 'EU Fundamental Rights Agency (FRA)',
            url: 'https://fra.europa.eu',
          ),
        ],
        deportationContactsFn: (l10n) => [
          const _HelpContact(
            name: 'UNHCR',
            url: 'https://www.unhcr.org',
          ),
          const _HelpContact(
            name: 'EU Fundamental Rights Agency (FRA)',
            url: 'https://fra.europa.eu',
          ),
        ],
        workplaceContactsFn: (l10n) => [
          const _HelpContact(
            name: 'EU-OSHA (Occupational Safety Agency)',
            url: 'https://osha.europa.eu',
          ),
        ],
        tenantContactsFn: (l10n) => [
          const _HelpContact(
            name: 'European Consumer Centre (ECC-Net)',
            url: 'https://ec.europa.eu/info/ecc-net',
          ),
        ],
        detentionContactsFn: (l10n) => [
          const _HelpContact(
            name: 'UNHCR',
            url: 'https://www.unhcr.org',
          ),
          const _HelpContact(
            name: 'European Committee for the Prevention of Torture (CPT)',
            url: 'https://www.coe.int/en/web/cpt',
          ),
        ],
        discriminationContactsFn: (l10n) => [
          const _HelpContact(
            name: 'EU Fundamental Rights Agency (FRA)',
            url: 'https://fra.europa.eu',
          ),
          const _HelpContact(
            name: 'Equinet (European Network of Equality Bodies)',
            url: 'https://equineteurope.org',
          ),
        ],
        consumerContactsFn: (l10n) => [
          const _HelpContact(
            name: 'European Consumer Centre (ECC-Net)',
            url: 'https://ec.europa.eu/info/ecc-net',
          ),
          const _HelpContact(
            name: 'EU Online Dispute Resolution (ODR)',
            url: 'https://ec.europa.eu/consumers/odr',
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class RightsDetailScreen extends StatefulWidget {
  const RightsDetailScreen({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  State<RightsDetailScreen> createState() => _RightsDetailScreenState();
}

class _RightsDetailScreenState extends State<RightsDetailScreen>
    with SingleTickerProviderStateMixin {
  final Set<int> _checkedActions = {};
  late final AnimationController _sectionController;

  @override
  void initState() {
    super.initState();
    _sectionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = _buildData(l10n);
    final scenario = data[widget.scenarioId];

    if (scenario == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.scenarioNotFound)),
      );
    }

    // Build sections list for staggered animation
    final sections = <Widget>[];
    var sectionIndex = 0;

    if (scenario.rights.isNotEmpty) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _ExpandableSection(
          icon: Icons.shield_outlined,
          iconColor: AppColors.info,
          title: l10n.yourRights.replaceAll(':', ''),
          initiallyExpanded: true,
          child: Column(
            children: [
              for (int i = 0; i < scenario.rights.length; i++)
                _RightItemTile(
                  index: i + 1,
                  item: scenario.rights[i],
                  onShare: () => _shareRight(scenario.rights[i].text),
                ),
            ],
          ),
        ),
      ));
    }

    if (scenario.didYouKnow.isNotEmpty) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _DidYouKnowCard(fact: scenario.didYouKnow.first),
      ));
    }

    if (scenario.obligations.isNotEmpty) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _ExpandableSection(
          icon: Icons.info_outline,
          iconColor: AppColors.warning,
          title: l10n.youMust.replaceAll(':', ''),
          child: Column(
            children: [
              for (int i = 0; i < scenario.obligations.length; i++)
                _RightItemTile(
                  index: i + 1,
                  item: scenario.obligations[i],
                  onShare: () =>
                      _shareRight(scenario.obligations[i].text),
                ),
            ],
          ),
        ),
      ));
    }

    if (scenario.actions.isNotEmpty) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _ExpandableSection(
          icon: Icons.bolt_outlined,
          iconColor: AppColors.accent,
          title: l10n.whatToDo,
          initiallyExpanded: true,
          child: Column(
            children: [
              for (int i = 0; i < scenario.actions.length; i++)
                _ActionChecklistItem(
                  index: i + 1,
                  text: scenario.actions[i].text,
                  isChecked: _checkedActions.contains(i),
                  onToggle: () {
                    setState(() {
                      if (_checkedActions.contains(i)) {
                        _checkedActions.remove(i);
                      } else {
                        _checkedActions.add(i);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ));
    }

    if (scenario.didYouKnow.length > 1) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _DidYouKnowCard(fact: scenario.didYouKnow[1]),
      ));
    }

    if (scenario.deadlines.isNotEmpty) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _ExpandableSection(
          icon: Icons.schedule_outlined,
          iconColor: AppColors.error,
          title: l10n.deadlines,
          child: Column(
            children: [
              for (final d in scenario.deadlines) _DeadlineTile(item: d),
            ],
          ),
        ),
      ));
    }

    if (scenario.helpContacts.isNotEmpty) {
      sections.add(_AnimatedSection(
        index: sectionIndex++,
        controller: _sectionController,
        child: _ExpandableSection(
          icon: Icons.phone_outlined,
          iconColor: AppColors.success,
          title: l10n.getHelp,
          child: Column(
            children: [
              for (final c in scenario.helpContacts)
                _HelpContactCard(contact: c),
            ],
          ),
        ),
      ));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Visual header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: scenario.color,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scenario.color,
                      scenario.color.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xxl + 16,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                scenario.icon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scenario.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    scenario.tagline,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white
                                          .withValues(alpha: 0.85),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              titlePadding: EdgeInsets.zero,
              title: const SizedBox.shrink(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _shareScenario(scenario),
                tooltip: l10n.share,
              ),
            ],
          ),

          // ── Body content ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  ...sections,

                  const SizedBox(height: AppSpacing.lg),

                  // Ask AI CTA button with glow
                  _PremiumCtaButton(
                    onPressed: () => context.push('/chat/general'),
                    label: AppLocalizations.of(context)?.haveQuestionsAi ??
                        'Have questions? Talk to AI',
                    icon: Icons.chat_bubble_outline,
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareScenario(_ScenarioData scenario) {
    final l10n = AppLocalizations.of(context)!;
    final allRights =
        scenario.rights.map((r) => '- ${r.text}').join('\n');
    final text =
        '${scenario.title}\n\n${scenario.tagline}\n\n${l10n.yourRights.replaceAll(':', '')}\n$allRights\n\n${l10n.sentFromAdvocat}';
    Share.share(text);
  }

  void _shareRight(String rightText) {
    final l10n = AppLocalizations.of(context)!;
    Share.share('$rightText\n\n${l10n.sentFromAdvocat}');
  }

  // ── Country-specific legal references based on locale ────────────────
  _CountryLegalData _getLegalData() {
    final lang = Localizations.localeOf(context).languageCode;
    switch (lang) {
      case 'et':
        return _CountryLegalData.estonia();
      case 'fi':
        return _CountryLegalData.finland();
      case 'de':
        return _CountryLegalData.germany();
      case 'sv':
        return _CountryLegalData.sweden();
      case 'lv':
        return _CountryLegalData.latvia();
      case 'lt':
        return _CountryLegalData.lithuania();
      default:
        return _CountryLegalData.eu();
    }
  }

  // ── Build scenario data ────────────────────────────────────────────────
  Map<String, _ScenarioData> _buildData(AppLocalizations l10n) {
    final law = _getLegalData();

    return {
      // ── Domestic Violence & Assault (TOP PRIORITY) ──────────────────
      'domestic-violence': _ScenarioData(
        title: l10n.domesticViolence,
        tagline: l10n.domesticViolenceDesc,
        icon: Icons.health_and_safety_outlined,
        color: AppColors.error,
        rights: [
          _RightItem(l10n.rightCallEmergency,
              severity: _Severity.critical,
              legalRef: law.emergencyAct,
              legalUrl: law.emergencyActUrl),
          _RightItem(l10n.rightVictimProtection,
              severity: _Severity.critical,
              legalRef: 'EU Victims\' Directive 2012/29/EU',
              legalUrl: 'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32012L0029'),
          _RightItem(l10n.rightRestrainingOrder,
              severity: _Severity.critical,
              legalRef: law.restrainingOrderAct,
              legalUrl: law.restrainingOrderActUrl),
          _RightItem(l10n.rightVictimInterpreter,
              severity: _Severity.important,
              legalRef: law.languageAct,
              legalUrl: law.languageActUrl),
          _RightItem(l10n.rightMedicalHelp,
              severity: _Severity.critical,
              legalRef: law.criminalCodeAssault,
              legalUrl: law.criminalCodeAssaultUrl),
          _RightItem(l10n.rightShelter,
              severity: _Severity.important,
              legalRef: law.shelterAct,
              legalUrl: law.shelterActUrl),
        ],
        obligations: [
          _RightItem(l10n.mustReportDanger, severity: _Severity.critical),
          _RightItem(l10n.mustDocumentInjuries, severity: _Severity.important),
        ],
        actions: [
          _ActionItem(l10n.domesticActionCallEmergency),
          _ActionItem(l10n.domesticActionGoToSafe),
          _ActionItem(l10n.domesticActionDocumentEverything),
          _ActionItem(l10n.domesticActionFilePoliceReport),
          _ActionItem(l10n.domesticActionContactShelter),
          _ActionItem(l10n.domesticActionApplyRestraining),
        ],
        deadlines: [
          _DeadlineTile.data(
            l10n.domesticDeadlinePoliceReport,
            isUrgent: false,
          ),
          _DeadlineTile.data(
            l10n.domesticDeadlineRestraining,
            isUrgent: false,
          ),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.domesticFactRestrainingOrder),
          _DidYouKnow(l10n.domesticFactVictimDirective),
        ],
        helpContacts: law.domesticViolenceContacts(l10n),
      ),
      // ── Police Stop ─────────────────────────────────────────────────
      'police-stop': _ScenarioData(
        title: l10n.stoppedByPolice,
        tagline: l10n.stoppedByPoliceDesc,
        icon: Icons.local_police_outlined,
        color: AppColors.info,
        rights: [
          _RightItem(l10n.rightKnowWhyStopped,
              severity: _Severity.critical,
              legalRef: law.policeAct,
              legalUrl: law.policeActUrl),
          _RightItem(l10n.rightRemainSilent,
              severity: _Severity.critical,
              legalRef: law.constitution,
              legalUrl: law.constitutionUrl),
          _RightItem(l10n.rightAskInterpreter,
              severity: _Severity.important,
              legalRef: law.languageAct,
              legalUrl: law.languageActUrl),
          _RightItem(l10n.rightContactLawyer,
              severity: _Severity.critical,
              legalRef: law.criminalProcedureAct,
              legalUrl: law.criminalProcedureActUrl),
          _RightItem(l10n.rightRecordEncounter, severity: _Severity.info),
        ],
        obligations: [
          _RightItem(l10n.mustProvideName, severity: _Severity.important),
          _RightItem(l10n.mustShowId, severity: _Severity.important),
          _RightItem(l10n.mustNotResist, severity: _Severity.critical),
        ],
        actions: [
          _ActionItem(l10n.policeActionStayCalm),
          _ActionItem(l10n.policeActionAskWhy),
          _ActionItem(l10n.policeActionProvideName),
          _ActionItem(l10n.policeActionWantLawyer),
          _ActionItem(l10n.policeActionAskInterpreter),
          _ActionItem(l10n.policeActionNoteBadge),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.policeFactMustTellReason),
          _DidYouKnow(l10n.policeFactCanRecord),
        ],
        helpContacts: law.policeStopContacts(l10n),
      ),
      'deportation': _ScenarioData(
        title: l10n.deportationNotice,
        tagline: l10n.deportationNoticeDesc,
        icon: Icons.flight_takeoff_outlined,
        color: AppColors.error,
        rights: [
          _RightItem(l10n.rightAppealAdmin,
              severity: _Severity.critical,
              legalRef: law.aliensAct,
              legalUrl: law.aliensActUrl),
          _RightItem(l10n.rightLegalRep,
              severity: _Severity.critical,
              legalRef: law.aliensActLegalRep,
              legalUrl: law.aliensActUrl),
          _RightItem(l10n.rightInterpreter,
              severity: _Severity.important,
              legalRef: law.languageAct,
              legalUrl: law.languageActUrl),
          _RightItem(l10n.rightStayDuringAppeal,
              severity: _Severity.critical,
              legalRef: law.aliensActStay,
              legalUrl: law.aliensActUrl),
        ],
        actions: [
          _ActionItem(l10n.doNotIgnoreNotice),
          _ActionItem(l10n.noteAppealDeadline),
          _ActionItem(l10n.contactLawyerImmediately),
          _ActionItem(l10n.applyLegalAid),
        ],
        deadlines: [
          _DeadlineTile.data(
            l10n.deportationDeadlineAppeal,
            isUrgent: true,
          ),
          _DeadlineTile.data(
            l10n.deportationDeadlineLegalAid,
            isUrgent: true,
          ),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.deportationFactStayDuringAppeal),
        ],
        helpContacts: law.deportationContacts(l10n),
      ),
      'workplace': _ScenarioData(
        title: l10n.workplaceRights,
        tagline: l10n.workplaceRightsDesc,
        icon: Icons.work_outline,
        color: AppColors.accent,
        rights: [
          _RightItem(l10n.minimumWage,
              severity: _Severity.critical,
              legalRef: law.employmentAct,
              legalUrl: law.employmentActUrl),
          _RightItem(l10n.workingTimeLimits,
              severity: _Severity.important,
              legalRef: law.workingTimeAct,
              legalUrl: law.workingTimeActUrl),
          _RightItem(l10n.annualLeave,
              severity: _Severity.important,
              legalRef: law.annualHolidaysAct,
              legalUrl: law.annualHolidaysActUrl),
          _RightItem(l10n.sickLeave,
              severity: _Severity.important,
              legalRef: law.sickLeaveRef,
              legalUrl: law.employmentActUrl),
          _RightItem(l10n.safeWorkingConditions,
              severity: _Severity.critical,
              legalRef: law.occupationalSafetyAct,
              legalUrl: law.occupationalSafetyActUrl),
        ],
        actions: [
          _ActionItem(l10n.workplaceActionKeepContract),
          _ActionItem(l10n.workplaceActionTrackHours),
          _ActionItem(l10n.workplaceActionReportUnsafe),
          _ActionItem(l10n.workplaceActionJoinUnion),
          _ActionItem(l10n.workplaceActionContactAuthority),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.workplaceFactCollectiveWage),
          _DidYouKnow(l10n.workplaceFactOralContract),
        ],
        helpContacts: law.workplaceContacts(l10n),
      ),
      'tenant': _ScenarioData(
        title: l10n.tenantRights,
        tagline: l10n.tenantRightsDesc,
        icon: Icons.home_outlined,
        color: AppColors.warning,
        rights: [
          _RightItem(l10n.writtenRentalAgreement,
              severity: _Severity.important,
              legalRef: law.residentialLeaseAct,
              legalUrl: law.residentialLeaseActUrl),
          _RightItem(l10n.securityDeposit,
              severity: _Severity.important,
              legalRef: law.residentialLeaseDeposit,
              legalUrl: law.residentialLeaseActUrl),
          _RightItem(l10n.landlordNotice,
              severity: _Severity.critical,
              legalRef: law.residentialLeaseNotice,
              legalUrl: law.residentialLeaseActUrl),
          _RightItem(l10n.rightHabitableDwelling,
              severity: _Severity.critical,
              legalRef: law.residentialLeaseHabitable,
              legalUrl: law.residentialLeaseActUrl),
          _RightItem(l10n.protectionUnjustEviction,
              severity: _Severity.critical,
              legalRef: law.residentialLeaseEviction,
              legalUrl: law.residentialLeaseActUrl),
        ],
        actions: [
          _ActionItem(l10n.tenantActionWrittenAgreement),
          _ActionItem(l10n.tenantActionDocumentCondition),
          _ActionItem(l10n.tenantActionReportMaintenance),
          _ActionItem(l10n.tenantActionNoIllegalEviction),
          _ActionItem(l10n.tenantActionContactAdvisory),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.tenantFactNoEvictionWithoutCourt),
        ],
        helpContacts: law.tenantContacts(l10n),
      ),
      'detention': _ScenarioData(
        title: l10n.immigrationDetention,
        tagline: l10n.immigrationDetentionDesc,
        icon: Icons.lock_outline,
        color: AppColors.error,
        rights: [
          _RightItem(l10n.rightKnowDetentionReason,
              severity: _Severity.critical,
              legalRef: law.aliensActDetention,
              legalUrl: law.aliensActUrl),
          _RightItem(l10n.rightContactLawyerDetention,
              severity: _Severity.critical,
              legalRef: law.constitution,
              legalUrl: law.constitutionUrl),
          _RightItem(l10n.rightContactEmbassy,
              severity: _Severity.important,
              legalRef: 'Vienna Convention on Consular Relations',
              legalUrl: 'https://legal.un.org/ilc/texts/instruments/english/conventions/9_2_1963.pdf'),
          _RightItem(l10n.rightChallengeDetention,
              severity: _Severity.critical,
              legalRef: law.aliensActChallengeDetention,
              legalUrl: law.aliensActUrl),
          _RightItem(l10n.rightHumaneTreatment,
              severity: _Severity.critical,
              legalRef: 'ECHR Article 3',
              legalUrl: 'https://www.echr.coe.int/documents/d/echr/convention_ENG'),
        ],
        actions: [
          _ActionItem(l10n.detentionActionAskDecision),
          _ActionItem(l10n.detentionActionRequestLawyer),
          _ActionItem(l10n.detentionActionContactEmbassy),
          _ActionItem(l10n.detentionActionAskMedical),
          _ActionItem(l10n.detentionActionRequestInterpreter),
        ],
        deadlines: [
          _DeadlineTile.data(
            l10n.detentionDeadlineCourtReview,
            isUrgent: true,
          ),
          _DeadlineTile.data(
            l10n.detentionDeadlineContinuation,
            isUrgent: false,
          ),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.detentionFactCourtReview),
        ],
        helpContacts: law.detentionContacts(l10n),
      ),
      'discrimination': _ScenarioData(
        title: l10n.discrimination,
        tagline: l10n.discriminationDesc,
        icon: Icons.balance_outlined,
        color: AppColors.primary,
        rights: [
          _RightItem(l10n.documentIncident,
              severity: _Severity.critical),
          _RightItem(l10n.fileComplaintOmbudsman,
              severity: _Severity.critical,
              legalRef: law.nonDiscriminationAct,
              legalUrl: law.nonDiscriminationActUrl),
          _RightItem(l10n.contactLegalAidOffice,
              severity: _Severity.important),
          _RightItem(l10n.reportToPolice,
              severity: _Severity.important,
              legalRef: law.criminalCodeDiscrimination,
              legalUrl: law.criminalCodeDiscriminationUrl),
        ],
        actions: [
          _ActionItem(l10n.discriminationActionWriteDown),
          _ActionItem(l10n.discriminationActionSaveEvidence),
          _ActionItem(l10n.discriminationActionFileComplaint),
          _ActionItem(l10n.discriminationActionContactLegalAid),
          _ActionItem(l10n.discriminationActionReportPolice),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.discriminationFactNonDiscriminationAct),
        ],
        helpContacts: law.discriminationContacts(l10n),
      ),
      // ── Consumer Protection ─────────────────────────────────────────
      'consumer': _ScenarioData(
        title: l10n.consumerProtection,
        tagline: l10n.consumerProtectionDesc,
        icon: Icons.shopping_bag_outlined,
        color: AppColors.accent,
        rights: [
          _RightItem(l10n.rightReturnOnline,
              severity: _Severity.critical,
              legalRef: 'EU Consumer Rights Directive 2011/83/EU',
              legalUrl: 'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32011L0083'),
          _RightItem(l10n.rightDefectiveProduct,
              severity: _Severity.critical,
              legalRef: law.consumerProtectionAct,
              legalUrl: law.consumerProtectionActUrl),
          _RightItem(l10n.rightClearPricing,
              severity: _Severity.important,
              legalRef: law.consumerProtectionPricing,
              legalUrl: law.consumerProtectionActUrl),
          _RightItem(l10n.rightComplainBoard,
              severity: _Severity.important,
              legalRef: law.consumerDisputesAct,
              legalUrl: law.consumerDisputesActUrl),
          _RightItem(l10n.rightProtectionFraud,
              severity: _Severity.critical,
              legalRef: law.consumerProtectionUnfair,
              legalUrl: law.consumerProtectionActUrl),
        ],
        obligations: [
          _RightItem(l10n.mustKeepReceipts, severity: _Severity.important),
          _RightItem(l10n.mustActTimely, severity: _Severity.important),
        ],
        actions: [
          _ActionItem(l10n.consumerActionKeepEvidence),
          _ActionItem(l10n.consumerActionContactSeller),
          _ActionItem(l10n.consumerActionFileComplaint),
          _ActionItem(l10n.consumerActionContactAuthority),
          _ActionItem(l10n.consumerActionReportFraud),
        ],
        deadlines: [
          _DeadlineTile.data(
            l10n.consumerDeadlineWithdrawal,
            isUrgent: true,
          ),
          _DeadlineTile.data(
            l10n.consumerDeadlineDefect,
            isUrgent: false,
          ),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.consumerFactWithdrawal),
          _DidYouKnow(l10n.consumerFactWarranty),
        ],
        helpContacts: law.consumerContacts(l10n),
      ),
      // ── Children's Rights & Alimony ───────────────────────────────────
      'children-rights': _ScenarioData(
        title: l10n.childrenRights,
        tagline: l10n.childrenRightsDesc,
        icon: Icons.child_care,
        color: const Color(0xFFE91E63),
        rights: [
          _RightItem(l10n.rightChildSupport,
              severity: _Severity.critical,
              legalRef: 'Perekonnaseadus § 100–102',
              legalUrl: 'https://www.riigiteataja.ee/akt/PKS'),
          _RightItem(l10n.rightMinimumAlimony,
              severity: _Severity.critical,
              legalRef: 'Perekonnaseadus § 101²',
              legalUrl: 'https://www.riigiteataja.ee/akt/PKS'),
          _RightItem(l10n.rightCourtAlimony,
              severity: _Severity.important,
              legalRef: 'Tsiviilkohtumenetluse seadustik',
              legalUrl: 'https://www.riigiteataja.ee/akt/TsMS'),
          _RightItem(l10n.rightBailiffEnforcement,
              severity: _Severity.important,
              legalRef: 'Täitemenetluse seadustik',
              legalUrl: 'https://www.riigiteataja.ee/akt/TMS'),
          _RightItem(l10n.rightStateAlimonyGuarantee,
              severity: _Severity.critical,
              legalRef: 'Perehüvitiste seadus § 57–62',
              legalUrl: 'https://www.riigiteataja.ee/akt/PHS'),
          _RightItem(l10n.rightChildEducation,
              severity: _Severity.important,
              legalRef: 'Lastekaitseseadus § 4–5',
              legalUrl: 'https://www.riigiteataja.ee/akt/LasteKS'),
          _RightItem(l10n.rightChildContact,
              severity: _Severity.info,
              legalRef: 'Perekonnaseadus § 143',
              legalUrl: 'https://www.riigiteataja.ee/akt/PKS'),
        ],
        obligations: [
          _RightItem(l10n.mustFileCourtClaim,
              severity: _Severity.important),
          _RightItem(l10n.mustNotifyAddressChange,
              severity: _Severity.info),
        ],
        actions: [
          _ActionItem(l10n.childrenActionGatherDocs),
          _ActionItem(l10n.childrenActionFileCourtClaim),
          _ActionItem(l10n.childrenActionApplyElatisabi),
          _ActionItem(l10n.childrenActionContactBailiff),
          _ActionItem(l10n.childrenActionCallLasteabi),
        ],
        deadlines: [
          _DeadlineTile.data(
            l10n.childrenDeadlineCourt,
            isUrgent: false,
          ),
          _DeadlineTile.data(
            l10n.childrenDeadlineElatisabi,
            isUrgent: false,
          ),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.childrenFactMinimum),
          _DidYouKnow(l10n.childrenFactElatisabi),
        ],
        helpContacts: [
          const _HelpContact(
            name: 'Lasteabi telefon',
            phone: '116 111',
            url: 'https://www.lasteabi.ee',
          ),
          const _HelpContact(
            name: 'Sotsiaalkindlustusamet (elatisabi)',
            phone: '612 1360',
            url: 'https://www.sotsiaalkindlustusamet.ee/et/lapsed-ja-pere/elatisabi',
          ),
          const _HelpContact(
            name: 'Riigi Õigusabi',
            phone: '631 4222',
            url: 'https://www.rik.ee/oigusabi',
          ),
          const _HelpContact(
            name: 'e-toimik (kohtusse pöördumine)',
            url: 'https://www.e-toimik.ee',
          ),
        ],
      ),
      // ── Cyberbullying / Online Harassment ─────────────────────────────
      'cyberbullying': _ScenarioData(
        title: l10n.cyberbullying,
        tagline: l10n.cyberbullyingDesc,
        icon: Icons.security,
        color: const Color(0xFF9C27B0),
        rights: [
          _RightItem(l10n.rightReportCybercrime,
              severity: _Severity.critical,
              legalRef: 'Karistusseadustik § 120 (Ähvardamine)',
              legalUrl: 'https://www.riigiteataja.ee/akt/184411'),
          _RightItem(l10n.rightPrivacyProtection,
              severity: _Severity.critical,
              legalRef: 'Karistusseadustik § 157 (Eraelu puutumatuse rikkumine)',
              legalUrl: 'https://www.riigiteataja.ee/akt/184411'),
          _RightItem(l10n.rightContentRemoval,
              severity: _Severity.important,
              legalRef: 'GDPR Art. 17 (Õigus olla unustatud)',
              legalUrl: 'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32016R0679'),
          _RightItem(l10n.rightMoralDamageCompensation,
              severity: _Severity.important,
              legalRef: 'Võlaõigusseadus § 1043–1055',
              legalUrl: 'https://www.riigiteataja.ee/akt/VOS'),
          _RightItem(l10n.rightDataProtection,
              severity: _Severity.important,
              legalRef: 'Isikuandmete kaitse seadus',
              legalUrl: 'https://www.riigiteataja.ee/akt/IKS'),
          _RightItem(l10n.rightDefamationAction,
              severity: _Severity.info,
              legalRef: 'Võlaõigusseadus § 1047',
              legalUrl: 'https://www.riigiteataja.ee/akt/VOS'),
        ],
        obligations: [
          _RightItem(l10n.mustCollectEvidence,
              severity: _Severity.critical),
          _RightItem(l10n.mustNotRetaliate,
              severity: _Severity.important),
        ],
        actions: [
          _ActionItem(l10n.cyberActionScreenshots),
          _ActionItem(l10n.cyberActionReportPolice),
          _ActionItem(l10n.cyberActionReportPlatform),
          _ActionItem(l10n.cyberActionContactDPA),
          _ActionItem(l10n.cyberActionConsultLawyer),
        ],
        deadlines: [
          _DeadlineTile.data(
            l10n.cyberDeadlineCriminal,
            isUrgent: false,
          ),
          _DeadlineTile.data(
            l10n.cyberDeadlineCivil,
            isUrgent: false,
          ),
        ],
        didYouKnow: [
          _DidYouKnow(l10n.cyberFactPrivacy),
          _DidYouKnow(l10n.cyberFactGDPR),
        ],
        helpContacts: [
          const _HelpContact(
            name: 'Politsei (hädaabi)',
            phone: '112',
          ),
          const _HelpContact(
            name: 'Lasteabi telefon',
            phone: '116 111',
            url: 'https://www.lasteabi.ee',
          ),
          const _HelpContact(
            name: 'Vihjeliin (veebikonstaabel)',
            url: 'https://www.politsei.ee/et/juhend/vihjeliin',
          ),
          const _HelpContact(
            name: 'Andmekaitse Inspektsioon',
            phone: '627 4135',
            url: 'https://www.aki.ee',
          ),
          const _HelpContact(
            name: 'Riigi Õigusabi',
            phone: '631 4222',
            url: 'https://www.rik.ee/oigusabi',
          ),
        ],
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Animated section wrapper for staggered entrance
// ---------------------------------------------------------------------------

class _AnimatedSection extends StatelessWidget {
  const _AnimatedSection({
    required this.index,
    required this.controller,
    required this.child,
  });

  final int index;
  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final begin = (index * 0.08).clamp(0.0, 0.6);
    final end = (begin + 0.4).clamp(0.0, 1.0);

    final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium CTA button with glow
// ---------------------------------------------------------------------------

class _PremiumCtaButton extends StatefulWidget {
  const _PremiumCtaButton({
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  State<_PremiumCtaButton> createState() => _PremiumCtaButtonState();
}

class _PremiumCtaButtonState extends State<_PremiumCtaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: _pressed ? 0.4 : 0.25),
                blurRadius: _pressed ? 20 : 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable section widget with enhanced styling
// ---------------------------------------------------------------------------

class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            childrenPadding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            children: [child],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Right item tile with severity indicator, number, and share
// ---------------------------------------------------------------------------

class _RightItemTile extends StatefulWidget {
  const _RightItemTile({
    required this.index,
    required this.item,
    required this.onShare,
  });

  final int index;
  final _RightItem item;
  final VoidCallback onShare;

  @override
  State<_RightItemTile> createState() => _RightItemTileState();
}

class _RightItemTileState extends State<_RightItemTile> {
  bool _showRef = false;

  Color get _severityColor {
    switch (widget.item.severity) {
      case _Severity.critical:
        return AppColors.error;
      case _Severity.important:
        return AppColors.warning;
      case _Severity.info:
        return AppColors.accent;
    }
  }

  String _severityLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.item.severity) {
      case _Severity.critical:
        return l10n.mustKnow;
      case _Severity.important:
        return l10n.important;
      case _Severity.info:
        return l10n.goodToKnow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: widget.item.legalRef != null
            ? () => setState(() => _showRef = !_showRef)
            : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: _severityColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border(
              left: BorderSide(color: _severityColor, width: 3),
            ),
            boxShadow: [
              BoxShadow(
                color: _severityColor.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _severityColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _severityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.text,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Severity tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _severityColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            _severityLabel(context),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _severityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Share button
                  GestureDetector(
                    onTap: widget.onShare,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.share_outlined,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              // Expandable legal reference
              if (_showRef && widget.item.legalRef != null) ...[
                const SizedBox(height: AppSpacing.sm),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: widget.item.legalUrl != null
                        ? () async {
                            final uri = Uri.parse(widget.item.legalUrl!);
                            // Security: only allow https:// URLs
                            if (uri.scheme != 'https') return;
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.item.legalUrl != null
                                ? Icons.open_in_new_outlined
                                : Icons.gavel_outlined,
                            size: 14,
                            color: widget.item.legalUrl != null
                                ? AppColors.info
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              widget.item.legalRef!,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: widget.item.legalUrl != null
                                    ? AppColors.info
                                    : AppColors.textSecondary,
                                decoration: widget.item.legalUrl != null
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                decorationColor: AppColors.info,
                              ),
                            ),
                          ),
                          if (widget.item.legalUrl != null)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.launch_outlined,
                                size: 12,
                                color: AppColors.info,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action checklist item with tappable checkbox
// ---------------------------------------------------------------------------

class _ActionChecklistItem extends StatelessWidget {
  const _ActionChecklistItem({
    required this.index,
    required this.text,
    required this.isChecked,
    required this.onToggle,
  });

  final int index;
  final String text;
  final bool isChecked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () {
          HapticFeedback.lightImpact();
          onToggle();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: isChecked
                ? AppColors.success.withValues(alpha: 0.06)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isChecked
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
            boxShadow: [
              if (isChecked)
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Row(
            children: [
              // Step number / check
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isChecked
                      ? AppColors.success
                      : AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: isChecked
                      ? [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: isChecked
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$index',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isChecked
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    decoration: isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Deadline tile with urgency colors
// ---------------------------------------------------------------------------

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({required this.item});

  final _DeadlineItem item;

  /// Helper factory for building deadline data inline.
  static _DeadlineItem data(String text, {bool isUrgent = false}) {
    return _DeadlineItem(text, isUrgent: isUrgent);
  }

  @override
  Widget build(BuildContext context) {
    final color = item.isUrgent ? AppColors.error : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border(
            left: BorderSide(color: color, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              item.isUrgent
                  ? Icons.warning_amber_rounded
                  : Icons.schedule_outlined,
              color: color,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                item.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight:
                      item.isUrgent ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Did you know?" card
// ---------------------------------------------------------------------------

class _DidYouKnowCard extends StatelessWidget {
  const _DidYouKnowCard({required this.fact});

  final _DidYouKnow fact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.08),
              AppColors.info.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.didYouKnow,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fact.text,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Help contact card
// ---------------------------------------------------------------------------

class _HelpContactCard extends StatelessWidget {
  const _HelpContactCard({required this.contact});

  final _HelpContact contact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (contact.phone != null)
              _ContactRow(
                icon: Icons.phone_outlined,
                text: contact.phone!,
                color: AppColors.success,
              ),
            if (contact.email != null)
              _ContactRow(
                icon: Icons.email_outlined,
                text: contact.email!,
                color: AppColors.info,
              ),
            if (contact.url != null)
              _ContactRow(
                icon: Icons.language_outlined,
                text: contact.url!,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
