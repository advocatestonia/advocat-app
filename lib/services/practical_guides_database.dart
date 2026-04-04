// practical_guides_database.dart
// Ultra-practical step-by-step guides for common immigration situations in the EU
// Written for people who are stressed, scared, and need clear actionable steps

class PracticalGuide {
  final String id;
  final String title;
  final String urgencyLevel; // 'emergency', 'urgent', 'important', 'planning'
  final List<String> steps;
  final List<String> doNots;
  final List<String> documentsNeeded;
  final String typicalTimeline;
  final String costEstimate;
  final String legalBasis;

  const PracticalGuide({
    required this.id,
    required this.title,
    required this.urgencyLevel,
    required this.steps,
    required this.doNots,
    required this.documentsNeeded,
    required this.typicalTimeline,
    required this.costEstimate,
    required this.legalBasis,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'urgencyLevel': urgencyLevel,
      'steps': steps,
      'doNots': doNots,
      'documentsNeeded': documentsNeeded,
      'typicalTimeline': typicalTimeline,
      'costEstimate': costEstimate,
      'legalBasis': legalBasis,
    };
  }

  factory PracticalGuide.fromMap(Map<String, dynamic> map) {
    return PracticalGuide(
      id: map['id'] as String,
      title: map['title'] as String,
      urgencyLevel: map['urgencyLevel'] as String,
      steps: List<String>.from(map['steps']),
      doNots: List<String>.from(map['doNots']),
      documentsNeeded: List<String>.from(map['documentsNeeded']),
      typicalTimeline: map['typicalTimeline'] as String,
      costEstimate: map['costEstimate'] as String,
      legalBasis: map['legalBasis'] as String,
    );
  }
}

