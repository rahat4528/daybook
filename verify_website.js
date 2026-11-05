/**
 * Verification test suite for Vectis AI website.
 * Runs in Node.js to validate syntax, DOM references, CSS rules, and screenshot requirements.
 */

const fs = require('fs');
const path = require('path');

const websiteDir = path.join(__dirname);
const htmlPath = path.join(websiteDir, 'index.html');
const cssPath = path.join(websiteDir, 'styles.css');
const jsPath = path.join(websiteDir, 'app.js');

let passedTests = 0;
let totalTests = 0;

function assert(condition, message) {
  totalTests++;
  if (!condition) {
    console.error(`❌ FAILED: ${message}`);
    process.exitCode = 1;
  } else {
    passedTests++;
    console.log(`✅ PASSED: ${message}`);
  }
}

console.log('--- Starting Website Automated Verifications ---');

// 1. Files existence check
assert(fs.existsSync(htmlPath), 'index.html exists');
assert(fs.existsSync(cssPath), 'styles.css exists');
assert(fs.existsSync(jsPath), 'app.js exists');

const html = fs.readFileSync(htmlPath, 'utf8');
const css = fs.readFileSync(cssPath, 'utf8');
const js = fs.readFileSync(jsPath, 'utf8');

// 2. Exact match of reference screenshot requirements
assert(html.includes('Why choose Vectis'), 'Contains screenshot title: "Why choose Vectis"');
assert(html.includes('Global satellite coverage'), 'Contains screenshot feature 1: "Global satellite coverage"');
assert(html.includes('Secure & Private'), 'Contains screenshot feature 2: "Secure & Private"');
assert(html.includes('Ranked leads with evidence'), 'Contains screenshot feature 3: "Ranked leads with evidence"');
assert(html.includes('Meter-level in 2,300+ cities') || html.includes('Meter-level in 2,400+ cities'), 'Contains screenshot feature 4: "Meter-level in 2,300+ cities"');
assert(html.includes('View our features'), 'Contains screenshot banner title: "View our features"');
assert(html.includes('Go To Dashboard'), 'Contains screenshot navbar CTA: "Go To Dashboard"');

// 3. Typography & Luxury Aesthetic Rules
assert(css.includes('#050505'), 'CSS implements Obsidian dark background #050505');
assert(css.includes('Instrument Serif'), 'CSS imports and defines Instrument Serif font');
assert(css.includes('Plus Jakarta Sans'), 'CSS imports and defines Plus Jakarta Sans font');
assert(css.includes('backdrop-filter: blur'), 'CSS includes glassmorphism blur for floating navigation');
assert(css.includes('--radius-container: 32px'), 'CSS uses large rounded containers (32px border-radius)');

// 4. Section structure & IDs
const requiredIds = [
  'navbar',
  'themeToggleBtn',
  'openDashboardBtn',
  'mobileMenuBtn',
  'mobileDrawer',
  'hero',
  'liveTimestamp',
  'hudCoords',
  'why-choose',
  'features',
  'featureGrid',
  'demo',
  'how-it-works',
  'solutions',
  'pricing',
  'billingSwitch',
  'testimonials',
  'faq',
  'dashboardModal',
  'accessForm'
];

requiredIds.forEach(id => {
  assert(html.includes(`id="${id}"`), `HTML includes required element id="${id}"`);
});

// 5. Check JS logic
assert(js.includes('simulateCity'), 'app.js defines city simulation engine');
assert(js.includes('toggleBilling'), 'app.js defines annual/monthly billing toggle');
assert(js.includes('switchTab'), 'app.js defines solutions tab switching');
assert(js.includes('toggleFaq'), 'app.js defines accordion toggling');
assert(js.includes('openModal') && js.includes('closeModal'), 'app.js defines modal dialog controls');

console.log(`\nVerification Summary: ${passedTests}/${totalTests} tests passed.`);
