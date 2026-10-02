<script setup>
import { computed } from 'vue'
import {
  PhArrowRight,
  PhArrowsClockwise,
  PhCalendarBlank,
  PhCheck,
  PhCheckCircle,
  PhForkKnife,
  PhLeaf,
  PhNote,
  PhShoppingCart,
  PhSparkle,
  PhSpinnerGap,
  PhSpeakerHigh,
  PhWarningCircle,
} from '@phosphor-icons/vue'
import { mealLabels } from '../../lib/ui'

const props = defineProps({
  days: { type: Array, required: true },
  selected: { type: Set, required: true },
  rangeDraft: { type: Object, required: true },
  range: { type: Object, required: true },
  loading: Boolean,
  loadError: { type: String, default: '' },
  generating: Boolean,
  warning: { type: String, default: '' },
  missing: { type: Array, required: true },
  items: { type: Array, required: true },
  excluded: { type: Array, required: true },
  groups: { type: Array, required: true },
  checked: { type: Set, required: true },
  pendingOnly: Boolean,
  supermarketLogo: { type: Function, required: true },
  isDarkLogo: { type: Function, required: true },
})
const emit = defineEmits([
  'range-field',
  'load',
  'preset',
  'toggle-dish',
  'select-dishes',
  'toggle-item',
  'pending-only',
  'reset-checks',
  'complete',
  'edit-dish',
  'plan',
  'copy',
  'alexa',
])
const allKeys = computed(() => props.days.flatMap((day) => day.dishes.map((dish) => dish.key)))
const selectedCount = computed(() => allKeys.value.filter((key) => props.selected.has(key)).length)
const pending = computed(() => props.items.filter((item) => !props.checked.has(item.key)).length)
const completed = computed(() => props.items.length - pending.value)
const percent = computed(() =>
  props.items.length ? Math.round((completed.value / props.items.length) * 100) : 0,
)
const selectedInDay = (day) => day.dishes.filter((dish) => props.selected.has(dish.key)).length
const formatDate = (value) =>
  new Intl.DateTimeFormat('es', { day: 'numeric', month: 'short' }).format(
    new Date(`${value}T12:00:00`),
  )
</script>

