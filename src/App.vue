<script setup>
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  PhAlarm,
  PhArrowLeft,
  PhArrowRight,
  PhArrowsClockwise,
  PhArrowsLeftRight,
  PhBarbell,
  PhBell,
  PhCalendarBlank,
  PhCalendarCheck,
  PhCaretLeft,
  PhCaretRight,
  PhCheck,
  PhCheckCircle,
  PhChefHat,
  PhClock,
  PhCoffee,
  PhCookingPot,
  PhDiceFive,
  PhDownloadSimple,
  PhForkKnife,
  PhGear,
  PhGoogleLogo,
  PhHeart,
  PhHouse,
  PhLeaf,
  PhLightning,
  PhList,
  PhListChecks,
  PhMagnifyingGlass,
  PhMoon,
  PhNote,
  PhNotePencil,
  PhPlus,
  PhSignOut,
  PhShoppingCart,
  PhSpeakerHigh,
  PhSmiley,
  PhSparkle,
  PhSpinnerGap,
  PhStar,
  PhSun,
  PhTag,
  PhTelegramLogo,
  PhUsers,
  PhWarningCircle,
  PhX,
} from '@phosphor-icons/vue'
import { ApiError, getJson, postJson } from './lib/api'
import { formatDay, fromIsoDate, mondayOf, shiftDate, toIsoDate } from './lib/dates'
import {
  getFirebaseAuth,
  hasFirebaseConfig,
  observeAuth,
  signInWithGoogle,
  signOut,
} from './lib/firebase'

const mealLabels = { breakfast: 'Desayuno', lunch: 'Comida', dinner: 'Cena' }
const mealIcons = { breakfast: PhCoffee, lunch: PhForkKnife, dinner: PhMoon }
const optionIcons = {
  note: PhNote,
  clock: PhClock,
  utensils: PhForkKnife,
  kids: PhUsers,
  training: PhBarbell,
  'no-cook': PhCookingPot,
  calendar: PhCalendarCheck,
  shopping: PhShoppingCart,
  cooking: PhChefHat,
  leaf: PhLeaf,
  sun: PhSun,
  star: PhStar,
  checklist: PhListChecks,
  smile: PhSmiley,
}
const optionIconOptions = [
  { id: 'note', label: 'Nota', icon: PhNote },
  { id: 'clock', label: 'Reloj', icon: PhClock },
  { id: 'utensils', label: 'Cubiertos', icon: PhForkKnife },
  { id: 'kids', label: 'Familia', icon: PhUsers },
  { id: 'training', label: 'Entreno', icon: PhBarbell },
  { id: 'no-cook', label: 'Sin cocinar', icon: PhCookingPot },
  { id: 'calendar', label: 'Calendario', icon: PhCalendarCheck },
  { id: 'shopping', label: 'Compra', icon: PhShoppingCart },
  { id: 'cooking', label: 'Cocinar', icon: PhChefHat },
  { id: 'leaf', label: 'Saludable', icon: PhLeaf },
  { id: 'sun', label: 'Día', icon: PhSun },
  { id: 'star', label: 'Favorito', icon: PhStar },
  { id: 'checklist', label: 'Lista', icon: PhListChecks },
  { id: 'smile', label: 'Bienestar', icon: PhSmiley },
]
const allMeals = ['breakfast', 'lunch', 'dinner']
const notificationTypes = [
  { id: 'meal_added', label: 'Comidas añadidas' },
  { id: 'meal_updated', label: 'Comidas modificadas' },
  { id: 'meal_moved', label: 'Comidas movidas' },
  { id: 'group', label: 'Actividad del grupo' },
  { id: 'reminder', label: 'Recordatorios programados' },
]
const alertIconOptions = [
  { id: 'bell', label: 'Campana', icon: PhBell },
  { id: 'alarm', label: 'Alarma', icon: PhAlarm },
  { id: 'clock', label: 'Reloj', icon: PhClock },
  { id: 'calendar', label: 'Calendario', icon: PhCalendarCheck },
  { id: 'utensils', label: 'Cubiertos', icon: PhForkKnife },
  { id: 'cooking', label: 'Cocinar', icon: PhCookingPot },
  { id: 'shopping', label: 'Compra', icon: PhShoppingCart },
  { id: 'note', label: 'Nota', icon: PhNote },
  { id: 'checklist', label: 'Lista', icon: PhListChecks },
  { id: 'leaf', label: 'Hoja', icon: PhLeaf },
  { id: 'sun', label: 'Día', icon: PhSun },
  { id: 'star', label: 'Favorito', icon: PhStar },
  { id: 'tag', label: 'Etiqueta', icon: PhTag },
  { id: 'lightning', label: 'Rápido', icon: PhLightning },
  { id: 'warning', label: 'Aviso', icon: PhWarningCircle },
]
const loading = ref(true)
const authReady = ref(false)
const user = ref(null)
const error = ref('')
const notice = ref('')
const preferences = reactive({
  enabled_meals: ['lunch'],
  theme: 'system',
  default_reminder_enabled: false,
  default_reminder_time: '09:00',
  notification_enabled: true,
  notification_types: notificationTypes.map((type) => type.id),
})
const dishes = ref([])
const group = ref(null)
const dailyOptions = ref([])
const globalAlerts = ref([])
const notifications = ref([])
const notificationUnreadCount = ref(0)
const notificationsOpen = ref(false)
const menuOpen = ref(false)
const inviteEmail = ref('')
const joinCode = ref('')
const optionDraft = reactive({
  id: 0,
  name: '',
  description: '',
  active: true,
  color: 'blue',
  icon: 'note',
  order: 0,
})
const alertDraft = reactive({
  id: 0,
  name: '',
  message: '',
  time: '09:00',
  day_offset: 0,
  icon: 'bell',
  default_enabled: false,
  scope: 'all',
  active: true,
  order: 0,
})
const menus = ref(new Map())
const rangeDays = ref(new Map())
const dayEntries = ref([])
const nextRangeStart = ref('')
const loadingMore = ref(false)
const editorOpen = ref(false)
const saving = ref(false)
const draftDayKey = ref('')
const draftWeekStart = ref('')
const draftDay = ref(null)
const swapSource = ref(null)
const dragSource = ref(null)
const userToken = ref('')
const dishSearch = ref('')
const favoritesOnly = ref(false)
const dishDraft = ref('')
const calendarMonth = ref(new Date(new Date().getFullYear(), new Date().getMonth(), 1))
const calendarDays = ref(new Map())
const calendarLoading = ref(false)
const calendarDetailOpen = ref(false)
const calendarSelectedDay = ref(null)
const shoppingSelectedDays = ref(new Set())
const shoppingSelectionInitialized = ref(false)
const shoppingItems = ref([])
const shoppingGenerating = ref(false)
const shoppingChecked = ref(new Set())
const shoppingErrorDetails = ref('')
const shoppingErrorModal = ref(null)
const shoppingStep = ref(1)
const shoppingSteps = [
  { id: 1, label: 'Días' },
  { id: 2, label: 'Platos' },
  { id: 3, label: 'Lista' },
]
const shoppingAlexaUrl = 'alexa://index.html#lists/shopping'
const rouletteOpen = ref(false)
const rouletteSpinning = ref(false)
const rouletteContextLoading = ref(false)
const rouletteMeal = ref('lunch')
const rouletteReelPosition = ref(0)
const rouletteReelTransition = ref(true)
const rouletteResult = ref(null)
const rouletteCandidates = ref([])
const rouletteUsedNames = ref(new Set())
const RANGE_PAGE_DAYS = 7
const telegram = ref({
  configured: false,
  connected: false,
  bot_username: '',
  chat_id: null,
  username: '',
  first_name: '',
  linked_at: null,
})
const telegramLinking = ref(false)
const telegramTesting = ref(false)
const telegramStatusLoading = ref(false)
const remindingGroup = ref(false)
const shareLoading = ref(false)
const shareData = ref(null)
const shareError = ref('')
const installPrompt = ref(null)
const installBannerVisible = ref(false)
const isStandalone = ref(false)
let telegramPollTimer = null
let rouletteTimer = null
let installPromptHandler = null
let appInstalledHandler = null

const enabledMeals = computed(() =>
  preferences.enabled_meals.length ? preferences.enabled_meals : ['lunch'],
)
const draftTitle = computed(() =>
  draftDayKey.value ? formatDay(new Date(`${draftDayKey.value}T00:00:00`)) : '',
)
const route = useRoute()
const router = useRouter()
const baseUrl = import.meta.env.BASE_URL
const publicAsset = (path) => `${baseUrl}${path.replace(/^\/+/, '')}`
const isSettings = computed(() => route.name === 'settings')
const isDishes = computed(() => route.name === 'dishes')
const isShopping = computed(() => route.name === 'shopping')
const isCalendar = computed(() => route.name === 'calendar')
const isShared = computed(() => route.name === 'shared-day')
const isDashboard = computed(() => route.name === 'dashboard')
const monthLabel = computed(() =>
  new Intl.DateTimeFormat('es-ES', { month: 'long', year: 'numeric' }).format(calendarMonth.value),
)
const sortedDishes = computed(() => {
  const query = dishSearch.value.trim().toLocaleLowerCase('es')
  return [...dishes.value]
    .filter(
      (dish) =>
        (!favoritesOnly.value || dish.is_favorite) &&
        (!query || dish.name.toLocaleLowerCase('es').includes(query)),
    )
    .sort(
      (a, b) =>
        Number(b.is_favorite) - Number(a.is_favorite) ||
        Number(b.times_used || 0) - Number(a.times_used || 0) ||
        a.name.localeCompare(b.name, 'es'),
    )
})
const calendarCells = computed(() => {
  const first = mondayOf(calendarMonth.value)
  const last = new Date(calendarMonth.value.getFullYear(), calendarMonth.value.getMonth() + 1, 0)
  const end = new Date(mondayOf(last))
  end.setDate(end.getDate() + 6)
  const cells = []
  for (const cursor = new Date(first); cursor <= end; cursor.setDate(cursor.getDate() + 1)) {
    const isoDate = toIsoDate(cursor)
    const entry = calendarDays.value.get(isoDate)
    cells.push({
      isoDate,
      date: new Date(cursor),
      inMonth: cursor.getMonth() === calendarMonth.value.getMonth(),
      ...entry,
    })
  }
  return cells
})
const calendarWeeks = computed(() =>
  Array.from({ length: Math.ceil(calendarCells.value.length / 7) }, (_, index) =>
    calendarCells.value.slice(index * 7, index * 7 + 7),
  ),
)
const shoppingDayEntries = computed(() => dayEntries.value.slice(0, 7))
const shoppingMeals = computed(() =>
  shoppingDayEntries.value.flatMap((entry) => {
    if (!shoppingSelectedDays.value.has(entry.isoDate)) return []
    const day = currentDay(entry.isoDate, entry.weekStart)
    if (day.skipped) return []
    return enabledMeals.value.flatMap((meal) => {
      const mealState = day.meals[meal]
      const dishes = mealState.items.filter((item) => String(item).trim())
      return mealState.skipped || !dishes.length
        ? []
        : [{ dayDate: entry.isoDate, date: entry.date, meal, dishes }]
    })
  }),
)
const shoppingGroups = computed(() => {
  const groups = new Map()
  shoppingItems.value.forEach((item, index) => {
    const category = item.category || 'Otros'
    if (!groups.has(category)) groups.set(category, [])
    groups.get(category).push({ ...item, index })
  })
  return [...groups.entries()].map(([category, items]) => ({ category, items }))
})
const shoppingToBuyItems = computed(() =>
  shoppingItems.value.filter((_, index) => !shoppingChecked.value.has(index)),
)
const hasUnreadNotifications = computed(() => notificationUnreadCount.value > 0)
const defaultRouletteDishes = [
  {
    id: 'roulette-default-1',
    name: 'Bowl mediterráneo de garbanzos',
    source: 'default',
    times_used: 0,
    is_favorite: false,
  },
  {
    id: 'roulette-default-2',
    name: 'Tacos de pollo y mango',
    source: 'default',
    times_used: 0,
    is_favorite: false,
  },
  {
    id: 'roulette-default-3',
    name: 'Arroz meloso de verduras',
    source: 'default',
    times_used: 0,
    is_favorite: false,
  },
  {
    id: 'roulette-default-4',
    name: 'Pasta cremosa de calabacín',
    source: 'default',
    times_used: 0,
    is_favorite: false,
  },
  {
    id: 'roulette-default-5',
    name: 'Tortilla rellena de espinacas',
    source: 'default',
    times_used: 0,
    is_favorite: false,
  },
  {
    id: 'roulette-default-6',
    name: 'Cuscús especiado con verduras',
    source: 'default',
    times_used: 0,
    is_favorite: false,
  },
  {
    id: 'roulette-default-7',
    name: 'Salmón cítrico con patata',
    source: 'default',
    times_used: 0,
    is_favorite: false,
  },
  {
    id: 'roulette-default-8',
    name: 'Piadina de hummus y verduras',
    source: 'default',
    times_used: 0,
    is_favorite: false,
  },
]
const roulettePool = computed(() => {
  const personal = dishes.value.filter((dish) => dish.source !== 'admin')
  if (personal.length) return personal
  return defaultRouletteDishes
})
const rouletteReelItems = computed(() =>
  Array.from({ length: 10 }, () => rouletteCandidates.value).flat(),
)
const draftDayCompleted = computed(() =>
  Boolean(draftDayKey.value && draftDayKey.value <= toIsoDate(new Date())),
)
const draftDayHasMeals = computed(() =>
  Boolean(
    draftDay.value &&
    allMeals.some((meal) => draftDay.value.meals[meal].items.some((item) => String(item).trim())),
  ),
)
const sharedDayTitle = computed(() =>
  shareData.value?.day_date ? formatDay(fromIsoDate(shareData.value.day_date)) : '',
)