class PracticalGuidesDatabase {
  static const List<PracticalGuide> allGuides = [
    // =========================================================================
    // GUIDE 1: DEPORTATION ORDER
    // =========================================================================
    PracticalGuide(
      id: 'deportation_order',
      title: 'I received a deportation order -- what do I do?',
      urgencyLevel: 'emergency',
      steps: [
        'STEP 1: STAY CALM AND READ THE ENTIRE DOCUMENT. '
            'The deportation order is a legal paper -- it does not mean police will come tonight. '
            'You have rights and time to act. Read every word, especially the dates and deadlines.',
        'STEP 2: FIND THE APPEAL DEADLINE. '
            'Look for a line that says "you have X days to appeal" or "deadline for appeal." '
            'In most EU countries this is 14-30 days from the date you received the order. '
            'Write this date down immediately. This is your most important deadline.',
        'STEP 3: DO NOT LEAVE THE COUNTRY YET. '
            'Filing an appeal usually stops (suspends) the deportation while the court decides. '
            'But you must file BEFORE the deadline. Do not board any plane or bus out of the country.',
        'STEP 4: CONTACT A FREE LEGAL AID ORGANIZATION TODAY. '
            'Every EU country must provide free legal help to people facing deportation. '
            'Search for "[your country] free immigration lawyer" or call the national legal aid hotline. '
            'In Finland: call Legal Aid Office (Oikeusaputoimisto) at 0295 435 335. '
            'In Germany: contact local Fluechtlingsrat. In Sweden: Migrationsverket provides a public counsel.',
        'STEP 5: IF YOU CANNOT FIND A LAWYER WITHIN 48 HOURS, GO TO COURT YOURSELF. '
            'You can file the appeal yourself at the Administrative Court. '
            'Write a simple letter: "I appeal the deportation decision [number] dated [date]. '
            'I request that the deportation is suspended while the appeal is processed. '
            'My reasons: [list your reasons -- family ties, health, danger in home country, etc.]"',
        'STEP 6: GATHER YOUR EVIDENCE. '
            'Collect everything that shows why you should stay: '
            'employment contracts, school enrollment for children, medical records, '
            'evidence of danger in your home country (news articles, reports from UNHCR), '
            'letters from friends/family/community in this country, proof of integration.',
        'STEP 7: CHECK IF YOU HAVE PROTECTED STATUS. '
            'You CANNOT be deported if: you are under 18 and unaccompanied, '
            'you are pregnant or recently gave birth, you have a serious medical condition '
            'that cannot be treated in your home country, you face torture or death in your home country, '
            'you are a victim of trafficking, your children are EU citizens or legal residents.',
        'STEP 8: REGISTER YOUR CURRENT ADDRESS WITH AUTHORITIES. '
            'If you are required to report to police or immigration office, DO IT. '
            'Missing a reporting date can be used against you in court and may lead to detention.',
        'STEP 9: CONTACT YOUR HOME COUNTRY EMBASSY -- BUT BE CAREFUL. '
            'If you are fleeing persecution by your government, do NOT contact your embassy. '
            'If your case is not about government persecution, the embassy may help with documents.',
        'STEP 10: CONTACT SUPPORT ORGANIZATIONS. '
            'NGOs like Red Cross, Caritas, local refugee councils can provide practical help: '
            'food, shelter, translation, emotional support. You do not have to face this alone.',
        'STEP 11: PREPARE FOR THE COURT HEARING. '
            'If you get a hearing date, attend in clean clothes, be polite, bring all documents, '
            'bring a translator if needed (ask the court to provide one for free).',
        'STEP 12: IF YOUR APPEAL IS REJECTED, YOU MAY HAVE A SECOND APPEAL. '
            'Ask your lawyer about appealing to a higher court. '
            'In some countries you can also apply to the European Court of Human Rights (ECHR) '
            'if your life or safety is at risk.',
        'STEP 13: KNOW YOUR RIGHTS DURING REMOVAL. '
            'If deportation proceeds: you have the right to pack your belongings, '
            'contact your lawyer, say goodbye to family, and you must not be subjected to violence. '
            'Officers must show you identification and a valid removal order.',
      ],
      doNots: [
        'DO NOT ignore the deportation order -- ignoring it does not make it go away and you lose your right to appeal.',
        'DO NOT leave the country before filing an appeal -- once you leave, you usually cannot come back.',
        'DO NOT sign any document you do not understand -- ask for a translation first.',
        'DO NOT resist physically if police come -- it can lead to criminal charges and hurt your case.',
        'DO NOT pay anyone who promises to "fix" your case for cash -- this is likely a scam.',
        'DO NOT hide or go underground -- this makes everything worse if you are found.',
        'DO NOT destroy your identity documents -- courts see this negatively.',
        'DO NOT post about your case on social media -- anything you say can be used against you.',
      ],
      documentsNeeded: [
        'The deportation order itself (keep the original safe, make 3 copies)',
        'Your passport or any identity document',
        'Your residence permit (even if expired)',
        'Any previous decisions from immigration authorities',
        'Employment contract or pay slips',
        'School enrollment papers for children',
        'Medical records (especially for serious conditions)',
        'Evidence of danger in home country (news, reports, personal testimony)',
        'Proof of family ties in this country (marriage certificate, birth certificates)',
        'Letters of support from employer, school, community, religious leaders',
        'Proof of address (rental contract, utility bills)',
        'Any correspondence with immigration authorities',
      ],
      typicalTimeline:
          'Appeal deadline: 14-30 days from receiving the order. '
          'Court decision on suspension: 1-7 days (urgent). '
          'Full appeal hearing: 1-6 months. '
          'Higher court appeal: 3-12 months. '
          'Total process if you fight: 6-18 months.',
      costEstimate:
          'Legal aid is FREE in all EU countries for deportation cases. '
          'If you hire a private lawyer: 500-3000 EUR depending on the country. '
          'Court fees: usually waived for deportation appeals. '
          'Translation of documents: 20-50 EUR per page (may be covered by legal aid).',
      legalBasis:
          'EU Return Directive 2008/115/EC (right to appeal, voluntary departure period). '
          'EU Charter of Fundamental Rights, Article 19 (protection from removal to danger). '
          'European Convention on Human Rights, Article 3 (prohibition of torture) and Article 8 (right to family life). '
          'Each EU country has national implementation laws.',
    ),

    // =========================================================================
    // GUIDE 2: ASYLUM REJECTION APPEAL
    // =========================================================================
    PracticalGuide(
      id: 'asylum_rejection_appeal',
      title: 'My asylum application was rejected -- how to appeal?',
      urgencyLevel: 'emergency',
      steps: [
        'STEP 1: READ THE REJECTION LETTER CAREFULLY. '
            'Find two critical pieces of information: (a) the REASON they rejected you, '
            'and (b) the DEADLINE to appeal. The deadline is usually 14-30 days. '
            'In Finland it is 30 days. In Germany it is 1-2 weeks depending on the type of rejection.',
        'STEP 2: UNDERSTAND THE TYPE OF REJECTION. '
            '"Clearly unfounded" or "manifestly unfounded" = shorter deadline (often 7 days), '
            'appeal may NOT automatically stop deportation. '
            '"Regular rejection" = longer deadline (14-30 days), appeal usually stops deportation.',
        'STEP 3: CONTACT YOUR ASSIGNED LAWYER IMMEDIATELY. '
            'If you had a lawyer during the asylum process, call them TODAY. '
            'If you do not have a lawyer, contact: Legal Aid Office, UNHCR, Red Cross, '
            'or a local refugee support organization. They can assign you a free lawyer.',
        'STEP 4: FILE THE APPEAL EVEN IF YOU DO NOT HAVE A LAWYER YET. '
            'If the deadline is close and you have no lawyer, file the appeal yourself. '
            'Write to the court: "I appeal decision [number] dated [date] by [authority]. '
            'I request suspension of any removal. I will submit detailed grounds with my lawyer. '
            'Name, date, signature." Send this by registered mail or deliver it in person.',
        'STEP 5: REQUEST SUSPENSION OF DEPORTATION. '
            'In your appeal, always write: "I request that any removal be suspended pending the outcome '
            'of this appeal, as removal would cause irreparable harm." '
            'If your case is "manifestly unfounded," you may need to file a separate urgent request.',
        'STEP 6: IDENTIFY WHAT WENT WRONG WITH YOUR FIRST APPLICATION. '
            'Common reasons for rejection: credibility issues (authorities did not believe your story), '
            'safe country of origin, internal relocation possible, insufficient evidence of persecution. '
            'Your appeal must directly address the reason they gave for rejecting you.',
        'STEP 7: GATHER NEW EVIDENCE. '
            'The appeal is your chance to present new or better evidence: '
            'updated country reports (from UNHCR, Amnesty International, Human Rights Watch), '
            'medical reports documenting trauma or torture (ask a doctor for a medico-legal report), '
            'witness statements, news articles about the specific danger you face, '
            'social media evidence of threats, expert opinions.',
        'STEP 8: GET A MEDICAL/PSYCHOLOGICAL REPORT IF RELEVANT. '
            'If you suffered torture, violence, or trauma, a medical report documenting scars, '
            'PTSD, or other conditions strongly supports your case. '
            'Many EU countries have free medico-legal examination services for asylum seekers.',
        'STEP 9: PREPARE YOUR PERSONAL STATEMENT. '
            'Write a clear, detailed account of why you fled. Be specific: names, dates, places, '
            'what happened, who did it, why you were targeted. If you left out details before '
            'because you were scared or traumatized, explain why. Courts understand trauma affects memory.',
        'STEP 10: ATTEND THE APPEAL HEARING. '
            'Dress respectfully, arrive early, bring all originals of your documents. '
            'The court must provide a free interpreter. '
            'Answer questions honestly and directly. If you do not understand, say so. '
            'If you do not remember, say "I do not remember" -- do not guess.',
        'STEP 11: IF THE FIRST APPEAL FAILS, CHECK FOR FURTHER APPEALS. '
            'Many countries allow a second appeal to a higher court. '
            'Your lawyer can advise whether you have grounds for a higher appeal.',
        'STEP 12: CONSIDER SUBSIDIARY PROTECTION OR HUMANITARIAN STATUS. '
            'Even if you do not qualify for refugee status, you may qualify for: '
            'subsidiary protection (serious harm in home country), '
            'humanitarian protection (health reasons, family ties), '
            'or tolerated stay (temporary protection from removal).',
        'STEP 13: IF ALL APPEALS FAIL, EXPLORE OTHER OPTIONS. '
            'Talk to your lawyer about: a new asylum application if circumstances changed, '
            'residence permit on other grounds (work, family, study), '
            'voluntary return programs (which include financial support and reintegration help).',
        'STEP 14: KEEP YOUR CONTACT INFORMATION UPDATED. '
            'Always tell the court and immigration authorities your current address. '
            'If they send a letter and it comes back undelivered, you can lose your case by default.',
      ],
      doNots: [
        'DO NOT miss the appeal deadline -- even one day late means you lose your right to appeal.',
        'DO NOT wait for a lawyer before filing -- file a basic appeal yourself to meet the deadline.',
        'DO NOT change your story -- if details differ from your first interview, authorities will say you are lying.',
        'DO NOT provide false documents -- if caught, it destroys your credibility permanently.',
        'DO NOT skip the hearing -- the court may decide without you and it will be a rejection.',
        'DO NOT contact your home country embassy if you are fleeing government persecution.',
        'DO NOT refuse to cooperate with your lawyer -- they need the full truth to help you.',
        'DO NOT go underground if the appeal fails -- it eliminates future legal options.',
      ],
      documentsNeeded: [
        'The rejection decision (original + 3 copies)',
        'Your asylum application and interview transcript',
        'Your identity documents or explanation of why you have none',
        'Country of origin information (UNHCR reports, Amnesty International, news articles)',
        'Medical or psychological reports',
        'Witness statements from people who can confirm your story',
        'Photographs, screenshots, or other evidence of persecution/threats',
        'Police reports from your home country (if available and safe to obtain)',
        'Letters from human rights organizations about your specific situation',
        'Proof of your current situation in the EU (integration, language courses, employment)',
      ],
      typicalTimeline:
          'Appeal deadline: 7-30 days from rejection (check your specific country). '
          'Court hearing: 1-6 months after filing appeal. '
          'Court decision: immediately to 3 months after hearing. '
          'Higher court appeal: additional 3-12 months. '
          'Total: 6-24 months from rejection to final decision.',
      costEstimate:
          'Free legal aid is available in all EU countries for asylum appeals. '
          'Court fees: usually free or waived for asylum seekers. '
          'Medical report: free through specialized NGOs or 100-500 EUR privately. '
          'Translation: may be covered by legal aid. '
          'Total out-of-pocket if using only free services: 0 EUR.',
      legalBasis:
          'EU Asylum Procedures Directive 2013/32/EU (right to effective remedy, Article 46). '
          'EU Qualification Directive 2011/95/EU (refugee status and subsidiary protection). '
          'Geneva Convention 1951 (definition of refugee, non-refoulement). '
          'EU Charter of Fundamental Rights, Article 18 (right to asylum). '
          'ECHR Article 3 (prohibition of torture) and Article 13 (right to effective remedy).',
    ),

    // =========================================================================
    // GUIDE 3: EMPLOYER NOT PAYING WAGES
    // =========================================================================
    PracticalGuide(
      id: 'unpaid_wages',
      title: 'My employer is not paying my wages',
      urgencyLevel: 'urgent',
      steps: [
        'STEP 1: DOCUMENT EVERYTHING STARTING TODAY. '
            'Write down: all days and hours you worked, what work you did, '
            'what you were promised (hourly rate or monthly salary), '
            'when you were supposed to be paid, how much is owed. '
            'Keep a notebook or use your phone to take notes every day.',
        'STEP 2: SAVE ALL EVIDENCE YOU ALREADY HAVE. '
            'Screenshot or save: text messages, WhatsApp chats, emails with your employer, '
            'your work schedule, photos of you at the workplace, '
            'any written or verbal agreements about pay. '
            'If you have a written contract, make copies and keep the original safe.',
        'STEP 3: SEND A WRITTEN PAYMENT DEMAND TO YOUR EMPLOYER. '
            'Send an email or letter (keep a copy) saying: "I am writing to request payment of '
            'my wages for the period [dates]. I worked [hours] and I am owed [amount]. '
            'Please pay by [date, give them 7-14 days]. If I do not receive payment, '
            'I will contact the labor authorities." This creates a paper trail.',
        'STEP 4: YOUR IMMIGRATION STATUS DOES NOT MATTER FOR WAGE CLAIMS. '
            'Even if you are undocumented or your work permit does not cover this job, '
            'you are STILL legally entitled to be paid for work you already did. '
            'EU law protects all workers regardless of immigration status for unpaid wages.',
        'STEP 5: CONTACT THE LABOR INSPECTORATE / WORK AUTHORITY. '
            'Every EU country has a government office that handles wage complaints: '
            'Finland: AVI (Regional State Administrative Agency) or occupational safety. '
            'Germany: Zoll (customs) for minimum wage violations. '
            'Sweden: Arbetsmiljoverket. '
            'File a complaint -- it is free and they can order your employer to pay.',
        'STEP 6: CONTACT A TRADE UNION. '
            'Even if you are not a member, many unions help non-members with wage theft. '
            'They can negotiate with your employer, provide legal advice, '
            'and represent you at no cost or low cost.',
        'STEP 7: SEEK FREE LEGAL AID. '
            'Apply for free legal aid through your national legal aid system. '
            'Also contact workers rights NGOs -- many EU countries have organizations '
            'specifically helping migrant workers with unpaid wages.',
        'STEP 8: CALCULATE EXACTLY WHAT YOU ARE OWED. '
            'Include: basic wages, overtime pay, holiday pay (you are entitled to this even if not taken), '
            'penalty interest for late payment (in Finland: 7% + European Central Bank reference rate). '
            'Your lawyer or union can help calculate the total.',
        'STEP 9: FILE A CLAIM WITH THE COURT IF NEEDED. '
            'If the employer refuses to pay after your demand and the labor authority complaint, '
            'you can file a civil claim in court. For small amounts, there is usually a simplified process. '
            'In Finland: District Court (karajaoikeus). Many countries waive court fees for low-income workers.',
        'STEP 10: CHECK IF THIS IS LABOR EXPLOITATION OR TRAFFICKING. '
            'Warning signs: employer controls where you live, took your passport, '
            'threatens you with deportation, forces excessive hours, pays far below minimum wage, '
            'physical threats or violence. If YES -- this may be trafficking or forced labor.',
        'STEP 11: IF THIS IS TRAFFICKING OR SEVERE EXPLOITATION, CONTACT POLICE OR A HELPLINE. '
            'You are a VICTIM, not a criminal. EU law protects trafficking victims '
            'and can grant you a residence permit. Contact: national anti-trafficking helpline, '
            'police (ask specifically for the trafficking unit), or an NGO that helps trafficking victims.',
        'STEP 12: REPORT THE EMPLOYER TO TAX AUTHORITIES. '
            'If the employer was paying you "under the table" (no taxes, no official contract), '
            'reporting them to tax authorities creates additional pressure. '
            'You will not be punished for this -- the employer broke the law, not you.',
        'STEP 13: PROTECT YOURSELF FROM RETALIATION. '
            'If you are still working there: document any threats, changes in hours, or punishment '
            'for asking about wages. Retaliation against a worker who claims wages is illegal. '
            'If you feel unsafe, stop going to work and seek help from a union or NGO.',
      ],
      doNots: [
        'DO NOT continue working without documenting hours -- you need proof later.',
        'DO NOT accept "I will pay you later" without getting it in writing.',
        'DO NOT threaten your employer with violence -- it gives them a weapon against you.',
        'DO NOT believe "you will be deported if you complain" -- wage claims are protected.',
        'DO NOT give back any documents your employer gives you (pay slips, contracts, etc.).',
        'DO NOT sign anything that says you received money you did not actually receive.',
        'DO NOT quit without first getting legal advice -- quitting may affect your claims.',
        'DO NOT delete text messages or chats with your employer -- they are evidence.',
      ],
      documentsNeeded: [
        'Employment contract (written or any evidence of verbal agreement)',
        'Record of hours worked (your notes, time sheets, photos of schedule)',
        'Pay slips or bank statements showing previous payments',
        'Text messages, emails, WhatsApp chats with employer about work/pay',
        'Photos of the workplace, your work, or work schedule',
        'Names and contact information of coworkers who can confirm you worked there',
        'Your written payment demand letter and proof it was sent',
        'Any responses from the employer',
        'Your bank account details (for where wages should be paid)',
        'Your identity document and work permit (if applicable)',
      ],
      typicalTimeline:
          'Written demand to employer: allow 7-14 days for response. '
          'Labor inspectorate complaint: investigation takes 1-3 months. '
          'Trade union negotiation: 2-8 weeks. '
          'Court claim (if needed): 3-12 months for a decision. '
          'Enforcement of court decision: 1-3 months additional.',
      costEstimate:
          'Labor inspectorate complaint: FREE. '
          'Trade union help: FREE for members; many help non-members for free too. '
          'Legal aid: FREE if you qualify (most low-income workers do). '
          'Court fees: 0-250 EUR (often waived for low-income). '
          'Private lawyer if needed: 150-300 EUR/hour. '
          'Penalty interest: your employer pays this ON TOP of wages owed.',
      legalBasis:
          'EU Employers Sanctions Directive 2009/52/EC (right to back pay regardless of immigration status). '
          'EU Working Time Directive 2003/88/EC. '
          'EU Anti-Trafficking Directive 2011/36/EU (if exploitation is severe). '
          'Each country has national labor laws and minimum wage regulations. '
          'Finland: Employment Contracts Act (Tyosopimuslaki) and Working Hours Act (Tyoaikalaki).',
    ),

    // =========================================================================
    // GUIDE 4: ILLEGAL EVICTION
    // =========================================================================
    PracticalGuide(
      id: 'illegal_eviction',
      title: 'My landlord is evicting me illegally',
      urgencyLevel: 'urgent',
      steps: [
        'STEP 1: KNOW YOUR RIGHTS -- A LANDLORD CANNOT JUST THROW YOU OUT. '
            'In every EU country, eviction requires a COURT ORDER. Your landlord cannot: '
            'change the locks, remove your belongings, cut off electricity/water/heating, '
            'physically force you to leave, or threaten you to leave. '
            'All of these are ILLEGAL, even if you owe rent.',
        'STEP 2: DO NOT LEAVE VOLUNTARILY UNDER PRESSURE. '
            'If you leave because the landlord pressured you, it is very hard to get your home back. '
            'Stay in the apartment. If the landlord threatens you, call the police.',
        'STEP 3: CALL THE POLICE IF THE LANDLORD TRIES FORCED EVICTION. '
            'If the landlord changes locks, removes your things, or threatens you, call 112. '
            'Tell police: "My landlord is illegally evicting me without a court order." '
            'Police must protect you -- illegal eviction is a crime in most EU countries.',
        'STEP 4: DOCUMENT EVERYTHING. '
            'Photograph or video: changed locks, removed belongings, cut utilities. '
            'Save all messages and calls from the landlord. '
            'Write down dates, times, and what the landlord said or did. '
            'Get witness names and contact details (neighbors, friends who saw what happened).',
        'STEP 5: CHECK IF THE EVICTION NOTICE IS VALID. '
            'A valid eviction requires: proper written notice with the correct notice period '
            '(usually 1-6 months depending on the country and reason), '
            'a valid legal reason (non-payment of rent, end of fixed-term lease, landlord needs the property), '
            'and eventually a court order if you do not leave voluntarily.',
        'STEP 6: RESPOND TO ANY EVICTION NOTICE IN WRITING. '
            'If you received a written eviction notice, respond in writing within 7 days. '
            'State: "I dispute this eviction because [reason]. I intend to remain in the property. '
            'If you pursue eviction, I request proper legal proceedings."',
        'STEP 7: CONTACT A FREE LEGAL AID OR TENANT RIGHTS ORGANIZATION. '
            'Most EU countries have free tenant advice services: '
            'Finland: tenant associations (Vuokralaiset ry), legal aid offices. '
            'Germany: Mieterverein (tenants association). '
            'Many cities have free housing advice clinics.',
        'STEP 8: IF YOU OWE RENT, TRY TO PAY OR NEGOTIATE. '
            'If the eviction is about unpaid rent, paying the rent (even late) can stop the eviction '
            'in many countries. Contact social services -- they may help pay rent arrears '
            'to prevent homelessness. Ask about emergency housing allowance.',
        'STEP 9: APPLY FOR SOCIAL SERVICES HELP. '
            'Contact your local social services (sosiaalitoimisto in Finland). '
            'They can: help pay rent arrears, provide emergency housing, '
            'connect you with housing support services. '
            'Mention that you face homelessness -- this is treated as an emergency.',
        'STEP 10: PREPARE FOR A COURT HEARING IF IT GOES THAT FAR. '
            'If the landlord files for eviction in court, you will receive a court notice. '
            'ATTEND THE HEARING. Bring: your rental contract, proof of rent payments, '
            'evidence of illegal landlord behavior, any correspondence.',
        'STEP 11: KNOW YOUR SPECIAL PROTECTIONS. '
            'You may have extra protection if: you have children, you are pregnant, '
            'you are elderly or disabled, it is winter (some countries ban evictions in winter), '
            'you are a victim of domestic violence. Tell your lawyer about your circumstances.',
        'STEP 12: IF EVICTION IS ORDERED BY THE COURT, KNOW YOUR TIMELINE. '
            'Even after a court order, you usually have time to find new housing '
            '(execution period is typically 1-4 weeks). '
            'Ask the court for an extension if you need more time. '
            'Contact social services for emergency housing.',
      ],
      doNots: [
        'DO NOT leave the apartment voluntarily under threats -- once you leave, it is hard to get back in.',
        'DO NOT stop paying rent as "revenge" -- this gives the landlord a legal reason to evict you.',
        'DO NOT damage the apartment -- this is a crime and hurts your case.',
        'DO NOT sign any agreement to leave without getting legal advice first.',
        'DO NOT ignore court letters -- if you do not respond, the court will decide without you.',
        'DO NOT change locks yourself -- this can be used against you.',
        'DO NOT threaten or harass the landlord -- keep all interactions calm and documented.',
        'DO NOT throw away any paperwork from the landlord, even if it seems unfair.',
      ],
      documentsNeeded: [
        'Your rental contract or lease agreement',
        'Proof of rent payments (bank statements, receipts)',
        'The eviction notice you received',
        'All correspondence with the landlord (letters, texts, emails)',
        'Photos or videos of any illegal landlord actions',
        'Witness contact details',
        'Proof of your current circumstances (family, health, employment)',
        'Any previous complaints about the apartment (repairs, conditions)',
        'Your registration at this address',
        'Police reports (if you called police about threats/illegal eviction)',
      ],
      typicalTimeline:
          'Notice period (valid eviction): 1-6 months depending on country and reason. '
          'Court eviction process: 1-6 months from filing. '
          'Execution after court order: 1-4 weeks. '
          'If landlord acted illegally, you can get back in within days through police/court.',
      costEstimate:
          'Legal aid: FREE for low-income tenants. '
          'Tenant association membership: 30-100 EUR/year (gives access to legal help). '
          'Court fees: 0-300 EUR (often waived). '
          'Social services assistance for rent arrears: FREE (grant, not loan in most cases). '
          'Emergency housing through social services: FREE.',
      legalBasis:
          'EU Charter of Fundamental Rights, Article 7 (respect for private and family life/home). '
          'Each EU country has detailed tenant protection laws. '
          'Finland: Act on Residential Leases (Laki asuinhuoneiston vuokrauksesta 481/1995). '
          'Illegal eviction is a criminal offense in most EU countries. '
          'Social services have a duty to prevent homelessness under national social welfare acts.',
    ),

    // =========================================================================
    // GUIDE 5: VICTIM OF CRIME IN A FOREIGN COUNTRY
    // =========================================================================
    PracticalGuide(
      id: 'crime_victim_abroad',
      title: 'I was a victim of a crime in a foreign country',
      urgencyLevel: 'emergency',
      steps: [
        'STEP 1: GET TO SAFETY FIRST. '
            'If you are in immediate danger, call the emergency number: 112 works in ALL EU countries. '
            'Move to a safe public place, a hospital, or a police station.',
        'STEP 2: SEEK MEDICAL ATTENTION. '
            'Go to a hospital or emergency room. In the EU, emergency medical care must be provided '
            'regardless of your insurance status, immigration status, or ability to pay. '
            'Ask the doctor to document ALL injuries in writing -- this is critical evidence.',
        'STEP 3: REPORT THE CRIME TO POLICE. '
            'Go to the nearest police station and file a report (a "complaint" or "declaration"). '
            'You have the right to an interpreter -- ask for one in your language. '
            'You have the right to receive a written confirmation of your report. '
            'Keep this confirmation -- you will need it for everything else.',
        'STEP 4: YOUR IMMIGRATION STATUS DOES NOT MATTER -- YOU ARE A VICTIM. '
            'Police must take your report regardless of your immigration status. '
            'If you are undocumented, you are still a crime victim with full rights. '
            'Under EU law, reporting a crime should not trigger deportation proceedings.',
        'STEP 5: ASK FOR VICTIM SUPPORT SERVICES. '
            'Every EU country must have victim support services (EU Victims Directive). '
            'Police should refer you, or search for "[country] victim support." '
            'These services are FREE and provide: emotional support, legal advice, '
            'help navigating the system, translation.',
        'STEP 6: PRESERVE ALL EVIDENCE. '
            'Keep: medical reports, photos of injuries, torn clothing (in a sealed bag), '
            'names and contacts of any witnesses, screenshots of threats or harassment, '
            'the police report number. Do not wash clothing or clean wounds before medical examination '
            'if this is a sexual assault -- evidence can be collected.',
        'STEP 7: CONTACT YOUR COUNTRY\'S EMBASSY OR CONSULATE. '
            'They can help with: emergency travel documents, contacting your family, '
            'finding a local lawyer, translation, emergency financial assistance. '
            'Call them or visit in person.',
        'STEP 8: APPLY FOR VICTIM COMPENSATION. '
            'EU countries have crime victim compensation funds that pay for: '
            'medical expenses, lost wages, pain and suffering, funeral costs. '
            'You can apply even if the criminal is not caught. '
            'Ask victim support services to help you apply.',
        'STEP 9: GET LEGAL REPRESENTATION. '
            'As a crime victim, you have the right to a lawyer. '
            'In many EU countries, legal aid is free for crime victims. '
            'Your lawyer can help you: participate in the criminal case, '
            'file a civil claim for damages, apply for compensation.',
        'STEP 10: IF YOU ARE A VICTIM OF TRAFFICKING, DOMESTIC VIOLENCE, OR HATE CRIME -- SPECIAL PROTECTIONS APPLY. '
            'You may be entitled to: a residence permit as a victim, '
            'special protection measures, shelter/safe housing, '
            'reflection period before deciding whether to cooperate with police.',
        'STEP 11: UNDERSTAND YOUR RIGHTS IN THE CRIMINAL PROCESS. '
            'Under the EU Victims Directive you have the right to: '
            'receive information about your case, be heard in proceedings, '
            'request protection from the offender, receive interpretation for free, '
            'have your privacy protected.',
        'STEP 12: TAKE CARE OF YOUR MENTAL HEALTH. '
            'Being a crime victim is traumatic. Victim support services can connect you with '
            'a psychologist or counselor. Many offer this for free. '
            'It is normal to feel scared, angry, or unable to sleep. Ask for help.',
        'STEP 13: IF YOU NEED TO RETURN HOME, COORDINATE WITH AUTHORITIES. '
            'If you want to leave the country, make sure: your police report is filed, '
            'you have copies of all documents, victim support knows how to contact you, '
            'you understand how to participate in the case from abroad.',
      ],
      doNots: [
        'DO NOT delay reporting to police -- evidence can be lost and some deadlines are short.',
        'DO NOT wash clothing or clean up before a medical/forensic examination (especially for assault/sexual crimes).',
        'DO NOT confront the attacker yourself -- let the police handle it.',
        'DO NOT accept money from the offender in exchange for dropping the complaint without legal advice.',
        'DO NOT believe anyone who says "police will deport you if you report" -- you have rights as a victim.',
        'DO NOT delete messages, photos, or other digital evidence.',
        'DO NOT blame yourself -- you are the victim and you deserve help.',
        'DO NOT sign statements in a language you do not understand -- insist on a translator.',
      ],
      documentsNeeded: [
        'Police report number and written confirmation',
        'Medical reports documenting injuries',
        'Photos of injuries (taken at the hospital and after)',
        'Witness names and contact details',
        'Your identity document or passport',
        'Insurance card (if you have insurance)',
        'Contact information for your embassy/consulate',
        'Any evidence: photos, videos, screenshots of threats',
        'List of stolen or damaged property (with values)',
        'Receipts for expenses caused by the crime',
      ],
      typicalTimeline:
          'Police report: file immediately or within days. '
          'Medical examination: immediately after the crime. '
          'Victim compensation application: varies by country (up to 1-3 years after the crime). '
          'Criminal investigation: 1-12 months. '
          'Criminal trial: 3-18 months. '
          'Compensation payment: 1-6 months after decision.',
      costEstimate:
          'Filing a police report: FREE. '
          'Emergency medical care: FREE in all EU countries (may need to claim back later). '
          'Victim support services: FREE. '
          'Legal aid for crime victims: usually FREE. '
          'Victim compensation: can cover medical bills, lost wages, pain and suffering. '
          'Embassy help: mostly FREE for emergency consular assistance.',
      legalBasis:
          'EU Victims Directive 2012/29/EU (minimum rights for crime victims). '
          'EU Compensation Directive 2004/80/EC (right to compensation in cross-border cases). '
          'EU Anti-Trafficking Directive 2011/36/EU (for trafficking victims). '
          'ECHR Article 3 (state duty to investigate ill-treatment). '
          'Vienna Convention on Consular Relations (embassy assistance).',
    ),

    // =========================================================================
    // GUIDE 6: FAMILY REUNIFICATION
    // =========================================================================
    PracticalGuide(
      id: 'family_reunification',
      title: 'I need to apply for family reunification',
      urgencyLevel: 'important',
      steps: [
        'STEP 1: CHECK IF YOU ARE ELIGIBLE TO BE A "SPONSOR." '
            'To bring family members to join you, you usually need: '
            'a valid residence permit (not a tourist visa), '
            'sufficient income to support your family, '
            'adequate housing. Some permits do not allow family reunification -- check yours.',
        'STEP 2: UNDERSTAND WHO COUNTS AS "FAMILY." '
            'Generally eligible: your spouse or registered partner, '
            'your minor children (under 18), '
            'in some countries: your parents (if you are a minor), '
            'dependent adult children (with disability). '
            'Unmarried partners may qualify in some countries. Check your specific country.',
        'STEP 3: CHECK INCOME REQUIREMENTS. '
            'Most countries require you to earn enough to support your family without social benefits. '
            'The amount varies by country and family size. '
            'Finland: approximately 1000-1700 EUR/month net depending on family size. '
            'Some refugees are exempt from income requirements -- check if this applies to you.',
        'STEP 4: CHECK TIMING REQUIREMENTS. '
            'Some countries require you to apply within a certain period: '
            'refugees often must apply within 3-6 months of receiving their status '
            'to be exempt from income and housing requirements. '
            'DO NOT MISS THIS DEADLINE -- it is critical.',
        'STEP 5: GATHER DOCUMENTS FOR YOUR FAMILY MEMBERS. '
            'Each family member needs: passport, birth certificate, marriage certificate '
            '(if spouse), photos, medical examination results (some countries), '
            'proof of relationship (DNA test may be requested if documents are unavailable).',
        'STEP 6: GET DOCUMENTS TRANSLATED AND APOSTILLED. '
            'All documents from abroad usually need: official translation into the local language, '
            'apostille or legalization by the issuing country. '
            'Your embassy can help with legalization. Translations cost 20-50 EUR per page.',
        'STEP 7: YOUR FAMILY MEMBERS SUBMIT THE APPLICATION. '
            'In most EU countries, your family members must apply at the embassy or consulate '
            'of the destination country in their home country or country of residence. '
            'Some countries allow you (the sponsor) to submit the application from inside the EU. '
            'Check your country\'s specific process.',
        'STEP 8: PAY THE APPLICATION FEE. '
            'Fees vary: 50-400 EUR per person depending on the country. '
            'Refugees are often exempt from fees. '
            'If you cannot afford the fee, ask about fee waivers.',
        'STEP 9: PREPARE FOR AN INTERVIEW. '
            'Your family members may be interviewed at the embassy. '
            'They should be ready to answer: how you met, when you married, '
            'details about your life together, why they want to come. '
            'Be honest and consistent with what you said in your application.',
        'STEP 10: PREPARE HOUSING. '
            'Most countries require adequate housing before family arrives: '
            'enough rooms for the family size, meets health/safety standards. '
            'Start looking for housing as soon as you apply -- waiting lists can be long.',
        'STEP 11: WAIT FOR THE DECISION AND TRACK YOUR APPLICATION. '
            'Processing times vary enormously: 2-18 months depending on the country. '
            'Finland: 4-12 months. Germany: 3-12 months. '
            'You can usually check the status online or by calling the immigration office.',
        'STEP 12: IF APPROVED, PREPARE FOR ARRIVAL. '
            'Once approved, your family members get a visa to travel. '
            'They must register at the immigration office within a few days of arrival. '
            'Arrange: airport pickup, temporary or permanent housing, '
            'registration with local authorities, school enrollment for children.',
        'STEP 13: IF REJECTED, APPEAL THE DECISION. '
            'You have the right to appeal. Get legal help. '
            'Common reasons for rejection: insufficient income, relationship not proven, '
            'housing inadequate. You can reapply after fixing the problem.',
      ],
      doNots: [
        'DO NOT miss the 3-6 month deadline to apply (if you are a refugee -- this deadline is critical).',
        'DO NOT submit fake marriage certificates or birth certificates -- document fraud leads to permanent ban.',
        'DO NOT bring family members on tourist visas hoping to convert -- this usually fails and can lead to deportation.',
        'DO NOT forget to translate and legalize documents -- incomplete applications are delayed or rejected.',
        'DO NOT hide the existence of other family members (e.g., children from another marriage) -- honesty is essential.',
        'DO NOT assume the process is quick -- start as early as possible.',
        'DO NOT lose contact with the embassy while your family waits -- keep phone numbers and email updated.',
      ],
      documentsNeeded: [
        'Your valid residence permit (copy)',
        'Your passport (copy)',
        'Proof of income (employment contract, salary slips for 3-6 months, tax returns)',
        'Proof of housing (rental contract, apartment size/conditions)',
        'Marriage certificate (if bringing spouse)',
        'Birth certificates for all children',
        'Passports of family members',
        'Passport photos of all applicants',
        'Application form (from the embassy or immigration website)',
        'Medical examination results (required by some countries)',
        'DNA test results (if requested due to lack of documents)',
        'Proof of relationship (photos together, communication records, previous visits)',
        'Health insurance proof (required by some countries)',
      ],
      typicalTimeline:
          'Gathering documents: 1-3 months. '
          'Application processing: 2-18 months (varies greatly by country). '
          'Finland: 4-12 months. Germany: 3-12 months. '
          'Visa issuance after approval: 1-4 weeks. '
          'Total from start to family arrival: 6-24 months.',
      costEstimate:
          'Application fee: 50-400 EUR per person (refugees often exempt). '
          'Document translation: 20-50 EUR per page. '
          'Document legalization/apostille: 10-50 EUR per document. '
          'DNA test (if requested): 200-500 EUR. '
          'Medical examination: 50-200 EUR per person. '
          'Travel costs for family: varies. '
          'Total estimate: 300-2000 EUR depending on family size and country.',
      legalBasis:
          'EU Family Reunification Directive 2003/86/EC (right to family reunification for third-country nationals). '
          'ECHR Article 8 (right to respect for family life). '
          'EU Charter of Fundamental Rights, Article 7 (family life) and Article 24 (best interests of child). '
          'Geneva Convention (special provisions for refugees). '
          'National immigration laws implement these EU rules with specific requirements.',
    ),

    // =========================================================================
    // GUIDE 7: RESIDENCE PERMIT RENEWAL
    // =========================================================================
    PracticalGuide(
      id: 'permit_renewal',
      title: 'My residence permit is expiring -- how to renew?',
      urgencyLevel: 'urgent',
      steps: [
        'STEP 1: CHECK YOUR EXPIRY DATE AND START EARLY. '
            'Most countries require you to apply for renewal BEFORE the permit expires -- '
            'usually 1-3 months before the expiry date. '
            'In Finland: apply no later than 1 month before expiry. '
            'In Germany: apply at least 3 months before. '
            'DO NOT WAIT until the last week.',
        'STEP 2: CHECK THAT YOUR RENEWAL GROUNDS ARE STILL VALID. '
            'If your permit is based on work, you must still be employed. '
            'If based on studies, you must still be enrolled. '
            'If based on family, the family relationship must still exist. '
            'If your situation changed, you may need to apply for a DIFFERENT type of permit.',
        'STEP 3: GATHER THE REQUIRED DOCUMENTS. '
            'Typical requirements: valid passport, current residence permit, '
            'proof of continued grounds (employment contract, enrollment letter, etc.), '
            'proof of income, proof of housing, health insurance, passport photos. '
            'Check the immigration office website for the exact list.',
        'STEP 4: CHECK FOR PASSPORT VALIDITY. '
            'Most countries require your passport to be valid for at least 3-6 months '
            'beyond the new permit period. If your passport is expiring, '
            'renew it FIRST at your embassy.',
        'STEP 5: FILL OUT THE APPLICATION FORM. '
            'Download it from the immigration office website or get it in person. '
            'Fill it in carefully -- mistakes can cause delays. '
            'If you do not understand something, get help from a legal aid office.',
        'STEP 6: SUBMIT THE APPLICATION. '
            'Some countries allow online submission: Finland (Enter Finland portal), '
            'others require in-person visits. '
            'Book an appointment early -- wait times can be weeks. '
            'Keep your confirmation receipt -- it proves you applied on time.',
        'STEP 7: YOUR RIGHTS WHILE THE APPLICATION IS PENDING. '
            'If you applied before your permit expired, you can usually stay '
            'and continue working/studying while waiting for the decision. '
            'Your old permit remains valid until the decision. '
            'Carry both your old permit and the application receipt.',
        'STEP 8: IF YOU APPLIED LATE (AFTER EXPIRY), ACT FAST. '
            'Contact the immigration office immediately and explain why. '
            'Some countries have a grace period. Apply the same day if possible. '
            'Being late does not automatically mean rejection, but it complicates things.',
        'STEP 9: BE AVAILABLE FOR ADDITIONAL REQUESTS. '
            'The immigration office may ask for: additional documents, '
            'an interview, or clarification. Respond QUICKLY -- delays on your side '
            'can delay the decision. Check your mail and email regularly.',
        'STEP 10: TRACK YOUR APPLICATION STATUS. '
            'Most countries have online tracking. Check regularly. '
            'If it has been longer than the advertised processing time, '
            'contact the office politely to ask about the status.',
        'STEP 11: IF THE RENEWAL IS DENIED, APPEAL IMMEDIATELY. '
            'You have the right to appeal a denial. The deadline is usually 14-30 days. '
            'Contact a lawyer. Common denial reasons: gaps in employment, '
            'insufficient income, criminal record. '
            'Your appeal may allow you to stay while the court decides.',
        'STEP 12: PLAN AHEAD FOR THE NEXT RENEWAL. '
            'Set a reminder on your phone for 3 months before the new permit expires. '
            'Keep a folder with all your documents organized. '
            'Consider applying for a permanent residence permit or long-term EU residence '
            'if you have lived in the country long enough (usually 5 years).',
      ],
      doNots: [
        'DO NOT wait until the last week to apply -- processing times and appointment backlogs are real.',
        'DO NOT let your passport expire before renewing your residence permit.',
        'DO NOT travel outside the EU while your renewal is pending without checking if you can re-enter.',
        'DO NOT change jobs or drop out of school without understanding how it affects your permit.',
        'DO NOT ignore requests for additional documents -- this can lead to automatic rejection.',
        'DO NOT assume your old conditions still apply -- check for any changes in rules.',
        'DO NOT overstay without an application pending -- this can lead to an entry ban.',
      ],
      documentsNeeded: [
        'Valid passport (with at least 6 months remaining validity)',
        'Current residence permit',
        'Completed application form',
        'Recent passport photos (usually 2, check specifications)',
        'Proof of continued grounds: employment contract, enrollment letter, marriage certificate',
        'Income proof: salary slips (3-6 months), tax returns, bank statements',
        'Housing proof: rental contract or property deed',
        'Health insurance proof',
        'Criminal record extract (some countries)',
        'Registration certificate at current address',
        'Language certificate (some countries require for renewal)',
        'Application fee payment receipt',
      ],
      typicalTimeline:
          'Apply: 1-3 months before expiry. '
          'Processing time: 1-6 months depending on country. '
          'Finland: 1-4 months. Germany: 2-6 months. '
          'If denied: 14-30 days to appeal. '
          'Appeal decision: 2-8 months.',
      costEstimate:
          'Application fee: 100-300 EUR (varies by country and permit type). '
          'Finland: 119-500 EUR depending on permit type. '
          'Passport photos: 10-30 EUR. '
          'Document translations: 20-50 EUR per page if needed. '
          'Legal aid if issues arise: FREE for qualifying individuals.',
      legalBasis:
          'EU Long-term Residents Directive 2003/109/EC (after 5 years). '
          'EU Single Permit Directive 2011/98/EU (work-based permits). '
          'EU Students and Researchers Directive 2016/801. '
          'National immigration laws govern specific renewal requirements. '
          'Finland: Aliens Act (Ulkomaalaislaki 301/2004).',
    ),

    // =========================================================================
    // GUIDE 8: POLICE TOOK DOCUMENTS
    // =========================================================================
    PracticalGuide(
      id: 'police_took_documents',
      title: 'I was stopped by police and they took my documents',
      urgencyLevel: 'emergency',
      steps: [
        'STEP 1: STAY CALM AND COOPERATE. '
            'Police have the right to ask for identification. Stay polite and calm. '
            'Do not run, resist, or argue loudly. '
            'You have the right to ask: "Why are you stopping me?" and '
            '"Am I free to go?" Remember these answers.',
        'STEP 2: ASK FOR A RECEIPT. '
            'If police take any of your documents (passport, residence permit, ID), '
            'you have the right to a WRITTEN RECEIPT listing exactly what was taken, '
            'the reason, the officer\'s name/number, and the date. '
            'INSIST on getting this receipt -- it is your proof.',
        'STEP 3: REMEMBER THE DETAILS. '
            'Write down or save in your phone as soon as possible: '
            'the time and place, the officers\' names or badge numbers, '
            'what documents were taken, what reason they gave, '
            'names of any witnesses.',
        'STEP 4: UNDERSTAND WHY THEY CAN TAKE DOCUMENTS. '
            'Legal reasons to take documents: suspected forgery, '
            'you are suspected of a crime, you are under a deportation order, '
            'court order. '
            'NOT legal: random check without reason, racial profiling, '
            'intimidation, keeping documents without explanation.',
        'STEP 5: ASK IF YOU ARE BEING DETAINED OR ARRESTED. '
            'You have the right to know: "Am I under arrest? Am I being detained? Am I free to leave?" '
            'If you are arrested: you have the right to a lawyer (free if you cannot afford one), '
            'the right to an interpreter, the right to remain silent, '
            'the right to contact your embassy.',
        'STEP 6: CONTACT A LAWYER. '
            'If your documents were taken, contact a lawyer as soon as possible. '
            'If you were arrested, the police must allow you to contact a lawyer. '
            'Legal aid number in Finland: 0295 435 335. '
            'If you cannot reach a lawyer, contact a human rights organization.',
        'STEP 7: CONTACT YOUR EMBASSY OR CONSULATE. '
            'If your passport was taken, inform your embassy. '
            'They can confirm your identity and issue emergency travel documents if needed. '
            'Exception: do NOT contact your embassy if you are an asylum seeker fleeing your government.',
        'STEP 8: GO TO THE POLICE STATION TO RETRIEVE YOUR DOCUMENTS. '
            'If police took documents during a stop, go to the police station the next business day. '
            'Bring: the receipt they gave you, another form of ID if possible, '
            'your lawyer if you have one. Ask when you can get your documents back.',
        'STEP 9: FILE A COMPLAINT IF YOUR RIGHTS WERE VIOLATED. '
            'If police acted illegally (no reason for the stop, racial profiling, '
            'violence, no receipt given), you have the right to complain. '
            'File with: the police internal affairs unit, the national ombudsman, '
            'or a human rights organization.',
        'STEP 10: GET COPIES OF YOUR IMPORTANT DOCUMENTS. '
            'After this experience, make copies of ALL important documents: '
            'passport (every page), residence permit (both sides), ID card, '
            'work permit. Store copies: in your email, with a trusted friend, '
            'in cloud storage. Carry copies, keep originals safe at home.',
        'STEP 11: KNOW YOUR RIGHTS FOR FUTURE STOPS. '
            'In the EU you have the right to: know why you are being stopped, '
            'not be stopped based only on your race or ethnicity, '
            'an interpreter if needed, have a lawyer present during questioning, '
            'not answer questions that might incriminate you.',
        'STEP 12: IF DOCUMENTS ARE NOT RETURNED WITHIN A REASONABLE TIME, TAKE LEGAL ACTION. '
            'If the police do not return your documents within a few days to weeks '
            '(depending on the reason), your lawyer can: file a complaint with the court, '
            'request an order to return the documents, '
            'file for compensation if the seizure was unlawful.',
      ],
      doNots: [
        'DO NOT run from police -- it gives them reason to detain you and may lead to criminal charges.',
        'DO NOT physically resist -- even if the stop is illegal, resistance makes it worse.',
        'DO NOT give false information about your identity -- lying to police is a crime.',
        'DO NOT hand over documents without asking for a receipt.',
        'DO NOT argue aggressively with officers -- stay calm, note everything, complain later through proper channels.',
        'DO NOT sign anything you do not understand -- ask for translation.',
        'DO NOT assume it is normal -- police keeping your documents without proper reason is NOT normal.',
        'DO NOT throw away the receipt or forget the details -- you need them if you file a complaint.',
      ],
      documentsNeeded: [
        'Receipt from police for confiscated documents',
        'Any other form of identification you have',
        'Notes about the incident (time, place, officers, witnesses)',
        'Copies of the taken documents (if you had copies)',
        'Police complaint form (from the police station or ombudsman)',
        'Lawyer contact details',
        'Embassy contact details',
      ],
      typicalTimeline:
          'Getting a receipt: immediately during the stop. '
          'Retrieving documents: 1-7 business days (routine). '
          'If related to investigation: may be held for weeks to months. '
          'Filing a complaint: do it within days to weeks. '
          'Complaint investigation: 1-6 months. '
          'Court action to recover documents: 1-3 months.',
      costEstimate:
          'Retrieving documents from police: FREE (they are YOUR documents). '
          'Legal aid: FREE for qualifying individuals. '
          'Filing a complaint: FREE. '
          'Replacement passport from embassy: 30-100 EUR. '
          'Replacement residence permit: 50-100 EUR. '
          'Compensation claim if rights violated: potentially thousands of EUR.',
      legalBasis:
          'EU Charter of Fundamental Rights, Article 6 (right to liberty and security). '
          'ECHR Article 5 (right to liberty), Article 8 (right to private life), Article 14 (non-discrimination). '
          'EU Race Equality Directive 2000/43/EC (prohibition of racial profiling). '
          'EU Directive 2012/13/EU (right to information in criminal proceedings). '
          'National police laws regulate document seizure and return procedures.',
    ),

    // =========================================================================
    // GUIDE 9: APPLYING FOR CITIZENSHIP
    // =========================================================================
    PracticalGuide(
      id: 'citizenship_application',
      title: 'I want to apply for citizenship',
      urgencyLevel: 'planning',
      steps: [
        'STEP 1: CHECK THE RESIDENCE REQUIREMENT. '
            'Most EU countries require you to have lived there continuously for a minimum period: '
            'Finland: 5 years (4 years with certain conditions). '
            'Germany: 8 years (7 with integration course). '
            'Sweden: 5 years. France: 5 years. '
            'Check your specific country. Absences may reset the clock.',
        'STEP 2: CHECK IF YOU MEET THE OTHER REQUIREMENTS. '
            'Typical requirements: valid residence permit for the required period, '
            'sufficient language skills (B1-B2 level in most countries), '
            'no serious criminal record, financial self-sufficiency (not relying on social welfare), '
            'passing a citizenship/integration test (in some countries), '
            'good conduct and integration into society.',
        'STEP 3: CHECK THE DUAL CITIZENSHIP RULES. '
            'Some EU countries allow dual citizenship, some do not. '
            'Finland: allows dual citizenship (you keep your original nationality). '
            'Germany: generally requires giving up previous nationality (exceptions exist). '
            'Netherlands: generally requires giving up (exceptions exist). '
            'Check if you must give up your current nationality.',
        'STEP 4: TAKE THE REQUIRED LANGUAGE TEST. '
            'Most countries require a certified language test. '
            'Finland: Finnish or Swedish at YKI level 3 (B1). '
            'Germany: B1 German. '
            'Register for the test well in advance -- waiting times can be months. '
            'Language courses are often available for free or low cost through integration programs.',
        'STEP 5: TAKE THE CITIZENSHIP TEST (IF REQUIRED). '
            'Germany: Einbuergerungstest (33 questions about history, politics, society). '
            'UK: Life in the UK test. '
            'Study materials are usually available free online. '
            'Finland: no citizenship test required.',
        'STEP 6: GATHER ALL REQUIRED DOCUMENTS. '
            'This is the most time-consuming part. Start months in advance. '
            'You will likely need documents from your home country -- '
            'ask family there to help obtain them. '
            'All foreign documents need official translation and often apostille/legalization.',
        'STEP 7: REQUEST A CRIMINAL RECORD CHECK. '
            'You need a clean criminal record from: the country you live in '
            'AND often from your home country. '
            'Request these early -- they can take weeks to arrive. '
            'Minor offenses (traffic fines) usually do not disqualify you.',
        'STEP 8: CHECK YOUR TAX AND FINANCIAL HISTORY. '
            'Most countries check that you have: filed your taxes, '
            'paid any debts to the government, not been receiving social welfare '
            '(or not excessively). Get your tax transcripts ready.',
        'STEP 9: FILL OUT THE APPLICATION FORM. '
            'Download from the immigration/citizenship office website. '
            'Fill in carefully -- any inconsistency may trigger extra questions. '
            'If anything is unclear, get help from a legal aid office.',
        'STEP 10: SUBMIT THE APPLICATION AND PAY THE FEE. '
            'Application fees: Finland 420-650 EUR, Germany 255 EUR, France FREE. '
            'Some countries offer fee reductions for low-income applicants. '
            'Keep the receipt and confirmation number.',
        'STEP 11: WAIT FOR PROCESSING AND RESPOND TO REQUESTS. '
            'Processing times: 6-24 months depending on the country. '
            'During this time, continue living normally in the country -- '
            'do not take long trips abroad, do not commit any offenses, '
            'maintain your employment or studies.',
        'STEP 12: ATTEND THE INTERVIEW (IF REQUIRED). '
            'Some countries interview citizenship applicants. '
            'Be prepared to talk about: your life in the country, why you want citizenship, '
            'your integration, your language skills. Be honest and relaxed.',
        'STEP 13: RECEIVE THE DECISION AND TAKE THE OATH. '
            'If approved, many countries require a citizenship ceremony where you take an oath. '
            'After this, apply for your new passport. '
            'Congratulations -- you are now a citizen with full rights.',
        'STEP 14: IF REJECTED, APPEAL THE DECISION. '
            'You can appeal to an administrative court. Get legal help. '
            'Common rejection reasons: insufficient language skills, '
            'gaps in residence, criminal record. Fix the issue and reapply.',
      ],
      doNots: [
        'DO NOT lie on the application -- false information is grounds for revoking citizenship even years later.',
        'DO NOT travel extensively during the required residence period -- long absences can disqualify you.',
        'DO NOT commit any crimes while the application is pending -- even minor ones can cause rejection.',
        'DO NOT give up your current nationality BEFORE receiving the new citizenship (unless required).',
        'DO NOT forget to translate and legalize foreign documents -- incomplete applications are rejected.',
        'DO NOT assume requirements from a few years ago still apply -- rules change frequently.',
        'DO NOT rush the language test -- take preparation courses first.',
      ],
      documentsNeeded: [
        'Valid passport',
        'Current and all previous residence permits',
        'Birth certificate (apostilled and translated)',
        'Marriage certificate (if married, apostilled and translated)',
        'Language test certificate (B1/B2 level)',
        'Citizenship test certificate (if required)',
        'Criminal record from country of residence',
        'Criminal record from home country (apostilled and translated)',
        'Tax returns for the residence period',
        'Employment history (contracts, salary slips)',
        'Proof of address for the entire residence period',
        'Passport photos',
        'Completed application form',
        'Application fee payment receipt',
        'Proof of social integration (community involvement, education, etc.)',
      ],
      typicalTimeline:
          'Preparation (language test, gathering documents): 3-12 months. '
          'Processing time after submission: 6-24 months. '
          'Finland: 6-18 months. Germany: 6-12 months. '
          'Oath/ceremony after approval: 1-3 months. '
          'New passport issuance: 2-6 weeks.',
      costEstimate:
          'Language course: often FREE through integration programs. '
          'Language test: 50-250 EUR. '
          'Citizenship test: 25-100 EUR. '
          'Document translations: 20-50 EUR per page. '
          'Apostille/legalization: 10-50 EUR per document. '
          'Criminal record checks: 10-50 EUR each. '
          'Application fee: 0-650 EUR (varies by country). '
          'Total estimate: 200-1500 EUR.',
      legalBasis:
          'European Convention on Nationality 1997 (Council of Europe). '
          'EU Treaty (EU citizenship is automatic with national citizenship of any EU member state). '
          'National citizenship laws: Finland Citizenship Act (Kansalaisuuslaki 359/2003), '
          'German Nationality Act (Staatsangehoerigkeitsgesetz), etc. '
          'ECHR Article 8 (right to private life -- relevant in long-term residence cases).',
    ),

    // =========================================================================
    // GUIDE 10: WORKPLACE DISCRIMINATION
    // =========================================================================
    PracticalGuide(
      id: 'workplace_discrimination',
      title: 'I am experiencing discrimination at work',
      urgencyLevel: 'important',
      steps: [
        'STEP 1: RECOGNIZE WHAT COUNTS AS DISCRIMINATION. '
            'Illegal discrimination includes treating you differently because of: '
            'race, ethnicity, or skin color; nationality or origin; religion; '
            'gender; age; disability; sexual orientation; pregnancy. '
            'Examples: being paid less than colleagues for the same work, '
            'being passed over for promotion, insults or jokes about your background, '
            'being given worse shifts or tasks, being fired for discriminatory reasons.',
        'STEP 2: START A DETAILED WRITTEN RECORD TODAY. '
            'Write down every incident: date, time, place, what happened, '
            'who said or did it, who witnessed it. Be specific. '
            '"On March 15 at 10am, my supervisor Jan said [exact words] in the break room. '
            'Maria and Ahmed were present." Keep this record secure.',
        'STEP 3: SAVE ALL EVIDENCE. '
            'Keep: emails, text messages, chat messages showing discrimination; '
            'written work evaluations; schedule changes; pay slips showing unequal pay; '
            'photos of offensive signs, graffiti, or materials at work; '
            'recordings (check if one-party consent is legal in your country).',
        'STEP 4: REPORT TO YOUR EMPLOYER FIRST (IN WRITING). '
            'Send a written complaint to: your HR department, your supervisor\'s manager, '
            'or the designated complaints officer. '
            'Write: "I am experiencing discrimination based on [reason]. '
            'The incidents include [list main incidents]. I request that this be investigated '
            'and stopped." Keep a copy with proof you sent it.',
        'STEP 5: YOUR EMPLOYER IS LEGALLY REQUIRED TO ACT. '
            'Under EU law, employers must: investigate complaints of discrimination, '
            'take steps to stop it, protect you from retaliation for complaining. '
            'If they do nothing, this is itself a violation of the law.',
        'STEP 6: CONTACT THE EQUALITY BODY / OMBUDSMAN. '
            'Every EU country has an equality body that handles discrimination complaints: '
            'Finland: Non-Discrimination Ombudsman (Yhdenvertaisuusvaltuutettu). '
            'Germany: Federal Anti-Discrimination Agency (Antidiskriminierungsstelle). '
            'They can: investigate, mediate, and support you. Their services are FREE.',
        'STEP 7: CONTACT YOUR TRADE UNION. '
            'If you are a union member, they can: represent you, negotiate with your employer, '
            'provide legal support, file a complaint on your behalf. '
            'Even non-members can sometimes get union help for discrimination cases.',
        'STEP 8: SEEK FREE LEGAL ADVICE. '
            'Contact: legal aid office, anti-discrimination NGOs, '
            'migrant support organizations. Many offer free legal consultations. '
            'A lawyer can assess whether you have a strong case.',
        'STEP 9: FILE A FORMAL COMPLAINT IF THE EMPLOYER DOES NOT FIX IT. '
            'You can file with: the equality body (ombudsman), '
            'the labor inspectorate, or directly with the court. '
            'Many countries have specific anti-discrimination tribunals.',
        'STEP 10: KNOW ABOUT COMPENSATION. '
            'If discrimination is proven, you may receive: '
            'compensation for lost wages, compensation for emotional harm, '
            'reinstatement to your job (if you were fired), '
            'an order for the employer to change their practices.',
        'STEP 11: PROTECT YOURSELF FROM RETALIATION. '
            'It is ILLEGAL for your employer to punish you for complaining about discrimination: '
            'firing you, reducing hours, giving worse tasks, bullying. '
            'If this happens, document it and report it -- retaliation is a separate violation.',
        'STEP 12: TAKE CARE OF YOUR MENTAL HEALTH. '
            'Discrimination is stressful and harmful. You deserve support. '
            'Talk to: a counselor, a support group, friends. '
            'Your doctor can refer you to mental health services -- '
            'often covered by health insurance or available free.',
        'STEP 13: KNOW THE TIME LIMITS. '
            'Most countries have deadlines for filing discrimination complaints: '
            'typically 6 months to 2 years from the last incident. '
            'Do not wait too long -- start the process early.',
      ],
      doNots: [
        'DO NOT suffer in silence -- discrimination is illegal and you have the right to stop it.',
        'DO NOT quit your job before getting legal advice -- quitting may weaken your claim.',
        'DO NOT confront the discriminator aggressively -- keep calm and document everything.',
        'DO NOT delete messages or evidence -- you need them for your complaint.',
        'DO NOT accept an informal "apology" without written agreement that it will stop.',
        'DO NOT assume nothing will happen -- EU anti-discrimination law is strong and enforceable.',
        'DO NOT be afraid of retaliation -- retaliation itself is illegal and gives you additional claims.',
        'DO NOT miss the filing deadline -- check your country\'s specific time limits.',
      ],
      documentsNeeded: [
        'Written record of all discriminatory incidents (your diary/log)',
        'Emails, messages, or communications showing discrimination',
        'Your employment contract',
        'Pay slips (to show unequal pay if relevant)',
        'Work schedules (to show unequal treatment)',
        'Performance evaluations',
        'Your written complaint to the employer and their response',
        'Witness statements from colleagues',
        'Medical records showing impact on your health',
        'Union correspondence (if applicable)',
      ],
      typicalTimeline:
          'Internal complaint to employer: expect response within 2-4 weeks. '
          'Equality body complaint: investigation takes 1-6 months. '
          'Mediation: 1-3 months. '
          'Court case: 6-18 months. '
          'Compensation: paid within 1-3 months of decision.',
      costEstimate:
          'Internal complaint: FREE. '
          'Equality body / ombudsman: FREE. '
          'Trade union help: included in membership (30-50 EUR/month). '
          'Legal aid: FREE for qualifying individuals. '
          'Private lawyer: 150-300 EUR/hour (but many discrimination cases are taken on contingency). '
          'Compensation if you win: can range from 5,000 to 30,000+ EUR.',
      legalBasis:
          'EU Employment Equality Directive 2000/78/EC (discrimination based on religion, disability, age, sexual orientation). '
          'EU Race Equality Directive 2000/43/EC (racial and ethnic discrimination). '
          'EU Gender Equality Directive 2006/54/EC (gender discrimination at work). '
          'EU Charter of Fundamental Rights, Article 21 (non-discrimination). '
          'National equality acts: Finland Non-Discrimination Act (Yhdenvertaisuuslaki 1325/2014).',
    ),

    // =========================================================================
    // GUIDE 11: EMPLOYER TOOK PASSPORT
    // =========================================================================
    PracticalGuide(
      id: 'passport_confiscated',
      title: 'My employer took my passport',
      urgencyLevel: 'emergency',
      steps: [
        'STEP 1: UNDERSTAND THIS IS ILLEGAL AND MAY BE A CRIME. '
            'No employer is EVER allowed to take or hold your passport, ID, or travel documents. '
            'This is YOUR personal property. In many countries, confiscating someone\'s passport '
            'is a criminal offense. It is also a key indicator of forced labor or trafficking.',
        'STEP 2: DEMAND YOUR PASSPORT BACK IN WRITING. '
            'Send a message (text, email, or letter -- keep proof): '
            '"I demand the immediate return of my passport which you are holding without my consent. '
            'Holding another person\'s passport is illegal. Please return it by [date -- give 48 hours]."',
        'STEP 3: IF THEY REFUSE, DO NOT PANIC. '
            'Your passport belongs to your government, not your employer. '
            'You have several options to get it back. Do not feel trapped.',
        'STEP 4: CALL THE POLICE. '
            'Report that your employer has taken your passport. '
            'Explain: "My employer is holding my passport against my will." '
            'The police can order the employer to return it or charge them with a crime. '
            'File an official report and get a copy.',
        'STEP 5: CONTACT YOUR EMBASSY OR CONSULATE. '
            'Your embassy can: confirm to authorities that the passport belongs to you, '
            'issue a replacement passport or emergency travel document, '
            'intervene with the employer through diplomatic channels. '
            'Call the emergency consular line.',
        'STEP 6: ASSESS IF THIS IS TRAFFICKING OR FORCED LABOR. '
            'Taking your passport is one of the strongest signs. Other signs: '
            'controlling where you live, not allowing you to leave, '
            'threatening deportation, not paying wages, physical violence or threats, '
            'debt bondage (you owe them money for travel/housing). '
            'If ANY of these apply, this is likely trafficking or forced labor.',
        'STEP 7: IF THIS IS TRAFFICKING, CONTACT A HELPLINE. '
            'National anti-trafficking helplines exist in every EU country. '
            'Finland: Help System for Victims of Trafficking (ihmiskauppa.fi). '
            'EU-wide: you can contact the national referral mechanism. '
            'You will receive PROTECTION, not punishment.',
        'STEP 8: AS A TRAFFICKING VICTIM, YOU HAVE SPECIAL RIGHTS. '
            'EU law grants trafficking victims: a reflection period (30+ days) to recover, '
            'a residence permit, access to housing and support services, '
            'exemption from prosecution for crimes committed under coercion, '
            'right to compensation from the trafficker.',
        'STEP 9: CONTACT A WORKERS RIGHTS ORGANIZATION OR NGO. '
            'Organizations that help migrant workers can: advise you, '
            'accompany you to the police, provide shelter, connect you with a lawyer. '
            'Search for "[country] migrant workers rights" or "anti-trafficking NGO."',
        'STEP 10: GET FREE LEGAL HELP. '
            'A lawyer can: help you get your passport back through legal channels, '
            'file a criminal complaint against the employer, '
            'claim compensation for damages, '
            'help you obtain a residence permit as a victim of exploitation.',
        'STEP 11: DO NOT FEEL ASHAMED OR BLAME YOURSELF. '
            'Passport confiscation is a form of control and abuse. '
            'You are the victim. Thousands of people experience this. '
            'Help is available and you will not be punished for coming forward.',
        'STEP 12: SECURE YOUR DOCUMENTS IN THE FUTURE. '
            'Once you get your passport back: keep it in a safe place only YOU control, '
            'make copies (paper and digital), store copies with a trusted friend, '
            'NEVER give your original passport to an employer. '
            'If they need your details, give them a photocopy.',
      ],
      doNots: [
        'DO NOT accept the excuse that "it is for safekeeping" -- there is no legal reason for an employer to hold your passport.',
        'DO NOT sign any document agreeing to let them hold it.',
        'DO NOT believe threats that you will be deported -- as a victim, you have protections.',
        'DO NOT continue working for this employer if you feel unsafe -- your safety comes first.',
        'DO NOT try to steal your passport back by force -- use legal channels.',
        'DO NOT destroy evidence (messages, contracts, etc.) -- you need them.',
        'DO NOT feel ashamed to ask for help -- this is a crime against YOU.',
      ],
      documentsNeeded: [
        'Your written demand for passport return (with proof of sending)',
        'Police report (file one immediately)',
        'Any copy of your passport you may have (even a photo on your phone)',
        'Employment contract or any document showing the work relationship',
        'Messages/evidence of the employer holding your passport',
        'Evidence of threats or coercion (if any)',
        'Witness contact details (coworkers who can confirm)',
        'Embassy contact details',
        'Any receipts or evidence showing the employer received your passport',
      ],
      typicalTimeline:
          'Written demand: allow 48 hours for return. '
          'Police intervention: can happen same day or within days. '
          'Embassy replacement passport: 1-14 days (emergency) or 2-6 weeks (regular). '
          'Trafficking identification process: days to weeks. '
          'Residence permit for victims: 1-3 months. '
          'Criminal case against employer: 3-12 months.',
      costEstimate:
          'Police report: FREE. '
          'Embassy replacement passport: 30-100 EUR. '
          'Legal aid: FREE for victims of exploitation. '
          'Victim support services: FREE. '
          'Compensation from employer (if trafficking proven): can be significant -- back pay, damages, emotional harm.',
      legalBasis:
          'EU Anti-Trafficking Directive 2011/36/EU (trafficking includes confiscation of documents). '
          'EU Employers Sanctions Directive 2009/52/EC (employer obligations). '
          'ILO Forced Labour Convention (passport confiscation as indicator of forced labor). '
          'National criminal codes: passport confiscation is a criminal offense in most EU countries. '
          'EU Residence Permit Directive for Trafficking Victims 2004/81/EC.',
    ),

    // =========================================================================
    // GUIDE 12: EMERGENCY MEDICAL CARE WITHOUT INSURANCE
    // =========================================================================
    PracticalGuide(
      id: 'emergency_medical_no_insurance',
      title: 'I need emergency medical care but have no insurance',
      urgencyLevel: 'emergency',
      steps: [
        'STEP 1: GO TO THE HOSPITAL EMERGENCY ROOM NOW. '
            'Do NOT delay seeking medical care because you have no insurance. '
            'In the EU, emergency rooms MUST treat you regardless of: '
            'insurance status, immigration status, ability to pay, nationality. '
            'If it is an emergency, call 112 for an ambulance.',
        'STEP 2: WHAT COUNTS AS EMERGENCY CARE. '
            'You are guaranteed treatment for: life-threatening conditions, '
            'severe pain, active bleeding, broken bones, heart attack/stroke symptoms, '
            'pregnancy complications, childbirth, psychiatric emergencies, '
            'acute infections, and any condition that would seriously worsen without immediate care.',
        'STEP 3: AT THE HOSPITAL, GIVE YOUR NAME AND EXPLAIN YOUR SITUATION. '
            'Say: "I need emergency medical care. I do not have insurance." '
            'They MUST treat you. They may ask for your details -- provide them. '
            'If you are undocumented, you can still receive emergency care.',
        'STEP 4: ASK FOR AN INTERPRETER IF YOU NEED ONE. '
            'Hospitals should provide interpretation services. '
            'If not immediately available, ask if they can call a phone interpreter. '
            'It is important that you understand your diagnosis and treatment.',
        'STEP 5: GET ALL TREATMENT DOCUMENTED. '
            'Ask for copies of: your diagnosis, treatment records, prescribed medications, '
            'follow-up instructions. You may need these for: insurance claims later, '
            'legal proceedings, or immigration applications.',
        'STEP 6: ASK ABOUT PAYMENT OPTIONS BEFORE YOU LEAVE. '
            'Talk to the hospital social worker or billing department. '
            'Options may include: payment plan, reduced fees for uninsured patients, '
            'charity care (hospitals sometimes write off bills for people who cannot pay), '
            'government emergency medical fund.',
        'STEP 7: CONTACT SOCIAL SERVICES. '
            'Municipal social services may cover emergency medical costs for: '
            'asylum seekers, undocumented people (in some countries), '
            'people with no income. Contact them and explain: '
            '"I received emergency medical care and cannot afford the bill."',
        'STEP 8: CHECK IF YOU QUALIFY FOR ANY HEALTH COVERAGE. '
            'You may be eligible for: European Health Insurance Card (EHIC) from your home EU country, '
            'asylum seeker health coverage, emergency Medicaid-equivalent programs, '
            'municipal health services for uninsured residents. '
            'Many people are covered and do not know it.',
        'STEP 9: FOR ONGOING CONDITIONS, FIND LOW-COST HEALTH SERVICES. '
            'Many cities have: free clinics run by NGOs, charitable health centers, '
            'Red Cross medical services, volunteer doctor networks. '
            'Search for "[city] free clinic" or "[city] health care for uninsured."',
        'STEP 10: FOR MEDICATIONS, ASK ABOUT AFFORDABLE OPTIONS. '
            'Ask your doctor to prescribe generic medications (cheaper). '
            'Some pharmacies have programs for people who cannot pay. '
            'NGOs sometimes provide free medications. '
            'Hospital pharmacies may be cheaper than regular pharmacies.',
        'STEP 11: IF YOU ARE PREGNANT. '
            'Pregnant women receive extra protections in ALL EU countries: '
            'free prenatal care (in most countries even without insurance), '
            'free childbirth and postpartum care, '
            'special support through maternal health services. '
            'Contact the nearest maternity clinic.',
        'STEP 12: DO NOT IGNORE FOLLOW-UP CARE. '
            'If the doctor says you need follow-up visits, try to attend them. '
            'Untreated conditions get worse and more expensive. '
            'Ask the hospital social worker to help arrange affordable follow-up care.',
        'STEP 13: GET INSURANCE AS SOON AS POSSIBLE. '
            'Once your immediate emergency is handled, work on getting health coverage: '
            'through employment, through the public system if eligible, '
            'through asylum seeker services, or through private insurance. '
            'Ask an NGO to help you navigate the system.',
      ],
      doNots: [
        'DO NOT delay going to the hospital because of insurance or cost worries -- your life is more important.',
        'DO NOT leave the hospital before treatment is complete because you are worried about the bill.',
        'DO NOT give a fake name -- it creates complications and may prevent follow-up care.',
        'DO NOT assume you have to pay upfront -- most hospitals bill you later.',
        'DO NOT ignore symptoms hoping they will go away -- many conditions worsen without treatment.',
        'DO NOT be afraid to call an ambulance -- in a real emergency, call 112.',
        'DO NOT accept substandard care -- you have the right to proper emergency treatment regardless of status.',
      ],
      documentsNeeded: [
        'Any form of identification (even expired)',
        'Any insurance card (even from another country -- EHIC, travel insurance)',
        'List of medications you currently take',
        'List of allergies',
        'Medical records (if you have any from previous treatment)',
        'Contact details of a family member or friend (emergency contact)',
        'Proof of income/no income (for financial assistance requests)',
        'Asylum seeker registration card (if applicable)',
      ],
      typicalTimeline:
          'Emergency treatment: IMMEDIATE upon arrival. '
          'Hospital bill: arrives 1-4 weeks later. '
          'Social services application for help with bill: 1-4 weeks for decision. '
          'Payment plan: can be set up over weeks to months. '
          'Getting proper insurance: days to months depending on situation.',
      costEstimate:
          'Emergency room visit: 0-500 EUR (varies by country, often reduced for uninsured). '
          'Finland: emergency visit 41.80 EUR (public hospital). '
          'Ambulance: 0-300 EUR (varies, sometimes free). '
          'Hospital stay: 0-50 EUR/day in public hospitals (many countries cap costs). '
          'Medications: 5-100 EUR depending on the medication. '
          'Social services may cover all costs if you qualify.',
      legalBasis:
          'EU Charter of Fundamental Rights, Article 35 (right to health care). '
          'EU Cross-Border Healthcare Directive 2011/24/EU. '
          'EU Reception Conditions Directive 2013/33/EU (health care for asylum seekers). '
          'ECHR Article 2 (right to life) and Article 3 (prohibition of inhuman treatment). '
          'National health laws guarantee emergency care for all persons. '
          'Finland: Health Care Act (Terveydenhuoltolaki), Primary Health Care Act.',
    ),

    // =========================================================================
    // GUIDE 13: IMMIGRATION DETENTION RIGHTS
    // =========================================================================
    PracticalGuide(
      id: 'immigration_detention',
      title: 'I am in immigration detention -- what are my rights?',
      urgencyLevel: 'emergency',
      steps: [
        'STEP 1: YOU HAVE RIGHTS EVEN IN DETENTION. '
            'Immigration detention is NOT a criminal prison. You are being held for immigration reasons, '
            'not because you committed a crime. You have significant legal rights. '
            'This guide helps you know and use them.',
        'STEP 2: DEMAND TO KNOW WHY YOU ARE DETAINED. '
            'The authorities MUST tell you in writing, in a language you understand: '
            'why you are detained, the legal basis for detention, '
            'and how to challenge it. If they have not given you this, ask for it immediately.',
        'STEP 3: DEMAND ACCESS TO A LAWYER. '
            'You have the RIGHT to a lawyer. If you cannot afford one, '
            'you have the right to FREE legal aid. '
            'Tell the detention staff: "I want to speak to a lawyer." '
            'They MUST arrange this. Do not sign anything until you speak to a lawyer.',
        'STEP 4: CONTACT YOUR FAMILY. '
            'You have the right to contact your family and tell them where you are. '
            'You have the right to make phone calls. '
            'If staff refuse, this is a violation of your rights -- tell your lawyer.',
        'STEP 5: CONTACT YOUR EMBASSY. '
            'You have the right to contact your country\'s embassy or consulate. '
            'They can visit you, verify your identity, and provide assistance. '
            'Exception: if you are an asylum seeker fleeing your government, '
            'you do NOT have to contact your embassy and they should NOT be notified.',
        'STEP 6: CHALLENGE YOUR DETENTION IN COURT. '
            'You have the RIGHT to have a court review whether your detention is legal. '
            'This is called a "judicial review" or "habeas corpus." '
            'Your lawyer can file this for you. '
            'Detention must be: lawful, necessary, proportionate, and for the shortest possible time.',
        'STEP 7: DETENTION HAS TIME LIMITS. '
            'EU law sets a maximum of 18 months for immigration detention '
            '(some countries have shorter limits). '
            'If there is no realistic prospect of removing you (no travel documents, '
            'your country does not cooperate), detention may be unlawful. Tell your lawyer.',
        'STEP 8: YOUR RIGHTS INSIDE THE DETENTION CENTER. '
            'You have the right to: adequate food and clean water, '
            'medical care (including mental health care), '
            'outdoor exercise, communication with family and lawyer, '
            'personal space and privacy, your own clothing, '
            'religious practice, information in a language you understand.',
        'STEP 9: REQUEST MEDICAL CARE IF YOU NEED IT. '
            'Detention centers must provide medical care. '
            'If you are sick, injured, or have a mental health condition, '
            'request to see a doctor. If they refuse, tell your lawyer immediately. '
            'Your medical condition may also be grounds for release.',
        'STEP 10: ALTERNATIVES TO DETENTION MUST BE CONSIDERED. '
            'EU law says detention should be a last resort. Alternatives include: '
            'regular reporting to police, residing at a specific address, '
            'electronic monitoring, deposit of a financial guarantee. '
            'Your lawyer should argue for an alternative to detention.',
        'STEP 11: VULNERABLE PEOPLE GET SPECIAL PROTECTION. '
            'You may have additional rights if you are: pregnant, '
            'a minor (under 18 -- minors generally should NOT be detained), '
            'elderly, disabled, a victim of trafficking or torture, '
            'suffering from serious illness. Tell your lawyer about your circumstances.',
        'STEP 12: FILE COMPLAINTS IF YOUR RIGHTS ARE VIOLATED. '
            'If you are mistreated: tell your lawyer, file a written complaint '
            'with the detention center management, contact the national ombudsman '
            'or human rights organization, contact UNHCR. '
            'Document everything: dates, what happened, who was involved, witnesses.',
        'STEP 13: PREPARE FOR YOUR CASE. '
            'Even while detained, you can prepare your legal case: '
            'gather evidence against deportation (danger in home country, family ties), '
            'communicate with your lawyer, '
            'ask family or friends to collect documents for you.',
        'STEP 14: IF RELEASED, COMPLY WITH ALL CONDITIONS. '
            'If the court orders your release (with or without conditions), '
            'follow ALL conditions: report to police as required, '
            'stay at the required address, attend all appointments. '
            'Violating conditions can lead to re-detention.',
      ],
      doNots: [
        'DO NOT sign any documents without your lawyer reviewing them -- especially "voluntary return" agreements.',
        'DO NOT resist detention physically -- it can lead to criminal charges.',
        'DO NOT give up -- detention can be challenged and many people are released.',
        'DO NOT accept that "you have no rights" -- you have many rights, even without papers.',
        'DO NOT refuse to eat as a protest without medical supervision -- it is dangerous.',
        'DO NOT share your legal strategy with other detainees or staff -- only with your lawyer.',
        'DO NOT lose hope -- detention is temporary and you have legal options.',
        'DO NOT agree to "voluntary return" under pressure without legal advice.',
      ],
      documentsNeeded: [
        'Written detention order (demand a copy)',
        'Any identity documents you have',
        'Asylum application (if pending)',
        'Court decisions or appeal papers',
        'Medical records',
        'Lawyer contact information',
        'Embassy contact information',
        'Family contact information',
        'Written record of complaints about conditions',
        'Any evidence supporting your case (photos, letters, documents friends can bring)',
      ],
      typicalTimeline:
          'Maximum detention: 6-18 months (varies by country; EU max is 18 months). '
          'First judicial review: within 48-72 hours of detention. '
          'Subsequent reviews: every 1-4 weeks. '
          'Asylum claim while detained: can take 2-6 months. '
          'Release decision: can happen at any review hearing.',
      costEstimate:
          'Legal aid: FREE for immigration detainees in all EU countries. '
          'Court applications: FREE (no court fees for detention challenges). '
          'Phone calls from detention: may cost a small amount (varies by facility). '
          'Medical care in detention: FREE (provided by the facility). '
          'Compensation if detention was unlawful: can be significant.',
      legalBasis:
          'EU Return Directive 2008/115/EC (detention conditions, time limits, judicial review). '
          'EU Reception Conditions Directive 2013/33/EU (detention of asylum seekers). '
          'EU Charter of Fundamental Rights, Article 6 (right to liberty). '
          'ECHR Article 5 (right to liberty, lawfulness of detention, right to judicial review). '
          'UN Convention on the Rights of the Child (detention of minors should be last resort). '
          'CPT Standards (Council of Europe Committee for Prevention of Torture).',
    ),

    // =========================================================================
    // GUIDE 14: STARTING A BUSINESS IN THE EU
    // =========================================================================
    PracticalGuide(
      id: 'start_business_eu',
      title: 'I want to start a business in the EU',
      urgencyLevel: 'planning',
      steps: [
        'STEP 1: CHECK IF YOUR RESIDENCE PERMIT ALLOWS SELF-EMPLOYMENT. '
            'Not all residence permits allow you to start a business. '
            'Check your permit: does it say "employment," "self-employment," or "business"? '
            'If it only says "employment," you may need to apply for a change or additional permit. '
            'EU/EEA citizens can start a business freely in any EU country.',
        'STEP 2: CHOOSE YOUR COUNTRY AND BUSINESS FORM. '
            'Consider: tax rates, ease of starting a business, language, market potential. '
            'Business forms in most EU countries: sole proprietorship (simplest), '
            'limited liability company (LLC -- protects personal assets), '
            'partnership, branch of a foreign company. '
            'For most small businesses, sole proprietorship or LLC is best.',
        'STEP 3: IF YOU NEED A SPECIAL BUSINESS VISA OR PERMIT, APPLY FOR IT. '
            'Some countries have startup visas or entrepreneur residence permits: '
            'Finland: Startup Permit (for innovative startups). '
            'France: French Tech Visa. '
            'Estonia: e-Residency (digital business identity). '
            'Germany: Self-employment residence permit. '
            'Check requirements: business plan, funding, qualifications.',
        'STEP 4: WRITE A SIMPLE BUSINESS PLAN. '
            'You need a business plan for: visa applications, bank accounts, funding. '
            'Include: what your business does, who your customers are, '
            'how you will make money, expected costs and revenue for year 1, '
            'your background and qualifications. Keep it 3-5 pages.',
        'STEP 5: REGISTER YOUR BUSINESS. '
            'In most EU countries this can be done online: '
            'Finland: register at PRH (Patent and Registration Office) and Tax Administration. '
            'Germany: register at Gewerbeamt (trade office) or Handelsregister (commercial register). '
            'Estonia: online through e-Business Register. '
            'Registration usually takes 1-7 days and costs 0-300 EUR.',
        'STEP 6: GET A TAX NUMBER. '
            'Register with the tax authority for: income tax, VAT (if turnover exceeds threshold -- '
            'typically 10,000-85,000 EUR/year depending on country), '
            'social security contributions. '
            'Finland: apply for a Business ID (Y-tunnus) at ytj.fi.',
        'STEP 7: OPEN A BUSINESS BANK ACCOUNT. '
            'You need a separate bank account for your business. '
            'Bring: business registration documents, your ID, proof of address. '
            'Some banks are stricter with non-citizens -- if one bank refuses, try another. '
            'Online banks (like Holvi, N26 Business) may be easier.',
        'STEP 8: CHECK WHAT LICENSES OR PERMITS YOU NEED. '
            'Some businesses need special licenses: food service, healthcare, '
            'transport, financial services, childcare, construction. '
            'Contact your local business advisory service (free in most EU countries) '
            'to check what your specific business needs.',
        'STEP 9: UNDERSTAND YOUR TAX OBLIGATIONS. '
            'You will need to: file tax returns (quarterly or annually), '
            'pay income tax on profits, pay VAT if registered, '
            'pay social security contributions (for yourself and any employees). '
            'Get an accountant or use accounting software from the start.',
        'STEP 10: PROTECT YOURSELF WITH INSURANCE. '
            'Consider: business liability insurance, '
            'personal accident/health insurance (especially if self-employed), '
            'product liability insurance (if selling products). '
            'In Finland, self-employed persons MUST have YEL pension insurance.',
        'STEP 11: USE FREE BUSINESS SUPPORT SERVICES. '
            'Most EU countries offer FREE help for new businesses: '
            'Finland: Enterprise Finland (Yritys-Suomi), NewCo Helsinki. '
            'Germany: Gruenderplattform, IHK (Chamber of Commerce). '
            'These provide: business advice, mentoring, networking, '
            'and sometimes grants or subsidized loans.',
        'STEP 12: CONSIDER FUNDING OPTIONS. '
            'Options: personal savings, bank loans (harder for immigrants), '
            'startup grants (Finland: TE-Office startup grant covers 6 months of living expenses), '
            'microfinance loans, EU-funded programs for entrepreneurs, '
            'crowdfunding, angel investors.',
        'STEP 13: KEEP YOUR IMMIGRATION STATUS VALID. '
            'Starting a business may affect your residence permit. '
            'Make sure: your permit covers self-employment, '
            'you meet any income requirements, '
            'you apply for renewal on time. '
            'If your business fails, you may need to switch to another permit type.',
      ],
      doNots: [
        'DO NOT start operating a business without proper registration -- it can lead to fines and tax problems.',
        'DO NOT mix personal and business finances -- always use a separate account.',
        'DO NOT forget about tax obligations -- unpaid taxes can affect your residence permit.',
        'DO NOT sign long-term leases or contracts before validating your business idea.',
        'DO NOT ignore insurance requirements -- especially mandatory ones like YEL in Finland.',
        'DO NOT pay for "business setup" services that charge thousands -- registration is cheap and simple.',
        'DO NOT forget to check if your business activity requires special permits or licenses.',
      ],
      documentsNeeded: [
        'Valid passport and residence permit',
        'Proof of address in the EU country',
        'Business plan (3-5 pages)',
        'Business registration form (from the national registry)',
        'Tax registration form',
        'Bank documents for opening a business account',
        'Professional qualifications (if applicable for your business type)',
        'Any required licenses or permits',
        'Insurance documents (liability, pension)',
        'Proof of initial funding/capital (if registering a limited company)',
      ],
      typicalTimeline:
          'Planning and business plan: 1-4 weeks. '
          'Business registration: 1-7 days. '
          'Tax registration: 1-2 weeks. '
          'Bank account: 1-4 weeks. '
          'Licenses (if needed): 2-12 weeks. '
          'Startup visa (if needed): 1-6 months. '
          'Total from idea to operating: 1-3 months.',
      costEstimate:
          'Business registration: 0-300 EUR depending on business form and country. '
          'Finland sole proprietorship: 60 EUR. Finland LLC: 240 EUR. '
          'Accountant: 50-200 EUR/month for small businesses. '
          'Insurance: 100-500 EUR/month. '
          'Startup grant (Finland): up to 700 EUR/month for 6-12 months. '
          'Total initial costs: 300-2000 EUR (not counting the business itself).',
      legalBasis:
          'EU Treaty Articles 49 and 56 (freedom of establishment and services for EU citizens). '
          'EU Self-Employment Directive (equal treatment of EU citizens). '
          'National business registration laws. '
          'National tax codes. '
          'Finland: Trade Register Act, YEL (Self-Employed Persons Pensions Act). '
          'Startup visa regulations vary by country.',
    ),

    // =========================================================================
    // GUIDE 15: CHILD NEEDS SCHOOL BUT NO PAPERS
    // =========================================================================
    PracticalGuide(
      id: 'child_school_no_papers',
      title: 'My child needs to go to school but we have no papers',
      urgencyLevel: 'urgent',
      steps: [
        'STEP 1: YOUR CHILD HAS THE RIGHT TO EDUCATION REGARDLESS OF IMMIGRATION STATUS. '
            'This is not a favor -- it is a fundamental right under international and EU law. '
            'Every child in the EU has the right to go to school, whether they are: '
            'documented, undocumented, asylum seekers, refugees, or any other status. '
            'No school can refuse your child because of missing immigration papers.',
        'STEP 2: EDUCATION IS COMPULSORY -- AND THAT PROTECTS YOUR CHILD. '
            'In every EU country, education is compulsory for children (usually ages 6-16). '
            'This means the government MUST provide a school place for your child. '
            'Schools are legally required to accept children in their area.',
        'STEP 3: CONTACT THE LOCAL SCHOOL OR MUNICIPALITY EDUCATION OFFICE. '
            'Go to the nearest school or the municipal education department. '
            'Say: "I want to enroll my child in school." '
            'You do NOT need to reveal your immigration status. '
            'In Finland: contact the education department (sivistystoimi) of your municipality.',
        'STEP 4: WHAT DOCUMENTS YOU NEED (MINIMAL). '
            'Schools typically need: the child\'s name and date of birth, '
            'your address (where you live), any previous school records (if available). '
            'Schools should NOT require: a residence permit, social security number, '
            'or passport as a condition for enrollment. '
            'If they ask and you do not have them, explain your situation.',
        'STEP 5: IF THE SCHOOL REFUSES YOUR CHILD, ESCALATE. '
            'If a school says no, do not give up. Contact: '
            'the municipal education office (they can order the school to accept), '
            'the regional education authority, '
            'a children\'s rights NGO, '
            'the ombudsman for children. '
            'Refusal to educate a child is a violation of the law.',
        'STEP 6: ASK ABOUT PREPARATORY OR TRANSITION CLASSES. '
            'Many EU countries have special classes to help immigrant children: '
            'language preparation classes, transition classes, welcome classes. '
            'Finland: preparatory education (valmistava opetus) -- 1 year of intensive Finnish/Swedish '
            'before or alongside regular classes. These are free.',
        'STEP 7: YOUR CHILD\'S INFORMATION IS PROTECTED. '
            'Schools should NOT report your immigration status to police or immigration authorities. '
            'In most EU countries, there is a "firewall" between education and immigration enforcement. '
            'Ask the school about their confidentiality policy. '
            'If you are worried, contact an NGO for advice before enrolling.',
        'STEP 8: SCHOOL IS FREE -- INCLUDING EXTRAS. '
            'In most EU countries, public school is completely free: no tuition, '
            'free textbooks, free lunch (Finland: free lunch for all students), '
            'free transportation (if the school is far). '
            'If the school asks for money, ask what financial assistance is available.',
        'STEP 9: YOUR CHILD MAY NEED SPECIAL SUPPORT. '
            'If your child has trauma, learning difficulties, or special needs, '
            'tell the school. They must provide: language support, '
            'psychological support, special education services if needed. '
            'All of this is free.',
        'STEP 10: CONNECT WITH OTHER FAMILIES. '
            'Other immigrant families in the school can help: share information, '
            'provide translation help, offer emotional support. '
            'Ask the school if there is a parent group for international families.',
        'STEP 11: HELP YOUR CHILD ADJUST. '
            'Starting school in a new country is hard for children. '
            'Expect: a language adjustment period (3-12 months to become comfortable), '
            'possible bullying (report to the school immediately), '
            'cultural differences. Be patient and supportive.',
        'STEP 12: OLDER CHILDREN (16+) HAVE OPTIONS TOO. '
            'If your child is over compulsory school age: '
            'they may still attend high school or vocational school, '
            'adult education centers (kansalaisopisto in Finland) offer language and skills courses, '
            'some countries have programs specifically for young migrants aged 16-25.',
        'STEP 13: USE SCHOOL AS A GATEWAY TO OTHER SERVICES. '
            'Through school, your family can access: health checkups for children, '
            'social worker support, after-school activities, '
            'language courses for parents, community connections. '
            'School is not just education -- it is a support system.',
      ],
      doNots: [
        'DO NOT keep your child out of school because you fear deportation -- education is protected and schools do not report to immigration.',
        'DO NOT accept "we cannot enroll without papers" -- the law requires schools to accept all children.',
        'DO NOT send your child to an unregistered or informal school -- they deserve proper education.',
        'DO NOT be afraid to ask for language support -- it is your child\'s right.',
        'DO NOT wait "until the situation is resolved" -- every day out of school is a day lost.',
        'DO NOT sign documents you do not understand -- ask for an interpreter.',
        'DO NOT let anyone charge you money for public school enrollment -- it is free.',
      ],
      documentsNeeded: [
        'Child\'s name and date of birth (birth certificate if available, but not always required)',
        'Your contact information and address',
        'Previous school records or report cards (if available, translated if possible)',
        'Vaccination records (if available -- many countries require certain vaccinations for school)',
        'Any medical information relevant to the child\'s education',
        'Photo of the child (for school records)',
        'Emergency contact information',
        'Note: a residence permit or social security number is NOT required for enrollment in most EU countries',
      ],
      typicalTimeline:
          'Enrollment: can happen within days to 2 weeks. '
          'Preparatory classes: start within 1-4 weeks of enrollment. '
          'Transition to regular classes: 6-12 months of language preparation. '
          'Full integration into the school system: 1-2 years.',
      costEstimate:
          'Public school enrollment: FREE. '
          'Textbooks: FREE in most EU countries. '
          'School lunch: FREE (Finland, Sweden) or very low cost (others). '
          'Transportation: FREE or subsidized if the school is not within walking distance. '
          'After-school activities: usually FREE or very low cost. '
          'Total cost: 0 EUR in most cases.',
      legalBasis:
          'UN Convention on the Rights of the Child, Article 28 (right to education). '
          'EU Charter of Fundamental Rights, Article 14 (right to education). '
          'EU Reception Conditions Directive 2013/33/EU, Article 14 (education for asylum seeker children). '
          'ECHR Protocol 1, Article 2 (right to education). '
          'National education laws: Finland Basic Education Act (Perusopetuslaki 628/1998) -- '
          'municipalities must provide education for all children living in their area.',
    ),
  ];

