class TourHubLocation {
  const TourHubLocation({
    required this.kabupatenKota,
    required this.kecamatan,
    required this.bmkgAdm4,
  });

  final String kabupatenKota;
  final String kecamatan;
  final String bmkgAdm4;

  String get label => '$kabupatenKota — $kecamatan';
}

const List<TourHubLocation> tourHubLocations = [
  TourHubLocation(
    kabupatenKota: 'Kabupaten Gianyar',
    kecamatan: 'Ubud',
    bmkgAdm4: '51.04.05.1005',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Gianyar',
    kecamatan: 'Gianyar',
    bmkgAdm4: '51.04.03.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Gianyar',
    kecamatan: 'Tegallalang',
    bmkgAdm4: '51.04.06.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Gianyar',
    kecamatan: 'Blahbatuh',
    bmkgAdm4: '51.04.02.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Gianyar',
    kecamatan: 'Tampaksiring',
    bmkgAdm4: '51.04.04.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Gianyar',
    kecamatan: 'Sukawati',
    bmkgAdm4: '51.04.01.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Gianyar',
    kecamatan: 'Payangan',
    bmkgAdm4: '51.04.07.2001',
  ),

  TourHubLocation(
    kabupatenKota: 'Kabupaten Badung',
    kecamatan: 'Kuta',
    bmkgAdm4: '51.03.01.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Badung',
    kecamatan: 'Kuta Selatan',
    bmkgAdm4: '51.03.05.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Badung',
    kecamatan: 'Kuta Utara',
    bmkgAdm4: '51.03.06.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Badung',
    kecamatan: 'Mengwi',
    bmkgAdm4: '51.03.02.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Badung',
    kecamatan: 'Abiansemal',
    bmkgAdm4: '51.03.03.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Badung',
    kecamatan: 'Petang',
    bmkgAdm4: '51.03.04.2001',
  ),

  TourHubLocation(
    kabupatenKota: 'Kabupaten Tabanan',
    kecamatan: 'Tabanan',
    bmkgAdm4: '51.02.05.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Tabanan',
    kecamatan: 'Kediri',
    bmkgAdm4: '51.02.06.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Tabanan',
    kecamatan: 'Penebel',
    bmkgAdm4: '51.02.08.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Tabanan',
    kecamatan: 'Baturiti',
    bmkgAdm4: '51.02.09.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Tabanan',
    kecamatan: 'Pupuan',
    bmkgAdm4: '51.02.10.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Tabanan',
    kecamatan: 'Selemadeg Timur',
    bmkgAdm4: '51.02.02.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Tabanan',
    kecamatan: 'Selemadeg Barat',
    bmkgAdm4: '51.02.03.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Tabanan',
    kecamatan: 'Kerambitan',
    bmkgAdm4: '51.02.04.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Tabanan',
    kecamatan: 'Marga',
    bmkgAdm4: '51.02.07.2001',
  ),

  TourHubLocation(
    kabupatenKota: 'Kabupaten Buleleng',
    kecamatan: 'Buleleng',
    bmkgAdm4: '51.08.06.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Buleleng',
    kecamatan: 'Gerokgak',
    bmkgAdm4: '51.08.01.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Buleleng',
    kecamatan: 'Seririt',
    bmkgAdm4: '51.08.02.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Buleleng',
    kecamatan: 'Busungbiu',
    bmkgAdm4: '51.08.03.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Buleleng',
    kecamatan: 'Banjar',
    bmkgAdm4: '51.08.04.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Buleleng',
    kecamatan: 'Sukasada',
    bmkgAdm4: '51.08.05.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Buleleng',
    kecamatan: 'Sawan',
    bmkgAdm4: '51.08.07.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Buleleng',
    kecamatan: 'Kubutambahan',
    bmkgAdm4: '51.08.08.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Buleleng',
    kecamatan: 'Tejakula',
    bmkgAdm4: '51.08.09.2001',
  ),

  TourHubLocation(
    kabupatenKota: 'Kabupaten Karangasem',
    kecamatan: 'Karangasem',
    bmkgAdm4: '51.07.04.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Karangasem',
    kecamatan: 'Rendang',
    bmkgAdm4: '51.07.01.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Karangasem',
    kecamatan: 'Sidemen',
    bmkgAdm4: '51.07.02.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Karangasem',
    kecamatan: 'Manggis',
    bmkgAdm4: '51.07.03.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Karangasem',
    kecamatan: 'Abang',
    bmkgAdm4: '51.07.05.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Karangasem',
    kecamatan: 'Bebandem',
    bmkgAdm4: '51.07.06.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Karangasem',
    kecamatan: 'Selat',
    bmkgAdm4: '51.07.07.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Karangasem',
    kecamatan: 'Kubu',
    bmkgAdm4: '51.07.08.2001',
  ),

  TourHubLocation(
    kabupatenKota: 'Kabupaten Bangli',
    kecamatan: 'Kintamani',
    bmkgAdm4: '51.06.04.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Bangli',
    kecamatan: 'Bangli',
    bmkgAdm4: '51.06.02.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Bangli',
    kecamatan: 'Susut',
    bmkgAdm4: '51.06.01.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Bangli',
    kecamatan: 'Tembuku',
    bmkgAdm4: '51.06.03.2001',
  ),

  TourHubLocation(
    kabupatenKota: 'Kabupaten Klungkung',
    kecamatan: 'Nusa Penida',
    bmkgAdm4: '51.05.01.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Klungkung',
    kecamatan: 'Klungkung',
    bmkgAdm4: '51.05.03.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Klungkung',
    kecamatan: 'Banjarangkan',
    bmkgAdm4: '51.05.02.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Klungkung',
    kecamatan: 'Dawan',
    bmkgAdm4: '51.05.04.2001',
  ),

  TourHubLocation(
    kabupatenKota: 'Kabupaten Jembrana',
    kecamatan: 'Negara',
    bmkgAdm4: '51.01.01.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Jembrana',
    kecamatan: 'Jembrana',
    bmkgAdm4: '51.01.05.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Jembrana',
    kecamatan: 'Mendoyo',
    bmkgAdm4: '51.01.02.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Jembrana',
    kecamatan: 'Melaya',
    bmkgAdm4: '51.01.04.2001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kabupaten Jembrana',
    kecamatan: 'Pekutatan',
    bmkgAdm4: '51.01.03.2001',
  ),

  TourHubLocation(
    kabupatenKota: 'Kota Denpasar',
    kecamatan: 'Denpasar Selatan',
    bmkgAdm4: '51.71.01.1006',
  ),
  TourHubLocation(
    kabupatenKota: 'Kota Denpasar',
    kecamatan: 'Denpasar Barat',
    bmkgAdm4: '51.71.03.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kota Denpasar',
    kecamatan: 'Denpasar Timur',
    bmkgAdm4: '51.71.02.1001',
  ),
  TourHubLocation(
    kabupatenKota: 'Kota Denpasar',
    kecamatan: 'Denpasar Utara',
    bmkgAdm4: '51.71.04.1001',
  ),
];
