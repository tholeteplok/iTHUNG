import 'dart:math' as math;
import 'dart:math' show Random;

import '../models/question.dart';

/// Range nilai minimum dan maksimum untuk operan aritmatika.
class OperandRange {
  const OperandRange({required this.min, required this.max});

  final int min;
  final int max;

  /// Memperlebar rentang untuk relaxation ladder saat generasi operan gagal.
  OperandRange widen([int amount = 5]) =>
      OperandRange(min: math.max(1, min - amount), max: max + amount);

  int sample(Random rng) {
    if (min >= max) return min;
    return min + rng.nextInt(max - min + 1);
  }
}

/// Template spesifikasi pembuatan soal aritmatika.
///
/// Mengacu pada `math-speed-game-core-gameplay-spec.md` §2.
class QuestionTemplate {
  const QuestionTemplate({
    required this.operation,
    required this.rangeA,
    required this.rangeB,
    required this.strategyTag,
    required this.levelBand,
    required this.level,
    this.requireCarry,
    this.requireBorrow,
    this.avoidTrivial = true,
    this.stepCount = 1,
  });

  final Operation operation;
  final OperandRange rangeA;
  final OperandRange rangeB;
  final StrategyTag strategyTag;
  final String levelBand;
  final int level;
  final bool? requireCarry;
  final bool? requireBorrow;
  final bool avoidTrivial;
  final int stepCount;

  QuestionTemplate copyWith({
    Operation? operation,
    OperandRange? rangeA,
    OperandRange? rangeB,
    StrategyTag? strategyTag,
    String? levelBand,
    int? level,
    bool? requireCarry,
    bool? requireBorrow,
    bool? avoidTrivial,
    int? stepCount,
  }) {
    return QuestionTemplate(
      operation: operation ?? this.operation,
      rangeA: rangeA ?? this.rangeA,
      rangeB: rangeB ?? this.rangeB,
      strategyTag: strategyTag ?? this.strategyTag,
      levelBand: levelBand ?? this.levelBand,
      level: level ?? this.level,
      requireCarry: requireCarry ?? this.requireCarry,
      requireBorrow: requireBorrow ?? this.requireBorrow,
      avoidTrivial: avoidTrivial ?? this.avoidTrivial,
      stepCount: stepCount ?? this.stepCount,
    );
  }
}

/// Generator soal aritmatika berbasis template + constraint kognitif + relaxation ladder.
///
/// Mengacu pada:
/// - `math-speed-game-core-gameplay-spec.md` §2
/// - `math-speed-game-error-handling-spec.md` §2 (zero failure relaxation ladder)
class QuestionGenerator {
  const QuestionGenerator();

  /// Menghasilkan soal baru yang sesuai dengan tingkat [level] pemain.
  Question generateForLevel(int level, {Random? rng}) {
    final random = rng ?? Random();
    final template = _templateForLevel(level, random);
    return generateFromTemplate(template, rng: random);
  }

  /// Menghasilkan soal dari [QuestionTemplate] menggunakan constraint relaxation ladder.
  Question generateFromTemplate(QuestionTemplate template, {Random? rng}) {
    final random = rng ?? Random();
    const maxAttemptsPerTier = 150;

    // Iterasi melalui tingkat relaksasi jika constraint terlalu ketat (§2 error handling)
    for (final relaxedTemplate in _relaxationLadder(template)) {
      for (var i = 0; i < maxAttemptsPerTier; i++) {
        final candidate = _tryGenerate(relaxedTemplate, random);
        if (candidate != null) {
          return candidate;
        }
      }
    }

    // Tingkat pengaman absolut: jaminan tidak pernah gagal total
    return _absoluteFallback(
      template.operation,
      template.level,
      template.levelBand,
      rng: random,
    );
  }

