#!/usr/bin/env python3
"""
Pluralize selected ARB keys across all 17 locales using ICU MessageFormat.

For RU/PL/UK/LT: emit `one`/`few`/`many`/`other` (and `=0` where useful).
For LV: emit `zero`/`one`/`other`.
For other locales (EN/FI/ET/DE/FR/ES/IT/SV/RO/TR/AR/FA): emit `=1` + `other`
which is valid CLDR fallback (other is the catch-all category).

This script does TARGETED line-by-line replacement on the existing ARB JSON
to preserve the surrounding formatting (4-space indent, key order,
@meta blocks, comments-in-values).

Run from project root (advocat_project/):
    python3 scripts/i18n_pluralize.py
"""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
L10N = ROOT / "lib" / "l10n"

# `_` in form values is a placeholder for `{count}`.
KEYS = {
    "daysRemaining": {
        "en": {"=0": "no days remaining", "=1": "1 day", "other": "_ days"},
        "ru": {"=0": "дней не осталось", "one": "_ день", "few": "_ дня", "many": "_ дней", "other": "_ дня"},
        "pl": {"=0": "brak pozostałych dni", "one": "1 dzień", "few": "_ dni", "many": "_ dni", "other": "_ dni"},
        "uk": {"=0": "днів не залишилось", "one": "_ день", "few": "_ дні", "many": "_ днів", "other": "_ днів"},
        "lt": {"=0": "dienų nebeliko", "one": "_ diena", "few": "_ dienos", "many": "_ dienos", "other": "_ dienų"},
        "lv": {"zero": "_ dienu", "one": "_ diena", "other": "_ dienas"},
        "fi": {"=0": "ei jäljellä päiviä", "=1": "1 päivä", "other": "_ päivää"},
        "et": {"=0": "päevi pole jäänud", "=1": "1 päev", "other": "_ päeva"},
        "de": {"=0": "keine Tage übrig", "=1": "1 Tag", "other": "_ Tage"},
        "fr": {"=0": "aucun jour restant", "=1": "1 jour", "other": "_ jours"},
        "es": {"=0": "ningún día restante", "=1": "1 día", "other": "_ días"},
        "it": {"=0": "nessun giorno rimanente", "=1": "1 giorno", "other": "_ giorni"},
        "sv": {"=0": "inga dagar kvar", "=1": "1 dag", "other": "_ dagar"},
        "ro": {"=0": "nicio zi rămasă", "=1": "1 zi", "other": "_ zile"},
        "tr": {"=0": "kalan gün yok", "other": "_ gün"},
        "ar": {"=0": "لا توجد أيام متبقية", "=1": "يوم واحد", "other": "_ أيام"},
        "fa": {"=0": "روزی باقی نمانده", "=1": "۱ روز", "other": "_ روز"},
    },
    "documentsCount": {
        "en": {"=0": "no documents", "=1": "1 document", "other": "_ documents"},
        "ru": {"=0": "нет документов", "one": "_ документ", "few": "_ документа", "many": "_ документов", "other": "_ документа"},
        "pl": {"=0": "brak dokumentów", "one": "1 dokument", "few": "_ dokumenty", "many": "_ dokumentów", "other": "_ dokumentów"},
        "uk": {"=0": "немає документів", "one": "_ документ", "few": "_ документи", "many": "_ документів", "other": "_ документів"},
        "lt": {"=0": "dokumentų nėra", "one": "_ dokumentas", "few": "_ dokumentai", "many": "_ dokumento", "other": "_ dokumentų"},
        "lv": {"zero": "_ dokumentu", "one": "_ dokuments", "other": "_ dokumenti"},
        "fi": {"=0": "ei asiakirjoja", "=1": "1 asiakirja", "other": "_ asiakirjaa"},
        "et": {"=0": "dokumente pole", "=1": "1 dokument", "other": "_ dokumenti"},
        "de": {"=0": "keine Dokumente", "=1": "1 Dokument", "other": "_ Dokumente"},
        "fr": {"=0": "aucun document", "=1": "1 document", "other": "_ documents"},
        "es": {"=0": "ningún documento", "=1": "1 documento", "other": "_ documentos"},
        "it": {"=0": "nessun documento", "=1": "1 documento", "other": "_ documenti"},
        "sv": {"=0": "inga dokument", "=1": "1 dokument", "other": "_ dokument"},
        "ro": {"=0": "niciun document", "=1": "1 document", "other": "_ documente"},
        "tr": {"=0": "belge yok", "other": "_ belge"},
        "ar": {"=0": "لا توجد مستندات", "=1": "مستند واحد", "other": "_ مستندات"},
        "fa": {"=0": "بدون سند", "=1": "۱ سند", "other": "_ سند"},
    },
    "issuesFound": {
        "en": {"=0": "no issues found", "=1": "1 issue found", "other": "_ issues found"},
        "ru": {"=0": "проблем не найдено", "one": "Найдена _ проблема", "few": "Найдено _ проблемы", "many": "Найдено _ проблем", "other": "Найдено _ проблем"},
        "pl": {"=0": "nie znaleziono problemów", "one": "Znaleziono 1 problem", "few": "Znaleziono _ problemy", "many": "Znaleziono _ problemów", "other": "Znaleziono _ problemów"},
        "uk": {"=0": "проблем не знайдено", "one": "Знайдено _ проблему", "few": "Знайдено _ проблеми", "many": "Знайдено _ проблем", "other": "Знайдено _ проблем"},
        "lt": {"=0": "problemų nerasta", "one": "Rasta _ problema", "few": "Rasta _ problemos", "many": "Rasta _ problemos", "other": "Rasta _ problemų"},
        "lv": {"zero": "Atrastas _ problēmas", "one": "Atrasta _ problēma", "other": "Atrastas _ problēmas"},
        "fi": {"=0": "ei löytynyt ongelmia", "=1": "1 ongelma löytyi", "other": "_ ongelmaa löytyi"},
        "et": {"=0": "probleeme ei leitud", "=1": "Leitud 1 probleem", "other": "Leitud _ probleemi"},
        "de": {"=0": "keine Probleme gefunden", "=1": "1 Problem gefunden", "other": "_ Probleme gefunden"},
        "fr": {"=0": "aucun problème trouvé", "=1": "1 problème trouvé", "other": "_ problèmes trouvés"},
        "es": {"=0": "no se encontraron problemas", "=1": "1 problema encontrado", "other": "_ problemas encontrados"},
        "it": {"=0": "nessun problema trovato", "=1": "1 problema trovato", "other": "_ problemi trovati"},
        "sv": {"=0": "inga problem hittades", "=1": "1 problem hittat", "other": "_ problem hittade"},
        "ro": {"=0": "nicio problemă găsită", "=1": "1 problemă găsită", "other": "_ probleme găsite"},
        "tr": {"=0": "sorun bulunamadı", "other": "_ sorun bulundu"},
        "ar": {"=0": "لم يتم العثور على مشاكل", "=1": "تم العثور على مشكلة واحدة", "other": "تم العثور على _ مشاكل"},
        "fa": {"=0": "مشکلی یافت نشد", "=1": "۱ مشکل یافت شد", "other": "_ مشکل یافت شد"},
    },
    "issuesFoundInDocument": {
        "en": {"=0": "No issues found in your document", "=1": "Found 1 issue in your document", "other": "Found _ issues in your document"},
        "ru": {"=0": "В документе проблем не найдено", "one": "В документе найдена _ проблема", "few": "В документе найдено _ проблемы", "many": "В документе найдено _ проблем", "other": "В документе найдено _ проблем"},
        "pl": {"=0": "Nie znaleziono problemów w dokumencie", "one": "Znaleziono 1 problem w dokumencie", "few": "Znaleziono _ problemy w dokumencie", "many": "Znaleziono _ problemów w dokumencie", "other": "Znaleziono _ problemów w dokumencie"},
        "uk": {"=0": "У документі проблем не знайдено", "one": "У документі знайдено _ проблему", "few": "У документі знайдено _ проблеми", "many": "У документі знайдено _ проблем", "other": "У документі знайдено _ проблем"},
        "lt": {"=0": "Dokumente problemų nerasta", "one": "Dokumente rasta _ problema", "few": "Dokumente rasta _ problemos", "many": "Dokumente rasta _ problemos", "other": "Dokumente rasta _ problemų"},
        "lv": {"zero": "Dokumentā atrastas _ problēmas", "one": "Dokumentā atrasta _ problēma", "other": "Dokumentā atrastas _ problēmas"},
        "fi": {"=0": "Asiakirjasta ei löytynyt ongelmia", "=1": "Asiakirjasta löytyi 1 ongelma", "other": "Asiakirjasta löytyi _ ongelmaa"},
        "et": {"=0": "Dokumendist probleeme ei leitud", "=1": "Dokumendist leitud 1 probleem", "other": "Dokumendist leitud _ probleemi"},
        "de": {"=0": "Keine Probleme im Dokument gefunden", "=1": "1 Problem im Dokument gefunden", "other": "_ Probleme im Dokument gefunden"},
        "fr": {"=0": "Aucun problème dans votre document", "=1": "1 problème trouvé dans votre document", "other": "_ problèmes trouvés dans votre document"},
        "es": {"=0": "No se encontraron problemas en su documento", "=1": "Se encontró 1 problema en su documento", "other": "Se encontraron _ problemas en su documento"},
        "it": {"=0": "Nessun problema nel documento", "=1": "Trovato 1 problema nel documento", "other": "Trovati _ problemi nel documento"},
        "sv": {"=0": "Inga problem hittades i dokumentet", "=1": "1 problem hittat i dokumentet", "other": "_ problem hittade i dokumentet"},
        "ro": {"=0": "Nicio problemă în documentul dvs.", "=1": "1 problemă găsită în documentul dvs.", "other": "_ probleme găsite în documentul dvs."},
        "tr": {"=0": "Belgenizde sorun bulunamadı", "other": "Belgenizde _ sorun bulundu"},
        "ar": {"=0": "لم يتم العثور على مشاكل في المستند", "=1": "تم العثور على مشكلة واحدة في المستند", "other": "تم العثور على _ مشاكل في المستند"},
        "fa": {"=0": "مشکلی در سند یافت نشد", "=1": "۱ مشکل در سند یافت شد", "other": "_ مشکل در سند یافت شد"},
    },
    "generateAppealWithIssues": {
        "en": {"=1": "Generate Appeal (1 issue)", "other": "Generate Appeal (_ issues)"},
        "ru": {"one": "Сформировать жалобу (_ проблема)", "few": "Сформировать жалобу (_ проблемы)", "many": "Сформировать жалобу (_ проблем)", "other": "Сформировать жалобу (_ проблем)"},
        "pl": {"one": "Wygeneruj odwołanie (1 problem)", "few": "Wygeneruj odwołanie (_ problemy)", "many": "Wygeneruj odwołanie (_ problemów)", "other": "Wygeneruj odwołanie (_ problemów)"},
        "uk": {"one": "Створити оскарження (_ проблема)", "few": "Створити оскарження (_ проблеми)", "many": "Створити оскарження (_ проблем)", "other": "Створити оскарження (_ проблем)"},
        "lt": {"one": "Generuoti apeliaciją (_ problema)", "few": "Generuoti apeliaciją (_ problemos)", "many": "Generuoti apeliaciją (_ problemos)", "other": "Generuoti apeliaciją (_ problemų)"},
        "lv": {"zero": "Ģenerēt apelāciju (_ problēmas)", "one": "Ģenerēt apelāciju (_ problēma)", "other": "Ģenerēt apelāciju (_ problēmas)"},
        "fi": {"=1": "Luo valitus (1 ongelma)", "other": "Luo valitus (_ ongelmaa)"},
        "et": {"=1": "Loo apellatsioon (1 probleem)", "other": "Loo apellatsioon (_ probleemi)"},
        "de": {"=1": "Beschwerde erstellen (1 Problem)", "other": "Beschwerde erstellen (_ Probleme)"},
        "fr": {"=1": "Générer un recours (1 problème)", "other": "Générer un recours (_ problèmes)"},
        "es": {"=1": "Generar apelación (1 problema)", "other": "Generar apelación (_ problemas)"},
        "it": {"=1": "Genera ricorso (1 problema)", "other": "Genera ricorso (_ problemi)"},
        "sv": {"=1": "Skapa överklagande (1 problem)", "other": "Skapa överklagande (_ problem)"},
        "ro": {"=1": "Generează apel (1 problemă)", "other": "Generează apel (_ probleme)"},
        "tr": {"other": "İtiraz Oluştur (_ sorun)"},
        "ar": {"=1": "إنشاء طعن (مشكلة واحدة)", "other": "إنشاء طعن (_ مشاكل)"},
        "fa": {"=1": "ایجاد دادخواست (۱ مشکل)", "other": "ایجاد دادخواست (_ مشکل)"},
    },
    "pageCount": {
        "en": {"=0": "no pages", "=1": "1 page", "other": "_ pages"},
        "ru": {"=0": "нет страниц", "one": "_ страница", "few": "_ страницы", "many": "_ страниц", "other": "_ страницы"},
        "pl": {"=0": "brak stron", "one": "1 strona", "few": "_ strony", "many": "_ stron", "other": "_ stron"},
        "uk": {"=0": "немає сторінок", "one": "_ сторінка", "few": "_ сторінки", "many": "_ сторінок", "other": "_ сторінок"},
        "lt": {"=0": "puslapių nėra", "one": "_ puslapis", "few": "_ puslapiai", "many": "_ puslapio", "other": "_ puslapių"},
        "lv": {"zero": "_ lapu", "one": "_ lapa", "other": "_ lapas"},
        "fi": {"=0": "ei sivuja", "=1": "1 sivu", "other": "_ sivua"},
        "et": {"=0": "lehekülgi pole", "=1": "1 lehekülg", "other": "_ lehekülge"},
        "de": {"=0": "keine Seiten", "=1": "1 Seite", "other": "_ Seiten"},
        "fr": {"=0": "aucune page", "=1": "1 page", "other": "_ pages"},
        "es": {"=0": "ninguna página", "=1": "1 página", "other": "_ páginas"},
        "it": {"=0": "nessuna pagina", "=1": "1 pagina", "other": "_ pagine"},
        "sv": {"=0": "inga sidor", "=1": "1 sida", "other": "_ sidor"},
        "ro": {"=0": "nicio pagină", "=1": "1 pagină", "other": "_ pagini"},
        "tr": {"=0": "sayfa yok", "other": "_ sayfa"},
        "ar": {"=0": "لا توجد صفحات", "=1": "صفحة واحدة", "other": "_ صفحات"},
        "fa": {"=0": "بدون صفحه", "=1": "۱ صفحه", "other": "_ صفحه"},
    },
    "pagesUploadedSuccess": {
        "en": {"=1": "1 page uploaded successfully", "other": "_ pages uploaded successfully"},
        "ru": {"one": "Загружена _ страница", "few": "Загружено _ страницы", "many": "Загружено _ страниц", "other": "Загружено _ страниц"},
        "pl": {"one": "1 strona przesłana pomyślnie", "few": "_ strony przesłane pomyślnie", "many": "_ stron przesłanych pomyślnie", "other": "_ stron przesłanych pomyślnie"},
        "uk": {"one": "_ сторінка успішно завантажена", "few": "_ сторінки успішно завантажено", "many": "_ сторінок успішно завантажено", "other": "_ сторінок успішно завантажено"},
        "lt": {"one": "Sėkmingai įkeltas _ puslapis", "few": "Sėkmingai įkelti _ puslapiai", "many": "Sėkmingai įkelti _ puslapio", "other": "Sėkmingai įkelta _ puslapių"},
        "lv": {"zero": "_ lapas veiksmīgi augšupielādētas", "one": "_ lapa veiksmīgi augšupielādēta", "other": "_ lapas veiksmīgi augšupielādētas"},
        "fi": {"=1": "1 sivu ladattu onnistuneesti", "other": "_ sivua ladattu onnistuneesti"},
        "et": {"=1": "1 lehekülg laaditud edukalt", "other": "_ lehekülge laaditud edukalt"},
        "de": {"=1": "1 Seite erfolgreich hochgeladen", "other": "_ Seiten erfolgreich hochgeladen"},
        "fr": {"=1": "1 page téléchargée avec succès", "other": "_ pages téléchargées avec succès"},
        "es": {"=1": "1 página subida con éxito", "other": "_ páginas subidas con éxito"},
        "it": {"=1": "1 pagina caricata con successo", "other": "_ pagine caricate con successo"},
        "sv": {"=1": "1 sida laddades upp", "other": "_ sidor laddades upp"},
        "ro": {"=1": "1 pagină încărcată cu succes", "other": "_ pagini încărcate cu succes"},
        "tr": {"other": "_ sayfa başarıyla yüklendi"},
        "ar": {"=1": "تم تحميل صفحة واحدة بنجاح", "other": "تم تحميل _ صفحات بنجاح"},
        "fa": {"=1": "۱ صفحه با موفقیت بارگذاری شد", "other": "_ صفحه با موفقیت بارگذاری شد"},
    },
    "rightsInsideCount": {
        "en": {"=0": "no rights inside", "=1": "1 right inside", "other": "_ rights inside"},
        "ru": {"=0": "нет прав внутри", "one": "_ право внутри", "few": "_ права внутри", "many": "_ прав внутри", "other": "_ прав внутри"},
        "pl": {"=0": "brak praw w środku", "one": "1 prawo w środku", "few": "_ prawa w środku", "many": "_ praw w środku", "other": "_ praw w środku"},
        "uk": {"=0": "немає прав всередині", "one": "_ право всередині", "few": "_ права всередині", "many": "_ прав всередині", "other": "_ прав всередині"},
        "lt": {"=0": "teisių nėra", "one": "_ teisė viduje", "few": "_ teisės viduje", "many": "_ teisės viduje", "other": "_ teisių viduje"},
        "lv": {"zero": "_ tiesību iekšā", "one": "_ tiesība iekšā", "other": "_ tiesības iekšā"},
        "fi": {"=0": "ei oikeuksia", "=1": "1 oikeus sisällä", "other": "_ oikeutta sisällä"},
        "et": {"=0": "õigusi pole", "=1": "1 õigus sees", "other": "_ õigust sees"},
        "de": {"=0": "keine Rechte", "=1": "1 Recht enthalten", "other": "_ Rechte enthalten"},
        "fr": {"=0": "aucun droit à l'intérieur", "=1": "1 droit à l'intérieur", "other": "_ droits à l'intérieur"},
        "es": {"=0": "ningún derecho dentro", "=1": "1 derecho dentro", "other": "_ derechos dentro"},
        "it": {"=0": "nessun diritto incluso", "=1": "1 diritto incluso", "other": "_ diritti inclusi"},
        "sv": {"=0": "inga rättigheter", "=1": "1 rättighet inkluderad", "other": "_ rättigheter inkluderade"},
        "ro": {"=0": "niciun drept înăuntru", "=1": "1 drept înăuntru", "other": "_ drepturi înăuntru"},
        "tr": {"=0": "hak yok", "other": "İçinde _ hak var"},
        "ar": {"=0": "لا توجد حقوق", "=1": "حق واحد بالداخل", "other": "_ حقوق بالداخل"},
        "fa": {"=0": "بدون حق", "=1": "۱ حق در داخل", "other": "_ حق در داخل"},
    },
    "citationFooterSummaryTotal": {
        "en": {"=1": "1 citation", "other": "_ citations"},
        "ru": {"one": "_ ссылка", "few": "_ ссылки", "many": "_ ссылок", "other": "_ ссылок"},
        "pl": {"one": "1 cytat", "few": "_ cytaty", "many": "_ cytatów", "other": "_ cytatów"},
        "uk": {"one": "_ посилання", "few": "_ посилання", "many": "_ посилань", "other": "_ посилань"},
        "lt": {"one": "_ citata", "few": "_ citatos", "many": "_ citatos", "other": "_ citatų"},
        "lv": {"zero": "_ citātu", "one": "_ citāts", "other": "_ citāti"},
        "fi": {"=1": "1 viittaus", "other": "_ viittausta"},
        "et": {"=1": "1 viide", "other": "_ viidet"},
        "de": {"=1": "1 Zitat", "other": "_ Zitate"},
        "fr": {"=1": "1 citation", "other": "_ citations"},
        "es": {"=1": "1 cita", "other": "_ citas"},
        "it": {"=1": "1 citazione", "other": "_ citazioni"},
        "sv": {"=1": "1 citat", "other": "_ citat"},
        "ro": {"=1": "1 citare", "other": "_ citări"},
        "tr": {"other": "_ alıntı"},
        "ar": {"=1": "اقتباس واحد", "other": "_ اقتباسات"},
        "fa": {"=1": "۱ نقل قول", "other": "_ نقل قول"},
    },
    "citationFooterSummaryVerified": {
        "en": {"=1": "1 verified", "other": "_ verified"},
        "ru": {"one": "_ проверена", "few": "_ проверены", "many": "_ проверено", "other": "_ проверено"},
        "pl": {"one": "1 zweryfikowany", "few": "_ zweryfikowane", "many": "_ zweryfikowanych", "other": "_ zweryfikowanych"},
        "uk": {"one": "_ перевірено", "few": "_ перевірено", "many": "_ перевірено", "other": "_ перевірено"},
        "lt": {"one": "_ patvirtinta", "few": "_ patvirtintos", "many": "_ patvirtintos", "other": "_ patvirtintų"},
        "lv": {"zero": "_ pārbaudītu", "one": "_ pārbaudīts", "other": "_ pārbaudīti"},
        "fi": {"=1": "1 vahvistettu", "other": "_ vahvistettua"},
        "et": {"=1": "1 kinnitatud", "other": "_ kinnitatud"},
        "de": {"=1": "1 verifiziert", "other": "_ verifiziert"},
        "fr": {"=1": "1 vérifiée", "other": "_ vérifiées"},
        "es": {"=1": "1 verificada", "other": "_ verificadas"},
        "it": {"=1": "1 verificata", "other": "_ verificate"},
        "sv": {"=1": "1 verifierat", "other": "_ verifierade"},
        "ro": {"=1": "1 verificată", "other": "_ verificate"},
        "tr": {"other": "_ doğrulanmış"},
        "ar": {"=1": "تم التحقق من واحد", "other": "تم التحقق من _"},
        "fa": {"=1": "۱ تأیید شده", "other": "_ تأیید شده"},
    },
    "citationFooterSummaryUnverified": {
        "en": {"=1": "1 unverified", "other": "_ unverified"},
        "ru": {"one": "_ непроверенная", "few": "_ непроверенные", "many": "_ непроверенных", "other": "_ непроверенных"},
        "pl": {"one": "1 niezweryfikowany", "few": "_ niezweryfikowane", "many": "_ niezweryfikowanych", "other": "_ niezweryfikowanych"},
        "uk": {"one": "_ не перевірено", "few": "_ не перевірено", "many": "_ не перевірено", "other": "_ не перевірено"},
        "lt": {"one": "_ nepatvirtinta", "few": "_ nepatvirtintos", "many": "_ nepatvirtintos", "other": "_ nepatvirtintų"},
        "lv": {"zero": "_ nepārbaudītu", "one": "_ nepārbaudīts", "other": "_ nepārbaudīti"},
        "fi": {"=1": "1 vahvistamaton", "other": "_ vahvistamatonta"},
        "et": {"=1": "1 kinnitamata", "other": "_ kinnitamata"},
        "de": {"=1": "1 unverifiziert", "other": "_ unverifiziert"},
        "fr": {"=1": "1 non vérifiée", "other": "_ non vérifiées"},
        "es": {"=1": "1 no verificada", "other": "_ no verificadas"},
        "it": {"=1": "1 non verificata", "other": "_ non verificate"},
        "sv": {"=1": "1 overifierad", "other": "_ overifierade"},
        "ro": {"=1": "1 neverificată", "other": "_ neverificate"},
        "tr": {"other": "_ doğrulanmamış"},
        "ar": {"=1": "غير مُتحقق منه واحد", "other": "_ غير مُتحقق منها"},
        "fa": {"=1": "۱ تأیید نشده", "other": "_ تأیید نشده"},
    },
    "citationFooterSummaryHistorical": {
        "en": {"=1": "1 historical", "other": "_ historical"},
        "ru": {"one": "_ устаревшая", "few": "_ устаревшие", "many": "_ устаревших", "other": "_ устаревших"},
        "pl": {"one": "1 historyczny", "few": "_ historyczne", "many": "_ historycznych", "other": "_ historycznych"},
        "uk": {"one": "_ історичне", "few": "_ історичні", "many": "_ історичних", "other": "_ історичних"},
        "lt": {"one": "_ senoji redakcija", "few": "_ senosios redakcijos", "many": "_ senosios redakcijos", "other": "_ senųjų redakcijų"},
        "lv": {"zero": "_ vēsturisku", "one": "_ vēsturisks", "other": "_ vēsturiski"},
        "fi": {"=1": "1 vanhentunut", "other": "_ vanhentunutta"},
        "et": {"=1": "1 vananenud", "other": "_ vananenud"},
        "de": {"=1": "1 historisch", "other": "_ historisch"},
        "fr": {"=1": "1 historique", "other": "_ historiques"},
        "es": {"=1": "1 histórica", "other": "_ históricas"},
        "it": {"=1": "1 storica", "other": "_ storiche"},
        "sv": {"=1": "1 historisk", "other": "_ historiska"},
        "ro": {"=1": "1 istorică", "other": "_ istorice"},
        "tr": {"other": "_ tarihsel"},
        "ar": {"=1": "تاريخي واحد", "other": "_ تاريخية"},
        "fa": {"=1": "۱ تاریخی", "other": "_ تاریخی"},
    },
    "deadlineCardDaysLeft": {
        "en": {"=0": "today", "=1": "in 1 day", "other": "in _ days"},
        "ru": {"=0": "сегодня", "one": "через _ день", "few": "через _ дня", "many": "через _ дней", "other": "через _ дня"},
        "pl": {"=0": "dzisiaj", "one": "za 1 dzień", "few": "za _ dni", "many": "za _ dni", "other": "za _ dni"},
        "uk": {"=0": "сьогодні", "one": "через _ день", "few": "через _ дні", "many": "через _ днів", "other": "через _ днів"},
        "lt": {"=0": "šiandien", "one": "po _ dienos", "few": "po _ dienų", "many": "po _ dienos", "other": "po _ dienų"},
        "lv": {"zero": "pēc _ dienām", "one": "pēc _ dienas", "other": "pēc _ dienām"},
        "fi": {"=0": "tänään", "=1": "1 päivän kuluttua", "other": "_ päivän kuluttua"},
        "et": {"=0": "täna", "=1": "1 päeva pärast", "other": "_ päeva pärast"},
        "de": {"=0": "heute", "=1": "in 1 Tag", "other": "in _ Tagen"},
        "fr": {"=0": "aujourd'hui", "=1": "dans 1 jour", "other": "dans _ jours"},
        "es": {"=0": "hoy", "=1": "en 1 día", "other": "en _ días"},
        "it": {"=0": "oggi", "=1": "tra 1 giorno", "other": "tra _ giorni"},
        "sv": {"=0": "idag", "=1": "om 1 dag", "other": "om _ dagar"},
        "ro": {"=0": "astăzi", "=1": "în 1 zi", "other": "în _ zile"},
        "tr": {"=0": "bugün", "other": "_ gün içinde"},
        "ar": {"=0": "اليوم", "=1": "خلال يوم واحد", "other": "خلال _ أيام"},
        "fa": {"=0": "امروز", "=1": "۱ روز دیگر", "other": "_ روز دیگر"},
    },
    "deadlineCardOverdue": {
        "en": {"=1": "1 day overdue", "other": "_ days overdue"},
        "ru": {"one": "просрочено на _ день", "few": "просрочено на _ дня", "many": "просрочено на _ дней", "other": "просрочено на _ дня"},
        "pl": {"one": "1 dzień po terminie", "few": "_ dni po terminie", "many": "_ dni po terminie", "other": "_ dni po terminie"},
        "uk": {"one": "прострочено на _ день", "few": "прострочено на _ дні", "many": "прострочено на _ днів", "other": "прострочено на _ днів"},
        "lt": {"one": "vėluoja _ dieną", "few": "vėluoja _ dienas", "many": "vėluoja _ dienos", "other": "vėluoja _ dienų"},
        "lv": {"zero": "kavējas _ dienas", "one": "kavējas _ dienu", "other": "kavējas _ dienas"},
        "fi": {"=1": "1 päivä myöhässä", "other": "_ päivää myöhässä"},
        "et": {"=1": "1 päev hilinenud", "other": "_ päeva hilinenud"},
        "de": {"=1": "1 Tag überfällig", "other": "_ Tage überfällig"},
        "fr": {"=1": "1 jour de retard", "other": "_ jours de retard"},
        "es": {"=1": "1 día de retraso", "other": "_ días de retraso"},
        "it": {"=1": "1 giorno di ritardo", "other": "_ giorni di ritardo"},
        "sv": {"=1": "1 dag försenat", "other": "_ dagar försenat"},
        "ro": {"=1": "1 zi întârziere", "other": "_ zile întârziere"},
        "tr": {"other": "_ gün gecikme"},
        "ar": {"=1": "متأخر يوم واحد", "other": "متأخر _ أيام"},
        "fa": {"=1": "۱ روز تأخیر", "other": "_ روز تأخیر"},
    },
    "contractReviewsLeft": {
        "en": {"=0": "No contract reviews left this month", "=1": "1 contract review left this month", "other": "_ contract reviews left this month"},
        "ru": {"=0": "В этом месяце проверок договоров не осталось", "one": "Осталась _ проверка договоров в этом месяце", "few": "Осталось _ проверки договоров в этом месяце", "many": "Осталось _ проверок договоров в этом месяце", "other": "Осталось _ проверок договоров в этом месяце"},
        "pl": {"=0": "Brak przeglądów umów w tym miesiącu", "one": "Pozostał 1 przegląd umów w tym miesiącu", "few": "Pozostały _ przeglądy umów w tym miesiącu", "many": "Pozostało _ przeglądów umów w tym miesiącu", "other": "Pozostało _ przeglądów umów w tym miesiącu"},
        "uk": {"=0": "Цього місяця перевірок договорів не залишилось", "one": "Залишилась _ перевірка договорів цього місяця", "few": "Залишилось _ перевірки договорів цього місяця", "many": "Залишилось _ перевірок договорів цього місяця", "other": "Залишилось _ перевірок договорів цього місяця"},
        "lt": {"=0": "Šį mėnesį sutarčių peržiūrų nebeliko", "one": "Šį mėnesį liko _ sutarties peržiūra", "few": "Šį mėnesį liko _ sutarčių peržiūros", "many": "Šį mėnesį liko _ sutarčių peržiūros", "other": "Šį mėnesį liko _ sutarčių peržiūrų"},
        "lv": {"zero": "Šomēnes palikušas _ līgumu pārbaudes", "one": "Šomēnes palikusi _ līgumu pārbaude", "other": "Šomēnes palikušas _ līgumu pārbaudes"},
        "fi": {"=0": "Sopimustarkastuksia ei ole tässä kuussa jäljellä", "=1": "1 sopimustarkastus jäljellä tässä kuussa", "other": "_ sopimustarkastusta jäljellä tässä kuussa"},
        "et": {"=0": "Sel kuul lepinguülevaatuseid pole jäänud", "=1": "1 lepinguülevaatus sel kuul jäänud", "other": "_ lepinguülevaatust sel kuul jäänud"},
        "de": {"=0": "Diesen Monat keine Vertragsprüfungen übrig", "=1": "1 Vertragsprüfung diesen Monat übrig", "other": "_ Vertragsprüfungen diesen Monat übrig"},
        "fr": {"=0": "Aucune revue de contrat restante ce mois-ci", "=1": "1 revue de contrat restante ce mois-ci", "other": "_ revues de contrat restantes ce mois-ci"},
        "es": {"=0": "No quedan revisiones de contratos este mes", "=1": "1 revisión de contrato restante este mes", "other": "_ revisiones de contratos restantes este mes"},
        "it": {"=0": "Nessuna revisione di contratto rimasta questo mese", "=1": "1 revisione contratto rimasta questo mese", "other": "_ revisioni contratti rimaste questo mese"},
        "sv": {"=0": "Inga kontraktsgranskningar kvar denna månad", "=1": "1 kontraktsgranskning kvar denna månad", "other": "_ kontraktsgranskningar kvar denna månad"},
        "ro": {"=0": "Nicio revizuire de contract rămasă luna aceasta", "=1": "1 revizuire de contract rămasă luna aceasta", "other": "_ revizuiri de contracte rămase luna aceasta"},
        "tr": {"=0": "Bu ay sözleşme incelemesi kalmadı", "other": "Bu ay _ sözleşme incelemesi kaldı"},
        "ar": {"=0": "لا توجد مراجعات عقود متبقية هذا الشهر", "=1": "تبقت مراجعة عقد واحدة هذا الشهر", "other": "تبقت _ مراجعات عقود هذا الشهر"},
        "fa": {"=0": "این ماه بررسی قراردادی باقی نمانده", "=1": "۱ بررسی قرارداد این ماه باقی مانده", "other": "_ بررسی قرارداد این ماه باقی مانده"},
    },
    "consiliumExpertsAgreed": {
        "en": {"=1": "1 expert agreed", "other": "_ experts agreed"},
        "ru": {"one": "_ эксперт согласен", "few": "_ эксперта согласны", "many": "_ экспертов согласны", "other": "_ экспертов согласны"},
        "pl": {"one": "1 ekspert zgadza się", "few": "_ ekspertów zgadza się", "many": "_ ekspertów zgadza się", "other": "_ ekspertów zgadza się"},
        "uk": {"one": "_ експерт згоден", "few": "_ експерти згодні", "many": "_ експертів згодні", "other": "_ експертів згодні"},
        "lt": {"one": "_ ekspertas sutinka", "few": "_ ekspertai sutinka", "many": "_ eksperto sutinka", "other": "_ ekspertų sutinka"},
        "lv": {"zero": "_ eksperti piekrīt", "one": "_ eksperts piekrīt", "other": "_ eksperti piekrīt"},
        "fi": {"=1": "1 asiantuntija samaa mieltä", "other": "_ asiantuntijaa samaa mieltä"},
        "et": {"=1": "1 ekspert nõustub", "other": "_ eksperti nõustub"},
        "de": {"=1": "1 Experte stimmt zu", "other": "_ Experten stimmen zu"},
        "fr": {"=1": "1 expert d'accord", "other": "_ experts d'accord"},
        "es": {"=1": "1 experto de acuerdo", "other": "_ expertos de acuerdo"},
        "it": {"=1": "1 esperto d'accordo", "other": "_ esperti d'accordo"},
        "sv": {"=1": "1 expert håller med", "other": "_ experter håller med"},
        "ro": {"=1": "1 expert de acord", "other": "_ experți de acord"},
        "tr": {"other": "_ uzman katılıyor"},
        "ar": {"=1": "خبير واحد موافق", "other": "_ خبراء موافقون"},
        "fa": {"=1": "۱ کارشناس موافق", "other": "_ کارشناس موافق"},
    },
    "consiliumExpertsDisagree": {
        "en": {"=1": "1 expert disagrees", "other": "_ experts disagree"},
        "ru": {"one": "_ эксперт не согласен", "few": "_ эксперта не согласны", "many": "_ экспертов не согласны", "other": "_ экспертов не согласны"},
        "pl": {"one": "1 ekspert nie zgadza się", "few": "_ ekspertów nie zgadza się", "many": "_ ekspertów nie zgadza się", "other": "_ ekspertów nie zgadza się"},
        "uk": {"one": "_ експерт не згоден", "few": "_ експерти не згодні", "many": "_ експертів не згодні", "other": "_ експертів не згодні"},
        "lt": {"one": "_ ekspertas nesutinka", "few": "_ ekspertai nesutinka", "many": "_ eksperto nesutinka", "other": "_ ekspertų nesutinka"},
        "lv": {"zero": "_ eksperti nepiekrīt", "one": "_ eksperts nepiekrīt", "other": "_ eksperti nepiekrīt"},
        "fi": {"=1": "1 asiantuntija eri mieltä", "other": "_ asiantuntijaa eri mieltä"},
        "et": {"=1": "1 ekspert ei nõustu", "other": "_ eksperti ei nõustu"},
        "de": {"=1": "1 Experte stimmt nicht zu", "other": "_ Experten stimmen nicht zu"},
        "fr": {"=1": "1 expert en désaccord", "other": "_ experts en désaccord"},
        "es": {"=1": "1 experto en desacuerdo", "other": "_ expertos en desacuerdo"},
        "it": {"=1": "1 esperto in disaccordo", "other": "_ esperti in disaccordo"},
        "sv": {"=1": "1 expert oense", "other": "_ experter oense"},
        "ro": {"=1": "1 expert dezacord", "other": "_ experți dezacord"},
        "tr": {"other": "_ uzman katılmıyor"},
        "ar": {"=1": "خبير واحد غير موافق", "other": "_ خبراء غير موافقين"},
        "fa": {"=1": "۱ کارشناس مخالف", "other": "_ کارشناس مخالف"},
    },
}

