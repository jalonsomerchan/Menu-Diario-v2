<script setup>
import {
  PhArrowsClockwise,
  PhBell,
  PhCalendarBlank,
  PhCookingPot,
  PhArrowsClockwise,
  PhForkKnife,
  PhGear,
  PhHouse,
  PhLeaf,
  PhList,
  PhListChecks,
  PhShoppingCart,
  PhSignOut,
} from '@phosphor-icons/vue'

defineProps({
  user: { type: Object, default: null },
  baseUrl: { type: String, required: true },
  asset: { type: Function, required: true },
  routeName: { type: String, default: '' },
  menuOpen: Boolean,
  notificationsOpen: Boolean,
  notifications: { type: Array, default: () => [] },
  unreadCount: { type: Number, default: 0 },
  formatNotificationDate: { type: Function, required: true },
})

defineEmits([
  'navigate',
  'toggle-menu',
  'toggle-notifications',
  'mark-all-read',
  'mark-read',
  'logout',
])

const navigation = [
  { route: 'dashboard', label: 'Planificador', icon: PhHouse },
  { route: 'dishes', label: 'Platos del grupo', icon: PhForkKnife },
  { route: 'dish-merge', label: 'Fusionar platos', icon: PhArrowsClockwise },
  { route: 'ingredients', label: 'Ingredientes', icon: PhLeaf },
  { route: 'ingredient-merge', label: 'Fusionar ingredientes', icon: PhArrowsClockwise },
  { route: 'tuppers', label: 'Mis tuppers', icon: PhCookingPot },
  { route: 'shopping', label: 'Lista de la compra', icon: PhShoppingCart },
  { route: 'calendar', label: 'Calendario', icon: PhCalendarBlank },
  { route: 'tasks', label: 'Tareas', icon: PhListChecks },
  { route: 'settings', label: 'Ajustes', icon: PhGear },
]
</script>

<template>
  <header class="topbar">
    <a
      v-if="user"
      :href="baseUrl"
      class="brand-mark brand-link"
      aria-label="Ir al planificador"
      @click.prevent="$emit('navigate', 'dashboard')"
    >
      <img class="brand-icon" :src="asset('icons/menu-diario-96.png')" alt="" aria-hidden="true" />
      <div><strong>Menu Diario</strong><small>Comer bien, cada día</small></div>
    </a>
    <div v-else class="brand-mark">
      <img class="brand-icon" :src="asset('icons/menu-diario-96.png')" alt="" aria-hidden="true" />
      <div><strong>Menu Diario</strong><small>Comer bien, cada día</small></div>
    </div>
    <div v-if="user" class="navigation-menu">
      <button
        type="button"
        class="menu-trigger"
        :aria-expanded="menuOpen"
        :aria-label="menuOpen ? 'Cerrar menú' : 'Abrir menú'"
        aria-controls="main-navigation"
        @click.stop="$emit('toggle-menu')"
      >
        <PhList :size="22" weight="regular" /><span>Menú</span>
      </button>
      <nav
        v-if="menuOpen"
        id="main-navigation"
        class="navigation-panel"
        aria-label="Navegación principal"
        @click.stop
      >
        <button
          v-for="item in navigation"
          :key="item.route"
          type="button"
          :class="{ active: routeName === item.route }"
          :aria-current="routeName === item.route ? 'page' : undefined"
          @click="$emit('navigate', item.route)"
        >
          <component :is="item.icon" :size="19" weight="regular" /><span>{{ item.label }}</span>
        </button>
      </nav>
    </div>
    <div v-if="user" class="account-actions">
      <span class="user-name">{{ user.displayName || user.email }}</span>
      <div class="notification-menu">
        <button
          class="round-icon-button notification-trigger"
          title="Abrir notificaciones"
          aria-label="Abrir notificaciones"
          :aria-expanded="notificationsOpen"
          aria-controls="notifications-panel"
          @click.stop="$emit('toggle-notifications')"
        >
          <PhBell :size="22" weight="regular" /><span
            v-if="unreadCount"
            class="notification-badge"
            >{{ unreadCount > 99 ? '99+' : unreadCount }}</span
          >
        </button>
        <div
          v-if="notificationsOpen"
          id="notifications-panel"
          class="notifications-panel"
          @click.stop
        >
          <div class="notifications-header">
            <div>
              <strong>Notificaciones</strong
              ><small>{{ unreadCount ? `${unreadCount} sin leer` : 'Todo leído' }}</small>
            </div>
            <button
              v-if="unreadCount"
              type="button"
              class="text-button"
              @click="$emit('mark-all-read')"
            >
              Marcar todas como leídas
            </button>
          </div>
          <div v-if="!notifications.length" class="notifications-empty">
            No hay notificaciones todavía.
          </div>
          <div v-else class="notification-list">
            <article
              v-for="notification in notifications"
              :key="notification.id"
              class="notification-item"
              :class="{ unread: !notification.read }"
            >
              <div class="notification-copy">
                <strong>{{ notification.message }}</strong
                ><small>{{ formatNotificationDate(notification.created_at) }}</small>
              </div>
              <button
                v-if="!notification.read"
                type="button"
                class="text-button"
                @click="$emit('mark-read', notification)"
              >
                Marcar leída
              </button>
            </article>
          </div>
        </div>
      </div>
      <button
        class="round-icon-button"
        title="Cerrar sesión"
        aria-label="Cerrar sesión"
        @click="$emit('logout')"
      >
        <PhSignOut :size="22" weight="regular" />
      </button>
    </div>
  </header>
</template>
