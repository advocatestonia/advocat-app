// Vorantis OÜ trader identification — required by ITSS § 4 + e-Commerce Dir Art 5
(function() {
  var lang = document.documentElement.lang || 'et';
  var t = {
    et: {
      reg: 'Vorantis OÜ · Reg 17098992 · Tornimäe tn 5, 15010 Tallinn, Eesti',
      contact: 'Kontakt: ',
      privacy: 'Privaatsus',
      terms: 'Tingimused',
      disclaimer: 'Infoteenus. Ei ole õigusabi ega asenda vandeadvokaati. Vorantis OÜ on registreeritud Eesti äriregistris; teenust reguleerib Infoühiskonna teenuse seadus § 4.'
    },
    en: {
      reg: 'Vorantis OÜ · Reg 17098992 · Tornimäe tn 5, 15010 Tallinn, Estonia',
      contact: 'Contact: ',
      privacy: 'Privacy',
      terms: 'Terms',
      disclaimer: 'Information service. Not legal advice. Vorantis OÜ is registered in the Estonian Commercial Register; service regulated under Infoühiskonna teenuse seadus § 4.'
    },
    ru: {
      reg: 'Vorantis OÜ · Рег. 17098992 · Tornimäe tn 5, 15010 Tallinn, Эстония',
      contact: 'Контакт: ',
      privacy: 'Конфиденциальность',
      terms: 'Условия',
      disclaimer: 'Информационный сервис. Не является юридическим советом. Vorantis OÜ зарегистрирована в Коммерческом реестре Эстонии; услуга регулируется Infoühiskonna teenuse seadus § 4.'
    }
  };
  var s = t[lang] || t.et;
  var html = '<footer class="blog-trader-footer" style="margin-top:48px;padding:24px 16px;border-top:1px solid #e5e7eb;font-size:13px;color:#4b5563;line-height:1.5;text-align:center;">' +
    '<p style="margin:0 0 8px;"><strong>' + s.reg + '</strong></p>' +
    '<p style="margin:0 0 8px;">' + s.contact + '<a href="mailto:support@advocat.ee" style="color:#0d9488;">support@advocat.ee</a> · ' +
    '<a href="/privacy.html" style="color:#0d9488;">' + s.privacy + '</a> · ' +
    '<a href="/terms.html" style="color:#0d9488;">' + s.terms + '</a></p>' +
    '<p style="margin:0;font-size:11px;color:#6b7280;">' + s.disclaimer + '</p>' +
    '</footer>';
  // Inject before existing footer or at end of body
  var existingFooter = document.querySelector('footer');
  if (existingFooter) {
    existingFooter.insertAdjacentHTML('beforebegin', html);
  } else {
    document.body.insertAdjacentHTML('beforeend', html);
  }
})();
