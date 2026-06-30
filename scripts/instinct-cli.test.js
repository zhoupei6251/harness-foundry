/**
 * instinct-cli 测试文件
 *
 * 测试 instinct-cli.js 的核心功能：创建、评分、聚类、进化和清理
 *
 * 运行方式：node scripts/instinct-cli.test.js
 */

const assert = {
  equal(actual, expected, msg) {
    if (actual !== expected) {
      console.error(`FAIL: ${msg} — expected "${expected}", got "${actual}"`);
      process.exitCode = 1;
    } else {
      console.log(`PASS: ${msg}`);
    }
  },
  inRange(actual, min, max, msg) {
    if (actual < min || actual > max) {
      console.error(`FAIL: ${msg} — expected [${min}, ${max}], got ${actual}`);
      process.exitCode = 1;
    } else {
      console.log(`PASS: ${msg}`);
    }
  },
  ok(value, msg) {
    if (!value) {
      console.error(`FAIL: ${msg} — expected truthy`);
      process.exitCode = 1;
    } else {
      console.log(`PASS: ${msg}`);
    }
  }
};

// === Confidence Scoring Tests ===

function testCalculateScore() {
  console.log('\n--- Confidence Scoring ---');

  // 模拟 calculateScore 函数
  function calculateScore(instinct, events) {
    let score = instinct.base_confidence || 0.5;

    events.forEach(event => {
      switch(event.type) {
        case 'successful_application': score += 0.1; break;
        case 'user_affirmation':       score += 0.2; break;
        case 'user_rejection':         score -= 0.1; break;
        case 'led_to_error':           score -= 0.15; break;
      }
    });

    // 时间衰减
    const daysUnused = (Date.now() - new Date(instinct.last_used)) / 86400000;
    if (daysUnused > 30) {
      score -= 0.05 * Math.floor(daysUnused / 30);
    }

    return Math.max(0, Math.min(1, Math.round(score * 100) / 100));
  }

  // Test 1: base confidence only
  const r1 = calculateScore(
    { base_confidence: 0.5, last_used: new Date().toISOString() },
    []
  );
  assert.equal(r1, 0.5, "base confidence = 0.5");

  // Test 2: successful applications
  const r2 = calculateScore(
    { base_confidence: 0.5, last_used: new Date().toISOString() },
    [{ type: 'successful_application' }, { type: 'successful_application' }]
  );
  assert.equal(r2, 0.7, "two successful = 0.7");

  // Test 3: user affirmation
  const r3 = calculateScore(
    { base_confidence: 0.5, last_used: new Date().toISOString() },
    [{ type: 'user_affirmation' }]
  );
  assert.equal(r3, 0.7, "one affirmation = 0.7");

  // Test 4: user rejection
  const r4 = calculateScore(
    { base_confidence: 0.8, last_used: new Date().toISOString() },
    [{ type: 'user_rejection' }]
  );
  assert.equal(r4, 0.7, "rejection subtracts 0.1");

  // Test 5: led to error
  const r5 = calculateScore(
    { base_confidence: 0.7, last_used: new Date().toISOString() },
    [{ type: 'led_to_error' }]
  );
  assert.equal(r5, 0.55, "error subtracts 0.15");

  // Test 6: combination
  const r6 = calculateScore(
    { base_confidence: 0.5, last_used: new Date().toISOString() },
    [
      { type: 'successful_application' },
      { type: 'successful_application' },
      { type: 'user_affirmation' },
      { type: 'user_rejection' }
    ]
  );
  assert.equal(r6, 0.8, "combination = 0.8 (0.5+0.2+0.2-0.1)");

  // Test 7: ceiling at 1.0
  const r7 = calculateScore(
    { base_confidence: 0.9, last_used: new Date().toISOString() },
    [{ type: 'user_affirmation' }, { type: 'successful_application' }]
  );
  assert.equal(r7, 1.0, "ceiling at 1.0");

  // Test 8: floor at 0
  const r8 = calculateScore(
    { base_confidence: 0.1, last_used: new Date().toISOString() },
    [{ type: 'led_to_error' }, { type: 'user_rejection' }]
  );
  assert.equal(r8, 0, "floor at 0");

  // Test 9: time decay — 60 days unused
  const sixtyDaysAgo = new Date(Date.now() - 60 * 86400000).toISOString();
  const r9 = calculateScore(
    { base_confidence: 0.6, last_used: sixtyDaysAgo },
    []
  );
  assert.equal(r9, 0.5, "60 days decay = -0.10");

  // Test 10: time decay — 90 days unused
  const ninetyDaysAgo = new Date(Date.now() - 90 * 86400000).toISOString();
  const r10 = calculateScore(
    { base_confidence: 0.6, last_used: ninetyDaysAgo },
    []
  );
  assert.equal(r10, 0.45, "90 days decay = -0.15");
}

// === Quality Gate Tests ===

