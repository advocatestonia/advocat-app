// ---------------------------------------------------------------------------
// Sample case canned conversation (backlog #36, Layer 3)
// ---------------------------------------------------------------------------
//
// Pre-baked transcript shown when a new user picks "Try with a sample case"
// in the welcome modal. Demonstrates Advocat analyzing a fictional service
// agreement and proposing counter-clauses — entirely static, no Anthropic
// API call. Estonian legal style with VÕS references; identical structural
// content across EN/ET/FI/RU with locale-appropriate phrasing.
//
// Used by ChatScreen when `caseId == sampleCaseId` to seed [_messages] and
// short-circuit the Supabase load. No persistence, no quota cost.

class SampleCaseMessage {
  const SampleCaseMessage({
    required this.role,
    required this.content,
  });

  /// 'user' or 'assistant'. Lower-case for direct equality with the chat
  /// screen's existing string comparisons.
  final String role;
  final String content;
}

abstract final class SampleCase {
  /// Sentinel caseId routed to the sample chat experience. Anything special
  /// in chat_screen.dart switches on this constant.
  static const String id = 'sample';

  /// Title shown in the chat app-bar for the sample. Localized.
  static String title(String locale) {
    switch (locale.toLowerCase()) {
      case 'et':
        return 'Näide: Teenuse osutamise lepingu analüüs';
      case 'fi':
        return 'Esimerkki: Palvelusopimuksen analyysi';
      case 'ru':
        return 'Пример: Разбор договора оказания услуг';
      default:
        return 'Example: Service Agreement Review';
    }
  }

  /// Banner copy rendered above the sample transcript: makes it crystal
  /// clear the conversation is canned so users don't think the AI is broken
  /// when input is disabled.
  static String banner(String locale) {
    switch (locale.toLowerCase()) {
      case 'et':
        return 'See on näide. Vestlust ei salvestata ja AI-päringuid ei tehta. Vajuta nuppu allpool, et alustada päris vestlust.';
      case 'fi':
        return 'Tämä on esimerkki. Keskustelua ei tallenneta eikä tekoälyä kutsuta. Aloita oma keskustelu alla olevasta painikkeesta.';
      case 'ru':
        return 'Это пример. Беседа не сохраняется, запросы к AI не отправляются. Нажмите кнопку ниже, чтобы начать настоящий разговор.';
      default:
        return 'This is a sample. Nothing is saved and no AI calls are made. Tap the button below to start a real conversation.';
    }
  }

  /// "Start your own conversation" CTA label.
  static String startRealCta(String locale) {
    switch (locale.toLowerCase()) {
      case 'et':
        return 'Alusta oma vestlust';
      case 'fi':
        return 'Aloita oma keskustelu';
      case 'ru':
        return 'Начать свой разговор';
      default:
        return 'Start your own conversation';
    }
  }

  /// The canned transcript. 4 messages, alternating user/assistant.
  static List<SampleCaseMessage> messages(String locale) {
    switch (locale.toLowerCase()) {
      case 'et':
        return _et;
      case 'fi':
        return _fi;
      case 'ru':
        return _ru;
      default:
        return _en;
    }
  }