  /// Relaxation ladder: melonggarkan constraint satu per satu.
  List<QuestionTemplate> _relaxationLadder(QuestionTemplate t) => [
    t, // Tier 0: template asli
    t.copyWith(
      avoidTrivial: false,
    ), // Tier 1: perbolehkan angka trivial (x1, x10, dsb)
    t.copyWith(
      requireCarry: null,
      requireBorrow: null,
    ), // Tier 2: abaikan syarat carry/borrow
    t.copyWith(
      rangeA: t.rangeA.widen(),
      rangeB: t.rangeB.widen(),
    ), // Tier 3: lebarkan rentang
  ];

  /// Mencoba men-sample operan yang memenuhi seluruh constraint template.
  Question? _tryGenerate(QuestionTemplate t, Random rng) {
    final a = t.rangeA.sample(rng);
    final b = t.rangeB.sample(rng);

    // Cek constraint trivial
    if (t.avoidTrivial) {
      if (t.operation == Operation.multiply &&
          (a <= 1 || b <= 1 || a == 10 || b == 10)) {
        return null;
      }
      if (t.operation == Operation.add && (a == 0 || b == 0)) {
        return null;
      }
      if (t.operation == Operation.subtract && (a == b || b == 0)) {
        return null;
      }
      if (t.operation == Operation.divide && (b <= 1 || a == b)) {
        return null;
      }
    }

    int op1 = a;
    int op2 = b;
    int correct;
    StructuralProperty prop = StructuralProperty.none;

    switch (t.operation) {
      case Operation.add:
        correct = op1 + op2;
        final hasCarry = _hasAdditionCarry(op1, op2);
        if (t.requireCarry != null && hasCarry != t.requireCarry!) {
          return null;
        }
        if (hasCarry) {
          prop = StructuralProperty.requiresCarry;
        } else if ((op1 % 10) + (op2 % 10) >= 10) {
          prop = StructuralProperty.crossesDecade;
        }

      case Operation.subtract:
        // Pastikan hasil selalu positif
        if (op1 < op2) {
          final temp = op1;
          op1 = op2;
          op2 = temp;
        }
        if (op1 == op2) return null;
        correct = op1 - op2;

        final hasBorrow = _hasSubtractionBorrow(op1, op2);
        if (t.requireBorrow != null && hasBorrow != t.requireBorrow!) {
          return null;
        }
        if (hasBorrow) {
          prop = StructuralProperty.requiresBorrow;
        }

      case Operation.multiply:
        correct = op1 * op2;

      case Operation.divide:
        // Pembagian harus habis dibagi (integer exact)
        if (op2 == 0) return null;
        // Bentuk: dividend = op1 * op2, sehingga dividend ÷ op2 = op1
        final dividend = op1 * op2;
        correct = op1;
        op1 = dividend;

      case Operation.mixed || Operation.mixedMultistep:
        if (t.operation == Operation.mixedMultistep) {
          return _tryGenerateMultistep(t, rng);
        }
        correct = op1 + op2;
    }

    final factKey = _buildFactKey(t.operation, op1, op2);
    final id = 'q_${factKey}_${rng.nextInt(1000000)}';

    return Question(
      id: id,
      factKey: factKey,
      operation: t.operation,
      operands: [op1, op2],
      correctAnswer: correct,
      difficulty: QuestionDifficulty(
        operandMagnitude: _resolveMagnitude(op1, op2),
        structuralProperty: prop,
        strategyTag: t.strategyTag,
        stepCount: t.stepCount,
      ),
      levelBand: t.levelBand,
      level: t.level,
    );
  }

  /// Kunci unik fakta untuk Mastery & Mistake Bank (mis. '7x8', '27+8', '15-7', '42/6').
  static String _buildFactKey(Operation op, int a, int b) {
    return switch (op) {
      Operation.add => '$a+$b',
      Operation.subtract => '$a-$b',
      Operation.multiply => '${a}x$b',
      Operation.divide => '$a/$b',
      Operation.mixed || Operation.mixedMultistep => '$a+${b}_mix',
    };
  }

