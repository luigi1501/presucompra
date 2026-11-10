// ── Variables & Configuración del Simulador ─────────────────────────────
let liveTasaBsUsd = 897.54;

const totalInput = document.getElementById('sim-total');
const cashInput = document.getElementById('sim-cash');
const totalBsDisplay = document.getElementById('sim-total-bs');
const rateDisplay = document.getElementById('sim-rate-display');
const heroRateTag = document.getElementById('hero-rate-tag');
const liveRateTag = document.getElementById('live-rate-tag');

const resultBox = document.getElementById('sim-result-box');
const resultTitle = document.getElementById('sim-result-title');
const resultPrimary = document.getElementById('sim-result-primary');
const resultSub = document.getElementById('sim-result-sub');

// ── Consulta opcional de tasa real del BCV al cargar ─────────────────────
async function fetchLiveBcvRate() {
  try {
    const res = await fetch('https://ve.dolarapi.com/v1/dolares/oficial');
    if (res.ok) {
      const data = await res.json();
      if (data.promedio && data.promedio > 0) {
        liveTasaBsUsd = data.promedio;
        if (rateDisplay) rateDisplay.textContent = `${formatBs(liveTasaBsUsd)} Bs./$`;
        if (heroRateTag) heroRateTag.textContent = `${formatBs(liveTasaBsUsd)} Bs./$`;
        if (liveRateTag) liveRateTag.textContent = `${formatBs(liveTasaBsUsd)} Bs.`;
        updateSimulator();
      }
    }
  } catch (err) {
    console.log('[Landing] Usando tasa de referencia inicial:', liveTasaBsUsd);
  }
}

// ── Formateo con estilo venezolano (puntos para miles, comas para decimales) ─
function formatBs(amount) {
  const parts = Math.abs(amount).toFixed(2).split('.');
  parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  return parts.join(',');
}

function formatUsd(amount) {
  return `$${Math.abs(amount).toFixed(2)}`;
}

// ── Lógica Interactiva del Simulador de Caja ─────────────────────────────
function updateSimulator() {
  const totalUsd = parseFloat(totalInput.value) || 0.0;
  const cashUsd = parseFloat(cashInput.value) || 0.0;

  const totalBs = totalUsd * liveTasaBsUsd;
  totalBsDisplay.textContent = `≈ ${formatBs(totalBs)} Bs.`;

  // Remover clases previas
  resultBox.classList.remove('exact', 'vuelto');

  if (totalUsd <= 0) {
    resultTitle.textContent = 'Ingresa el total a pagar arriba';
    resultPrimary.textContent = '0,00 Bs.';
    resultSub.textContent = 'Escribe el monto de la compra';
    return;
  }

  const diferenciaUsd = cashUsd - totalUsd;
  const diferenciaBs = Math.abs(diferenciaUsd) * liveTasaBsUsd;

  if (diferenciaUsd < -0.009) {
    // Falta dinero -> Restante a pagar en Pago Móvil
    resultTitle.textContent = 'Restante exacto a transferir en Pago Móvil:';
    resultPrimary.textContent = `${formatBs(diferenciaBs)} Bs.`;
    resultSub.textContent = `Equivale a ${formatUsd(Math.abs(diferenciaUsd))} restantes`;
  } else if (diferenciaUsd > 0.009) {
    // Sobra dinero -> Vuelto a favor del cliente
    resultBox.classList.add('vuelto');
    resultTitle.textContent = 'Vuelto para ti (Cambio):';
    resultPrimary.textContent = formatUsd(diferenciaUsd);
    resultSub.textContent = `O en Bolívares: ${formatBs(diferenciaBs)} Bs.`;
  } else {
    // Pago Exacto
    resultBox.classList.add('exact');
    resultTitle.textContent = '¡Pago Exacto! 🎉';
    resultPrimary.textContent = 'Cuenta saldada';
    resultSub.textContent = `El efectivo de ${formatUsd(cashUsd)} cubre el 100% de la cuenta`;
  }
}

// ── Botones de Billetes Rápidos ──────────────────────────────────────────
function setSimCash(amount) {
  cashInput.value = amount.toFixed(2);
  document.querySelectorAll('.quick-chips .chip').forEach(btn => {
    btn.classList.toggle('active', btn.textContent.trim() === `$${amount}`);
  });
  updateSimulator();
}

// ── Listeners de Inputs ──────────────────────────────────────────────────
totalInput.addEventListener('input', () => {
  updateSimulator();
});