  // ---------------------------------------------------------------------
  // EN
  // ---------------------------------------------------------------------
  static const List<SampleCaseMessage> _en = [
    SampleCaseMessage(
      role: 'user',
      content:
          "I'm signing a service agreement with a vendor. Can you spot risks?",
    ),
    SampleCaseMessage(
      role: 'assistant',
      content: '''I reviewed the draft and found **3 material risks**:

**1. Unilateral termination clause (§7.2)**
The vendor can terminate "for any reason" with 7 days' notice, but you owe 90 days. That asymmetry is unenforceable under Estonian Law of Obligations Act (VÕS) § 42 — a clause that places one party in a "significantly worse position" is void. Practical risk: vendor walks away mid-project, you pay anyway.

**2. IP assignment overreach (§11.1)**
The clause assigns "all intellectual property created in connection with the services" to the vendor. That sweeps in YOUR pre-existing IP (your brand assets, internal docs) the moment they touch them. VÕS § 9 requires the scope of assignment to be specific.

**3. No SLA on response times (§4)**
"Reasonable efforts" — undefined. If they ghost you for 6 weeks, you have no contractual lever. Standard market terms specify 1-business-day acknowledgement, 5 days resolution for non-critical issues.''',
    ),
    SampleCaseMessage(
      role: 'user',
      content: "What should I negotiate?",
    ),
    SampleCaseMessage(
      role: 'assistant',
      content: '''Here are **3 specific counter-proposals** in priority order:

**A. Symmetric termination (§7.2)**
> "Either party may terminate this Agreement for convenience upon thirty (30) days' written notice. The Vendor shall complete all work-in-progress through the notice period and deliver work product."

*Why*: Removes the 90/7 asymmetry and stops the vendor from walking with deposits.

**B. Bounded IP assignment (§11.1)**
> "Vendor assigns to Client all intellectual property rights in deliverables created specifically for Client under this Agreement. Client's pre-existing materials remain Client's sole property and are licensed to Vendor only for the duration of performance."

*Why*: Aligns with VÕS § 9 specificity requirement and protects your prior work.

**C. Concrete SLA (§4)**
> "Vendor shall acknowledge support requests within one (1) business day and resolve P1 issues within forty-eight (48) hours, P2 within five (5) business days. Failure to meet SLA in any month entitles Client to a 10% service credit."

*Why*: Creates a measurable remedy, not "reasonable efforts" theatre.

Want me to draft a redline of the full agreement, or a counter-offer email to the vendor?''',
    ),
  ];

  // ---------------------------------------------------------------------
  // ET
  // ---------------------------------------------------------------------
  static const List<SampleCaseMessage> _et = [
    SampleCaseMessage(
      role: 'user',
      content:
          'Sõlmin teenuse osutamise lepingu tarnijaga. Kas saad riskid välja tuua?',
    ),
    SampleCaseMessage(
      role: 'assistant',
      content: '''Vaatasin lepingu üle ja tuvastasin **3 olulist riski**:

**1. Ühepoolne ülesütlemisõigus (§7.2)**
Tarnija võib lepingu lõpetada "mis tahes põhjusel" 7-päevase etteteatamisega, kuid sina pead andma 90 päeva. Selline ebavõrdsus ei kehti võlaõigusseaduse (VÕS) § 42 kohaselt — säte, mis paneb ühe poole "oluliselt halvemasse seisundisse", on tühine. Praktiline risk: tarnija lahkub poole projekti pealt, sina maksad ikkagi.

**2. Liiga lai IP-õiguste loovutamine (§11.1)**
Säte annab tarnijale "kõik teenustega seoses tekkivad intellektuaalomandi õigused". See haarab ka SINU varasema vara (brändi materjalid, sisedokumendid) hetkel, kui tarnija nendega kokku puutub. VÕS § 9 nõuab, et loovutuse ulatus oleks täpselt määratletud.

**3. Reaktsiooniaegade SLA puudub (§4)**
"Mõistlikud jõupingutused" — defineerimata. Kui nad 6 nädalat ei vasta, sul ei ole lepingulist hooba. Turustandard on 1-päevane kinnitus, kriitilisete probleemide lahendus 5 päevaga.''',
    ),
    SampleCaseMessage(
      role: 'user',
      content: 'Mida peaksin läbi rääkima?',
    ),
    SampleCaseMessage(
      role: 'assistant',
      content: '''Siin on **3 konkreetset vastuettepanekut** prioriteetsuse järjekorras:

**A. Sümmeetriline ülesütlemine (§7.2)**
> "Kumbki pool võib käesoleva lepingu mis tahes põhjusel lõpetada kolmekümne (30) päevase etteteatamisega kirjalikus vormis. Tarnija viib lõpule käimasoleva töö etteteatamisaja jooksul ning annab töötulemuse üle."

*Miks*: Eemaldab 90/7 ebavõrdsuse ja takistab tarnijal sissemaksetega lahkumist.

**B. Piiratud IP-õiguste loovutamine (§11.1)**
> "Tarnija loovutab Kliendile kõik intellektuaalomandi õigused üksnes käesoleva lepingu raames Kliendile spetsiaalselt loodud tulemustes. Kliendi varem olemas olnud materjalid jäävad Kliendi ainuomandiks ning litsentseeritakse Tarnijale üksnes lepingu täitmise ajaks."

*Miks*: Kooskõlas VÕS § 9 määratletuse nõudega ja kaitseb sinu varasemat tööd.

**C. Konkreetne SLA (§4)**
> "Tarnija kinnitab tugitaotluse vastuvõtmist ühe (1) tööpäeva jooksul ning lahendab P1 probleemid neljakümne kaheksa (48) tunni jooksul, P2 viie (5) tööpäeva jooksul. Kui SLA-d kuu jooksul ei täideta, on Kliendil õigus 10% teenustasu krediidile."

*Miks*: Loob mõõdetava õiguskaitsevahendi, mitte "mõistlike jõupingutuste" teatri.

Kas soovid, et koostaksin lepingu täisversiooni paranduste markeeringuga või vastuettepaneku e-kirja tarnijale?''',
    ),
  ];