# Canonical CLDR order.
ORDER = ["=0", "zero", "=1", "one", "two", "few", "many", "other"]


def build_icu(forms: dict) -> str:
    parts = []
    for cat in ORDER:
        if cat in forms:
            val = forms[cat].replace("_", "{count}")
            parts.append(f"{cat}{{{val}}}")
    return "{count, plural, " + " ".join(parts) + "}"


def _escape_for_json(value: str) -> str:
    """Re-escape a string the way it appears inside JSON: backslash and quote."""
    return value.replace("\\", "\\\\").replace('"', '\\"')


def update_locale(locale: str):
    """Targeted line-based replacement: keeps existing ARB formatting intact."""
    path = L10N / f"app_{locale}.arb"
    text = path.read_text(encoding="utf-8")
    changed = []
    for key, locale_forms in KEYS.items():
        if locale not in locale_forms:
            continue
        new_icu = build_icu(locale_forms[locale])
        new_escaped = _escape_for_json(new_icu)
        # Find the line: '    "<key>": "...",' and replace just the value.
        # Pattern is greedy on quoted body, robust to escaped quotes.
        pattern = re.compile(
            r'("' + re.escape(key) + r'"\s*:\s*)"((?:[^"\\]|\\.)*)"',
            re.MULTILINE,
        )
        match = pattern.search(text)
        if not match:
            continue
        old_value = match.group(2)
        if old_value == new_escaped:
            continue
        text = pattern.sub(lambda m: m.group(1) + '"' + new_escaped + '"', text, count=1)
        changed.append(key)
    # Validate JSON before writing.
    json.loads(text)
    path.write_text(text, encoding="utf-8")
    return changed


def main():
    locales = ["en", "ru", "pl", "uk", "lt", "lv", "fi", "et", "de", "fr", "es", "it", "sv", "ro", "tr", "ar", "fa"]
    for loc in locales:
        changed = update_locale(loc)
        status = "ok" if changed else "no-op"
        print(f"{loc}: {len(changed)} keys updated [{status}] -> {changed}")


if __name__ == "__main__":
    main()
