sealed class RideTier {
  const RideTier();
}

final class Perfect extends RideTier {
  const Perfect();
}

final class Great extends RideTier {
  const Great();
}

final class Acceptable extends RideTier {
  const Acceptable();
}

final class Poor extends RideTier {
  const Poor();
}

RideTier rideTierFromScore(double score) {
  if (score >= 85) return const Perfect();
  if (score >= 70) return const Great();
  if (score >= 50) return const Acceptable();
  return const Poor();
}