  /// Sampling soal multi-langkah (a ± b) × c dengan 3 operand.
  Question? _tryGenerateMultistep(QuestionTemplate t, Random rng) {
    final a = 2 + rng.nextInt(11); // 2..12
    final b = 2 + rng.nextInt(11);
    final c = 2 + rng.nextInt(8); // 2..9
    final isAdd = rng.nextBool();
    final useAdd = isAdd || a == b;

    int first = a;
    int second = b;
    if (!useAdd) {
      // Pastikan operand pertama lebih besar agar hasil dalam kurung selalu positif
      if (first < second) {
        final temp = first;
        first = second;
        second = temp;
      }
      if (first == second) return null;
    }

    final innerValue = useAdd ? first + second : first - second;
    // Pastikan inner positif dan tidak nol agar soal valid.
    if (innerValue <= 0) return null;
    final correct = innerValue * c;
    final sign = useAdd ? '+' : '-';
    final factKey = '($first$sign$second)x$c';
    final id = 'q_${factKey}_${rng.nextInt(1000000)}';

    return Question(
      id: id,
      factKey: factKey,
      operation: Operation.mixedMultistep,
      operands: [first, second, c],
      correctAnswer: correct,
      difficulty: QuestionDifficulty(
        operandMagnitude: _resolveMagnitude(first > second ? first : second, c),
        structuralProperty: StructuralProperty.none,
        strategyTag: StrategyTag.procedural,
        stepCount: 2,
      ),
      levelBand: t.levelBand,
      level: t.level,
    );
  }