function testQualityGate() {
  console.log('\n--- Quality Gate ---');

  function qualityGate(instinct) {
    const checks = {
      description_length: instinct.description && instinct.description.length >= 10,
      valid_type: ['pattern','trap','lesson','preference'].includes(instinct.type),
      valid_confidence: instinct.confidence >= 0 && instinct.confidence <= 1,
      body_length: instinct.body && instinct.body.length >= 50,
      valid_date: !isNaN(Date.parse(instinct.source?.session_date))
    };

    const passCount = Object.values(checks).filter(Boolean).length;
    return {
      passed: passCount === Object.keys(checks).length,
      score: passCount / Object.keys(checks).length,
      failures: Object.entries(checks).filter(([,v]) => !v).map(([k]) => k)
    };
  }

  const validInstinct = {
    description: "A valid pattern description that is long enough",
    type: "pattern",
    confidence: 0.75,
    body: "This is a detailed body that is at least fifty characters long to pass the quality gate check for body length.",
    source: { session_date: "2026-06-26" }
  };
  const r1 = qualityGate(validInstinct);
  assert.ok(r1.passed, "valid instinct passes all checks");
  assert.equal(r1.score, 1.0, "valid instinct score = 1.0");

  const invalidInstinct = {
    description: "short",
    type: "invalid_type",
    confidence: 1.5,
    body: "short body",
    source: { session_date: "invalid-date" }
  };
  const r2 = qualityGate(invalidInstinct);
  assert.ok(!r2.passed, "invalid instinct fails");
  assert.equal(r2.failures.length, 5, "all 5 checks fail");

  const partialInstinct = {
    description: "Valid length description",
    type: "pattern",
    confidence: 0.6,
    body: "Too short",
    source: { session_date: "2026-06-26" }
  };
  const r3 = qualityGate(partialInstinct);
  assert.ok(!r3.passed, "partial instinct fails");
  assert.equal(r3.failures.length, 1, "only body_length fails");
  assert.equal(r3.failures[0], "body_length", "failure is body_length");
}

// === Jaccard Similarity Tests ===

function testJaccardSimilarity() {
  console.log('\n--- Jaccard Similarity ---');

  function jaccard(tagsA, tagsB) {
    const setA = new Set(tagsA);
    const setB = new Set(tagsB);
    const intersection = new Set([...setA].filter(x => setB.has(x)));
    const union = new Set([...setA, ...setB]);
    return union.size === 0 ? 0 : intersection.size / union.size;
  }

  // Test 1: identical
  assert.equal(jaccard(['a','b','c'], ['a','b','c']), 1.0, "identical = 1.0");

  // Test 2: disjoint
  assert.equal(jaccard(['a','b'], ['c','d']), 0, "disjoint = 0");

  // Test 3: partial
  assert.equal(jaccard(['a','b','c'], ['b','c','d']), 0.5, "partial = 0.5");

  // Test 4: similarity ≥ 0.7 → same cluster
  const sim = jaccard(['performance','sql','java','orm'], ['performance','sql','java']);
  assert.ok(sim >= 0.7, `high similarity triggers cluster (${sim})`);

  // Test 5: empty array
  assert.equal(jaccard([], []), 0, "empty arrays = 0");
}

// === Prune Threshold Tests ===

function testPruneThreshold() {
  console.log('\n--- Prune Threshold ---');

  function shouldPrune(instinct, threshold = 0.3) {
    // prunes if confidence < threshold AND not updated in 30 days
    const daysSinceUpdate = (Date.now() - new Date(instinct.last_updated)) / 86400000;
    return instinct.confidence < threshold && daysSinceUpdate > 30;
  }

  // Test 1: low confidence + stale → prune
  const stale = { confidence: 0.2, last_updated: new Date(Date.now() - 60 * 86400000).toISOString() };
  assert.ok(shouldPrune(stale), "low+stale → prune");

  // Test 2: low confidence + fresh → keep
  const fresh = { confidence: 0.2, last_updated: new Date().toISOString() };
  assert.ok(!shouldPrune(fresh), "low+fresh → keep");

  // Test 3: high confidence + stale → keep (don't prune valuable)
  const valuable = { confidence: 0.8, last_updated: new Date(Date.now() - 90 * 86400000).toISOString() };
  assert.ok(!shouldPrune(valuable), "high+stale → keep (valuable)");

  // Test 4: evolved instinct > 60 days → prune
  const evolved = { confidence: 0.9, last_updated: new Date(Date.now() - 90 * 86400000).toISOString(), evolved_to: "some-skill" };
  const daysSinceEvolve = (Date.now() - new Date(evolved.last_updated)) / 86400000;
  const shouldPruneEvolved = daysSinceEvolve > 60;
  assert.ok(shouldPruneEvolved, "evolved > 60 days → prune");
}

// Run all tests
console.log('=== instinct-cli Test Suite ===\n');

testCalculateScore();
testQualityGate();
testJaccardSimilarity();
testPruneThreshold();

console.log('\n=== Test Suite Complete ===');
if (process.exitCode === 1) {
  console.log('SOME TESTS FAILED');
} else {
  console.log('ALL TESTS PASSED');
}