function emptyMeal() {
  return {
    items: [],
    skipped: false,
    reason: '',
    note: '',
    alerts: [],
    reminder_enabled: false,
    reminder_time: '',
    reminder_message: '',
  }
}
function customAlertId() {
  return `custom-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
}
function alertDayOffsetLabel(offset) {
  const days = Number(offset || 0)
  if (days === 0) return 'Mismo día'
  return `${days} ${days === 1 ? 'día' : 'días'} antes`
}
function alertIcon(alert) {
  return alertIconOptions.find((option) => option.id === (alert?.icon || 'bell'))?.icon || PhBell
}
function formatNotificationDate(value) {
  if (!value) return ''
  const date = new Date(String(value).replace(' ', 'T'))
  return Number.isNaN(date.getTime())
    ? value
    : new Intl.DateTimeFormat('es-ES', {
        day: 'numeric',
        month: 'short',
        hour: '2-digit',
        minute: '2-digit',
      }).format(date)
}
function alertAppliesToMeal(alert, meal) {
  return alert.scope === 'all' || alert.scope === meal
}
function normalizedMealAlerts(sourceMeal, meal, withDefaults) {
  const sourceAlerts = Array.isArray(sourceMeal?.alerts) ? sourceMeal.alerts : []
  const legacyAlerts =
    !sourceAlerts.length && Boolean(sourceMeal?.reminder_enabled)
      ? [
          {
            type: 'custom',
            name: 'Aviso',
            time: sourceMeal.reminder_time || '09:00',
            message: sourceMeal.reminder_message || '',
            enabled: Boolean(sourceMeal.reminder_enabled),
          },
        ]
      : []
  const alerts = [...sourceAlerts, ...legacyAlerts]
  const overrides = new Map(
    alerts
      .filter((alert) => alert?.type === 'global')
      .map((alert) => [Number(alert.alert_id || alert.id), alert]),
  )
  const defaults = withDefaults
    ? globalAlerts.value
        .filter((alert) => alert.active && alertAppliesToMeal(alert, meal))
        .map((alert) => {
          const override = overrides.get(Number(alert.id))
          return {
            type: 'global',
            alert_id: Number(alert.id),
            name: alert.name,
            time: alert.time,
            day_offset: Number(alert.day_offset || 0),
            icon: alert.icon || 'bell',
            message: alert.message || '',
            enabled: override ? Boolean(override.enabled) : Boolean(alert.default_enabled),
            overridden: Boolean(override),
          }
        })
    : alerts
        .filter((alert) => alert?.type === 'global')
        .map((alert) => ({
          ...alert,
          alert_id: Number(alert.alert_id || alert.id),
          day_offset: Number(alert.day_offset || 0),
          icon: alert.icon || 'bell',
          overridden: true,
        }))
  const custom = alerts
    .filter((alert) => alert?.type !== 'global')
    .map((alert) => ({
      type: 'custom',
      id: alert.id || customAlertId(),
      name: alert.name || '',
      time: alert.time || '09:00',
      day_offset: Number(alert.day_offset || 0),
      icon: alert.icon || 'bell',
      message: alert.message || '',
      enabled: Boolean(alert.enabled),
    }))
  return [...defaults, ...custom]
}
function emptyDay() {
  return {
    skipped: false,
    reason: '',
    skip_note: '',
    notes: '',
    option_ids: [],
    meals: Object.fromEntries(allMeals.map((meal) => [meal, emptyMeal()])),
  }
}
function normalizedDay(day, withReminderDefaults = false) {
  const result = { ...emptyDay(), ...day }
  result.option_ids = [...(day?.option_ids || [])]
  result.meals = Object.fromEntries(
    allMeals.map((meal) => {
      const sourceMeal = day?.meals?.[meal]
      return [
        meal,
        {
          ...emptyMeal(),
          ...sourceMeal,
          items: [...(sourceMeal?.items || [])],
          alerts: normalizedMealAlerts(sourceMeal, meal, withReminderDefaults),
        },
      ]
    }),
  )
  return result
}
function currentDay(dayKey, requestedWeek = '', withAlertDefaults = false) {
  const rangeEntry = rangeDays.value.get(dayKey)
  return normalizedDay(
    rangeEntry?.day || menus.value.get(requestedWeek)?.days?.[dayKey],
    withAlertDefaults,
  )
}

function buildRangeDayEntries(data) {
  return Object.entries(data.days || {})
    .sort(([first], [second]) => first.localeCompare(second))
    .map(([isoDate, entry]) => {
      const weekStartValue = entry.week_start || toIsoDate(mondayOf(fromIsoDate(isoDate)))
      return {
        isoDate,
        date: fromIsoDate(isoDate),
        weekStart: weekStartValue,
        menu: menus.value.get(weekStartValue),
      }
    })
}

function applyRangeData(data, replace = false) {
  const nextMenus = replace ? new Map() : new Map(menus.value)
  const nextDays = replace ? new Map() : new Map(rangeDays.value)
  Object.entries(data.days || {}).forEach(([isoDate, entry]) => {
    const weekStartValue = entry.week_start || toIsoDate(mondayOf(fromIsoDate(isoDate)))
    const day = { ...entry }
    delete day.week_start
    nextDays.set(isoDate, { day, weekStart: weekStartValue })
    const currentMenu = nextMenus.get(weekStartValue) || { week_start: weekStartValue, days: {} }
    nextMenus.set(weekStartValue, { ...currentMenu, days: { ...currentMenu.days, [isoDate]: day } })
  })
  menus.value = nextMenus
  rangeDays.value = nextDays
}

function applyContext(data) {
  group.value = data.group || group.value
  dailyOptions.value = data.daily_options || dailyOptions.value
  globalAlerts.value = data.global_alerts || globalAlerts.value
  preferences.enabled_meals = data.group?.enabled_meals ||
    data.preferences?.enabled_meals || ['lunch']
  preferences.theme = data.preferences?.theme || 'system'
  preferences.default_reminder_enabled = Boolean(data.preferences?.default_reminder_enabled)
  preferences.default_reminder_time = data.preferences?.default_reminder_time || '09:00'
  preferences.notification_enabled = data.preferences?.notification_enabled !== false
  preferences.notification_types = Array.isArray(data.preferences?.notification_types)
    ? [...data.preferences.notification_types]
    : notificationTypes.map((type) => type.id)
  telegram.value = data.telegram || telegram.value
  notifications.value = data.notifications || notifications.value
  notificationUnreadCount.value = Number(data.notification_unread_count || 0)
  dishes.value = data.dishes || dishes.value
}

async function fetchRange(from, to, includeContext = true) {
  userToken.value = await user.value.getIdToken()
  return getJson(
    `menudiario/range?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}${includeContext ? '' : '&include_context=0'}`,
    userToken.value,
  )
}
async function refreshToken() {
  userToken.value = await user.value.getIdToken(true)
  return userToken.value
}

async function loadDashboardRange() {
  if (!user.value) return
  loading.value = true
  error.value = ''
  try {
    const rangeStart = toIsoDate(new Date())
    const rangeEnd = shiftDate(rangeStart, RANGE_PAGE_DAYS - 1)
    const data = await fetchRange(rangeStart, rangeEnd)
    applyContext(data)
    applyRangeData(data, true)
    dayEntries.value = buildRangeDayEntries(data)
    initializeShoppingSelection()
    nextRangeStart.value = shiftDate(rangeEnd, 1)
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo cargar el menú.'
    if (isShopping.value) showShoppingError('No se ha podido cargar el menú', error.value)
  } finally {
    loading.value = false
  }
}

function initializeShoppingSelection() {
  if (shoppingSelectionInitialized.value || !shoppingDayEntries.value.length) return
  shoppingSelectedDays.value = new Set(shoppingDayEntries.value.map((entry) => entry.isoDate))
  shoppingSelectionInitialized.value = true
}

async function loadShoppingRange() {
  if (!user.value) return
  if (!dayEntries.value.length) {
    loading.value = true
    error.value = ''
    try {
      const rangeStart = toIsoDate(new Date())
      const rangeEnd = shiftDate(rangeStart, RANGE_PAGE_DAYS - 1)
      const data = await fetchRange(rangeStart, rangeEnd)
      applyContext(data)
      applyRangeData(data, true)
      dayEntries.value = buildRangeDayEntries(data)
      nextRangeStart.value = shiftDate(rangeEnd, 1)
    } catch (reason) {
      error.value = reason instanceof Error ? reason.message : 'No se pudo cargar el menú.'
      if (isShopping.value) showShoppingError('No se ha podido cargar el menú', error.value)
    } finally {
      loading.value = false
    }
  }
  initializeShoppingSelection()
}

function toggleShoppingDay(dayDate) {
  const selected = new Set(shoppingSelectedDays.value)
  if (selected.has(dayDate)) selected.delete(dayDate)
  else selected.add(dayDate)
  shoppingSelectedDays.value = selected
  shoppingItems.value = []
}

function toggleShoppingItem(index) {
  const checked = new Set(shoppingChecked.value)
  if (checked.has(index)) checked.delete(index)
  else checked.add(index)
  shoppingChecked.value = checked
}

function shoppingItemChecked(index) {
  return shoppingChecked.value.has(index)
}

function formatShoppingErrorDetails(reason) {
  if (!(reason instanceof Error)) return ''
  if (!(reason instanceof ApiError)) return `${reason.name}: ${reason.message}`
  const metadata = [
    reason.code ? `code: ${reason.code}` : '',
    reason.status ? `http_status: ${reason.status}` : '',
  ].filter(Boolean)
  if (!reason.details) return [...metadata, `message: ${reason.message}`].filter(Boolean).join('\n')
  if (typeof reason.details === 'string') return [...metadata, reason.details].join('\n')
  const details = Object.entries(reason.details)
    .map(([key, value]) => {
      const printable = typeof value === 'string' ? value : JSON.stringify(value)
      return `${key}: ${printable}`
    })
    .join('\n')
  return [...metadata, details].filter(Boolean).join('\n')
}

function showShoppingError(title, message, details = '', retry = false) {
  shoppingErrorModal.value = { title, message, details, retry }
}

function closeShoppingError() {
  shoppingErrorModal.value = null
}

function retryShoppingGeneration() {
  closeShoppingError()
  void generateShoppingList()
}

function canEnterShoppingStep(step) {
  if (step === 1) return true
  if (step === 2) return shoppingSelectedDays.value.size > 0
  return shoppingMeals.value.length > 0 && shoppingItems.value.length > 0
}

function selectShoppingStep(step) {
  if (step > shoppingStep.value && !canEnterShoppingStep(step)) return
  shoppingStep.value = step
}

function nextShoppingStep() {
  if (shoppingStep.value === 1) {
    if (!shoppingSelectedDays.value.size) return
    shoppingStep.value = 2
    return
  }
  if (shoppingStep.value === 2) {
    if (!shoppingMeals.value.length) return
    shoppingStep.value = 3
    void generateShoppingList()
  }
}

function previousShoppingStep() {
  if (shoppingStep.value > 1) shoppingStep.value -= 1
}

function shoppingAlexaCommand() {
  const labels = shoppingToBuyItems.value.map((item) =>
    [item.name, item.quantity].filter(Boolean).join(' '),
  )
  if (labels.length <= 1) return labels[0] || ''
  if (labels.length === 2) return `${labels[0]} y ${labels[1]}`
  return `${labels.slice(0, -1).join(', ')} y ${labels.at(-1)}`
}

async function sendShoppingListToAlexa() {
  const command = `Añade a la lista de la compra ${shoppingAlexaCommand()}`.trim()
  if (!shoppingToBuyItems.value.length) {
    showShoppingError(
      'No hay productos pendientes',
      'Marca algún producto como pendiente antes de enviarlo a Alexa.',
    )
    return
  }
  try {
    await navigator.clipboard.writeText(command)
    notice.value = 'Orden copiada. Abriendo Alexa…'
    window.setTimeout(() => {
      notice.value = ''
    }, 3500)
    window.location.href = shoppingAlexaUrl
  } catch (reason) {
    showShoppingError(
      'No se ha podido preparar Alexa',
      'No se pudo copiar la orden para Alexa. Copia el texto desde el detalle técnico e inténtalo de nuevo.',
      reason instanceof Error
        ? `${reason.name}: ${reason.message}\n\nOrden:\n${command}`
        : `Orden:\n${command}`,
    )
  }
}

async function generateShoppingList() {
  if (shoppingGenerating.value || !shoppingMeals.value.length) return
  shoppingGenerating.value = true
  error.value = ''
  shoppingErrorDetails.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/generate_shopping_list', userToken.value, {
      meals: shoppingMeals.value.map((meal) => ({
        day_date: meal.dayDate,
        meal: meal.meal,
        dishes: meal.dishes,
      })),
    })
    shoppingItems.value = data.items || []
    shoppingChecked.value = new Set()
    shoppingErrorDetails.value = ''
    notice.value = 'Lista generada. Revísala antes de ir a comprar.'
    window.setTimeout(() => {
      notice.value = ''
    }, 3500)
  } catch (reason) {
    error.value =
      reason instanceof Error ? reason.message : 'No se pudo generar la lista de la compra.'
    shoppingErrorDetails.value = formatShoppingErrorDetails(reason)
    showShoppingError(
      'No se ha podido generar la lista',
      error.value,
      shoppingErrorDetails.value,
      true,
    )
  } finally {
    shoppingGenerating.value = false
  }
}

async function copyShoppingList() {
  if (!shoppingItems.value.length) return
  const text = shoppingGroups.value
    .map(
      (group) =>
        `${group.category}\n${group.items
          .map((item) => `☐ ${item.name}${item.quantity ? ` — ${item.quantity}` : ''}`)
          .join('\n')}`,
    )
    .join('\n\n')
  try {
    await navigator.clipboard.writeText(text)
    notice.value = 'Lista copiada al portapapeles.'
  } catch {
    error.value = 'No se pudo copiar la lista. Puedes seleccionarla manualmente.'
    showShoppingError('No se ha podido copiar la lista', error.value)
  }
  window.setTimeout(() => {
    notice.value = ''
  }, 2500)
}

async function loadCalendarMonth() {
  if (!user.value || !isCalendar.value) return
  calendarLoading.value = true
  error.value = ''
  try {
    const firstDay = new Date(calendarMonth.value.getFullYear(), calendarMonth.value.getMonth(), 1)
    const lastDay = new Date(
      calendarMonth.value.getFullYear(),
      calendarMonth.value.getMonth() + 1,
      0,
    )
    const firstWeek = mondayOf(firstDay)
    const lastWeek = mondayOf(lastDay)
    const rangeStart = toIsoDate(firstWeek)
    const rangeEnd = shiftDate(toIsoDate(lastWeek), 6)
    const data = await fetchRange(rangeStart, rangeEnd, false)
    applyRangeData(data)
    const nextDays = new Map()
    Object.entries(data.days || {}).forEach(([isoDate, entry]) => {
      const weekStartValue = entry.week_start || toIsoDate(mondayOf(fromIsoDate(isoDate)))
      const day = { ...entry }
      delete day.week_start
      nextDays.set(isoDate, { day, weekStart: weekStartValue })
    })
    calendarDays.value = nextDays
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo cargar el calendario.'
  } finally {
    calendarLoading.value = false
  }
}

async function loadMoreDays() {
  if (!isDashboard.value || !user.value || loadingMore.value || !nextRangeStart.value) return
  loadingMore.value = true
  try {
    const rangeStart = nextRangeStart.value
    const rangeEnd = shiftDate(rangeStart, RANGE_PAGE_DAYS - 1)
    const data = await fetchRange(rangeStart, rangeEnd, false)
    if (!isDashboard.value) return
    applyRangeData(data)
    dayEntries.value = [...dayEntries.value, ...buildRangeDayEntries(data)]
    nextRangeStart.value = shiftDate(rangeEnd, 1)
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo cargar el siguiente rango.'
  } finally {
    loadingMore.value = false
  }
}

function loadMoreOnScroll() {
  if (!isDashboard.value) return
  if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 650)
    void loadMoreDays()
}

function changeMonth(amount) {
  calendarMonth.value = new Date(
    calendarMonth.value.getFullYear(),
    calendarMonth.value.getMonth() + amount,
    1,
  )
}
function goToCurrentMonth() {
  calendarMonth.value = new Date(new Date().getFullYear(), new Date().getMonth(), 1)
}
function calendarDayHasMeals(day) {
  return Boolean(day && allMeals.some((meal) => day.meals?.[meal]?.items?.length))
}
function calendarDayClass(cell) {
  return {
    'calendar-day-outside': !cell.inMonth,
    'calendar-day-configured': calendarDayHasMeals(cell.day),
    'calendar-day-today': cell.isoDate === toIsoDate(new Date()),
  }
}
function calendarDateLabel(date) {
  return new Intl.DateTimeFormat('es-ES', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  }).format(date)
}
function openCalendarDay(cell) {
  if (!calendarDayHasMeals(cell.day)) return
  calendarSelectedDay.value = { ...cell, day: normalizedDay(cell.day, true) }
  calendarDetailOpen.value = true
}
function editCalendarDay() {
  if (!calendarSelectedDay.value) return
  const selected = calendarSelectedDay.value
  calendarDetailOpen.value = false
  openEditor(selected.isoDate, selected.weekStart)
}
async function saveDish() {
  const name = dishDraft.value.trim()
  if (!name) return
  saving.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/save_dish', userToken.value, { name })
    dishes.value = data.dishes || dishes.value
    dishDraft.value = ''
    notice.value = 'Plato añadido a tu lista.'
    window.setTimeout(() => {
      notice.value = ''
    }, 2500)
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo añadir el plato.'
  } finally {
    saving.value = false
  }
}
async function toggleDishFavorite(dish) {
  const previous = Boolean(dish.is_favorite)
  dish.is_favorite = !previous
  try {
    await refreshToken()
    const data = await postJson('menudiario/toggle_dish_favorite', userToken.value, {
      id: dish.id,
      favorite: dish.is_favorite,
    })
    if (Array.isArray(data.dishes)) dishes.value = data.dishes
  } catch (reason) {
    dish.is_favorite = previous
    error.value = reason instanceof Error ? reason.message : 'No se pudo actualizar el favorito.'
  }
}

async function login() {
  error.value = ''
  try {
    const result = await signInWithGoogle()
    const token = await result.user.getIdToken()
    await postJson('auth/login', token, { id_token: token })
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo iniciar sesión con Google.'
  }
}
async function logout() {
  stopTelegramPolling()
  await signOut()
  menus.value = new Map()
  rangeDays.value = new Map()
  dayEntries.value = []
  nextRangeStart.value = ''
  calendarDays.value = new Map()
  globalAlerts.value = []
  notifications.value = []
  notificationUnreadCount.value = 0
  notificationsOpen.value = false
  menuOpen.value = false
  shoppingSelectedDays.value = new Set()
  shoppingSelectionInitialized.value = false
  shoppingItems.value = []
  shoppingChecked.value = new Set()
  shoppingErrorDetails.value = ''
  shoppingErrorModal.value = null
  shoppingStep.value = 1
  telegram.value = {
    configured: false,
    connected: false,
    bot_username: '',
    chat_id: null,
    username: '',
    first_name: '',
    linked_at: null,
  }
}
async function savePreferences() {
  saving.value = true
  try {
    await refreshToken()
    const path =
      group.value?.owner_uid === user.value?.uid
        ? 'menudiario/group_options'
        : 'menudiario/preferences'
    const data = await postJson(path, userToken.value, {
      enabled_meals: preferences.enabled_meals,
      default_reminder_enabled: preferences.default_reminder_enabled,
      default_reminder_time: preferences.default_reminder_time,
      notification_enabled: preferences.notification_enabled,
      notification_types: preferences.notification_types,
    })
    if (data.group) group.value = data.group
    preferences.enabled_meals =
      data.group?.enabled_meals || data.preferences?.enabled_meals || preferences.enabled_meals
    preferences.default_reminder_enabled = Boolean(
      data.preferences?.default_reminder_enabled ?? preferences.default_reminder_enabled,
    )
    preferences.default_reminder_time =
      data.preferences?.default_reminder_time || preferences.default_reminder_time
    preferences.notification_enabled = data.preferences?.notification_enabled !== false
    preferences.notification_types = Array.isArray(data.preferences?.notification_types)
      ? [...data.preferences.notification_types]
      : preferences.notification_types
    notice.value = 'Ajustes guardados.'
    window.setTimeout(() => {
      notice.value = ''
    }, 2500)
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudieron guardar los ajustes.'
  } finally {
    saving.value = false
  }
}
function stopTelegramPolling() {
  if (telegramPollTimer) {
    window.clearTimeout(telegramPollTimer)
    telegramPollTimer = null
  }
}
async function refreshTelegramStatus() {
  if (!user.value) return false
  telegramStatusLoading.value = true
  try {
    await refreshToken()
    const data = await getJson('menudiario/telegram_status', userToken.value)
    telegram.value = data.telegram || telegram.value
    return Boolean(telegram.value.connected)
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo comprobar Telegram.'
    return false
  } finally {
    telegramStatusLoading.value = false
  }
}
async function pollTelegramStatus(deadline) {
  stopTelegramPolling()
  const connected = await refreshTelegramStatus()
  if (connected || Date.now() >= deadline) {
    telegramLinking.value = false
    if (connected) notice.value = 'Telegram conectado correctamente.'
    else
      error.value =
        'No hemos recibido la confirmación. Puedes volver a abrir el enlace o intentarlo de nuevo.'
    if (notice.value)
      window.setTimeout(() => {
        notice.value = ''
      }, 3500)
    return
  }
  telegramPollTimer = window.setTimeout(() => {
    void pollTelegramStatus(deadline)
  }, 1800)
}
async function connectTelegram() {
  if (telegramLinking.value) return
  telegramLinking.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/telegram_link', userToken.value, {})
    telegram.value = data.telegram || telegram.value
    const opened = window.open(data.url, '_blank', 'noopener,noreferrer')
    if (!opened) window.location.href = data.url
    notice.value = 'Abre Telegram y pulsa «Iniciar» en el bot.'
    window.setTimeout(() => {
      notice.value = ''
    }, 3500)
    void pollTelegramStatus(Date.now() + 120000)
  } catch (reason) {
    telegramLinking.value = false
    error.value =
      reason instanceof Error ? reason.message : 'No se pudo preparar la conexión con Telegram.'
  }
}
async function testTelegram() {
  telegramTesting.value = true
  error.value = ''
  try {
    await refreshToken()
    await postJson('menudiario/telegram_test', userToken.value, {})
    notice.value = 'Mensaje de prueba enviado a Telegram.'
    window.setTimeout(() => {
      notice.value = ''
    }, 3000)
  } catch (reason) {
    error.value =
      reason instanceof Error ? reason.message : 'No se pudo enviar el mensaje de prueba.'
  } finally {
    telegramTesting.value = false
  }
}
async function loadSharedDay() {
  const token = route.params.token
  if (typeof token !== 'string' || !token) {
    shareError.value = 'El enlace temporal no es válido o ha caducado.'
    return
  }
  shareLoading.value = true
  try {
    shareData.value = await getJson(`menudiario/day_share?token=${encodeURIComponent(token)}`, '')
  } catch (reason) {
    shareError.value =
      reason instanceof Error ? reason.message : 'No se pudo cargar el menú compartido.'
  } finally {
    shareLoading.value = false
  }
}
async function disconnectTelegram() {
  if (!window.confirm('¿Quieres desconectar Telegram de esta cuenta?')) return
  telegramStatusLoading.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/telegram_unlink', userToken.value, {})
    telegram.value = data.telegram || telegram.value
    notice.value = 'Telegram desconectado.'
    window.setTimeout(() => {
      notice.value = ''
    }, 2500)
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo desconectar Telegram.'
  } finally {
    telegramStatusLoading.value = false
  }
}
function openEditor(dayKey, requestedWeek = '') {
  draftDayKey.value = dayKey
  draftWeekStart.value = requestedWeek
  draftDay.value = normalizedDay(menus.value.get(requestedWeek)?.days?.[dayKey], true)
  enabledMeals.value.forEach((meal) => {
    if (!draftDay.value.meals[meal].items.length) draftDay.value.meals[meal].items.push('')
  })
  editorOpen.value = true
}
function closeEditor() {
  if (!saving.value) editorOpen.value = false
}
function addDish(meal) {
  draftDay.value.meals[meal].items.push('')
}
function removeDish(meal, index) {
  draftDay.value.meals[meal].items.splice(index, 1)
  if (!draftDay.value.meals[meal].items.length) draftDay.value.meals[meal].items.push('')
}
function optionIsSelected(id) {
  return Boolean(draftDay.value?.option_ids?.includes(Number(id)))
}
function toggleOption(id) {
  if (!draftDay.value) return
  const optionId = Number(id)
  const selected = new Set(draftDay.value.option_ids || [])
  if (selected.has(optionId)) selected.delete(optionId)
  else selected.add(optionId)
  draftDay.value.option_ids = [...selected]
}
function selectedOptions(dayKey, requestedWeek = '') {
  const ids = currentDay(dayKey, requestedWeek).option_ids || []
  return dailyOptions.value.filter((option) => ids.includes(Number(option.id)))
}
function optionIcon(option) {
  return optionIcons[option?.icon] || PhNote
}
function normalizeDishName(name) {
  return String(name || '')
    .trim()
    .toLocaleLowerCase('es')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
}
function loadedRouletteUsedNames() {
  const used = new Set()
  menus.value.forEach((menu) =>
    Object.entries(menu?.days || {}).forEach(([dayDate, day]) => {
      if (dayDate === draftDayKey.value) return
      allMeals.forEach((meal) =>
        (day.meals?.[meal]?.items || []).forEach((item) => {
          const normalized = normalizeDishName(item)
          if (normalized) used.add(normalized)
        }),
      )
    }),
  )
  return used
}
function refreshRouletteCandidates() {
  const used = rouletteUsedNames.value
  const unique = new Map()
  roulettePool.value.forEach((dish) => {
    const normalized = normalizeDishName(dish.name)
    if (normalized && !used.has(normalized) && !unique.has(normalized)) unique.set(normalized, dish)
  })
  // Nunca dejamos la máquina sin premios: si ya se han usado todos los platos
  // propios, recurrimos a ideas inventadas como reserva.
  if (!unique.size) {
    defaultRouletteDishes.forEach((dish) => {
      const normalized = normalizeDishName(dish.name)
      if (normalized && !unique.has(normalized)) unique.set(normalized, dish)
    })
  }
  rouletteCandidates.value = [...unique.values()]
}
function openRoulette() {
  if (!draftDay.value) return
  rouletteMeal.value = enabledMeals.value.includes(rouletteMeal.value)
    ? rouletteMeal.value
    : enabledMeals.value[0]
  rouletteResult.value = null
  rouletteReelPosition.value = 0
  rouletteReelTransition.value = true
  rouletteOpen.value = true
  void prepareRoulette()
}
async function prepareRoulette() {
  rouletteContextLoading.value = true
  rouletteUsedNames.value = loadedRouletteUsedNames()
  try {
    await refreshToken()
    const data = await getJson(
      `menudiario/roulette_context?day_date=${encodeURIComponent(draftDayKey.value)}`,
      userToken.value,
    )
    if (Array.isArray(data.used_dishes))
      rouletteUsedNames.value = new Set(data.used_dishes.map(normalizeDishName).filter(Boolean))
  } catch {
    // The local menu cache still protects against visible repetitions if the context endpoint is unavailable.
  } finally {
    refreshRouletteCandidates()
    rouletteContextLoading.value = false
  }
}
function spinRoulette() {
  if (rouletteSpinning.value || rouletteContextLoading.value || !rouletteCandidates.value.length)
    return
  const options =
    rouletteCandidates.value.length > 1 && rouletteResult.value
      ? rouletteCandidates.value.filter(
          (dish) => normalizeDishName(dish.name) !== normalizeDishName(rouletteResult.value.name),
        )
      : rouletteCandidates.value
  const selected = options[Math.floor(Math.random() * options.length)]
  const index = rouletteCandidates.value.findIndex((dish) => dish.id === selected.id)
  rouletteResult.value = null
  rouletteSpinning.value = true
  rouletteReelPosition.value += rouletteCandidates.value.length * 6 + index
  rouletteTimer = window.setTimeout(() => {
    rouletteResult.value = selected
    rouletteSpinning.value = false
    rouletteTimer = null
    // Keep the winning item visible but rewind the long track invisibly so
    // the next spin always has enough runway for its animation.
    window.requestAnimationFrame(() => {
      rouletteReelTransition.value = false
      rouletteReelPosition.value = index
      window.requestAnimationFrame(() => {
        rouletteReelTransition.value = true
      })
    })
  }, 3600)
}
function selectRouletteDish() {
  if (!rouletteResult.value || !draftDay.value?.meals?.[rouletteMeal.value]) return
  const items = draftDay.value.meals[rouletteMeal.value].items.filter((item) => String(item).trim())
  const selectedName = rouletteResult.value.name
  if (!items.some((item) => normalizeDishName(item) === normalizeDishName(selectedName)))
    items.push(selectedName)
  draftDay.value.meals[rouletteMeal.value].items = items
  closeRoulette()
}
function closeRoulette() {
  if (rouletteTimer) window.clearTimeout(rouletteTimer)
  rouletteTimer = null
  rouletteSpinning.value = false
  rouletteReelTransition.value = true
  rouletteOpen.value = false
}
const isGroupOwner = computed(() =>
  Boolean(group.value && user.value && group.value.owner_uid === user.value.uid),
)
const activeSettingsTab = ref('configuration')
const settingsTabs = computed(() =>
  [
    { id: 'configuration', label: 'Configuración', icon: PhGear },
    { id: 'group', label: 'Grupo', icon: PhUsers },
    { id: 'alerts', label: 'Avisos', icon: PhBell, ownerOnly: true },
    { id: 'options', label: 'Opciones', icon: PhNote },
    { id: 'telegram', label: 'Telegram', icon: PhTelegramLogo },
  ].filter((tab) => !tab.ownerOnly || isGroupOwner.value),
)
async function copyInviteLink() {
  if (!group.value?.invite_code) return
  const link = `${window.location.origin}${window.location.pathname}?groupInvite=${encodeURIComponent(group.value.invite_code)}`
  try {
    await navigator.clipboard.writeText(link)
    notice.value = 'Enlace de invitación copiado.'
  } catch {
    notice.value = link
  }
  window.setTimeout(() => {
    notice.value = ''
  }, 3500)
}
async function inviteMember() {
  if (!inviteEmail.value.trim()) return
  saving.value = true
  try {
    await refreshToken()
    const data = await postJson('menudiario/invite_email', userToken.value, {
      email: inviteEmail.value.trim(),
    })
    group.value = data.group || group.value
    inviteEmail.value = ''
    notice.value = 'Invitación guardada.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo crear la invitación.'
  } finally {
    saving.value = false
  }
}
async function joinGroup() {
  if (!joinCode.value.trim()) return
  saving.value = true
  try {
    await refreshToken()
    const data = await postJson('menudiario/join_group', userToken.value, {
      invite_code: joinCode.value.trim(),
    })
    group.value = data.group || group.value
    dailyOptions.value = data.daily_options || []
    preferences.enabled_meals = group.value?.enabled_meals || preferences.enabled_meals
    joinCode.value = ''
    goToDashboard()
    await loadDashboardRange()
    notice.value = 'Te has unido al grupo.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo unir al grupo.'
  } finally {
    saving.value = false
  }
}
async function leaveGroup() {
  saving.value = true
  try {
    await refreshToken()
    const data = await postJson('menudiario/leave_group', userToken.value, {})
    group.value = data.group || null
    dailyOptions.value = data.daily_options || []
    preferences.enabled_meals = group.value?.enabled_meals || ['lunch']
    await loadDashboardRange()
    notice.value = 'Has salido del grupo.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo salir del grupo.'
  } finally {
    saving.value = false
  }
}
function resetOptionDraft() {
  Object.assign(optionDraft, {
    id: 0,
    name: '',
    description: '',
    active: true,
    color: 'blue',
    icon: 'note',
    order: 0,
  })
}
function editOption(option) {
  Object.assign(optionDraft, {
    id: Number(option.id),
    name: option.name,
    description: option.description || '',
    active: Boolean(Number(option.active)),
    color: option.color || 'blue',
    icon: option.icon || 'note',
    order: Number(option.order || 0),
  })
}
async function saveOption() {
  if (!optionDraft.name.trim()) return
  saving.value = true
  try {
    await refreshToken()
    const data = await postJson('menudiario/save_daily_option', userToken.value, {
      ...optionDraft,
      name: optionDraft.name.trim(),
    })
    dailyOptions.value = data.daily_options || dailyOptions.value
    resetOptionDraft()
    notice.value = 'Opción diaria guardada.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo guardar la opción diaria.'
  } finally {
    saving.value = false
  }
}
async function deleteOption(id) {
  saving.value = true
  try {
    await refreshToken()
    const data = await postJson('menudiario/delete_daily_option', userToken.value, { id })
    dailyOptions.value = data.daily_options || dailyOptions.value
    if (Number(optionDraft.id) === Number(id)) resetOptionDraft()
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo borrar la opción diaria.'
  } finally {
    saving.value = false
  }
}
function resetAlertDraft() {
  Object.assign(alertDraft, {
    id: 0,
    name: '',
    message: '',
    time: '09:00',
    day_offset: 0,
    icon: 'bell',
    default_enabled: false,
    scope: 'all',
    active: true,
    order: 0,
  })
}
function editAlert(alert) {
  Object.assign(alertDraft, {
    id: Number(alert.id),
    name: alert.name,
    message: alert.message || '',
    time: alert.time || '09:00',
    day_offset: Number(alert.day_offset || 0),
    icon: alert.icon || 'bell',
    default_enabled: Boolean(alert.default_enabled),
    scope: alert.scope || 'all',
    active: Boolean(alert.active),
    order: Number(alert.order || 0),
  })
}
async function saveAlert() {
  if (!alertDraft.name.trim()) return
  saving.value = true
  try {
    await refreshToken()
    const data = await postJson('menudiario/save_global_alert', userToken.value, {
      ...alertDraft,
      name: alertDraft.name.trim(),
    })
    globalAlerts.value = data.global_alerts || globalAlerts.value
    resetAlertDraft()
    notice.value = 'Aviso global guardado.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo guardar el aviso global.'
  } finally {
    saving.value = false
  }
}
async function deleteAlert(id) {
  saving.value = true
  try {
    await refreshToken()
    const data = await postJson('menudiario/delete_global_alert', userToken.value, { id })
    globalAlerts.value = data.global_alerts || globalAlerts.value
    if (Number(alertDraft.id) === Number(id)) resetAlertDraft()
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo borrar el aviso global.'
  } finally {
    saving.value = false
  }
}
function setGlobalAlertEnabled(alert) {
  alert.overridden = true
}
function restoreGlobalAlertDefault(alert) {
  const definition = globalAlerts.value.find((item) => Number(item.id) === Number(alert.alert_id))
  if (!definition) return
  alert.enabled = Boolean(definition.default_enabled)
  alert.overridden = false
}
function addCustomAlert(meal) {
  draftDay.value.meals[meal].alerts.push({
    type: 'custom',
    id: customAlertId(),
    name: '',
    time: preferences.default_reminder_time || '09:00',
    day_offset: 0,
    icon: 'bell',
    message: '',
    enabled: true,
  })
}
function removeCustomAlert(meal, index) {
  draftDay.value.meals[meal].alerts.splice(index, 1)
}
function mealActiveAlerts(dayKey, meal, requestedWeek = '') {
  return currentDay(dayKey, requestedWeek, true).meals[meal].alerts.filter((alert) => alert.enabled)
}
function dayAlertIcons(dayKey, requestedWeek = '') {
  const icons = new Set()
  return enabledMeals.value
    .flatMap((meal) => mealActiveAlerts(dayKey, meal, requestedWeek))
    .filter((alert) => {
      const icon = alert.icon || 'bell'
      if (icons.has(icon)) return false
      icons.add(icon)
      return true
    })
}
async function markNotificationRead(notification) {
  if (notification.read) return
  try {
    await refreshToken()
    const data = await postJson('menudiario/mark_notification_read', userToken.value, {
      id: notification.id,
    })
    notification.read = true
    notificationUnreadCount.value = Number(data.notification_unread_count || 0)
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo marcar la notificación.'
  }
}
async function markAllNotificationsRead() {
  if (!hasUnreadNotifications.value) return
  try {
    await refreshToken()
    await postJson('menudiario/mark_all_notifications_read', userToken.value, {})
    notifications.value.forEach((notification) => {
      notification.read = true
    })
    notificationUnreadCount.value = 0
  } catch (reason) {
    error.value =
      reason instanceof Error ? reason.message : 'No se pudieron marcar las notificaciones.'
  }
}
async function saveDay(closeAfter = true) {
  saving.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/save_day', userToken.value, {
      week_start: draftWeekStart.value,
      day_date: draftDayKey.value,
      day: draftDay.value,
    })
    const nextMenus = new Map(menus.value)
    const currentMenu = nextMenus.get(draftWeekStart.value) || {
      week_start: draftWeekStart.value,
      days: {},
    }
    const savedMenu = {
      ...currentMenu,
      days: { ...currentMenu.days, [draftDayKey.value]: data.day },
    }
    nextMenus.set(draftWeekStart.value, savedMenu)
    menus.value = nextMenus
    rangeDays.value = new Map(rangeDays.value).set(draftDayKey.value, {
      day: data.day,
      weekStart: draftWeekStart.value,
    })
    if (calendarDays.value.has(draftDayKey.value))
      calendarDays.value = new Map(calendarDays.value).set(draftDayKey.value, {
        day: data.day,
        weekStart: draftWeekStart.value,
      })
    if (closeAfter) {
      editorOpen.value = false
      notice.value = 'Día guardado.'
      window.setTimeout(() => {
        notice.value = ''
      }, 2500)
    }
    return true
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo guardar el día.'
    return false
  } finally {
    saving.value = false
  }
}
async function remindGroup() {
  if (!draftDayCompleted.value || !draftDayHasMeals.value || remindingGroup.value) return
  remindingGroup.value = true
  error.value = ''
  try {
    const saved = await saveDay(false)
    if (!saved) return
    await refreshToken()
    const data = await postJson('menudiario/telegram_day_reminder', userToken.value, {
      week_start: draftWeekStart.value,
      day_date: draftDayKey.value,
    })
    notice.value = `Recordatorio enviado al grupo (${data.sent} ${data.sent === 1 ? 'persona' : 'personas'}).`
    window.setTimeout(() => {
      notice.value = ''
    }, 4000)
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo recordar al grupo.'
  } finally {
    remindingGroup.value = false
  }
}
function startSwap(dayKey, meal, requestedWeek = '') {
  swapSource.value =
    swapSource.value?.day_date === dayKey &&
    swapSource.value?.meal === meal &&
    swapSource.value?.week_start === requestedWeek
      ? null
      : { week_start: requestedWeek, day_date: dayKey, meal }
}
function startDrag(dayKey, meal, requestedWeek = '') {
  dragSource.value = { week_start: requestedWeek, day_date: dayKey, meal }
}
async function dropMeal(dayKey, meal, requestedWeek = '') {
  const source = dragSource.value || swapSource.value
  dragSource.value = null
  if (!source) return
  if (source.day_date === dayKey && source.meal === meal && source.week_start === requestedWeek) {
    swapSource.value = null
    return
  }
  saving.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/swap_meals', userToken.value, {
      week_start: requestedWeek,
      source,
      target: { week_start: requestedWeek, day_date: dayKey, meal },
    })
    const nextMenus = new Map(menus.value)
    for (const swappedMenu of data.menus || []) nextMenus.set(swappedMenu.week_start, swappedMenu)
    if (data.menu) nextMenus.set(requestedWeek, data.menu)
    menus.value = nextMenus
    const nextRangeDays = new Map(rangeDays.value)
    const nextCalendarDays = new Map(calendarDays.value)
    for (const swappedMenu of data.menus || []) {
      Object.entries(swappedMenu.days || {}).forEach(([isoDate, day]) => {
        const entry = { day, weekStart: swappedMenu.week_start }
        if (nextRangeDays.has(isoDate)) nextRangeDays.set(isoDate, entry)
        if (nextCalendarDays.has(isoDate)) nextCalendarDays.set(isoDate, entry)
      })
    }
    rangeDays.value = nextRangeDays
    calendarDays.value = nextCalendarDays
    swapSource.value = null
    notice.value = 'Platos intercambiados.'
    window.setTimeout(() => {
      notice.value = ''
    }, 2500)
  } catch (reason) {
    error.value =
      reason instanceof Error ? reason.message : 'No se pudieron intercambiar los platos.'
  } finally {
    saving.value = false
  }
}
function isSelected(dayKey, meal, requestedWeek = '') {
  return (
    swapSource.value?.day_date === dayKey &&
    swapSource.value?.meal === meal &&
    swapSource.value?.week_start === requestedWeek
  )
}
function hasItems(dayKey, meal, requestedWeek = '') {
  return currentDay(dayKey, requestedWeek).meals[meal].items.length > 0
}
function goToSettings() {
  menuOpen.value = false
  router.push({ name: 'settings' })
}
function goToDashboard() {
  menuOpen.value = false
  router.push({ name: 'dashboard' })
}
function goToDishes() {
  menuOpen.value = false
  router.push({ name: 'dishes' })
}
function goToShopping() {
  menuOpen.value = false
  router.push({ name: 'shopping' })
}
function goToCalendar() {
  menuOpen.value = false
  router.push({ name: 'calendar' })
}

function isRunningStandalone() {
  return (
    window.matchMedia?.('(display-mode: standalone)').matches ||
    window.navigator.standalone === true
  )
}

async function installApp() {
  if (!installPrompt.value) return
  const promptEvent = installPrompt.value
  installPrompt.value = null
  try {
    await promptEvent.prompt()
    await promptEvent.userChoice
  } finally {
    installBannerVisible.value = false
  }
}

function dismissInstallBanner() {
  installBannerVisible.value = false
}

watch([() => route.name, calendarMonth], () => {
  if (user.value && isCalendar.value) void loadCalendarMonth()
  if (user.value && isShopping.value) void loadShoppingRange()
})

onMounted(async () => {
  window.addEventListener('scroll', loadMoreOnScroll, { passive: true })
  isStandalone.value = isRunningStandalone()
  installPromptHandler = (event) => {
    event.preventDefault()
    installPrompt.value = event
    if (!isStandalone.value) installBannerVisible.value = true
  }
  appInstalledHandler = () => {
    installPrompt.value = null
    installBannerVisible.value = false
    isStandalone.value = true
  }
  window.addEventListener('beforeinstallprompt', installPromptHandler)
  window.addEventListener('appinstalled', appInstalledHandler)
  if (isShared.value) {
    await loadSharedDay()
    return
  }
  const inviteFromUrl = new URLSearchParams(window.location.search).get('groupInvite')
  if (inviteFromUrl) joinCode.value = inviteFromUrl.trim().toUpperCase()
  if (!hasFirebaseConfig()) {
    authReady.value = true
    loading.value = false
    error.value = 'Configura Firebase en el archivo .env para activar el acceso con Google.'
    return
  }
  try {
    await getFirebaseAuth()
    await observeAuth(async (nextUser) => {
      user.value = nextUser
      authReady.value = true
      if (nextUser) {
        if (inviteFromUrl) goToSettings()
        await loadDashboardRange()
        if (isCalendar.value) await loadCalendarMonth()
      } else loading.value = false
    })
  } catch (reason) {
    authReady.value = true
    loading.value = false
    error.value = reason instanceof Error ? reason.message : 'No se pudo inicializar Firebase.'
  }
})

onUnmounted(() => {
  window.removeEventListener('scroll', loadMoreOnScroll)
  if (installPromptHandler) window.removeEventListener('beforeinstallprompt', installPromptHandler)
  if (appInstalledHandler) window.removeEventListener('appinstalled', appInstalledHandler)
  stopTelegramPolling()
  if (rouletteTimer) window.clearTimeout(rouletteTimer)
})
</script>

<template>
  <div class="app-shell">
    <header class="topbar">
      <a
        v-if="user"
        :href="baseUrl"
        class="brand-mark brand-link"
        aria-label="Ir al dashboard"
        @click.prevent="goToDashboard"
      >
        <img
          class="brand-icon"
          :src="publicAsset('icons/menu-diario-96.png')"
          alt=""
          aria-hidden="true"
        />
        <div><strong>Menu Diario</strong><small>Comer bien, cada día</small></div>
      </a>
      <div v-else class="brand-mark">
        <img
          class="brand-icon"
          :src="publicAsset('icons/menu-diario-96.png')"
          alt=""
          aria-hidden="true"
        />
        <div><strong>Menu Diario</strong><small>Comer bien, cada día</small></div>
      </div>
      <div v-if="user" class="navigation-menu">
        <button
          type="button"
          class="menu-trigger"
          :aria-expanded="menuOpen"
          aria-label="Abrir menú"
          @click.stop="menuOpen = !menuOpen"
        >
          <PhList :size="22" weight="regular" /><span>Menú</span>
        </button>
        <div v-if="menuOpen" class="navigation-panel" @click.stop>
          <button
            type="button"
            :class="{ active: route.name === 'dashboard' }"
            @click="goToDashboard"
          >
            <PhHouse :size="19" weight="regular" /><span>Planificador</span></button
          ><button type="button" :class="{ active: isDishes }" @click="goToDishes">
            <PhForkKnife :size="19" weight="regular" /><span>Mis platos</span></button
          ><button type="button" :class="{ active: isShopping }" @click="goToShopping">
            <PhShoppingCart :size="19" weight="regular" /><span>Lista de la compra</span></button
          ><button type="button" :class="{ active: isCalendar }" @click="goToCalendar">
            <PhCalendarBlank :size="19" weight="regular" /><span>Calendario</span></button
          ><button type="button" :class="{ active: isSettings }" @click="goToSettings">
            <PhGear :size="19" weight="regular" /><span>Ajustes</span>
          </button>
        </div>
      </div>
      <div v-if="user" class="account-actions">
        <span class="user-name">{{ user.displayName || user.email }}</span>
        <div class="notification-menu">
          <button
            class="round-icon-button notification-trigger"
            title="Abrir notificaciones"
            aria-label="Abrir notificaciones"
            :aria-expanded="notificationsOpen"
            @click.stop="notificationsOpen = !notificationsOpen"
          >
            <PhBell :size="22" weight="regular" /><span
              v-if="hasUnreadNotifications"
              class="notification-badge"
              >{{ notificationUnreadCount > 99 ? '99+' : notificationUnreadCount }}</span
            >
          </button>
          <div v-if="notificationsOpen" class="notifications-panel" @click.stop>
            <div class="notifications-header">
              <div>
                <strong>Notificaciones</strong
                ><small>{{
                  notificationUnreadCount ? `${notificationUnreadCount} sin leer` : 'Todo leído'
                }}</small>
              </div>
              <button
                v-if="hasUnreadNotifications"
                type="button"
                class="text-button"
                @click="markAllNotificationsRead"
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
                  @click="markNotificationRead(notification)"
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
          @click="logout"
        >
          <PhSignOut :size="22" weight="regular" />
        </button>
      </div>
    </header>

    <aside v-if="installBannerVisible && !isStandalone" class="install-banner" aria-live="polite">
      <img :src="publicAsset('icons/menu-diario-96.png')" alt="" aria-hidden="true" />
      <div>
        <strong>Instala Menu Diario</strong>
        <span>Ten tu planificador siempre a mano.</span>
      </div>
      <button type="button" class="primary-button install-button" @click="installApp">
        <PhDownloadSimple :size="18" /> Instalar
      </button>
      <button
        type="button"
        class="icon-button install-dismiss"
        aria-label="Cerrar aviso de instalación"
        @click="dismissInstallBanner"
      >
        <PhX :size="20" />
      </button>
    </aside>

    <main :class="{ 'settings-main': isSettings }">
      <section v-if="isShared" class="shared-day-page">
        <div v-if="shareLoading" class="loading-card">
          <div class="spinner"></div>
          Cargando menú compartido…
        </div>
        <div v-else-if="shareError" class="shared-day-card shared-day-error">
          <div class="shared-day-icon"><PhWarningCircle :size="31" weight="regular" /></div>
          <p class="eyebrow">ENLACE TEMPORAL</p>
          <h1>Este menú ya no está disponible</h1>
          <p class="muted">{{ shareError }}</p>
        </div>
        <div v-else-if="shareData" class="shared-day-card">
          <div class="shared-day-heading">
            <div>
              <p class="eyebrow">{{ shareData.group_name }}</p>
              <h1>{{ sharedDayTitle }}</h1>
            </div>
            <div class="shared-day-icon"><PhForkKnife :size="30" weight="regular" /></div>
          </div>
          <div class="shared-meal-list">
            <article v-for="meal in allMeals" :key="meal" class="shared-meal">
              <span class="meal-icon"
                ><component :is="mealIcons[meal]" :size="20" weight="regular"
              /></span>
              <div>
                <strong>{{ mealLabels[meal] }}</strong>
                <div v-if="shareData.day.meals[meal].items.length" class="shared-dishes">
                  <span
                    v-for="(item, itemIndex) in shareData.day.meals[meal].items"
                    :key="`${item}-${itemIndex}`"
                    >{{ item }}</span
                  >
                </div>
                <span v-else class="detail-empty">Sin plato configurado</span>
                <small v-if="shareData.day.meals[meal].note">{{
                  shareData.day.meals[meal].note
                }}</small>
              </div>
            </article>
          </div>
          <div v-if="shareData.day.notes" class="day-note">
            <PhNotePencil :size="20" weight="regular" />
            <div>
              <strong>Nota del día</strong><span>{{ shareData.day.notes }}</span>
            </div>
          </div>
          <p class="shared-day-expiry">Este enlace caduca en 24 horas.</p>
        </div>
      </section>
      <section v-else-if="!user && authReady" class="welcome-card">
        <div class="welcome-icon">
          <img :src="publicAsset('icons/menu-diario-144.png')" alt="" aria-hidden="true" />
        </div>
        <p class="eyebrow">PLANIFICA SIN COMPLICARTE</p>
        <h1>Un menú claro para cada día.</h1>
        <p class="welcome-copy">
          Organiza desayuno, comida y cena en un vistazo. Tus platos quedan guardados y puedes
          moverlos entre días cuando cambien tus planes.
        </p>
        <div v-if="error" class="alert error-alert">{{ error }}</div>
        <button class="google-button" @click="login">
          <span class="google-g"><PhGoogleLogo :size="18" weight="bold" aria-hidden="true" /></span>
          Continuar con Google
        </button>
      </section>

      <template v-else-if="user">
        <div v-if="error && !isShopping" class="alert error-alert">{{ error }}</div>
        <div v-if="notice" class="alert notice-alert">{{ notice }}</div>
        <section v-if="isDishes" class="catalog-page">
          <div class="page-heading catalog-heading">
            <div>
              <p class="eyebrow">TU CATÁLOGO</p>
              <h1>Mis platos</h1>
              <p class="muted">Guarda tus platos habituales y tenlos a mano cuando planifiques.</p>
            </div>
            <button class="primary-button" @click="$refs.dishForm?.querySelector('input')?.focus()">
              <PhPlus :size="18" weight="regular" /> Añadir plato
            </button>
          </div>
          <form ref="dishForm" class="dish-create-form" @submit.prevent="saveDish">
            <PhPlus :size="20" weight="regular" aria-hidden="true" /><input
              v-model="dishDraft"
              type="text"
              maxlength="190"
              placeholder="Ej.: Curry de garbanzos"
              aria-label="Nombre del nuevo plato"
            /><button class="primary-button" :disabled="saving || !dishDraft.trim()">
              {{ saving ? 'Guardando…' : 'Guardar' }}
            </button>
          </form>
          <div class="catalog-toolbar">
            <label class="search-field"
              ><PhMagnifyingGlass :size="19" weight="regular" aria-hidden="true" /><input
                v-model="dishSearch"
                type="search"
                placeholder="Buscar en mis platos"
                aria-label="Buscar en mis platos" /></label
            ><button
              type="button"
              class="filter-button"
              :class="{ active: favoritesOnly }"
              @click="favoritesOnly = !favoritesOnly"
            >
              <PhHeart :size="18" :weight="favoritesOnly ? 'fill' : 'regular'" /> Solo favoritos
            </button>
          </div>
          <div v-if="!sortedDishes.length" class="empty-state">
            <PhForkKnife :size="34" weight="regular" />
            <h2>{{ favoritesOnly ? 'Aún no tienes favoritos' : 'Tu lista está vacía' }}</h2>
            <p>
              {{
                favoritesOnly
                  ? 'Marca el corazón de un plato para verlo aquí.'
                  : 'Añade tu primer plato y aparecerá también como sugerencia al planificar.'
              }}
            </p>
          </div>
          <section v-else class="dish-catalog-grid" aria-label="Listado de platos">
            <article v-for="dish in sortedDishes" :key="dish.id" class="dish-library-card">
              <div class="dish-library-icon"><PhForkKnife :size="22" weight="regular" /></div>
              <div class="dish-library-copy">
                <strong>{{ dish.name }}</strong
                ><small
                  >{{
                    dish.times_used
                      ? `Usado ${dish.times_used} ${dish.times_used === 1 ? 'vez' : 'veces'}`
                      : 'Todavía no usado'
                  }}<span v-if="dish.source === 'admin'"> · Sugerencia inicial</span></small
                >
              </div>
              <button
                type="button"
                class="favorite-button"
                :class="{ active: dish.is_favorite }"
                :aria-label="
                  dish.is_favorite
                    ? `Quitar ${dish.name} de favoritos`
                    : `Añadir ${dish.name} a favoritos`
                "
                :title="dish.is_favorite ? 'Quitar de favoritos' : 'Añadir a favoritos'"
                @click="toggleDishFavorite(dish)"
              >
                <PhHeart :size="22" :weight="dish.is_favorite ? 'fill' : 'regular'" />
              </button>
            </article>
          </section>
        </section>
        <section v-else-if="isShopping" class="shopping-page">
          <div class="page-heading shopping-heading">
            <div>
              <p class="eyebrow">ASISTENTE DE COMPRA</p>
              <h1>Lista de la compra</h1>
              <p class="muted">
                Dile a la IA qué vas a cocinar y tendrás los ingredientes agrupados en segundos.
              </p>
            </div>
          </div>
          <nav class="shopping-wizard-progress" aria-label="Progreso de la lista de la compra">
            <button
              v-for="step in shoppingSteps"
              :key="step.id"
              type="button"
              class="shopping-wizard-step"
              :class="{ active: shoppingStep === step.id, completed: shoppingStep > step.id }"
              :disabled="step.id > shoppingStep && !canEnterShoppingStep(step.id)"
              :aria-current="shoppingStep === step.id ? 'step' : undefined"
              @click="selectShoppingStep(step.id)"
            >
              <span>{{ step.id }}</span
              ><strong>{{ step.label }}</strong>
            </button>
          </nav>
          <div class="shopping-layout">
            <section
              v-if="shoppingStep === 1"
              class="shopping-builder"
              aria-labelledby="shopping-builder-title"
            >
              <div class="shopping-section-heading">
                <div class="shopping-section-icon">
                  <PhCalendarCheck :size="22" weight="regular" />
                </div>
                <div>
                  <p class="eyebrow">PASO 1</p>
                  <h2 id="shopping-builder-title">Elige los días</h2>
                  <p class="muted">
                    Partimos de tus próximos siete días. Puedes quitar los que no quieras cubrir.
                  </p>
                </div>
              </div>
              <div v-if="loading" class="shopping-loading">
                <div class="spinner"></div>
                Cargando tus próximos días…
              </div>
              <div v-else-if="!shoppingDayEntries.length" class="shopping-empty">
                <PhCalendarBlank :size="30" weight="regular" />
                <strong>Aún no hay días disponibles</strong>
                <span>Vuelve a intentarlo cuando tu menú esté cargado.</span>
              </div>
              <div v-else class="shopping-day-picker">
                <button
                  v-for="entry in shoppingDayEntries"
                  :key="entry.isoDate"
                  type="button"
                  class="shopping-day-option"
                  :class="{ selected: shoppingSelectedDays.has(entry.isoDate) }"
                  :aria-pressed="shoppingSelectedDays.has(entry.isoDate)"
                  @click="toggleShoppingDay(entry.isoDate)"
                >
                  <span class="shopping-day-check"><PhCheck :size="15" weight="bold" /></span>
                  <strong>{{ formatDay(entry.date) }}</strong>
                  <small
                    >{{
                      shoppingMeals.filter((meal) => meal.dayDate === entry.isoDate).length
                    }}
                    comidas con plato</small
                  >
                </button>
              </div>
              <div class="shopping-selection-footer">
                <span
                  ><PhForkKnife :size="18" /> {{ shoppingMeals.length }}
                  {{
                    shoppingMeals.length === 1 ? 'comida seleccionada' : 'comidas seleccionadas'
                  }}</span
                >
                <span class="shopping-selection-note"
                  >La IA usará solo los platos configurados.</span
                >
              </div>
              <div class="shopping-wizard-actions">
                <span>Paso 1 de 3</span>
                <button
                  type="button"
                  class="primary-button"
                  :disabled="!shoppingSelectedDays.size"
                  @click="nextShoppingStep"
                >
                  Revisar platos <PhArrowRight :size="17" />
                </button>
              </div>
            </section>

            <section
              v-else-if="shoppingStep === 2"
              class="shopping-builder shopping-review-step"
              aria-labelledby="shopping-review-title"
            >
              <div class="shopping-section-heading">
                <div class="shopping-section-icon"><PhForkKnife :size="22" weight="regular" /></div>
                <div>
                  <p class="eyebrow">PASO 2</p>
                  <h2 id="shopping-review-title">Revisa tus platos</h2>
                  <p class="muted">
                    Estas son las comidas que enviaré a la IA para preparar tu lista.
                  </p>
                </div>
              </div>
              <div
                v-if="shoppingMeals.length"
                class="shopping-meal-preview shopping-meal-preview-large"
              >
                <article
                  v-for="meal in shoppingMeals"
                  :key="`${meal.dayDate}-${meal.meal}`"
                  class="shopping-meal-preview-row"
                >
                  <span class="meal-icon"><component :is="mealIcons[meal.meal]" :size="18" /></span>
                  <div>
                    <small>{{ formatDay(meal.date) }} · {{ mealLabels[meal.meal] }}</small>
                    <strong>{{ meal.dishes.join(' · ') }}</strong>
                  </div>
                </article>
              </div>
              <div v-else class="shopping-no-meals">No hay platos en los días seleccionados.</div>
              <div class="shopping-wizard-actions">
                <button type="button" class="secondary-button" @click="previousShoppingStep">
                  <PhArrowLeft :size="17" /> Atrás
                </button>
                <button
                  type="button"
                  class="primary-button"
                  :disabled="!shoppingMeals.length || shoppingGenerating"
                  @click="nextShoppingStep"
                >
                  Generar lista <PhSparkle :size="17" weight="fill" />
                </button>
              </div>
            </section>

            <section v-else class="shopping-result" aria-labelledby="shopping-result-title">
              <div class="shopping-section-heading">
                <div class="shopping-section-icon result-icon">
                  <PhShoppingCart :size="22" weight="regular" />
                </div>
                <div>
                  <p class="eyebrow">PASO 3</p>
                  <h2 id="shopping-result-title">Tu lista</h2>
                  <p class="muted">
                    Revisa la propuesta, marca lo que ya tengas y envíala a Alexa.
                  </p>
                </div>
              </div>
              <div
                v-if="shoppingGenerating"
                class="shopping-generating"
                role="status"
                aria-live="polite"
              >
                <div class="shopping-generating-orbit"><PhSparkle :size="25" weight="fill" /></div>
                <strong>Preparando tu compra…</strong>
                <span>Estoy agrupando ingredientes repetidos.</span>
              </div>
              <div v-else-if="shoppingItems.length" class="shopping-result-content">
                <div class="shopping-result-toolbar">
                  <span
                    ><strong>{{ shoppingItems.length - shoppingChecked.size }}</strong> por
                    comprar</span
                  >
                  <button type="button" class="secondary-button" @click="copyShoppingList">
                    <PhNote :size="17" /> Copiar lista
                  </button>
                  <a
                    class="secondary-button shopping-alexa-link"
                    :href="shoppingAlexaUrl"
                    @click.prevent="sendShoppingListToAlexa"
                  >
                    <PhSpeakerHigh :size="17" /> Enviar a Alexa
                  </a>
                </div>
                <div class="shopping-groups">
                  <section
                    v-for="group in shoppingGroups"
                    :key="group.category"
                    class="shopping-group"
                  >
                    <h3>{{ group.category }}</h3>
                    <label
                      v-for="item in group.items"
                      :key="`${item.name}-${item.index}`"
                      class="shopping-item"
                      :class="{ checked: shoppingItemChecked(item.index) }"
                    >
                      <input
                        type="checkbox"
                        :checked="shoppingItemChecked(item.index)"
                        @change="toggleShoppingItem(item.index)"
                      />
                      <span class="shopping-item-check"><PhCheck :size="14" weight="bold" /></span>
                      <span class="shopping-item-copy"
                        ><strong>{{ item.name }}</strong
                        ><small v-if="item.quantity">{{ item.quantity }}</small></span
                      >
                    </label>
                  </section>
                </div>
                <div class="shopping-result-actions">
                  <button type="button" class="secondary-button" @click="previousShoppingStep">
                    <PhArrowLeft :size="17" /> Revisar platos
                  </button>
                  <button type="button" class="shopping-regenerate" @click="generateShoppingList">
                    <PhArrowsClockwise :size="17" /> Generar otra propuesta
                  </button>
                </div>
              </div>
              <div v-else class="shopping-result-empty">
                <div class="shopping-result-empty-icon">
                  <PhSparkle :size="29" weight="duotone" />
                </div>
                <h3>Tu lista aparecerá aquí</h3>
                <p>Selecciona los días que quieras cubrir y pulsa «Generar lista».</p>
                <button
                  type="button"
                  class="primary-button"
                  :disabled="!shoppingMeals.length"
                  @click="generateShoppingList"
                >
                  <PhSparkle :size="17" weight="fill" /> Generar con IA
                </button>
              </div>
            </section>
          </div>
          <dialog
            v-if="shoppingErrorModal"
            open
            class="modal-backdrop shopping-error-backdrop"
            @click.self="closeShoppingError"
          >
            <div class="modal-card shopping-error-modal">
              <div class="modal-header">
                <div class="shopping-error-heading">
                  <div class="shopping-error-icon"><PhWarningCircle :size="24" /></div>
                  <div>
                    <p class="eyebrow">AVISO</p>
                    <h2>{{ shoppingErrorModal.title }}</h2>
                  </div>
                </div>
                <button
                  type="button"
                  class="icon-button"
                  aria-label="Cerrar error"
                  @click="closeShoppingError"
                >
                  <PhX :size="22" />
                </button>
              </div>
              <p class="shopping-error-message">{{ shoppingErrorModal.message }}</p>
              <details v-if="shoppingErrorModal.details" class="shopping-error-details" open>
                <summary>Ver detalle técnico</summary>
                <pre>{{ shoppingErrorModal.details }}</pre>
              </details>
              <div class="modal-footer">
                <button type="button" class="secondary-button" @click="closeShoppingError">
                  Cerrar
                </button>
                <button
                  v-if="shoppingErrorModal.retry"
                  type="button"
                  class="primary-button"
                  @click="retryShoppingGeneration"
                >
                  <PhArrowsClockwise :size="17" /> Reintentar
                </button>
              </div>
            </div>
          </dialog>
        </section>
        <section v-else-if="isCalendar" class="calendar-page">
          <div class="page-heading calendar-heading">
            <div>
              <p class="eyebrow">VISTA MENSUAL</p>
              <h1>Calendario</h1>
              <p class="muted">
                Consulta tus comidas de un vistazo y abre cualquier día configurado.
              </p>
            </div>
            <button type="button" class="secondary-button" @click="goToCurrentMonth">Hoy</button>
          </div>
          <div class="calendar-toolbar">
            <button class="round-button" aria-label="Mes anterior" @click="changeMonth(-1)">
              <PhCaretLeft :size="22" weight="regular" />
            </button>
            <div>
              <strong>{{ monthLabel }}</strong
              ><small>Los días azules tienen comidas planificadas</small>
            </div>
            <button class="round-button" aria-label="Mes siguiente" @click="changeMonth(1)">
              <PhCaretRight :size="22" weight="regular" />
            </button>
          </div>
          <section class="calendar-card" aria-label="Calendario mensual">
            <div class="calendar-weekdays">
              <span v-for="weekday in ['L', 'M', 'X', 'J', 'V', 'S', 'D']" :key="weekday">{{
                weekday
              }}</span>
            </div>
            <div v-if="calendarLoading" class="calendar-loading">
              <div class="spinner"></div>
              Cargando mes…
            </div>
            <div v-else class="calendar-grid">
              <div v-for="week in calendarWeeks" :key="week[0].isoDate" class="calendar-week">
                <button
                  v-for="cell in week"
                  :key="cell.isoDate"
                  type="button"
                  class="calendar-day"
                  :class="calendarDayClass(cell)"
                  :disabled="!calendarDayHasMeals(cell.day)"
                  @click="openCalendarDay(cell)"
                >
                  <span class="calendar-number">{{ cell.date.getDate() }}</span
                  ><span v-if="calendarDayHasMeals(cell.day)" class="calendar-meals"
                    ><span
                      v-for="meal in allMeals"
                      :key="meal"
                      class="calendar-meal-dot"
                      :title="mealLabels[meal]"
                      ><component
                        :is="mealIcons[meal]"
                        :size="13"
                        weight="regular"
                        aria-hidden="true" /></span
                  ></span>
                </button>
              </div>
            </div>
          </section>
          <div class="calendar-legend">
            <span><i class="legend-dot"></i> Día con comidas</span
            ><span><i class="legend-today"></i> Hoy</span>
          </div>
        </section>
        <template v-else-if="isDashboard">
          <div v-if="swapSource" class="swap-hint">
            Selecciona otro bloque para intercambiarlo
            <button @click="swapSource = null">Cancelar</button>
          </div>
          <section v-if="loading" class="loading-card">
            <div class="spinner"></div>
            Cargando tu menú…
          </section>
          <section v-else class="week-grid">
            <article
              v-for="day in dayEntries"
              :key="`${day.weekStart}-${day.isoDate}`"
              class="day-card"
              :class="{ today: day.isoDate === toIsoDate(new Date()) }"
            >
              <header class="day-header">
                <div class="day-heading-copy">
                  <strong>{{
                    new Intl.DateTimeFormat('es-ES', { weekday: 'long' }).format(day.date)
                  }}</strong
                  ><small
                    >{{ day.date.getDate() }} de
                    {{
                      new Intl.DateTimeFormat('es-ES', { month: 'long' }).format(day.date)
                    }}</small
                  >
                </div>
                <span
                  v-if="dayAlertIcons(day.isoDate, day.weekStart).length"
                  class="day-alert-icons"
                  title="Avisos de este día"
                  aria-label="Este día tiene avisos"
                  ><component
                    v-for="alert in dayAlertIcons(day.isoDate, day.weekStart)"
                    :key="alert.icon"
                    :is="alertIcon(alert)"
                    :size="17"
                    weight="regular"
                    aria-hidden="true" /></span
                ><span v-if="day.isoDate === toIsoDate(new Date())" class="today-pill">Hoy</span>
              </header>
              <div v-if="selectedOptions(day.isoDate, day.weekStart).length" class="day-options">
                <span
                  v-for="option in selectedOptions(day.isoDate, day.weekStart)"
                  :key="option.id"
                  class="option-badge"
                  :class="`option-${option.color}`"
                  ><component
                    :is="optionIcon(option)"
                    :size="15"
                    weight="regular"
                    aria-hidden="true"
                  />
                  {{ option.name }}</span
                >
              </div>
              <div v-if="currentDay(day.isoDate, day.weekStart).notes" class="day-note">
                <PhNotePencil :size="20" weight="regular" aria-hidden="true" />
                <div>
                  <strong>Nota del día</strong
                  ><span>{{ currentDay(day.isoDate, day.weekStart).notes }}</span>
                </div>
              </div>
              <div class="meal-list">
                <div
                  v-for="meal in enabledMeals"
                  :key="meal"
                  class="meal-card"
                  :class="{
                    selected: isSelected(day.isoDate, meal, day.weekStart),
                    filled: hasItems(day.isoDate, meal, day.weekStart),
                  }"
                  draggable="true"
                  @dragstart="startDrag(day.isoDate, meal, day.weekStart)"
                  @dragover.prevent
                  @drop="dropMeal(day.isoDate, meal, day.weekStart)"
                  @click="swapSource ? dropMeal(day.isoDate, meal, day.weekStart) : null"
                >
                  <span class="meal-icon" aria-hidden="true"
                    ><component :is="mealIcons[meal]" :size="21" weight="regular"
                  /></span>
                  <div class="meal-content">
                    <div class="meal-top">
                      <span class="meal-name">{{ mealLabels[meal] }}</span
                      ><button
                        class="swap-button"
                        title="Seleccionar para intercambiar"
                        aria-label="Seleccionar para intercambiar"
                        @click.stop="startSwap(day.isoDate, meal, day.weekStart)"
                      >
                        <PhArrowsLeftRight :size="19" weight="regular" />
                      </button>
                    </div>
                    <div
                      v-if="currentDay(day.isoDate, day.weekStart).meals[meal].items.length"
                      class="dish-list"
                    >
                      <span
                        v-for="dish in currentDay(day.isoDate, day.weekStart).meals[meal].items"
                        :key="dish"
                        class="dish-chip"
                        >{{ dish }}</span
                      >
                    </div>
                    <button
                      v-else
                      class="empty-meal"
                      @click.stop="openEditor(day.isoDate, day.weekStart)"
                    >
                      Añadir plato <PhPlus :size="17" weight="regular" />
                    </button>
                    <span
                      v-if="mealActiveAlerts(day.isoDate, meal, day.weekStart).length"
                      class="meal-reminder"
                      ><PhBell :size="15" weight="regular" aria-hidden="true" />{{
                        mealActiveAlerts(day.isoDate, meal, day.weekStart).length
                      }}
                      aviso{{
                        mealActiveAlerts(day.isoDate, meal, day.weekStart).length > 1 ? 's' : ''
                      }}</span
                    ><span
                      v-if="currentDay(day.isoDate, day.weekStart).meals[meal].note"
                      class="meal-note"
                      >{{ currentDay(day.isoDate, day.weekStart).meals[meal].note }}</span
                    >
                  </div>
                </div>
              </div>
              <button class="edit-day" @click="openEditor(day.isoDate, day.weekStart)">
                Editar día <PhArrowRight :size="17" weight="regular" />
              </button>
            </article>
            <div class="infinite-status" aria-live="polite">
              <div v-if="loadingMore" class="spinner"></div>
              {{ loadingMore ? 'Cargando más días…' : 'Sigue bajando para ver más días' }}
            </div>
          </section>
          <button
            v-if="dayEntries.length"
            class="floating-add"
            aria-label="Añadir plato al primer día visible"
            @click="openEditor(dayEntries[0].isoDate, dayEntries[0].weekStart)"
          >
            <PhPlus :size="24" weight="regular" aria-hidden="true" /><span>Añadir plato</span>
          </button>
        </template>
      </template>
      <section v-else class="loading-card app-loading-card">
        <img
          class="loading-logo"
          :src="publicAsset('icons/menu-diario-144.png')"
          alt=""
          aria-hidden="true"
        />
        <div class="loading-copy">
          <strong>Menu Diario</strong>
          <span>Comprobando sesión…</span>
        </div>
        <div class="spinner" aria-hidden="true"></div>
      </section>
    </main>

    <dialog v-if="editorOpen" open class="modal-backdrop" @click.self="closeEditor">
      <div class="modal-card">
        <div class="modal-header">
          <div>
            <p class="eyebrow">EDITAR DÍA</p>
            <h2>{{ draftTitle }}</h2>
          </div>
          <div class="modal-header-actions">
            <button type="button" class="roulette-trigger" @click="openRoulette">
              <PhDiceFive :size="18" weight="duotone" /> Ruleta</button
            ><button class="icon-button" aria-label="Cerrar editor" @click="closeEditor">
              <PhX :size="22" weight="regular" />
            </button>
          </div>
        </div>
        <div class="editor-scroll">
          <div v-if="dailyOptions.filter((option) => option.active).length" class="editor-options">
            <span class="field-label">Condiciones del día</span
            ><label
              v-for="option in dailyOptions.filter((item) => item.active)"
              :key="option.id"
              class="option-check"
              ><input
                type="checkbox"
                :checked="optionIsSelected(option.id)"
                @change="toggleOption(option.id)"
              /><span class="option-badge" :class="`option-${option.color}`"
                ><component
                  :is="optionIcon(option)"
                  :size="15"
                  weight="regular"
                  aria-hidden="true"
                />
                {{ option.name }}</span
              ></label
            >
          </div>
          <div v-for="meal in enabledMeals" :key="meal" class="editor-meal">
            <div class="editor-meal-heading">
              <span
                ><component :is="mealIcons[meal]" :size="19" weight="regular" aria-hidden="true" />
                {{ mealLabels[meal] }}</span
              ><button class="text-button" @click="addDish(meal)">
                <PhPlus :size="16" weight="regular" /> Añadir plato
              </button>
            </div>
            <div v-if="draftDay.meals[meal].items.length" class="editor-dishes">
              <div
                v-for="(_, itemIndex) in draftDay.meals[meal].items"
                :key="itemIndex"
                class="dish-input-row"
              >
                <input
                  v-model="draftDay.meals[meal].items[itemIndex]"
                  list="dish-suggestions"
                  :placeholder="`Plato para ${mealLabels[meal].toLowerCase()}`"
                  maxlength="190"
                /><button
                  class="remove-button"
                  title="Quitar plato"
                  @click="removeDish(meal, itemIndex)"
                >
                  <PhX :size="17" weight="regular" />
                </button>
              </div>
            </div>
            <details class="meal-more-options">
              <summary>Más opciones</summary>
              <div class="more-options-content">
                <div class="meal-alert-list">
                  <div
                    v-for="alert in draftDay.meals[meal].alerts"
                    :key="alert.type === 'global' ? `global-${alert.alert_id}` : alert.id"
                    class="meal-alert-row"
                  >
                    <label class="reminder-check"
                      ><input
                        v-model="alert.enabled"
                        type="checkbox"
                        @change="alert.type === 'global' ? setGlobalAlertEnabled(alert) : null"
                      /><span
                        ><strong>{{ alert.name }}</strong
                        ><small>{{
                          alert.type === 'global'
                            ? alert.overridden
                              ? 'Aviso global personalizado para esta comida'
                              : 'Aviso global por defecto'
                            : 'Aviso solo para esta comida'
                        }}</small></span
                      ></label
                    >
                    <div class="meal-alert-meta">
                      <span class="meal-alert-time"
                        ><component
                          :is="alertIcon(alert)"
                          :size="15"
                          weight="regular"
                          aria-hidden="true"
                        />
                        {{ alert.time }} · {{ alertDayOffsetLabel(alert.day_offset) }}</span
                      ><button
                        v-if="alert.type === 'global' && alert.overridden"
                        type="button"
                        class="text-button"
                        @click="restoreGlobalAlertDefault(alert)"
                      >
                        Usar por defecto</button
                      ><button
                        v-if="alert.type === 'custom'"
                        type="button"
                        class="remove-button"
                        title="Quitar aviso"
                        @click="removeCustomAlert(meal, draftDay.meals[meal].alerts.indexOf(alert))"
                      >
                        <PhX :size="15" weight="regular" />
                      </button>
                    </div>
                    <p v-if="alert.message" class="alert-message">{{ alert.message }}</p>
                    <template v-if="alert.type === 'custom'"
                      ><div class="reminder-fields">
                        <label class="field-label"
                          >Nombre<input
                            v-model="alert.name"
                            type="text"
                            maxlength="120"
                            placeholder="Ej.: Comprar tupper" /></label
                        ><label class="field-label"
                          >Hora<input v-model="alert.time" type="time" /></label
                        ><label class="field-label"
                          >Día del aviso<select v-model.number="alert.day_offset">
                            <option v-for="days in 31" :key="days - 1" :value="days - 1">
                              {{ alertDayOffsetLabel(days - 1) }}
                            </option>
                          </select></label
                        >
                      </div>
                      <div class="field-label icon-picker-field custom-icon-picker-field">
                        Icono <span class="field-hint">Elige un icono</span>
                        <div
                          class="icon-picker"
                          role="group"
                          aria-label="Icono del aviso personalizado"
                        >
                          <button
                            v-for="icon in alertIconOptions"
                            :key="icon.id"
                            type="button"
                            class="icon-choice"
                            :class="{ selected: alert.icon === icon.id }"
                            :aria-label="icon.label"
                            :aria-pressed="alert.icon === icon.id"
                            :title="icon.label"
                            @click="alert.icon = icon.id"
                          >
                            <component
                              :is="icon.icon"
                              :size="19"
                              weight="regular"
                              aria-hidden="true"
                            />
                          </button>
                        </div>
                      </div>
                      <label class="field-label"
                        >Mensaje<input
                          v-model="alert.message"
                          type="text"
                          maxlength="240"
                          placeholder="Texto del aviso" /></label
                    ></template>
                  </div>
                </div>
                <button type="button" class="add-alert-button" @click="addCustomAlert(meal)">
                  <PhPlus :size="16" weight="regular" /> Añadir aviso solo a esta comida</button
                ><label class="field-label"
                  >Nota de la comida<textarea
                    v-model="draftDay.meals[meal].note"
                    rows="2"
                    placeholder="Nota opcional"
                  ></textarea>
                </label>
              </div>
            </details>
          </div>
          <label class="field-label"
            >Notas del día<textarea
              v-model="draftDay.notes"
              rows="3"
              placeholder="Preparación, compras o recordatorios"
            ></textarea>
          </label>
        </div>
        <div class="modal-footer">
          <button
            v-if="draftDayCompleted && draftDayHasMeals"
            class="telegram-reminder-button"
            :disabled="saving || remindingGroup"
            @click="remindGroup"
          >
            <PhTelegramLogo :size="18" />
            {{ remindingGroup ? 'Enviando…' : 'Recordar al grupo' }}
          </button>
          <button class="secondary-button" @click="closeEditor">Cancelar</button
          ><button class="primary-button" :disabled="saving || remindingGroup" @click="saveDay">
            {{ saving ? 'Guardando…' : 'Guardar día' }}
          </button>
        </div>
      </div>
    </dialog>

    <dialog
      v-if="rouletteOpen"
      open
      class="modal-backdrop roulette-backdrop"
      @click.self="closeRoulette"
    >
      <div class="modal-card roulette-card">
        <div class="modal-header">
          <div>
            <p class="eyebrow">UN POCO DE AZAR</p>
            <h2>Ruleta</h2>
          </div>
          <button class="icon-button" aria-label="Cerrar ruleta" @click="closeRoulette">
            <PhX :size="22" weight="regular" />
          </button>
        </div>
        <div class="roulette-intro">
          <PhSparkle :size="20" weight="fill" aria-hidden="true" /><span
            >Gira la casilla y deja que el azar prepare algo distinto.</span
          >
        </div>
        <label class="roulette-meal-select"
          >Añadir recomendación a<select v-model="rouletteMeal">
            <option v-for="meal in enabledMeals" :key="meal" :value="meal">
              {{ mealLabels[meal] }}
            </option>
          </select></label
        >
        <div
          class="slot-machine"
          :class="{ spinning: rouletteSpinning }"
          role="img"
          aria-label="Ruleta de recomendaciones"
        >
          <div class="slot-machine-top">
            <span class="slot-light"></span><strong>RULETA</strong><span class="slot-light"></span>
          </div>
          <div class="slot-reels">
            <div class="slot-reel-window">
              <div
                class="slot-reel-track"
                :class="{ 'reel-no-transition': !rouletteReelTransition }"
                :style="{ transform: `translateY(-${rouletteReelPosition * 64}px)` }"
              >
                <span
                  v-for="(dish, dishIndex) in rouletteReelItems"
                  :key="dishIndex"
                  class="slot-reel-item"
                  >{{ dish.name }}</span
                >
              </div>
            </div>
          </div>
          <div class="slot-machine-bottom"><span>✦</span><span>✦</span><span>✦</span></div>
        </div>
        <div v-if="rouletteContextLoading" class="roulette-status">
          <PhSpinnerGap :size="20" class="roulette-spin-icon" /> Comprobando tu historial…
        </div>
        <div v-else-if="rouletteResult" class="roulette-result" aria-live="polite">
          <span>La ruleta ha elegido</span><strong>{{ rouletteResult.name }}</strong
          ><small
            >Se añadirá a {{ mealLabels[rouletteMeal].toLowerCase() }} al seleccionarlo.</small
          >
        </div>
        <div class="roulette-actions">
          <button type="button" class="secondary-button" @click="closeRoulette">Cerrar</button
          ><button
            v-if="rouletteResult"
            type="button"
            class="roulette-repeat"
            @click="spinRoulette"
          >
            <PhArrowsClockwise :size="18" /> Repetir tirada</button
          ><button
            v-if="rouletteResult"
            type="button"
            class="primary-button roulette-select"
            @click="selectRouletteDish"
          >
            <PhCheckCircle :size="18" weight="fill" /> Seleccionar plato</button
          ><button
            v-else
            type="button"
            class="primary-button roulette-spin-button"
            :disabled="rouletteSpinning || rouletteContextLoading || !rouletteCandidates.length"
            @click="spinRoulette"
          >
            <PhDiceFive :size="21" weight="duotone" />
            {{ rouletteSpinning ? 'Girando…' : 'Girar la ruleta' }}
          </button>
        </div>
        <p class="roulette-footnote">
          La selección respeta los platos usados antes y después de este día. Guarda el día para
          confirmar.
        </p>
      </div>
    </dialog>

    <section v-if="user && isSettings" class="settings-page">
      <div class="page-heading settings-page-heading">
        <div>
          <p class="eyebrow">PERSONALIZA TU PLAN</p>
          <h1>Ajustes</h1>
          <p class="muted">
            Configura las comidas visibles, la colaboración y las condiciones de tus días.
          </p>
        </div>
        <button class="settings-button" @click="goToDashboard">
          <PhArrowLeft :size="18" weight="regular" /> <span>Volver al menú</span>
        </button>
      </div>
      <div class="settings-content">
        <nav class="settings-tabs" aria-label="Secciones de ajustes">
          <button
            v-for="tab in settingsTabs"
            :key="tab.id"
            type="button"
            class="settings-tab"
            :class="{ active: activeSettingsTab === tab.id }"
            :aria-current="activeSettingsTab === tab.id ? 'page' : undefined"
            @click="activeSettingsTab = tab.id"
          >
            <component :is="tab.icon" :size="18" weight="regular" /><span>{{ tab.label }}</span>
          </button>
        </nav>
        <section v-if="activeSettingsTab === 'configuration'" class="settings-tab-panel">
          <div class="meal-settings">
            <label v-for="meal in allMeals" :key="meal" class="meal-setting"
              ><input
                v-model="preferences.enabled_meals"
                type="checkbox"
                :value="meal"
                :disabled="!isGroupOwner" /><span class="setting-icon" aria-hidden="true"
                ><component :is="mealIcons[meal]" :size="22" weight="regular" /></span
              ><span
                ><strong>{{ mealLabels[meal] }}</strong
                ><small>{{
                  isGroupOwner ? 'Mostrar en cada día' : 'Lo gestiona el propietario del grupo'
                }}</small></span
              ><span class="checkmark" aria-hidden="true"><PhCheck :size="17" weight="bold" /></span
            ></label>
          </div>
          <p class="settings-note">
            Puedes cambiarlo cuando quieras. Tus platos guardados no se borran.
          </p>
        </section>
        <section
          v-if="activeSettingsTab === 'alerts' && isGroupOwner"
          class="global-alert-manager settings-section-card"
        >
          <div class="section-heading">
            <div>
              <p class="eyebrow">AVISOS</p>
              <h3>Avisos globales</h3>
            </div>
            <button class="text-button" @click="resetAlertDraft">Nuevo</button>
          </div>
          <p class="muted">
            Crea avisos reutilizables y decide en qué comidas aparecen por defecto.
          </p>
          <div class="alert-form">
            <div class="alert-form-primary">
              <label class="field-label"
                >Nombre del aviso<input
                  v-model="alertDraft.name"
                  placeholder="Ej.: Preparar la comida"
                  maxlength="120"
              /></label>
              <label class="field-label"
                >Mensaje <span class="field-hint">Opcional</span
                ><input
                  v-model="alertDraft.message"
                  placeholder="Un detalle que quieras recordar"
                  maxlength="240"
              /></label>
            </div>
            <div class="alert-form-row">
              <label class="field-label">Hora<input v-model="alertDraft.time" type="time" /></label
              ><label class="field-label"
                >Día del aviso<select v-model.number="alertDraft.day_offset">
                  <option v-for="days in 31" :key="days - 1" :value="days - 1">
                    {{ alertDayOffsetLabel(days - 1) }}
                  </option>
                </select></label
              ><label class="field-label"
                >Aplicar a<select v-model="alertDraft.scope">
                  <option value="all">Desayuno, comida y cena</option>
                  <option value="breakfast">Solo desayuno</option>
                  <option value="lunch">Solo comida</option>
                  <option value="dinner">Solo cena</option>
                </select></label
              >
            </div>
            <div class="field-label icon-picker-field">
              Icono <span class="field-hint">Elige uno para reconocerlo de un vistazo</span>
              <div class="icon-picker" role="group" aria-label="Icono del aviso">
                <button
                  v-for="icon in alertIconOptions"
                  :key="icon.id"
                  type="button"
                  class="icon-choice"
                  :class="{ selected: alertDraft.icon === icon.id }"
                  :aria-label="icon.label"
                  :aria-pressed="alertDraft.icon === icon.id"
                  :title="icon.label"
                  @click="alertDraft.icon = icon.id"
                >
                  <component :is="icon.icon" :size="20" weight="regular" aria-hidden="true" />
                </button>
              </div>
            </div>
            <div class="alert-form-row alert-form-settings">
              <label class="option-active"
                ><input v-model="alertDraft.default_enabled" type="checkbox" /> Activo por
                defecto</label
              ><label class="option-active"
                ><input v-model="alertDraft.active" type="checkbox" /> Visible</label
              ><label class="field-label alert-order"
                >Orden<input v-model.number="alertDraft.order" type="number" min="0" max="9999"
              /></label>
            </div>
            <button class="primary-button" :disabled="saving" @click="saveAlert">
              {{ alertDraft.id ? 'Actualizar aviso' : 'Crear aviso' }}
            </button>
          </div>
          <div class="alert-admin-list">
            <div v-for="alert in globalAlerts" :key="alert.id" class="alert-admin-row">
              <span class="alert-admin-icon" aria-hidden="true">
                <component :is="alertIcon(alert)" :size="20" weight="regular" />
              </span>
              <div class="alert-admin-title">
                <strong>{{ alert.name }}</strong
                ><small
                  >{{ alert.time }} · {{ alertDayOffsetLabel(alert.day_offset) }} ·
                  {{ alert.scope === 'all' ? 'Todas las comidas' : mealLabels[alert.scope]
                  }}<span v-if="alert.default_enabled"> · Activo por defecto</span></small
                >
              </div>
              <button class="text-button" @click="editAlert(alert)">Editar</button
              ><button class="remove-button" title="Borrar aviso" @click="deleteAlert(alert.id)">
                <PhX :size="16" weight="regular" />
              </button>
            </div>
          </div>
        </section>
        <section v-if="activeSettingsTab === 'group' && group" class="group-settings">
          <div class="section-heading">
            <div>
              <p class="eyebrow">GRUPO</p>
              <h3>{{ group.name }}</h3>
            </div>
            <span v-if="isGroupOwner" class="owner-pill">Propietario</span>
          </div>
          <p class="muted">Comparte este código para planificar juntos.</p>
          <div class="group-code">
            <code>{{ group.invite_code }}</code
            ><button class="secondary-button" @click="copyInviteLink">Copiar enlace</button>
          </div>
          <form v-if="isGroupOwner" class="inline-form" @submit.prevent="inviteMember">
            <input v-model="inviteEmail" type="email" placeholder="Email para invitar" /><button
              class="secondary-button"
              :disabled="saving"
            >
              Invitar
            </button>
          </form>
          <div class="group-members">
            <strong>Miembros ({{ group.members?.length || 0 }})</strong
            ><span v-for="member in group.members" :key="member.uid">{{ member.email }}</span
            ><small v-for="email in group.pending_emails" :key="email"
              >Pendiente: {{ email }}</small
            >
          </div>
          <form class="inline-form" @submit.prevent="joinGroup">
            <input v-model="joinCode" maxlength="8" placeholder="Código de otro grupo" /><button
              class="secondary-button"
              :disabled="saving"
            >
              Unirse
            </button>
          </form>
          <button class="danger-button" :disabled="saving" @click="leaveGroup">
            Salir del grupo
          </button>
        </section>
        <section v-if="activeSettingsTab === 'options'" class="options-settings">
          <section class="notification-settings settings-section-card">
            <div class="section-heading">
              <div>
                <p class="eyebrow">NOTIFICACIONES</p>
                <h3>Avisos que quieres recibir</h3>
              </div>
            </div>
            <p class="muted">
              Estas preferencias servirán para los avisos externos que añadiremos después. La
              campanita siempre conservará el historial del grupo.
            </p>
            <label class="notification-master"
              ><input v-model="preferences.notification_enabled" type="checkbox" /><span
                ><strong>Activar avisos</strong
                ><small>Permitir que te lleguen avisos fuera de la aplicación</small></span
              ></label
            >
            <div class="notification-type-list">
              <span class="field-label">Tipos de notificación</span
              ><label
                v-for="type in notificationTypes"
                :key="type.id"
                class="notification-type-option"
                ><input
                  v-model="preferences.notification_types"
                  type="checkbox"
                  :value="type.id"
                /><span>{{ type.label }}</span></label
              >
            </div>
            <button class="primary-button" :disabled="saving" @click="savePreferences">
              Guardar preferencias
            </button>
          </section>
          <section v-if="isGroupOwner" class="daily-option-manager settings-section-card">
            <div class="section-heading">
              <div>
                <p class="eyebrow">OPCIONES DIARIAS</p>
                <h3>Condiciones del día</h3>
              </div>
              <button class="text-button" @click="resetOptionDraft">Nueva</button>
            </div>
            <p class="muted">
              Crea etiquetas como “Entrenamiento” o “Sin cocinar” y selecciónalas al editar un día.
            </p>
            <div class="option-form">
              <div class="option-form-primary">
                <label class="field-label"
                  >Nombre de la opción<input
                    v-model="optionDraft.name"
                    placeholder="Ej.: Entrenamiento"
                    maxlength="60"
                /></label>
                <label class="field-label"
                  >Descripción <span class="field-hint">Opcional</span
                  ><input
                    v-model="optionDraft.description"
                    placeholder="Qué significa esta condición"
                    maxlength="180"
                /></label>
              </div>
              <div class="option-form-row">
                <label class="field-label"
                  >Color<select v-model="optionDraft.color">
                    <option value="blue">Azul</option>
                    <option value="green">Verde</option>
                    <option value="orange">Naranja</option>
                    <option value="rose">Rosa</option>
                    <option value="violet">Violeta</option>
                    <option value="slate">Gris</option>
                  </select></label
                >
                <label class="option-active"
                  ><input v-model="optionDraft.active" type="checkbox" /> Activa</label
                ><input
                  v-model.number="optionDraft.order"
                  type="number"
                  min="0"
                  max="9999"
                  placeholder="Orden"
                />
              </div>
              <div class="field-label icon-picker-field">
                Icono <span class="field-hint">Se mostrará junto al nombre de la opción</span>
                <div
                  class="icon-picker option-icon-picker"
                  role="group"
                  aria-label="Icono de la opción diaria"
                >
                  <button
                    v-for="icon in optionIconOptions"
                    :key="icon.id"
                    type="button"
                    class="icon-choice"
                    :class="{ selected: optionDraft.icon === icon.id }"
                    :aria-label="icon.label"
                    :aria-pressed="optionDraft.icon === icon.id"
                    :title="icon.label"
                    @click="optionDraft.icon = icon.id"
                  >
                    <component :is="icon.icon" :size="20" weight="regular" aria-hidden="true" />
                  </button>
                </div>
              </div>
              <button class="primary-button" :disabled="saving" @click="saveOption">
                {{ optionDraft.id ? 'Actualizar opción' : 'Crear opción' }}
              </button>
            </div>
            <div class="option-admin-list">
              <div v-for="option in dailyOptions" :key="option.id" class="option-admin-row">
                <span class="option-badge" :class="`option-${option.color}`"
                  ><component
                    :is="optionIcon(option)"
                    :size="15"
                    weight="regular"
                    aria-hidden="true"
                  />
                  {{ option.name }}</span
                ><small>{{ option.description || 'Sin descripción' }}</small
                ><button class="text-button" @click="editOption(option)">Editar</button
                ><button
                  class="remove-button"
                  title="Borrar opción"
                  @click="deleteOption(option.id)"
                >
                  <PhX :size="17" weight="regular" />
                </button>
              </div>
            </div>
          </section>
        </section>
        <div class="modal-footer">
          <button class="secondary-button" @click="goToDashboard">Volver al menú</button
          ><button class="primary-button" :disabled="saving" @click="savePreferences">
            Guardar ajustes
          </button>
        </div>
      </div>
    </section>
    <section v-if="user && isSettings && activeSettingsTab === 'telegram'" class="telegram-page">
      <div class="telegram-card">
        <div class="telegram-card-heading">
          <div class="telegram-logo"><PhTelegramLogo :size="28" weight="duotone" /></div>
          <div>
            <p class="eyebrow">AVISOS EXTERNOS</p>
            <h2>Conecta Telegram</h2>
          </div>
        </div>
        <p class="muted">
          Recibe en Telegram los cambios del grupo y tus recordatorios programados, sin tener que
          abrir Menu Diario.
        </p>
        <div v-if="!telegram.configured" class="telegram-unavailable">
          <PhBell :size="20" weight="regular" />
          <div>
            <strong>Telegram aún no está configurado</strong
            ><span>El administrador debe añadir las credenciales del bot en el servidor.</span>
          </div>
        </div>
        <template v-else-if="telegram.connected">
          <div class="telegram-connected">
            <span class="telegram-status-dot"></span>
            <div>
              <strong>Telegram conectado</strong
              ><small>{{
                telegram.username
                  ? '@' + telegram.username
                  : telegram.first_name || 'Tu cuenta de Telegram'
              }}</small>
            </div>
          </div>
          <div class="telegram-actions">
            <button class="secondary-button" :disabled="telegramTesting" @click="testTelegram">
              <PhTelegramLogo :size="18" /> {{ telegramTesting ? 'Enviando…' : 'Enviar prueba' }}
            </button>
            <button
              class="danger-button"
              :disabled="telegramStatusLoading"
              @click="disconnectTelegram"
            >
              Desconectar
            </button>
          </div>
          <p class="telegram-help">
            También puedes enviar <code>/stop</code> al bot para desconectar la cuenta.
          </p>
        </template>
        <template v-else>
          <div class="telegram-steps">
            <span><b>1</b> Pulsa el botón</span><span><b>2</b> Abre Telegram</span
            ><span><b>3</b> Pulsa «Iniciar»</span>
          </div>
          <button
            class="primary-button telegram-connect-button"
            :disabled="telegramLinking || telegramStatusLoading"
            @click="connectTelegram"
          >
            <PhTelegramLogo :size="19" />
            {{ telegramLinking ? 'Esperando a Telegram…' : 'Conectar con Telegram' }}
          </button>
          <small class="telegram-expiry">El enlace es privado y caduca en 10 minutos.</small>
        </template>
      </div>
    </section>

    <dialog
      v-if="calendarDetailOpen"
      open
      class="modal-backdrop"
      @click.self="calendarDetailOpen = false"
    >
      <div class="modal-card calendar-detail-card">
        <div class="modal-header">
          <div>
            <p class="eyebrow">CONFIGURACIÓN DEL DÍA</p>
            <h2>{{ calendarSelectedDay ? calendarDateLabel(calendarSelectedDay.date) : '' }}</h2>
          </div>
          <button
            class="icon-button"
            aria-label="Cerrar detalle"
            @click="calendarDetailOpen = false"
          >
            <PhX :size="22" weight="regular" />
          </button>
        </div>
        <div v-if="calendarSelectedDay" class="calendar-detail-content">
          <div v-for="meal in allMeals" :key="meal" class="calendar-detail-meal">
            <span class="meal-icon"
              ><component :is="mealIcons[meal]" :size="20" weight="regular"
            /></span>
            <div>
              <span class="meal-name">{{ mealLabels[meal] }}</span>
              <div v-if="calendarSelectedDay.day.meals[meal].items.length" class="detail-dish-list">
                <strong v-for="dish in calendarSelectedDay.day.meals[meal].items" :key="dish">{{
                  dish
                }}</strong>
              </div>
              <span v-else class="detail-empty">Sin plato configurado</span
              ><small v-if="calendarSelectedDay.day.meals[meal].note">{{
                calendarSelectedDay.day.meals[meal].note
              }}</small>
            </div>
          </div>
          <div v-if="calendarSelectedDay.day.notes" class="day-note">
            <PhNotePencil :size="20" weight="regular" />
            <div>
              <strong>Nota del día</strong><span>{{ calendarSelectedDay.day.notes }}</span>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="secondary-button" @click="calendarDetailOpen = false">Cerrar</button
          ><button class="primary-button" @click="editCalendarDay">
            <PhNotePencil :size="17" weight="regular" /> Editar día
          </button>
        </div>
      </div>
    </dialog>
    <datalist id="dish-suggestions">
      <option v-for="dish in dishes" :key="dish.id" :value="dish.name"></option>
    </datalist>
  </div>
</template>
