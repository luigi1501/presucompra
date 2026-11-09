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

// Inicializar al cargar
document.addEventListener('DOMContentLoaded', () => {
  fetchLiveBcvRate();
  updateSimulator();
});

