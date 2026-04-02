class EUCountryConfig {
  final String code;
  final String flag;
  final String nameEn;
  final String nameNative;
  const EUCountryConfig({required this.code, required this.flag, required this.nameEn, required this.nameNative});
}

abstract class EUCountries {
  static List<EUCountryConfig> get sorted => const [
    EUCountryConfig(code: 'FI', flag: '🇫🇮', nameEn: 'Finland', nameNative: 'Suomi'),
    EUCountryConfig(code: 'EE', flag: '🇪🇪', nameEn: 'Estonia', nameNative: 'Eesti'),
    EUCountryConfig(code: 'SE', flag: '🇸🇪', nameEn: 'Sweden', nameNative: 'Sverige'),
    EUCountryConfig(code: 'DE', flag: '🇩🇪', nameEn: 'Germany', nameNative: 'Deutschland'),
    EUCountryConfig(code: 'FR', flag: '🇫🇷', nameEn: 'France', nameNative: 'France'),
    EUCountryConfig(code: 'IT', flag: '🇮🇹', nameEn: 'Italy', nameNative: 'Italia'),
    EUCountryConfig(code: 'ES', flag: '🇪🇸', nameEn: 'Spain', nameNative: 'España'),
    EUCountryConfig(code: 'NL', flag: '🇳🇱', nameEn: 'Netherlands', nameNative: 'Nederland'),
    EUCountryConfig(code: 'PL', flag: '🇵🇱', nameEn: 'Poland', nameNative: 'Polska'),
    EUCountryConfig(code: 'RO', flag: '🇷🇴', nameEn: 'Romania', nameNative: 'România'),
    EUCountryConfig(code: 'LV', flag: '🇱🇻', nameEn: 'Latvia', nameNative: 'Latvija'),
    EUCountryConfig(code: 'LT', flag: '🇱🇹', nameEn: 'Lithuania', nameNative: 'Lietuva'),
    EUCountryConfig(code: 'AT', flag: '🇦🇹', nameEn: 'Austria', nameNative: 'Österreich'),
    EUCountryConfig(code: 'BE', flag: '🇧🇪', nameEn: 'Belgium', nameNative: 'België'),
    EUCountryConfig(code: 'IE', flag: '🇮🇪', nameEn: 'Ireland', nameNative: 'Ireland'),
  ];
}
