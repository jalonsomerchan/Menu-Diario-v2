<script setup>
defineProps({
  visible: Boolean,
  asset: { type: Function, required: true },
})
</script>

<template>
  <div
    v-if="visible"
    class="app-loading-screen"
    role="status"
    aria-live="polite"
    aria-label="Cargando Menu Diario"
  >
    <div class="app-loading-content">
      <div class="app-loading-logo-wrap">
        <img
          class="loading-logo"
          :src="asset('icons/menu-diario-144.png')"
          alt=""
          aria-hidden="true"
        />
        <span class="app-loading-pulse" aria-hidden="true"></span>
      </div>
      <div class="loading-copy">
        <strong>Menu Diario</strong><span>Preparando tu planificador…</span>
      </div>
      <div class="loading-progress" aria-hidden="true"><span></span></div>
    </div>
  </div>
</template>
