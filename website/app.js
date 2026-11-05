/**
 * VECTIS AI — Interactive Platform Experience Script
 * Modern vanilla JavaScript handling theme toggling, simulation engine,
 * pricing calculation, modal flows, and accessibility features.
 */

// State Management
const appState = {
  themeIndex: 0,
  themes: ['default', 'theme-midnight', 'theme-dim'],
  isAnnualBilling: false,
  activeCity: 'tokyo',
  cities: {
    tokyo: {
      name: 'Tokyo (Shinjuku)',
      coords: `35°41'22.1"N 139°41'30.2"E`,
      candidate1: 'Candidate #1 — Shinjuku Block 4',
      clues1: 'Concrete awning structure, overhead cable bundle',
      score1: '98.4%',
      candidate2: 'Candidate #2 — Shibuya Crossing N',
      clues2: 'Pavement stone layout, curb angle',
      score2: '84.7%',
      candidate3: 'Candidate #3 — Ginza 6-Chome',
      clues3: 'Masonry style match',
      score3: '68.2%'
    },
    london: {
      name: 'London (Canary Wharf)',
      coords: `51°30'18.4"N 0°01'12.8"W`,
      candidate1: 'Candidate #1 — Bank Street Pier',
      clues1: 'Glass panel reflection index, dockside bollard pattern',
      score1: '99.1%',
      candidate2: 'Candidate #2 — Isle of Dogs Promenade',
      clues2: 'Thames riverwall concrete aggregate match',
      score2: '89.3%',
      candidate3: 'Candidate #3 — Greenwich Reach',
      clues3: 'Brick masonry shadow alignment',
      score3: '71.5%'
    },
    sanfrancisco: {
      name: 'San Francisco (Mission)',
      coords: `37°45'34.8"N 122°25'06.2"W`,
      candidate1: 'Candidate #1 — Valencia & 18th St',
      clues1: 'Victorian bay window spacing, fire escape bracket style',
      score1: '97.8%',
      candidate2: 'Candidate #2 — Dolores Park West',
      clues2: 'Palm tree crown canopy & tram rail footprint',
      score2: '86.4%',
      candidate3: 'Candidate #3 — Potrero Hill Apex',
      clues3: 'Slope gradient and horizon line match',
      score3: '74.0%'
    },
    dubai: {
      name: 'Dubai (Marina)',
      coords: `25°04'52.3"N 55°08'41.0"E`,
      candidate1: 'Candidate #1 — Marina Walk Sector B',
      clues1: 'Interlocking pavers, curved yacht berth stanchion',
      score1: '98.9%',
      candidate2: 'Candidate #2 — Jumeirah Beach Residence',
      clues2: 'Sandstone facade texture & palm planter spacing',
      score2: '88.0%',
      candidate3: 'Candidate #3 — Bluewaters Causeway',
      clues3: 'Bridge pier shadow azimuth',
      score3: '70.6%'
    },
    dhaka: {
      name: 'Dhaka (Gulshan-2)',
      coords: `23°47'33.6"N 90°24'58.2"E`,
      candidate1: 'Candidate #1 — Madani Avenue Roundabout',
      clues1: 'Overhead transformer bracket, brick boundary wall contour',
      score1: '96.9%',
      candidate2: 'Candidate #2 — Banani Lake Bridge Approach',
      clues2: 'Reinforced concrete parapet bevel, roadside tree crown',
      score2: '85.2%',
      candidate3: 'Candidate #3 — Baridhara Diplomatic Zone',
      clues3: 'Pavement paver block color scheme',
      score3: '76.8%'
    }
  }
};

// 1. Navigation & Scroll Effects
window.addEventListener('DOMContentLoaded', () => {
  initTheme();
  initScrollNav();
  initLiveClock();
  setupNavHighlight();
});

function initScrollNav() {
  const navbar = document.getElementById('navbar');
  const mobileBtn = document.getElementById('mobileMenuBtn');
  const mobileDrawer = document.getElementById('mobileDrawer');

  window.addEventListener('scroll', () => {
    if (window.scrollY > 40) {
      navbar.style.background = 'rgba(10, 10, 10, 0.88)';
      navbar.style.boxShadow = '0 25px 50px -12px rgba(0, 0, 0, 0.95), inset 0 1px 0 rgba(255, 255, 255, 0.16)';
    } else {
      navbar.style.background = 'var(--surface-glass)';
      navbar.style.boxShadow = 'var(--shadow-nav)';
    }
  });

  if (mobileBtn && mobileDrawer) {
    mobileBtn.addEventListener('click', () => {
      const isVisible = mobileDrawer.style.display === 'block';
      mobileDrawer.style.display = isVisible ? 'none' : 'block';
    });

    document.querySelectorAll('.mobile-link').forEach(link => {
      link.addEventListener('click', () => {
        mobileDrawer.style.display = 'none';
      });
    });
  }
}