  // ---------------------------------------------------------------------
  // FI
  // ---------------------------------------------------------------------
  static const List<SampleCaseMessage> _fi = [
    SampleCaseMessage(
      role: 'user',
      content:
          'Allekirjoittamassa palvelusopimusta toimittajan kanssa. Voitko löytää riskit?',
    ),
    SampleCaseMessage(
      role: 'assistant',
      content: '''Tarkastin luonnoksen ja löysin **3 olennaista riskiä**:

**1. Yksipuolinen irtisanomislauseke (§7.2)**
Toimittaja voi irtisanoa sopimuksen "mistä tahansa syystä" 7 päivän varoitusajalla, mutta sinulta vaaditaan 90 päivää. Tämä epäsymmetria on Viron velvoiteoikeuslain (VÕS) § 42 mukaan pätemätön — sopimuskohta, joka asettaa toisen osapuolen "olennaisesti huonompaan asemaan", on mitätön. Käytännön riski: toimittaja kävelee pois projektin keskellä, sinä maksat silti.

**2. Liian laaja IP-oikeuksien luovutus (§11.1)**
Lauseke siirtää toimittajalle "kaikki palveluiden yhteydessä syntyvät immateriaalioikeudet". Tämä imee mukanaan SINUN aiemmin olemassa olleen aineiston (brändimateriaalit, sisäiset dokumentit) sillä hetkellä, kun he koskettavat niitä. VÕS § 9 vaatii, että luovutuksen laajuus on määriteltävä tarkasti.

**3. Vastausaikoja koskeva SLA puuttuu (§4)**
"Kohtuulliset ponnistelut" — määrittelemättä. Jos he eivät vastaa 6 viikkoon, sinulla ei ole sopimuksellista vipua. Markkinastandardi on 1 työpäivän kuittaus ja kriittisten ongelmien ratkaisu 5 päivässä.''',
    ),
    SampleCaseMessage(
      role: 'user',
      content: 'Mistä minun pitäisi neuvotella?',
    ),
    SampleCaseMessage(
      role: 'assistant',
      content: '''Tässä **3 konkreettista vastaehdotusta** tärkeysjärjestyksessä:

**A. Symmetrinen irtisanominen (§7.2)**
> "Kumpi tahansa osapuoli voi irtisanoa tämän sopimuksen ilman syytä kolmenkymmenen (30) päivän kirjallisella varoitusajalla. Toimittaja saattaa loppuun käynnissä olevan työn varoitusajan kuluessa ja luovuttaa työtuloksen."

*Miksi*: Poistaa 90/7 epäsymmetrian ja estää toimittajaa kävelemästä pois ennakkomaksujen kanssa.

**B. Rajattu IP-oikeuksien luovutus (§11.1)**
> "Toimittaja luovuttaa Asiakkaalle kaikki immateriaalioikeudet ainoastaan tämän sopimuksen perusteella Asiakkaalle erikseen luotuihin tuotoksiin. Asiakkaan aiemmin olemassa oleva aineisto pysyy Asiakkaan yksinomaisena omaisuutena ja lisensoidaan Toimittajalle vain sopimuksen suoritusajaksi."

*Miksi*: Vastaa VÕS § 9 määriteltävyysvaatimusta ja suojaa aiempaa työtäsi.

**C. Konkreettinen SLA (§4)**
> "Toimittaja kuittaa tukipyynnöt yhden (1) työpäivän kuluessa ja ratkaisee P1-ongelmat neljänkymmenenkahdeksan (48) tunnin sisällä, P2 viiden (5) työpäivän sisällä. Jos SLA jää saavuttamatta jonain kuukautena, Asiakkaalla on oikeus 10 %:n palveluhyvitykseen."

*Miksi*: Luo mitattavan oikeussuojakeinon eikä "kohtuullisten ponnistelujen" teatteria.

Haluatko, että laadin koko sopimuksen muutosehdotukset tai vastaehdotuksen sähköpostin toimittajalle?''',
    ),
  ];