cashInput.addEventListener('input', () => {
  document.querySelectorAll('.quick-chips .chip').forEach(btn => {
    btn.classList.remove('active');
  });
  updateSimulator();
});

// ── Botón de descarga con aviso amigable si el APK aún no está compilado ──
document.getElementById('btn-download-apk')?.addEventListener('click', (e) => {
  // Comprobar si el archivo local existe o dar instrucciones
  console.log('[PresuCompra] Iniciando descarga del APK...');
});

// ── Estado de la Demo Interactiva en el Modal ───────────────────────────
let demoProducts = [
  { id: 1, name: 'Harina P.A.N.', price: 1.25, qty: 2, checked: false },
  { id: 2, name: 'Queso Blanco Llanero', price: 5.50, qty: 1, checked: false },
  { id: 3, name: 'Pollo Entero (Fresco)', price: 11.20, qty: 1, checked: true },
  { id: 4, name: 'Café Molido 500g', price: 4.80, qty: 1, checked: false },
  { id: 5, name: 'Arroz Blanco Mary', price: 1.40, qty: 2, checked: true }
];
const demoBudgetLimit = 100.00;

function openDemoModal() {
  const overlay = document.getElementById('demoModalOverlay');
  if (!overlay) return;
  overlay.classList.add('open');
  document.body.style.overflow = 'hidden';

  // Actualizar hora del teléfono
  const now = new Date();
  const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  const timeElem = document.getElementById('demoCurrentTime');
  if (timeElem) timeElem.textContent = timeStr;

  // Actualizar badge BCV en teléfono
  const bcvBadge = document.getElementById('demoBcvBadge');
  if (bcvBadge) bcvBadge.textContent = `BCV: ${formatBs(liveTasaBsUsd)}`;

  renderDemoProducts();
  recalculateDemoBudget();
}

function closeDemoModal() {
  const overlay = document.getElementById('demoModalOverlay');
  if (!overlay) return;
  overlay.classList.remove('open');
  document.body.style.overflow = '';
}

function closeDemoModalOnOverlay(event) {
  if (event.target.id === 'demoModalOverlay') {
    closeDemoModal();
  }
}

function switchDemoTab(tab) {
  const tabLista = document.getElementById('tabLista');
  const tabCaja = document.getElementById('tabCaja');
  const contentLista = document.getElementById('contentLista');
  const contentCaja = document.getElementById('contentCaja');

  if (tab === 'lista') {
    tabLista?.classList.add('active');
    tabCaja?.classList.remove('active');
    contentLista?.classList.add('active');
    contentCaja?.classList.remove('active');
  } else {
    tabCaja?.classList.add('active');
    tabLista?.classList.remove('active');
    contentCaja?.classList.add('active');
    contentLista?.classList.remove('active');

    // Sincronizar el total actual de la lista con el monto a pagar en Modo Caja
    const totalUsd = demoProducts.reduce((sum, p) => sum + (p.price * p.qty), 0);
    const cajaTotalInput = document.getElementById('demoCajaTotal');
    if (cajaTotalInput) {
      cajaTotalInput.value = totalUsd.toFixed(2);
      updateDemoCaja();
    }
  }
}

function renderDemoProducts() {
  const container = document.getElementById('demoProductList');
  if (!container) return;
  container.innerHTML = '';

  demoProducts.forEach(prod => {
    const item = document.createElement('div');
    item.className = `demo-item ${prod.checked ? 'checked' : ''}`;
    item.onclick = (e) => {
      if (e.target.tagName !== 'BUTTON') {
        toggleDemoProduct(prod.id);
      }
    };

    const subtotal = prod.price * prod.qty;

    item.innerHTML = `
      <div class="demo-item-left">
        <div class="demo-checkbox">${prod.checked ? '✓' : ''}</div>
        <div>
          <span class="demo-item-name">${prod.name}</span>
          <span class="demo-item-qty">(${prod.qty}x $${prod.price.toFixed(2)})</span>
        </div>
      </div>
      <div style="display:flex;align-items:center;">
        <span class="demo-item-price mono">$${subtotal.toFixed(2)}</span>
        <button type="button" class="demo-item-del" onclick="deleteDemoProduct(${prod.id})" title="Eliminar">×</button>
      </div>
    `;

    container.appendChild(item);
  });
}

function toggleDemoProduct(id) {
  const prod = demoProducts.find(p => p.id === id);
  if (prod) {
    prod.checked = !prod.checked;
    renderDemoProducts();
  }
}