<template>
  <div class="purchase-workspace">
    <header class="purchase-heading">
      <div>
        <p class="eyebrow">DEL MENÚ A TU CESTA</p>
        <h1>Lista de la compra</h1>
        <p>Elige tus platos. Los ingredientes se añaden al momento.</p>
      </div>
      <a class="purchase-jump" href="#purchase-list">Ver mi lista <PhArrowRight :size="18" /></a>
    </header>

    <form class="purchase-range" @submit.prevent="emit('load')">
      <div class="purchase-range-label">
        <PhCalendarBlank :size="22" />
        <div><strong>¿Para cuándo compramos?</strong><small>Hasta 14 días de tu menú</small></div>
      </div>
      <div class="purchase-date-fields">
        <label
          >Desde<input
            type="date"
            :value="rangeDraft.from"
            required
            :disabled="loading"
            @input="emit('range-field', 'from', $event.target.value)"
        /></label>
        <span aria-hidden="true">→</span>
        <label
          >Hasta<input
            type="date"
            :value="rangeDraft.to"
            :min="rangeDraft.from"
            required
            :disabled="loading"
            @input="emit('range-field', 'to', $event.target.value)"
        /></label>
      </div>
      <button type="submit" class="secondary-button" :disabled="loading">
        <PhSpinnerGap v-if="loading" class="spin-icon" :size="17" /><PhArrowsClockwise
          v-else
          :size="17"
        />
        Actualizar menú
      </button>
      <div class="purchase-presets">
        <button type="button" :disabled="loading" @click="emit('preset', 7)">7 días</button
        ><button type="button" :disabled="loading" @click="emit('preset', 14)">14 días</button>
      </div>
    </form>
    <div v-if="loadError" class="purchase-alert" role="alert">
      <PhWarningCircle :size="21" />
      <div>
        <strong>No se ha actualizado el menú</strong>
        <p>{{ loadError }}</p>
      </div>
      <button type="button" class="text-button" :disabled="loading" @click="emit('load')">
        Reintentar
      </button>
    </div>

    <div class="purchase-summary" aria-live="polite" aria-atomic="true">
      <span
        ><PhForkKnife :size="18" /><strong>{{ selectedCount }}</strong> platos elegidos</span
      >
      <span
        ><PhShoppingCart :size="18" /><strong>{{ items.length }}</strong> productos</span
      >
      <span v-if="missing.length" class="purchase-summary-warning"
        ><PhWarningCircle :size="18" /><strong>{{ missing.length }}</strong>
        {{ missing.length === 1 ? 'plato sin ingredientes' : 'platos sin ingredientes' }}</span
      >
      <span v-else-if="selectedCount" class="purchase-summary-ready"
        ><PhCheckCircle :size="18" /> Lista actualizada</span
      >
    </div>

    <div class="purchase-columns">
      <section class="purchase-menu" aria-labelledby="purchase-menu-title" :aria-busy="loading">
        <div class="purchase-section-title">
          <div>
            <span class="purchase-step">01 · TU MENÚ</span>
            <h2 id="purchase-menu-title">Lo que vas a cocinar</h2>
            <p>{{ formatDate(range.from) }} — {{ formatDate(range.to) }}</p>
          </div>
          <div v-if="allKeys.length" class="purchase-bulk">
            <button
              type="button"
              :disabled="loading || selectedCount === allKeys.length"
              @click="emit('select-dishes', allKeys, true)"
            >
              Todos</button
            ><button
              type="button"
              :disabled="loading || !selectedCount"
              @click="emit('select-dishes', allKeys, false)"
            >
              Ninguno
            </button>
          </div>
        </div>
        <div v-if="loading" class="purchase-loading" role="status">
          <PhSpinnerGap :size="25" class="spin-icon" /><span>Cargando platos e ingredientes…</span>
        </div>
        <div v-else-if="!days.length && !loadError" class="purchase-empty">
          <PhCalendarBlank :size="34" />
          <h3>Este menú está por preparar</h3>
          <p>Añade platos al planificador o elige otras fechas.</p>
          <button type="button" class="secondary-button" @click="emit('plan')">
            Ir al planificador <PhArrowRight :size="17" />
          </button>
        </div>
        <div v-else class="purchase-days">
          <section v-for="day in days" :key="day.key" class="purchase-day">
            <div class="purchase-day-heading">
              <h3>{{ day.label }}</h3>
              <button
                type="button"
                :aria-label="`${selectedInDay(day) === day.dishes.length ? 'Desmarcar' : 'Seleccionar'} platos del ${day.label}`"
                @click="
                  emit(
                    'select-dishes',
                    day.dishes.map((dish) => dish.key),
                    selectedInDay(day) !== day.dishes.length,
                  )
                "
              >
                {{ selectedInDay(day) }}/{{ day.dishes.length }} <PhCheck :size="14" />
              </button>
            </div>
            <label
              v-for="dish in day.dishes"
              :key="dish.key"
              class="purchase-dish"
              :class="{ selected: selected.has(dish.key) }"
            >
              <input
                type="checkbox"
                :checked="selected.has(dish.key)"
                @change="emit('toggle-dish', dish.key)"
              />
              <span class="purchase-checkbox" aria-hidden="true"
                ><PhCheck :size="15" weight="bold"
              /></span>
              <span class="purchase-dish-photo"
                ><img
                  v-if="dish.catalogDish?.photo_url"
                  :src="dish.catalogDish.photo_url"
                  alt=""
                  loading="lazy" /><PhForkKnife v-else :size="23"
              /></span>
              <span class="purchase-dish-copy"
                ><small>{{ mealLabels[dish.meal] }}</small
                ><strong>{{ dish.dish }}</strong
                ><span
                  :class="{ 'purchase-missing-tag': !dish.isPurchased && !dish.ingredientCount }"
                  >{{
                    dish.isPurchased
                      ? 'Se compra preparado'
                      : dish.ingredientCount
                        ? `${dish.ingredientCount} ${dish.ingredientCount === 1 ? 'ingrediente guardado' : 'ingredientes guardados'}`
                        : 'Faltan ingredientes'
                  }}</span
                ></span
              >
            </label>
          </section>
        </div>
      </section>

      <section id="purchase-list" class="purchase-list" aria-labelledby="purchase-list-title">
        <div class="purchase-section-title">
          <div>
            <span class="purchase-step">02 · TU COMPRA</span>
            <h2 id="purchase-list-title">Todo lo que necesitas</h2>
            <p>Sin duplicados, por supermercado.</p>
          </div>
          <span class="purchase-list-icon"><PhShoppingCart :size="25" /></span>
        </div>
        <div v-if="missing.length" class="purchase-missing">
          <div class="purchase-missing-heading">
            <PhWarningCircle :size="21" /><strong
              >Faltan ingredientes de {{ missing.length }}
              {{ missing.length === 1 ? 'plato' : 'platos' }}</strong
            >
          </div>
          <p>Completa sus ingredientes para incluirlos en la compra.</p>
          <ul>
            <li v-for="dish in missing" :key="dish.name">
              <span>{{ dish.name }}</span
              ><button
                type="button"
                :disabled="generating || loading"
                :aria-label="`Añadir ingredientes de ${dish.name}`"
                @click="emit('edit-dish', dish)"
              >
                Añadir
              </button>
            </li>
          </ul>
          <button
            type="button"
            class="primary-button"
            :disabled="generating || loading"
            @click="emit('complete')"
          >
            <PhSpinnerGap v-if="generating" :size="18" class="spin-icon" /><PhSparkle
              v-else
              :size="18"
            />{{ generating ? 'Completando ingredientes…' : 'Completar con IA' }}
          </button>
          <p v-if="warning" class="purchase-generation-warning" role="alert">{{ warning }}</p>
        </div>
        <div v-if="items.length" class="purchase-progress">
          <div>
            <strong>{{ pending ? `${pending} por comprar` : '¡Compra lista!' }}</strong
            ><span>{{ completed }} de {{ items.length }}</span>
          </div>
          <div
            role="progressbar"
            :aria-valuenow="completed"
            :aria-valuemax="items.length"
            aria-valuemin="0"
            aria-label="Productos comprados"
            class="purchase-progress-track"
          >
            <span :style="{ width: `${percent}%` }"></span>
          </div>
        </div>
        <div v-if="items.length" class="purchase-list-controls">
          <label
            ><input
              type="checkbox"
              :checked="pendingOnly"
              @change="emit('pending-only', $event.target.checked)"
            />
            Solo pendientes</label
          ><button v-if="completed" type="button" @click="emit('reset-checks')">
            Desmarcar comprados
          </button>
        </div>
        <div v-if="!loading && !selectedCount" class="purchase-empty">
          <PhShoppingCart :size="36" />
          <h3>Tu compra empieza en el menú</h3>
          <p>Marca los platos que vas a preparar para ver aquí sus ingredientes.</p>
        </div>
        <div
          v-else-if="!loading && !items.length && !missing.length && excluded.length"
          class="purchase-empty"
        >
          <PhCheckCircle :size="36" />
          <h3>No necesitas comprar nada</h3>
          <p>Todos los ingredientes están excluidos de la compra.</p>
        </div>
        <div
          v-else-if="pendingOnly && items.length && !pending"
          class="purchase-all-done"
          role="status"
        >
          <PhCheckCircle :size="30" /><strong>Ya tienes todos los productos.</strong
          ><button type="button" @click="emit('pending-only', false)">Ver comprados</button>
        </div>
        <section
          v-for="shoppingGroup in groups"
          :key="shoppingGroup.supermarket.id"
          class="purchase-store"
        >
          <div class="purchase-store-heading">
            <img
              :class="{ 'supermarket-logo-dark': isDarkLogo(shoppingGroup.supermarket) }"
              :src="supermarketLogo(shoppingGroup.supermarket)"
              :alt="shoppingGroup.supermarket.name"
            />
            <h3>{{ shoppingGroup.supermarket.name }}</h3>
            <span
              >{{ shoppingGroup.pending }}
              {{ shoppingGroup.pending === 1 ? 'pendiente' : 'pendientes' }}</span
            >
          </div>
          <div class="purchase-products">
            <label
              v-for="item in shoppingGroup.items"
              :key="item.key"
              class="purchase-product"
              :class="{ checked: checked.has(item.key) }"
              ><input
                type="checkbox"
                :checked="checked.has(item.key)"
                @change="emit('toggle-item', item.key)"
              /><span class="purchase-checkbox" aria-hidden="true"
                ><PhCheck :size="15" weight="bold" /></span
              ><span
                ><strong>{{ item.name }}</strong
                ><small>{{ item.dishes.join(' · ') }}</small></span
              ></label
            >
          </div>
        </section>
        <details v-if="excluded.length" class="purchase-excluded">
          <summary>
            <PhLeaf :size="18" /> No necesitas comprar <span>{{ excluded.length }}</span>
          </summary>
          <p>Excluidos en tus preferencias de ingredientes.</p>
          <div v-for="item in excluded" :key="item.key">
            <strong>{{ item.name }}</strong
            ><small>{{ item.dishes.join(' · ') }}</small>
          </div>
        </details>
        <div v-if="items.length" class="purchase-share">
          <button type="button" class="primary-button" :disabled="!pending" @click="emit('copy')">
            <PhNote :size="18" /> Copiar pendientes</button
          ><button
            type="button"
            class="secondary-button"
            :disabled="!pending"
            @click="emit('alexa')"
          >
            <PhSpeakerHigh :size="18" /> Alexa</button
          ><small>Se comparten solo los productos que quedan por comprar.</small>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.purchase-workspace {
  --purchase-green: #27634f;
  --purchase-soft: #edf5f0;
  --purchase-border: #dce6e0;
  color: var(--ink);
}
.purchase-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1.5rem;
  margin-bottom: 1.7rem;
}
.purchase-heading h1 {
  font-size: clamp(2.2rem, 4.5vw, 3.4rem);
  letter-spacing: -0.035em;
  line-height: 1.12;
}
.purchase-heading p:not(.eyebrow) {
  color: var(--muted);
  margin: 0.7rem 0 0;
  line-height: 1.6;
  font-size: 0.95rem;
}
.purchase-jump {
  display: inline-flex;
  align-items: center;
  gap: 0.65rem;
  color: var(--purchase-green);
  font-size: 0.85rem;
  font-weight: 700;
  white-space: nowrap;
  text-decoration: none;
  border-bottom: 1px solid #b7d3c5;
  padding: 0.7rem 0;
}
.purchase-range {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 1.2rem;
  padding: 1.1rem 1.35rem;
  background: #fff;
  border: 1px solid var(--purchase-border);
  border-radius: 18px;
}
.purchase-range-label {
  display: flex;
  align-items: center;
  gap: 0.7rem;
  margin-right: auto;
  color: var(--purchase-green);
}
.purchase-range-label div {
  display: grid;
  gap: 0.3rem;
}
.purchase-range-label strong {
  font-size: 0.85rem;
}
.purchase-range-label small {
  color: var(--muted);
  font-size: 0.73rem;
}
.purchase-date-fields {
  display: flex;
  align-items: center;
  gap: 0.65rem;
}
.purchase-date-fields label {
  display: grid;
  gap: 0.3rem;
  font-size: 0.68rem;
  font-weight: 700;
  color: var(--muted);
}
.purchase-date-fields input {
  width: 145px;
  min-width: 0;
  min-height: 40px;
  padding: 0.5rem 0.6rem;
  border: 1px solid var(--purchase-border);
  border-radius: 9px;
  color: var(--ink);
  background: #f8faf9;
  font-size: 0.8rem;
}
.purchase-date-fields > span {
  margin-top: 1rem;
  color: #93a99d;
}
.purchase-range .secondary-button {
  gap: 0.45rem;
  display: inline-flex;
  align-items: center;
  min-height: 44px;
  font-size: 0.78rem;
}
.purchase-presets {
  display: flex;
  gap: 0.3rem;
}
.purchase-presets button,
.purchase-bulk button {
  padding: 0.65rem 0.7rem;
  min-height: 44px;
  border: 0;
  background: transparent;
  color: var(--purchase-green);
  font-weight: 700;
  font-size: 0.76rem;
}
.purchase-summary {
  display: flex;
  flex-wrap: wrap;
  gap: 0.7rem 1.7rem;
  margin: 1.3rem 0 1.6rem;
}
.purchase-summary > span {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 0.8rem;
  color: var(--muted);
}
.purchase-summary strong {
  color: var(--ink);
}
.purchase-summary .purchase-summary-warning {
  color: #8c591b;
}
.purchase-summary .purchase-summary-ready {
  color: var(--purchase-green);
}
.purchase-columns {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: clamp(1.25rem, 3vw, 2.5rem);
  align-items: start;
}
.purchase-menu,
.purchase-list {
  min-width: 0;
}
.purchase-section-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.4rem;
}
.purchase-step {
  color: var(--purchase-green);
  font-size: 0.65rem;
  font-weight: 800;
  letter-spacing: 0.14em;
}
.purchase-section-title h2 {
  margin-top: 0.45rem;
  font-size: clamp(1.5rem, 2.4vw, 1.9rem);
  letter-spacing: -0.025em;
}
.purchase-section-title p {
  color: var(--muted);
  margin: 0.4rem 0 0;
  font-size: 0.78rem;
}
.purchase-bulk {
  display: flex;
  gap: 0.1rem;
  align-self: flex-end;
}
.purchase-bulk button:disabled {
  opacity: 0.4;
}
.purchase-days {
  display: grid;
  gap: 1.4rem;
}
.purchase-day-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
  margin-bottom: 0.65rem;
}
.purchase-day-heading h3 {
  font-family: inherit;
  font-size: 0.77rem;
  text-transform: capitalize;
  color: var(--muted);
  font-weight: 700;
}
.purchase-day-heading button {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  min-height: 36px;
  padding: 0.4rem 0.6rem;
  border: 1px solid var(--purchase-border);
  border-radius: 8px;
  background: #fff;
  color: var(--purchase-green);
  font-size: 0.72rem;
}
.purchase-dish {
  position: relative;
  display: flex;
  align-items: center;
  gap: 0.8rem;
  padding: 0.95rem;
  margin-top: 0.5rem;
  min-height: 95px;
  border: 1px solid var(--purchase-border);
  border-radius: 16px;
  background: #fff;
  cursor: pointer;
  transition:
    background 120ms,
    border-color 120ms;
}
.purchase-dish.selected {
  background: var(--purchase-soft);
  border-color: #b8d2c3;
}
.purchase-dish:active {
  background: #e0eee6;
}
.purchase-dish input,
.purchase-product input {
  position: absolute;
  width: 1px;
  height: 1px;
  opacity: 0;
}
.purchase-checkbox {
  display: grid;
  place-items: center;
  flex: 0 0 22px;
  width: 22px;
  height: 22px;
  border: 1.5px solid #a9bbb1;
  border-radius: 7px;
  background: #fff;
  color: transparent;
}
.selected .purchase-checkbox,
.checked .purchase-checkbox {
  background: var(--purchase-green);
  border-color: var(--purchase-green);
  color: #fff;
}
input:focus-visible + .purchase-checkbox {
  outline: 3px solid var(--focus-ring);
  outline-offset: 4px;
}
.purchase-dish-photo {
  display: grid;
  place-items: center;
  flex: 0 0 48px;
  width: 48px;
  height: 48px;
  background: #fff;
  border: 1px solid #dde7e1;
  border-radius: 12px;
  color: #6c9581;
}
.purchase-dish-photo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: inherit;
}
.purchase-dish-copy {
  display: grid;
  min-width: 0;
  gap: 0.25rem;
}
.purchase-dish-copy small {
  color: var(--muted);
  font-size: 0.65rem;
}
.purchase-dish-copy strong {
  font-size: 0.9rem;
  line-height: 1.4;
  overflow-wrap: anywhere;
}
.purchase-dish-copy > span {
  font-size: 0.7rem;
  color: var(--purchase-green);
}
.purchase-dish-copy .purchase-missing-tag {
  color: #8c591b;
}
.purchase-list {
  padding: clamp(1.1rem, 2.5vw, 1.8rem);
  border: 1px solid var(--purchase-border);
  border-radius: 22px;
  background: #fff;
  box-shadow: 0 6px 30px #1f483b06;
  scroll-margin-top: 100px;
}
.purchase-list-icon {
  display: grid;
  place-items: center;
  width: 46px;
  height: 46px;
  flex: 0 0 46px;
  border-radius: 14px;
  background: var(--purchase-soft);
  color: var(--purchase-green);
}
.purchase-missing {
  background: #fffaef;
  border: 1px solid #ead7af;
  border-radius: 13px;
  padding: 1rem;
  margin-bottom: 1.2rem;
}
.purchase-missing-heading {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  color: #845316;
  font-size: 0.8rem;
  line-height: 1.45;
}
.purchase-missing-heading svg {
  flex: 0 0 auto;
}
.purchase-missing p {
  color: #765e3b;
  font-size: 0.75rem;
  line-height: 1.6;
  margin: 0.5rem 0;
}
.purchase-missing ul {
  list-style: none;
  padding: 0;
  margin: 0.7rem 0;
}
.purchase-missing li {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  font-size: 0.75rem;
  border-top: 1px solid #eddfc4;
}
.purchase-missing li span {
  overflow-wrap: anywhere;
}
.purchase-missing li button {
  background: transparent;
  border: 0;
  min-height: 44px;
  padding: 0.5rem 0.2rem;
  color: #845316;
  font-weight: 700;
}
.purchase-missing .primary-button {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  min-height: 44px;
  font-size: 0.78rem;
}
.purchase-missing .purchase-generation-warning {
  border-top: 1px solid #ead7af;
  padding-top: 0.8rem;
  margin-top: 0.8rem;
}
.purchase-progress {
  margin: 0.8rem 0 1rem;
}
.purchase-progress > div:first-child {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  align-items: baseline;
}
.purchase-progress strong {
  color: var(--purchase-green);
  font-size: 1.15rem;
}
.purchase-progress div > span {
  color: var(--muted);
  font-size: 0.75rem;
}
.purchase-progress-track {
  height: 5px;
  margin-top: 0.75rem;
  border-radius: 5px;
  background: #eaf0ec;
}
.purchase-progress-track span {
  display: block;
  height: 100%;
  border-radius: inherit;
  background: var(--purchase-green);
  transition: width 150ms;
}
.purchase-list-controls {
  display: flex;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 0.5rem;
  border-bottom: 1px solid var(--purchase-border);
  padding: 0.25rem 0 0.8rem;
}
.purchase-list-controls label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.75rem;
  color: var(--muted);
  cursor: pointer;
  min-height: 44px;
}
.purchase-list-controls input {
  width: 18px;
  height: 18px;
  accent-color: var(--purchase-green);
}
.purchase-list-controls button,
.purchase-all-done button {
  color: var(--purchase-green);
  background: transparent;
  border: 0;
  min-height: 44px;
  font-size: 0.73rem;
  font-weight: 700;
}
.purchase-store {
  margin-top: 1.3rem;
}
.purchase-store-heading {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  margin-bottom: 0.5rem;
}
.purchase-store-heading img {
  width: 32px;
  height: 32px;
  object-fit: contain;
  border-radius: 8px;
  border: 1px solid var(--purchase-border);
  background: #fff;
  padding: 0.15rem;
}
.purchase-store-heading img.supermarket-logo-dark {
  background: #17643a;
}
.purchase-store-heading h3 {
  font-family: inherit;
  font-size: 0.86rem;
}
.purchase-store-heading > span {
  margin-left: auto;
  color: var(--muted);
  font-size: 0.68rem;
}
.purchase-product {
  display: flex;
  align-items: center;
  position: relative;
  gap: 0.75rem;
  padding: 0.85rem 0.15rem;
  min-height: 64px;
  border-bottom: 1px solid #ecf0ed;
  cursor: pointer;
}
.purchase-product > span:last-child {
  display: grid;
  min-width: 0;
  gap: 0.3rem;
}
.purchase-product strong {
  font-size: 0.87rem;
  line-height: 1.4;
  overflow-wrap: anywhere;
}
.purchase-product small {
  font-size: 0.7rem;
  color: var(--muted);
  line-height: 1.55;
  overflow-wrap: anywhere;
}
.purchase-product.checked strong {
  color: #718278;
  text-decoration: line-through;
}
.purchase-product.checked small {
  opacity: 0.7;
}
.purchase-excluded {
  margin-top: 1.5rem;
  padding: 0.9rem 0;
  border-top: 1px solid var(--purchase-border);
}
.purchase-excluded summary {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.76rem;
  color: var(--muted);
  cursor: pointer;
  min-height: 44px;
}
.purchase-excluded summary > span {
  margin-left: auto;
  background: #f0f3f1;
  border-radius: 8px;
  padding: 0.3rem 0.6rem;
}
.purchase-excluded p,
.purchase-excluded small {
  font-size: 0.7rem;
  color: var(--muted);
  line-height: 1.5;
}
.purchase-excluded > div {
  display: grid;
  gap: 0.2rem;
  margin-top: 0.7rem;
  font-size: 0.78rem;
}
.purchase-share {
  display: flex;
  flex-wrap: wrap;
  gap: 0.6rem;
  border-top: 1px solid var(--purchase-border);
  padding-top: 1.2rem;
  margin-top: 1.2rem;
}
.purchase-share button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  min-height: 44px;
  font-size: 0.78rem;
}
.purchase-share > small {
  color: var(--muted);
  width: 100%;
  font-size: 0.68rem;
  line-height: 1.55;
  margin-top: 0.25rem;
}
.purchase-empty,
.purchase-loading,
.purchase-all-done {
  display: grid;
  justify-items: center;
  align-content: center;
  gap: 0.75rem;
  min-height: 240px;
  text-align: center;
  color: var(--muted);
  padding: 1.5rem 0.5rem;
}
.purchase-empty svg,
.purchase-loading svg,
.purchase-all-done svg {
  color: var(--purchase-green);
}
.purchase-empty h3 {
  color: var(--ink);
  font-size: 1.3rem;
}
.purchase-empty p {
  margin: 0;
  font-size: 0.8rem;
  line-height: 1.6;
  max-width: 30ch;
}
.purchase-empty .secondary-button {
  display: inline-flex;
  gap: 0.5rem;
  align-items: center;
  margin-top: 0.4rem;
}
.purchase-loading {
  min-height: 160px;
  font-size: 0.85rem;
}
.purchase-all-done {
  min-height: 150px;
  font-size: 0.85rem;
}
.purchase-alert {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  margin-top: 1rem;
  padding: 1rem;
  border: 1px solid #ead7af;
  border-radius: 12px;
  background: #fffaef;
  color: #845316;
}
.purchase-alert > svg {
  flex: 0 0 auto;
}
.purchase-alert strong {
  font-size: 0.8rem;
}
.purchase-alert p {
  margin: 0.35rem 0 0;
  font-size: 0.78rem;
  line-height: 1.5;
}
.purchase-alert .text-button {
  margin-left: auto;
  flex: 0 0 auto;
}
button:disabled {
  opacity: 0.5;
}
@media (max-width: 900px) {
  .purchase-range {
    gap: 0.8rem;
  }
  .purchase-range-label {
    width: 100%;
  }
  .purchase-columns {
    gap: 1.2rem;
  }
  .purchase-section-title {
    gap: 0.6rem;
  }
  .purchase-bulk {
    flex-direction: column;
    gap: 0;
  }
  .purchase-bulk button {
    min-height: 36px;
    padding: 0.4rem 0.6rem;
  }
}
@media (max-width: 700px) {
  .purchase-heading {
    align-items: flex-start;
    flex-direction: column;
    margin-bottom: 1.25rem;
    gap: 0.8rem;
  }
  .purchase-heading h1 {
    font-size: 2.25rem;
  }
  .purchase-heading p:not(.eyebrow) {
    font-size: 0.86rem;
  }
  .purchase-jump {
    font-size: 0.78rem;
    padding: 0.65rem 0.85rem;
    border: 1px solid var(--purchase-border);
    border-radius: 10px;
    background: #fff;
  }
  .purchase-jump svg {
    flex: 0 0 auto;
  }
  .purchase-range {
    padding: 1rem;
  }
  .purchase-date-fields {
    width: 100%;
    gap: 0.5rem;
  }
  .purchase-date-fields label {
    flex: 1;
    min-width: 0;
  }
  .purchase-date-fields input {
    width: 100%;
    box-sizing: border-box;
    font-size: 16px;
  }
  .purchase-range .secondary-button {
    flex: 1;
    justify-content: center;
  }
  .purchase-summary {
    margin: 1.1rem 0 1.5rem;
    gap: 0.7rem 1.1rem;
  }
  .purchase-summary > span {
    font-size: 0.73rem;
  }
  .purchase-columns {
    grid-template-columns: minmax(0, 1fr);
    gap: 2rem;
  }
  .purchase-bulk {
    flex-direction: row;
  }
  .purchase-bulk button {
    min-height: 44px;
  }
  .purchase-days {
    gap: 1.2rem;
  }
  .purchase-dish {
    padding: 0.85rem;
    gap: 0.7rem;
  }
  .purchase-dish-copy strong {
    font-size: 0.88rem;
  }
  .purchase-list {
    border-radius: 18px;
  }
  .purchase-alert {
    flex-wrap: wrap;
  }
  .purchase-alert > div {
    flex: 1;
    min-width: 0;
  }
}
@media (max-width: 380px) {
  .purchase-date-fields {
    flex-direction: column;
    gap: 0.6rem;
  }
  .purchase-date-fields label {
    display: grid;
    grid-template-columns: 42px minmax(0, 1fr);
    align-items: center;
    width: 100%;
  }
  .purchase-date-fields > span {
    display: none;
  }
}
@media (max-width: 360px) {
  .purchase-heading h1 {
    font-size: 1.9rem;
  }
  .purchase-dish-photo {
    width: 38px;
    height: 38px;
    flex-basis: 38px;
  }
  .purchase-date-fields input {
    padding: 0.5rem 0.2rem;
  }
  .purchase-share button {
    flex: 1;
  }
}
@media (prefers-reduced-motion: reduce) {
  .purchase-dish,
  .purchase-progress-track span {
    transition: none;
  }
}
</style>