  /// Penentuan template kognitif berdasarkan level pemain (§1.2 & §5 level_bands.json).
  QuestionTemplate _templateForLevel(int level, Random rng) {
    if (level <= 5) {
      // Onboarding: 1-digit add/sub, direct counting / retrieval
      final isAdd = rng.nextBool();
      return QuestionTemplate(
        operation: isAdd ? Operation.add : Operation.subtract,
        rangeA: const OperandRange(min: 2, max: 9),
        rangeB: const OperandRange(min: 1, max: 8),
        strategyTag: StrategyTag.retrieval,
        levelBand: 'onboarding',
        level: level,
        requireCarry: false,
        requireBorrow: false,
      );
    } else if (level <= 15) {
      // Basic: add, sub, mul (1-10 table)
      final roll = rng.nextInt(3);
      if (roll == 0) {
        return QuestionTemplate(
          operation: Operation.multiply,
          rangeA: const OperandRange(min: 2, max: 9),
          rangeB: const OperandRange(min: 2, max: 9),
          strategyTag: StrategyTag.retrieval,
          levelBand: 'basic',
          level: level,
        );
      } else if (roll == 1) {
        return QuestionTemplate(
          operation: Operation.add,
          rangeA: const OperandRange(min: 10, max: 40),
          rangeB: const OperandRange(min: 2, max: 9),
          strategyTag: StrategyTag.derived,
          levelBand: 'basic',
          level: level,
          requireCarry: rng.nextBool(),
        );
      } else {
        return QuestionTemplate(
          operation: Operation.subtract,
          rangeA: const OperandRange(min: 12, max: 45),
          rangeB: const OperandRange(min: 3, max: 9),
          strategyTag: StrategyTag.derived,
          levelBand: 'basic',
          level: level,
          requireBorrow: rng.nextBool(),
        );
      }
    } else if (level <= 30) {
      // Intermediate: 2-digit add/sub with carry/borrow, mul, div
      final roll = rng.nextInt(4);
      return switch (roll) {
        0 => QuestionTemplate(
          operation: Operation.divide,
          rangeA: const OperandRange(min: 2, max: 12),
          rangeB: const OperandRange(min: 2, max: 9),
          strategyTag: StrategyTag.derived,
          levelBand: 'intermediate',
          level: level,
        ),
        1 => QuestionTemplate(
          operation: Operation.multiply,
          rangeA: const OperandRange(min: 3, max: 12),
          rangeB: const OperandRange(min: 3, max: 12),
          strategyTag: StrategyTag.retrieval,
          levelBand: 'intermediate',
          level: level,
        ),
        2 => QuestionTemplate(
          operation: Operation.add,
          rangeA: const OperandRange(min: 15, max: 75),
          rangeB: const OperandRange(min: 12, max: 45),
          strategyTag: StrategyTag.procedural,
          levelBand: 'intermediate',
          level: level,
          requireCarry: true,
        ),
        _ => QuestionTemplate(
          operation: Operation.subtract,
          rangeA: const OperandRange(min: 30, max: 90),
          rangeB: const OperandRange(min: 15, max: 45),
          strategyTag: StrategyTag.procedural,
          levelBand: 'intermediate',
          level: level,
          requireBorrow: true,
        ),
      };
    } else if (level <= 50) {
      // Advanced: 2-3 digit mixed + 25% multistep
      if (rng.nextInt(4) == 0) {
        return QuestionTemplate(
          operation: Operation.mixedMultistep,
          rangeA: const OperandRange(min: 2, max: 12),
          rangeB: const OperandRange(min: 2, max: 9),
          strategyTag: StrategyTag.procedural,
          levelBand: 'advanced',
          level: level,
          stepCount: 2,
        );
      }
      final isMul = rng.nextBool();
      if (isMul) {
        return QuestionTemplate(
          operation: Operation.multiply,
          rangeA: const OperandRange(min: 6, max: 20),
          rangeB: const OperandRange(min: 4, max: 15),
          strategyTag: StrategyTag.derived,
          levelBand: 'advanced',
          level: level,
        );
      }
      return QuestionTemplate(
        operation: Operation.add,
        rangeA: const OperandRange(min: 45, max: 180),
        rangeB: const OperandRange(min: 25, max: 120),
        strategyTag: StrategyTag.procedural,
        levelBand: 'advanced',
        level: level,
        requireCarry: true,
      );
    } else if (level <= 75) {
      // Expert (Highland Wind, Level 51-75): 2-3 digit multiplication, division, and multistep
      final roll = rng.nextInt(10);
      if (roll < 4) {
        // 40% multistep (a ± b) × c
        return QuestionTemplate(
          operation: Operation.mixedMultistep,
          rangeA: const OperandRange(min: 2, max: 12),
          rangeB: const OperandRange(min: 2, max: 9),
          strategyTag: StrategyTag.procedural,
          levelBand: 'expert',
          level: level,
          stepCount: 2,
        );
      } else if (roll < 7) {
        // 30% multiplication 2-digit (11..25 x 11..25)
        return QuestionTemplate(
          operation: Operation.multiply,
          rangeA: const OperandRange(min: 11, max: 25),
          rangeB: const OperandRange(min: 11, max: 25),
          strategyTag: StrategyTag.procedural,
          levelBand: 'expert',
          level: level,
        );
      } else {
        // 30% division 2-digit (dividend up to 300)
        return QuestionTemplate(
          operation: Operation.divide,
          rangeA: const OperandRange(min: 11, max: 25),
          rangeB: const OperandRange(min: 3, max: 12),
          strategyTag: StrategyTag.procedural,
          levelBand: 'expert',
          level: level,
        );
      }
    } else {
      // Master (Frost Wind, Level 76+): Challenging multistep, 3-digit division, and higher-range mental math
      final roll = rng.nextInt(10);
      if (roll < 5) {
        // 50% multistep with expanded operands
        return QuestionTemplate(
          operation: Operation.mixedMultistep,
          rangeA: const OperandRange(min: 3, max: 15),
          rangeB: const OperandRange(min: 2, max: 12),
          strategyTag: StrategyTag.procedural,
          levelBand: 'master',
          level: level,
          stepCount: 2,
        );
      } else if (roll < 8) {
        // 30% division (3-digit dividend: 15..50 * 4..12 = 60..600)
        return QuestionTemplate(
          operation: Operation.divide,
          rangeA: const OperandRange(min: 15, max: 50),
          rangeB: const OperandRange(min: 4, max: 12),
          strategyTag: StrategyTag.procedural,
          levelBand: 'master',
          level: level,
        );
      } else {
        // 20% multiplication (12..35 x 11..25)
        return QuestionTemplate(
          operation: Operation.multiply,
          rangeA: const OperandRange(min: 12, max: 35),
          rangeB: const OperandRange(min: 11, max: 25),
          strategyTag: StrategyTag.procedural,
          levelBand: 'master',
          level: level,
        );
      }
    }
  }