function deleteDemoProduct(id) {
  demoProducts = demoProducts.filter(p => p.id !== id);
  renderDemoProducts();
  recalculateDemoBudget();
}

function demoAddProduct() {
  const nameInput = document.getElementById('demoNewName');
  const priceInput = document.getElementById('demoNewPrice');
  if (!nameInput || !priceInput) return;

  const name = nameInput.value.trim();
  const price = parseFloat(priceInput.value);

  if (!name || isNaN(price) || price <= 0) {
    alert('Ingresa el nombre del producto y su precio en USD');
    return;
  }

  demoProducts.unshift({
    id: Date.now(),
    name: name,
    price: price,
    qty: 1,
    checked: false
  });

  nameInput.value = '';
  priceInput.value = '';
  renderDemoProducts();
  recalculateDemoBudget();
}

function recalculateDemoBudget() {
  const totalUsd = demoProducts.reduce((sum, p) => sum + (p.price * p.qty), 0);
  const totalBs = totalUsd * liveTasaBsUsd;
  const percent = Math.min((totalUsd / demoBudgetLimit) * 100, 100);
  const remainingUsd = Math.max(demoBudgetLimit - totalUsd, 0);

  const totalUsdElem = document.getElementById('demoTotalUsd');
  const totalBsElem = document.getElementById('demoTotalBs');
  const fillElem = document.getElementById('demoProgressFill');
  const percentElem = document.getElementById('demoPercentUsed');
  const remainingElem = document.getElementById('demoRemainingUsd');

  if (totalUsdElem) totalUsdElem.textContent = `$${totalUsd.toFixed(2)}`;
  if (totalBsElem) totalBsElem.textContent = `≈ ${formatBs(totalBs)} Bs.`;
  if (fillElem) fillElem.style.width = `${percent.toFixed(1)}%`;
  if (percentElem) percentElem.textContent = `${percent.toFixed(1)}% usado`;
  if (remainingElem) remainingElem.textContent = `Disponible: $${remainingUsd.toFixed(2)}`;
}

// ── Modo Caja en el Modal del Teléfono ──────────────────────────────────
function updateDemoCaja() {
  const totalInput = document.getElementById('demoCajaTotal');
  const cashInput = document.getElementById('demoCajaCash');
  const resultBox = document.getElementById('demoCajaResult');
  const resLabel = document.getElementById('demoCajaResLabel');
  const resPrimary = document.getElementById('demoCajaResPrimary');
  const resSecondary = document.getElementById('demoCajaResSecondary');

  if (!totalInput || !cashInput || !resultBox) return;

  const totalUsd = parseFloat(totalInput.value) || 0.0;
  const cashUsd = parseFloat(cashInput.value) || 0.0;

  resultBox.classList.remove('vuelto');

  if (totalUsd <= 0) {
    resLabel.textContent = 'Ingresa el total arriba';
    resPrimary.textContent = '0,00 Bs.';
    resSecondary.textContent = 'Esperando monto...';
    return;
  }

  const difUsd = cashUsd - totalUsd;
  const difBs = Math.abs(difUsd) * liveTasaBsUsd;

  if (difUsd < -0.009) {
    resLabel.textContent = 'Restante por Pago Móvil:';
    resPrimary.textContent = `${formatBs(difBs)} Bs.`;
    resSecondary.textContent = `Equivale a $${Math.abs(difUsd).toFixed(2)} restantes`;
  } else if (difUsd > 0.009) {
    resultBox.classList.add('vuelto');
    resLabel.textContent = 'Vuelto para ti (Cambio):';
    resPrimary.textContent = `$${difUsd.toFixed(2)} USD`;
    resSecondary.textContent = `O en Bolívares: ${formatBs(difBs)} Bs.`;
  } else {
    resLabel.textContent = '¡Pago Exacto! 🎉';
    resPrimary.textContent = 'Cuenta saldada';
    resSecondary.textContent = `Efectivo cubre exactamente la cuenta`;
  }
}

function setDemoCajaCash(amount) {
  const cashInput = document.getElementById('demoCajaCash');
  if (cashInput) {
    cashInput.value = amount.toFixed(2);
    document.querySelectorAll('.demo-quick-bills .chip').forEach(btn => {
      btn.classList.toggle('active', btn.textContent.trim() === `$${amount}`);
    });
    updateDemoCaja();
  }
}

// Inicializar al cargar
document.addEventListener('DOMContentLoaded', () => {
  fetchLiveBcvRate();
  updateSimulator();
});

