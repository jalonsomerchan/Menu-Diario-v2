<script setup>
import { PhDownloadSimple, PhX } from '@phosphor-icons/vue'

defineProps({
  visible: Boolean,
  asset: { type: Function, required: true },
})

defineEmits(['install', 'dismiss'])
</script>

<template>
  <aside v-if="visible" class="install-banner" aria-live="polite">
    <img :src="asset('icons/menu-diario-96.png')" alt="" aria-hidden="true" />
    <div><strong>Instala Menu Diario</strong><span>Ten tu planificador siempre a mano.</span></div>
    <button type="button" class="primary-button install-button" @click="$emit('install')">
      <PhDownloadSimple :size="18" /> Instalar
    </button>
    <button
      type="button"
      class="icon-button install-dismiss"
      aria-label="Cerrar aviso de instalación"
      @click="$emit('dismiss')"
    >
      <PhX :size="20" />
    </button>
  </aside>
</template>
