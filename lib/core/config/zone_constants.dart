/// Konstanta bobot zona petualangan untuk penyesuaian delta skor mode tantangan.
///
/// Mencegah eksploitasi throughput di zona rendah dengan memberi apresiasi
/// proporsional pada pemain yang bertanding di zona level aslinya.
const Map<String, double> kZoneConstants = {
  'onboarding': 1.0,
  'basic': 1.2,
  'intermediate': 1.5,
  'advanced': 2.0,
  'expert': 2.8,
};