  /// Get a guide by its ID
  static PracticalGuide? getGuideById(String id) {
    try {
      return allGuides.firstWhere((guide) => guide.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all guides of a specific urgency level
  static List<PracticalGuide> getGuidesByUrgency(String urgencyLevel) {
    return allGuides
        .where((guide) => guide.urgencyLevel == urgencyLevel)
        .toList();
  }

  /// Get all emergency guides (highest priority)
  static List<PracticalGuide> getEmergencyGuides() {
    return getGuidesByUrgency('emergency');
  }

  /// Get all urgent guides
  static List<PracticalGuide> getUrgentGuides() {
    return getGuidesByUrgency('urgent');
  }

  /// Search guides by keyword in title or steps
  static List<PracticalGuide> searchGuides(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return allGuides.where((guide) {
      if (guide.title.toLowerCase().contains(lowerKeyword)) return true;
      for (final step in guide.steps) {
        if (step.toLowerCase().contains(lowerKeyword)) return true;
      }
      for (final doNot in guide.doNots) {
        if (doNot.toLowerCase().contains(lowerKeyword)) return true;
      }
      return false;
    }).toList();
  }

  /// Get all guide titles for display in a list
  static List<Map<String, String>> getGuideTitles() {
    return allGuides
        .map((guide) => <String, String>{
              'id': guide.id,
              'title': guide.title,
              'urgencyLevel': guide.urgencyLevel,
            })
        .toList();
  }

  /// Get guides sorted by urgency (emergency first)
  static List<PracticalGuide> getGuidesSortedByUrgency() {
    final urgencyOrder = {
      'emergency': 0,
      'urgent': 1,
      'important': 2,
      'planning': 3,
    };
    final sorted = List<PracticalGuide>.from(allGuides);
    sorted.sort((a, b) {
      final aOrder = urgencyOrder[a.urgencyLevel] ?? 4;
      final bOrder = urgencyOrder[b.urgencyLevel] ?? 4;
      return aOrder.compareTo(bOrder);
    });
    return sorted;
  }

  /// Get the count of guides by urgency level
  static Map<String, int> getUrgencyCounts() {
    final counts = <String, int>{};
    for (final guide in allGuides) {
      counts[guide.urgencyLevel] = (counts[guide.urgencyLevel] ?? 0) + 1;
    }
    return counts;
  }
}