  // ---------------------------------------------------------------------
  // RU
  // ---------------------------------------------------------------------
  static const List<SampleCaseMessage> _ru = [
    SampleCaseMessage(
      role: 'user',
      content:
          'Подписываю договор оказания услуг с подрядчиком. Можете найти риски?',
    ),
    SampleCaseMessage(
      role: 'assistant',
      content: '''Я разобрал черновик и нашёл **3 существенных риска**:

**1. Односторонний выход (§7.2)**
Подрядчик может расторгнуть договор «по любой причине» с уведомлением за 7 дней, а с вас требуется 90 дней. Такая асимметрия ничтожна по Закону об обязательственном праве Эстонии (VÕS) § 42 — условие, ставящее одну сторону в «существенно худшее положение», недействительно. Практический риск: подрядчик уходит в середине проекта, а вы продолжаете платить.

**2. Чрезмерно широкая передача ИС (§11.1)**
Пункт передаёт подрядчику «все права интеллектуальной собственности, возникающие в связи с услугами». Это захватывает ВАШИ существующие активы (бренд-материалы, внутренние документы) в момент, когда подрядчик их касается. VÕS § 9 требует конкретно определять объём передачи.

**3. Нет SLA на время реакции (§4)**
«Разумные усилия» — без определения. Если они пропадут на 6 недель, у вас нет договорного рычага. Стандарт рынка — подтверждение в течение 1 рабочего дня, решение некритичных вопросов за 5 дней.''',
    ),
    SampleCaseMessage(
      role: 'user',
      content: 'Что мне обсуждать на переговорах?',
    ),
    SampleCaseMessage(
      role: 'assistant',
      content: '''Вот **3 конкретных контр-предложения** в порядке приоритета:

**A. Симметричный выход (§7.2)**
> «Любая из сторон вправе расторгнуть настоящий договор без указания причины с письменным уведомлением за тридцать (30) дней. Подрядчик завершает все работы, находящиеся в исполнении, в течение периода уведомления и передаёт результат работ.»

*Почему*: Убирает асимметрию 90/7 и не даёт подрядчику уйти с предоплатами.

**B. Ограниченная передача ИС (§11.1)**
> «Подрядчик передаёт Заказчику все права интеллектуальной собственности на результаты работ, созданные специально для Заказчика по настоящему договору. Ранее существовавшие материалы Заказчика остаются его исключительной собственностью и лицензируются Подрядчику только на срок исполнения договора.»

*Почему*: Соответствует требованию конкретности по VÕS § 9 и защищает ваш ранний труд.

**C. Конкретный SLA (§4)**
> «Подрядчик подтверждает получение обращений в техподдержку в течение одного (1) рабочего дня и устраняет проблемы уровня P1 в течение сорока восьми (48) часов, P2 — в течение пяти (5) рабочих дней. Невыполнение SLA в любом месяце даёт Заказчику право на сервисный кредит в размере 10%.»

*Почему*: Создаёт измеримое средство правовой защиты, а не театр «разумных усилий».

Хотите, чтобы я составил полную редактуру договора или письмо-контр-предложение подрядчику?''',
    ),
  ];
}