// Active Nav Link Spy on Scroll
function setupNavHighlight() {
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-links a');

  window.addEventListener('scroll', () => {
    let current = '';
    const scrollY = window.pageYOffset;

    sections.forEach(section => {
      const sectionHeight = section.offsetHeight;
      const sectionTop = section.offsetTop - 140;
      if (scrollY >= sectionTop && scrollY < sectionTop + sectionHeight) {
        current = section.getAttribute('id');
      }
    });

    navLinks.forEach(link => {
      link.classList.remove('active');
      if (link.getAttribute('href') === `#${current}`) {
        link.classList.add('active');
      }
    });
  });
}

// 2. Theme Switching Logic (Obsidian -> Midnight -> Dim)
function initTheme() {
  const savedTheme = localStorage.getItem('vectis_theme');
  if (savedTheme) {
    document.body.className = savedTheme;
  }

  const themeBtn = document.getElementById('themeToggleBtn');
  if (themeBtn) {
    themeBtn.addEventListener('click', () => {
      appState.themeIndex = (appState.themeIndex + 1) % appState.themes.length;
      const nextTheme = appState.themes[appState.themeIndex];
      document.body.className = nextTheme === 'default' ? '' : nextTheme;
      localStorage.setItem('vectis_theme', document.body.className);
    });
  }
}

// 3. Live UTC Clock in HUD
function initLiveClock() {
  const timeElem = document.getElementById('liveTimestamp');
  if (!timeElem) return;

  function update() {
    const now = new Date();
    const utcString = now.toISOString().replace('T', ' ').substring(0, 19) + ' UTC';
    timeElem.textContent = utcString;
  }
  update();
  setInterval(update, 1000);
}

// 4. Interactive Live City Simulator
function simulateCity(cityKey, buttonElement) {
  if (!appState.cities[cityKey]) return;
  appState.activeCity = cityKey;
  const data = appState.cities[cityKey];

  // Update tabs
  document.querySelectorAll('#demo .tab-btn').forEach(btn => btn.classList.remove('active'));
  if (buttonElement) buttonElement.classList.add('active');

  // Update labels
  const cityLabel = document.getElementById('demoCityLabel');
  const demoCoords = document.getElementById('demoCoords');
  const cand1Name = document.getElementById('cand1Name');
  const cand1Details = document.getElementById('cand1Details');
  const cand1Score = document.getElementById('cand1Score');
  const cand2Name = document.getElementById('cand2Name');
  const cand2Score = document.getElementById('cand2Score');
  const cand3Name = document.getElementById('cand3Name');
  const cand3Score = document.getElementById('cand3Score');
  const hudCoords = document.getElementById('hudCoords');

  if (cityLabel) cityLabel.textContent = `Target: ${data.name}`;
  if (demoCoords) demoCoords.textContent = data.coords;
  if (hudCoords) hudCoords.textContent = data.coords;

  if (cand1Name) cand1Name.textContent = data.candidate1;
  if (cand1Details) cand1Details.textContent = `Clues: ${data.clues1}`;
  if (cand1Score) cand1Score.textContent = data.score1;

  if (cand2Name) cand2Name.textContent = data.candidate2;
  if (cand2Score) cand2Score.textContent = data.score2;

  if (cand3Name) cand3Name.textContent = data.candidate3;
  if (cand3Score) cand3Score.textContent = data.score3;
}

function runSimulation() {
  const statusElem = document.getElementById('demoStatus');
  const scoreElem = document.getElementById('cand1Score');
  if (!statusElem) return;

  statusElem.textContent = 'NEURAL COMPUTING...';
  statusElem.style.color = '#ffbd2e';

  setTimeout(() => {
    statusElem.textContent = 'MATCH CONFIRMED (100% LOCK)';
    statusElem.style.color = '#22c55e';
    if (scoreElem) {
      scoreElem.style.transform = 'scale(1.15)';
      setTimeout(() => {
        scoreElem.style.transform = 'scale(1)';
      }, 300);
    }
  }, 600);
}