  /// Menghasilkan soal darurat jika semua relaxation tier tidak menghasilkan solusi.
  Question _absoluteFallback(
    Operation op,
    int level,
    String band, {
    Random? rng,
  }) {
    final salt = rng != null
        ? rng.nextInt(100000)
        : DateTime.now().microsecondsSinceEpoch;
    final suffix = '_$salt';
    return switch (op) {
      Operation.add => Question(
        id: 'q_fallback_${level}_add$suffix',
        factKey: '7+5',
        operation: Operation.add,
        operands: const [7, 5],
        correctAnswer: 12,
        difficulty: const QuestionDifficulty(
          operandMagnitude: OperandMagnitude.oneDigit,
          structuralProperty: StructuralProperty.crossesDecade,
          strategyTag: StrategyTag.derived,
          stepCount: 1,
        ),
        levelBand: band,
        level: level,
      ),
      Operation.subtract => Question(
        id: 'q_fallback_${level}_sub$suffix',
        factKey: '12-5',
        operation: Operation.subtract,
        operands: const [12, 5],
        correctAnswer: 7,
        difficulty: const QuestionDifficulty(
          operandMagnitude: OperandMagnitude.twoDigit,
          structuralProperty: StructuralProperty.requiresBorrow,
          strategyTag: StrategyTag.derived,
          stepCount: 1,
        ),
        levelBand: band,
        level: level,
      ),
      Operation.multiply => Question(
        id: 'q_fallback_${level}_mul$suffix',
        factKey: '7x8',
        operation: Operation.multiply,
        operands: const [7, 8],
        correctAnswer: 56,
        difficulty: const QuestionDifficulty(
          operandMagnitude: OperandMagnitude.oneDigit,
          structuralProperty: StructuralProperty.none,
          strategyTag: StrategyTag.retrieval,
          stepCount: 1,
        ),
        levelBand: band,
        level: level,
      ),
      Operation.divide => Question(
        id: 'q_fallback_${level}_div$suffix',
        factKey: '56/8',
        operation: Operation.divide,
        operands: const [56, 8],
        correctAnswer: 7,
        difficulty: const QuestionDifficulty(
          operandMagnitude: OperandMagnitude.twoDigit,
          structuralProperty: StructuralProperty.none,
          strategyTag: StrategyTag.derived,
          stepCount: 1,
        ),
        levelBand: band,
        level: level,
      ),
      Operation.mixed || Operation.mixedMultistep => Question(
        id: 'q_fallback_${level}_mix$suffix',
        factKey: '8x4',
        operation: Operation.multiply,
        operands: const [8, 4],
        correctAnswer: 32,
        difficulty: const QuestionDifficulty(
          operandMagnitude: OperandMagnitude.oneDigit,
          structuralProperty: StructuralProperty.none,
          strategyTag: StrategyTag.retrieval,
          stepCount: 1,
        ),
        levelBand: band,
        level: level,
      ),
    };
  }

  bool _hasAdditionCarry(int a, int b) {
    var carry = 0;
    while (a > 0 || b > 0) {
      final sum = (a % 10) + (b % 10) + carry;
      if (sum >= 10) return true;
      carry = sum ~/ 10;
      a ~/= 10;
      b ~/= 10;
    }
    return false;
  }

  bool _hasSubtractionBorrow(int a, int b) {
    while (a > 0 || b > 0) {
      if ((a % 10) < (b % 10)) return true;
      a ~/= 10;
      b ~/= 10;
    }
    return false;
  }

  OperandMagnitude _resolveMagnitude(int a, int b) {
    final m = math.max(a, b);
    if (m >= 100) return OperandMagnitude.threeDigit;
    if (m >= 10) return OperandMagnitude.twoDigit;
    return OperandMagnitude.oneDigit;
  }
}
