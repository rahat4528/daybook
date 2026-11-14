/**
 * Verification test suite for DayBook Showcase Website.
 * Validates DOM integrity, required sections, OLED color tokens, and download CTAs.
 */

const fs = require('fs');
const path = require('path');

const websiteDir = __dirname;
const htmlPath = path.join(websiteDir, 'index.html');
const cssPath = path.join(websiteDir, 'styles.css');

let passedTests = 0;
let totalTests = 0;

function assert(condition, message) {
  totalTests++;
  if (!condition) {
    console.error(`[FAIL] ${message}`);
    process.exitCode = 1;
  } else {
    passedTests++;
    console.log(`[PASS] ${message}`);
  }
}

console.log('--- Starting DayBook Website Automated Verifications ---');

// 1. Files existence check
assert(fs.existsSync(htmlPath), 'index.html exists');
assert(fs.existsSync(cssPath), 'styles.css exists');

const html = fs.readFileSync(htmlPath, 'utf8');
const css = fs.readFileSync(cssPath, 'utf8');

// 2. DayBook Core Identity and Branding
assert(html.includes('DayBook'), 'HTML contains "DayBook" title branding');
assert(html.includes('Offline-First') || html.includes('offline-first'), 'HTML states Offline-First architectural pillar');
assert(html.includes('Bangla-First') || html.includes('Bilingual'), 'HTML highlights Bangla-First linguistic support');
assert(html.includes('Wake Quest'), 'HTML showcases Wake Quest native alarm engine');
assert(html.includes('Dhar') || html.includes('Money Ledger'), 'HTML highlights Dhar Ledger & Personal CRM');
assert(html.includes('Zero-Knowledge') || html.includes('SQLCipher'), 'HTML documents Zero-Knowledge security architecture');
assert(html.includes('.apk') || html.includes('Download'), 'HTML includes direct APK install link');

// 3. Design Tokens & Visual Language
assert(html.includes('#B6FF00') || css.includes('#B6FF00'), 'Design system implements Lime Accent #B6FF00');
assert(html.includes('#050505') || html.includes('#000000') || css.includes('#000000') || css.includes('#050505'), 'Implements true OLED Obsidian/Black background');

// 4. Section structure & Semantic IDs
const requiredIds = [
  'navbar',
  'navLinks',
  'downloadApkNavBtn',
  'hero',
  'features',
  'alarms',
  'ledger',
  'architecture',
  'install'
];

requiredIds.forEach(id => {
  assert(html.includes(`id="${id}"`), `HTML includes required element id="${id}"`);
});

console.log(`\nDayBook Website Verification Summary: ${passedTests}/${totalTests} tests passed.`);
if (passedTests === totalTests) {
  console.log('=== ALL DAYBOOK WEBSITE VERIFICATIONS PASSED ===\n');
}