// 5. Pricing Billing Switch (Monthly vs Annual 20% discount)
function toggleBilling() {
  appState.isAnnualBilling = !appState.isAnnualBilling;
  const pill = document.getElementById('billingSwitch');
  const monthlyLabel = document.getElementById('monthlyLabel');
  const annualLabel = document.getElementById('annualLabel');
  const starterElem = document.getElementById('priceStarter');
  const proElem = document.getElementById('pricePro');

  if (appState.isAnnualBilling) {
    pill.classList.add('active');
    pill.setAttribute('aria-checked', 'true');
    monthlyLabel.style.color = 'var(--text-secondary)';
    annualLabel.style.color = '#fff';
    annualLabel.style.fontWeight = '600';

    if (starterElem) starterElem.innerHTML = '$63<span> / month (billed $756/yr)</span>';
    if (proElem) proElem.innerHTML = '$199<span> / month (billed $2,388/yr)</span>';
  } else {
    pill.classList.remove('active');
    pill.setAttribute('aria-checked', 'false');
    monthlyLabel.style.color = '#fff';
    monthlyLabel.style.fontWeight = '600';
    annualLabel.style.color = 'var(--text-secondary)';
    annualLabel.style.fontWeight = 'normal';

    if (starterElem) starterElem.innerHTML = '$79<span> / month</span>';
    if (proElem) proElem.innerHTML = '$249<span> / month</span>';
  }
}

// 6. Solutions & Use Cases Tabs
function switchTab(tabId, btnElement) {
  document.querySelectorAll('.tab-btn').forEach(btn => {
    if (btn.closest('#solutions')) btn.classList.remove('active');
  });
  if (btnElement) btnElement.classList.add('active');

  document.querySelectorAll('#solutions .tab-content').forEach(content => {
    content.classList.remove('active');
  });

  const target = document.getElementById(`tab-${tabId}`);
  if (target) target.classList.add('active');
}

// 7. Smooth FAQ Accordion
function toggleFaq(questionHeader) {
  const item = questionHeader.closest('.faq-item');
  const isOpen = item.classList.contains('open');

  // Optional: close other open items for clean luxury feel
  document.querySelectorAll('.faq-item').forEach(el => el.classList.remove('open'));

  if (!isOpen) {
    item.classList.add('open');
  }
}

// 8. Smooth Scrolling Helper
function scrollToElement(id) {
  const target = document.getElementById(id);
  if (target) {
    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
}

// 9. Interactive Modal Handling
function openModal(tierName) {
  const modal = document.getElementById('dashboardModal');
  const tierField = document.getElementById('tierSelect');
  if (tierField && tierName) {
    tierField.value = `${tierName} Plan Request`;
  }
  if (modal) {
    modal.classList.add('open');
    const emailInput = document.getElementById('workEmail');
    if (emailInput) setTimeout(() => emailInput.focus(), 150);
  }
}

function closeModal() {
  const modal = document.getElementById('dashboardModal');
  if (modal) {
    modal.classList.remove('open');
    const feedback = document.getElementById('formFeedback');
    if (feedback) feedback.style.display = 'none';
  }
}

// Close on backdrop click & Escape key
window.addEventListener('click', (e) => {
  const modal = document.getElementById('dashboardModal');
  if (modal && e.target === modal) {
    closeModal();
  }
});

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    closeModal();
  }
});

function handleFormSubmit(e) {
  e.preventDefault();
  const feedback = document.getElementById('formFeedback');
  const email = document.getElementById('workEmail').value;

  if (feedback) {
    feedback.style.display = 'block';
    feedback.style.background = 'rgba(34, 197, 94, 0.15)';
    feedback.style.color = '#22c55e';
    feedback.style.border = '1px solid rgba(34, 197, 94, 0.3)';
    feedback.innerHTML = `✓ Verification key dispatched to <strong>${escapeHtml(email)}</strong>. Redirecting to mission workspace...`;

    setTimeout(() => {
      closeModal();
      alert(`Welcome to Vectis Mission Control! Credentials validated for ${email}.`);
    }, 1800);
  }
}

function escapeHtml(string) {
  return String(string)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// Attach open dashboard button
document.addEventListener('DOMContentLoaded', () => {
  const dashBtn = document.getElementById('openDashboardBtn');
  if (dashBtn) {
    dashBtn.addEventListener('click', () => openModal('Enterprise Access'));
  }
});
