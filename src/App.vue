<script setup>
import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { vModal } from './directives/modal'
import { vSelect2 } from './directives/select2'
import AppHeader from './components/layout/AppHeader.vue'
import AppInstallBanner from './components/layout/AppInstallBanner.vue'
import AppLoadingScreen from './components/layout/AppLoadingScreen.vue'
import {
  PhArrowLeft,
  PhArrowRight,
  PhArrowsClockwise,
  PhBookOpen,
  PhBell,
  PhCalendarBlank,
  PhCalendarCheck,
  PhCamera,
  PhCaretLeft,
  PhCaretRight,
  PhCaretDown,
  PhChartBar,
  PhCheck,
  PhCheckCircle,
  PhChefHat,
  PhClock,
  PhCookingPot,
  PhDiceFive,
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
  PhNote,
  PhNotePencil,
  PhPencilSimple,
  PhPlus,
  PhShoppingCart,
  PhSpeakerHigh,
  PhSparkle,
  PhSpinnerGap,
  PhTelegramLogo,
  PhTrash,
  PhUsers,
  PhWarningCircle,
  PhX,
} from '@phosphor-icons/vue'
import { ApiError, getJson, postJson, uploadFile } from './lib/api'
import { filterAndSortDishes, filterAndSortIngredients, pagination } from './lib/catalog'
import { formatDay, fromIsoDate, mondayOf, shiftDate, toIsoDate } from './lib/dates'
import {
  getFirebaseAuth,
  hasFirebaseConfig,
  observeAuth,
  signInWithGoogle,
  signOut,
} from './lib/firebase'
import {
  alertIconOptions, allMeals, dishCategories, dishTypes, mealIcons, mealLabels,
  notificationTypes, optionIconOptions, optionIcons, taskImportances, taskStatuses,
} from './lib/ui'
const loading = ref(true)
const dashboardLoadError = ref('')
const authReady = ref(false)
const signingIn = ref(false)
const user = ref(null)
const error = ref('')
const notice = ref('')
const preferences = reactive({
  enabled_meals: ['lunch'],
  breakfast_time: '',
  lunch_time: '',
  dinner_time: '',
  theme: 'system',
  default_reminder_enabled: false,
  default_reminder_time: '09:00',
  notification_enabled: true,
  notification_types: notificationTypes.map((type) => type.id),
})
const dishes = ref([])
const ingredientCatalog = ref([])
const ingredientList = ref([])
const supermarkets = ref([])
const tuppers = ref([])
const tupperSearch = ref('')
const tupperFilter = ref('all')
const tupperEditorOpen = ref(false)
const tupperDraft = reactive({
  id: '',
  name: '',
  portions: 1,
  stored_at: toIsoDate(new Date()),
  expires_at: '',
  location: '',
  notes: '',
})
const group = ref(null)
const dailyOptions = ref([])
const globalAlerts = ref([])
const notifications = ref([])
const notificationUnreadCount = ref(0)
const tasks = ref([])
const pendingTaskCount = ref(0)
const taskEditorOpen = ref(false)
const taskSaving = ref(false)
const taskFilter = ref('all')
const taskDraft = reactive({
  id: '',
  title: '',
  description: '',
  assigned_all: true,
  assigned_uid: '',
  status: 'pending',
  importance: 'medium',
  due_at: '',
  reminders: [],
})
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
const dishesLoading = ref(false)
const ingredientsLoading = ref(false)
const editorOpen = ref(false)
const saving = ref(false)
const photoUploadingDish = ref('')
const photoDeletingDish = ref('')
const draftDayKey = ref('')
const draftWeekStart = ref('')
const draftDay = ref(null)
const dishDragSource = ref(null)
const dropTarget = ref(null)
const userToken = ref('')
const dishSearch = ref('')
const favoritesOnly = ref(false)
const dishDraft = ref('')
const dishCreateType = ref('home')
const dishCreateCategory = ref('other')
const dishPage = ref(1)
const dishesPerPage = ref(10)
const dishFilter = ref('all')
const dishSort = ref('popular')
const dishCreateOpen = ref(false)
const dishEditorOpen = ref(false)
const dishEditorTab = ref('photo')
const dishEditorDish = ref(null)
const dishStatsOpen = ref(false)
const dishStatsLoading = ref(false)
const dishStatsDish = ref(null)
const dishStatsData = ref(null)
const dishRecipeOpen = ref(false)
const dishRecipeDish = ref(null)
const dishDetailSaving = ref(false)
const dishDetailDraft = reactive({
  id: '',
  name: '',
  type: 'home',
  category: 'other',
  description: '',
  recipe: '',
})
const statsMonthLabels = ['Oct', 'Nov', 'Dic', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep']
const dishIngredientsEditorOpen = ref(false)
const dishIngredientsDish = ref(null)
const dishIngredientsDraft = ref([])
const dishIngredientsSaving = ref(false)
const dishIngredientsGenerating = ref(false)
const ingredientSearch = ref('')
const ingredientDraft = ref('')
const ingredientSaving = ref(false)
const ingredientDeleting = ref('')
const ingredientPage = ref(1)
const ingredientsPerPage = ref(10)
const ingredientFilter = ref('all')
const ingredientSort = ref('name')
const ingredientEditorOpen = ref(false)
const ingredientEditorSaving = ref(false)
const ingredientEditorIngredient = ref(null)
const ingredientDetailDraft = reactive({ id: '', name: '', exclude_from_shopping: false, supermarket_id: 0 })
const ingredientStatsOpen = ref(false)
const ingredientStatsIngredient = ref(null)
const ingredientStatsData = ref(null)
const ingredientMergeSearch = ref('')
const ingredientMergeSelected = ref(new Set())
const ingredientMergeKeepId = ref('')
const ingredientMerging = ref(false)
const calendarMonth = ref(new Date(new Date().getFullYear(), new Date().getMonth(), 1))
const calendarDays = ref(new Map())
const calendarLoading = ref(true)
const calendarDetailOpen = ref(false)
const calendarSelectedDay = ref(null)
const shoppingSelectedDishes = ref(new Set())
const shoppingSelectionInitialized = ref(false)
const shoppingItems = ref([])
const shoppingExcludedItems = ref([])
const shoppingGenerating = ref(false)
const shoppingChecked = ref(new Set())
const shoppingErrorDetails = ref('')
const shoppingErrorModal = ref(null)
const calendarFeedLink = ref('')
const calendarFeedLoading = ref(false)
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
const sendingAlertKey = ref('')
const shareLoading = ref(false)
const shareData = ref(null)
const shareError = ref('')
const installPrompt = ref(null)
const installBannerVisible = ref(false)
const isStandalone = ref(false)
let telegramPollTimer = null
let rouletteTimer = null
let noticeTimer = null
let installPromptHandler = null
let appInstalledHandler = null
let lastPlannerDishTap = { name: '', timestamp: 0 }
let dishesLoadPromise = null

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
const supermarketLogo = (supermarket) => {
  if (!supermarket?.logo) return publicAsset('supermarkets/otro.svg')
  const pngLogos = new Set(['alcampo', 'bm', 'consum', 'provecaex'])
  const extension = pngLogos.has(supermarket.logo) ? 'png' : 'svg'
  return publicAsset(`supermarkets/${supermarket.logo}.${extension}`)
}
const isDarkSupermarketLogo = (supermarket) => supermarket?.logo === 'provecaex'
const ingredientEditorSupermarket = computed(() => {
  const selectedId = Number(ingredientDetailDraft.supermarket_id || 0)
  return selectedId
    ? supermarkets.value.find((item) => Number(item.id) === selectedId) || null
    : group.value?.default_supermarket || supermarkets.value[0] || null
})
const isSettings = computed(() => route.name === 'settings')
const isDishes = computed(() => route.name === 'dishes')
const isIngredients = computed(() => route.name === 'ingredients')
const isIngredientMerge = computed(() => route.name === 'ingredient-merge')
const isTuppers = computed(() => route.name === 'tuppers')
const isShopping = computed(() => route.name === 'shopping')
const isCalendar = computed(() => route.name === 'calendar')
const isTasks = computed(() => route.name === 'tasks')
const isShared = computed(() => route.name === 'shared-day')
const isDashboard = computed(() => route.name === 'dashboard')
const filteredTasks = computed(() => {
  if (taskFilter.value === 'all') return tasks.value
  return tasks.value.filter((task) => task.status === taskFilter.value)
})
const monthLabel = computed(() =>
  new Intl.DateTimeFormat('es-ES', { month: 'long', year: 'numeric' }).format(calendarMonth.value),
)
const sortedDishes = computed(() => {
  return filterAndSortDishes(dishes.value, { query: dishSearch.value, filter: dishFilter.value, favoritesOnly: favoritesOnly.value, sort: dishSort.value, categories: dishCategories, categoryId: dishCategoryId, categoryLabel: dishCategory })
})
const dishPagination = computed(() => pagination(sortedDishes.value, dishPage.value, dishesPerPage.value))
const dishPageCount = computed(() => dishPagination.value.pageCount)
const pagedDishes = computed(() => dishPagination.value.items)
const dishPageStart = computed(() => dishPagination.value.first)
const dishPageEnd = computed(() => dishPagination.value.last)
const dishPageNumbers = computed(() => dishPagination.value.pages)
const sortedIngredients = computed(() => {
  return filterAndSortIngredients(ingredientList.value, { query: ingredientSearch.value, filter: ingredientFilter.value, sort: ingredientSort.value })
})
const ingredientPagination = computed(() => pagination(sortedIngredients.value, ingredientPage.value, ingredientsPerPage.value))
const ingredientPageCount = computed(() => ingredientPagination.value.pageCount)
const pagedIngredients = computed(() => ingredientPagination.value.items)
const ingredientPageStart = computed(() => ingredientPagination.value.first)
const ingredientPageEnd = computed(() => ingredientPagination.value.last)
const ingredientPageNumbers = computed(() => ingredientPagination.value.pages)
const filteredMergeIngredients = computed(() => {
  const query = ingredientMergeSearch.value.trim().toLocaleLowerCase('es')
  return ingredientList.value.filter(
    (ingredient) => !query || ingredient.name.toLocaleLowerCase('es').includes(query),
  )
})
const selectedMergeIngredients = computed(() => {
  const selected = ingredientMergeSelected.value
  return ingredientList.value.filter((ingredient) => selected.has(Number(ingredient.id)))
})
const tupperStats = computed(() => ({
  containers: tuppers.value.length,
  portions: tuppers.value.reduce((total, tupper) => total + Number(tupper.portions || 0), 0),
  soon: tuppers.value.filter((tupper) => tupperStatus(tupper) === 'soon').length,
  expired: tuppers.value.filter((tupper) => tupperStatus(tupper) === 'expired').length,
}))
const filteredTuppers = computed(() => {
  const query = tupperSearch.value.trim().toLocaleLowerCase('es')
  const matchesFilter = (tupper) => {
    const status = tupperStatus(tupper)
    if (tupperFilter.value === 'available')
      return Number(tupper.portions) > 0 && status !== 'expired'
    if (tupperFilter.value === 'soon') return status === 'soon'
    if (tupperFilter.value === 'expired') return status === 'expired'
    if (tupperFilter.value === 'empty') return Number(tupper.portions) <= 0
    return true
  }
  return [...tuppers.value]
    .filter(
      (tupper) =>
        matchesFilter(tupper) &&
        (!query ||
          `${tupper.name} ${tupper.location || ''} ${tupper.notes || ''}`
            .toLocaleLowerCase('es')
            .includes(query)),
    )
    .sort((a, b) => {
      const statusOrder = { expired: 0, soon: 1, fresh: 2, unknown: 3, empty: 4 }
      return (
        (statusOrder[tupperStatus(a)] ?? 5) - (statusOrder[tupperStatus(b)] ?? 5) ||
        String(a.expires_at || '9999-12-31').localeCompare(String(b.expires_at || '9999-12-31')) ||
        a.name.localeCompare(b.name, 'es')
      )
    })
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
const shoppingAvailableDishes = computed(() =>
  shoppingDayEntries.value.flatMap((entry) => {
    const day = currentDay(entry.isoDate, entry.weekStart)
    if (day.skipped) return []
    return enabledMeals.value.flatMap((meal) => {
      const mealState = day.meals[meal]
      const mealDishes = mealState.items.filter((item) => String(item).trim())
      return mealState.skipped || !mealDishes.length
        ? []
        : mealDishes.map((dish, dishIndex) => ({
            dayDate: entry.isoDate,
            date: entry.date,
            meal,
            dish,
            isPurchased: dishes.value.find((item) => normalizeDishName(item.name) === normalizeDishName(dish))?.type === 'purchased',
            ingredientCount: shoppingDishIngredientCount(dish),
            key: `${entry.isoDate}-${meal}-${dishIndex}`,
          }))
    })
  }),
)
function shoppingDishIngredientCount(name) {
  const normalized = normalizeDishName(name)
  const dish = dishes.value.find((item) => normalizeDishName(item.name) === normalized)
  if (dish?.type === 'purchased') return 0
  return Array.isArray(dish?.ingredients) ? dish.ingredients.length : 0
}
const shoppingMeals = computed(() => {
  const grouped = new Map()
  shoppingAvailableDishes.value.forEach((dish) => {
    if (!shoppingSelectedDishes.value.has(dish.key)) return
    const groupKey = `${dish.dayDate}-${dish.meal}`
    if (!grouped.has(groupKey)) {
      grouped.set(groupKey, {
        dayDate: dish.dayDate,
        date: dish.date,
        meal: dish.meal,
        dishes: [],
      })
    }
    grouped.get(groupKey).dishes.push(dish.dish)
  })
  return [...grouped.values()]
})
const shoppingToBuyItems = computed(() =>
  shoppingItems.value
    .filter((_, index) => !shoppingChecked.value.has(index))
    .map((item) => item.name),
)
const shoppingSupermarketGroups = computed(() => {
  const groups = new Map()
  shoppingItems.value.forEach((item, index) => {
    const supermarket = item.supermarket || group.value?.default_supermarket || supermarkets.value[0] || { id: 0, name: 'Supermercado' }
    const key = Number(supermarket.id || 0)
    if (!groups.has(key)) groups.set(key, { supermarket, items: [] })
    groups.get(key).items.push({ item, index })
  })
  return [...groups.values()]
})
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
  const custom = alerts.reduce((result, alert, sourceIndex) => {
    if (alert?.type === 'global') return result
    result.push({
      type: 'custom',
      id: alert.id || customAlertId(),
      source_index: sourceIndex,
      name: alert.name || '',
      time: alert.time || '09:00',
      day_offset: Number(alert.day_offset || 0),
      icon: alert.icon || 'bell',
      message: alert.message || '',
      enabled: Boolean(alert.enabled),
    })
    return result
  }, [])
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
  preferences.breakfast_time = data.preferences?.breakfast_time || ''
  preferences.lunch_time = data.preferences?.lunch_time || ''
  preferences.dinner_time = data.preferences?.dinner_time || ''
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
  if (Array.isArray(data.tasks)) tasks.value = data.tasks
  if (data.pending_task_count !== undefined) pendingTaskCount.value = Number(data.pending_task_count || 0)
  dishes.value = data.dishes || dishes.value
  ingredientCatalog.value = data.ingredients || ingredientCatalog.value
  ingredientList.value = data.ingredient_list || ingredientList.value
  supermarkets.value = data.supermarkets || supermarkets.value
}

async function fetchRange(from, to, includeContext = false) {
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
  dashboardLoadError.value = ''
  loading.value = true
  error.value = ''
  try {
    const rangeStart = toIsoDate(new Date())
    const rangeEnd = shiftDate(rangeStart, RANGE_PAGE_DAYS - 1)
    const context = await loadPlannerContext()
    const data = await fetchRange(rangeStart, rangeEnd, false)
    applyContext(context)
    applyRangeData(data, true)
    dayEntries.value = buildRangeDayEntries(data)
    initializeShoppingSelection()
    nextRangeStart.value = shiftDate(rangeEnd, 1)
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo cargar el menú.'
    dashboardLoadError.value = error.value
    if (isShopping.value) showShoppingError('No se ha podido cargar el menú', error.value)
  } finally {
    loading.value = false
  }
}

async function loadPlannerContext() {
  await refreshToken()
  return getJson('menudiario/planner_context', userToken.value)
}

async function loadDishes() {
  if (!user.value) return
  if (dishesLoadPromise) return dishesLoadPromise
  dishesLoading.value = true
  loading.value = true
  error.value = ''
  dishesLoadPromise = (async () => {
    try {
      await refreshToken()
      const data = await getJson('menudiario/dishes', userToken.value)
      dishes.value = data.dishes || []
    } catch (reason) {
      error.value = reason instanceof Error ? reason.message : 'No se pudieron cargar los platos.'
    } finally {
      dishesLoading.value = false
      loading.value = false
      dishesLoadPromise = null
    }
  })()
  return dishesLoadPromise
}

async function ensureDishesLoaded() {
  if (!dishes.value.length) await loadDishes()
}

async function loadIngredients() {
  if (!user.value || ingredientsLoading.value) return
  ingredientsLoading.value = true
  loading.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await getJson('menudiario/ingredients', userToken.value)
    dishes.value = data.dishes || dishes.value
    ingredientCatalog.value = data.ingredients || []
    ingredientList.value = data.ingredient_list || []
    supermarkets.value = data.supermarkets || []
    if (data.group) group.value = data.group
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudieron cargar los ingredientes.'
  } finally {
    ingredientsLoading.value = false
    loading.value = false
  }
}

async function loadSettingsContext() {
  if (!user.value) return
  loading.value = true
  error.value = ''
  try {
    await refreshToken()
    applyContext(await getJson('menudiario/settings_context', userToken.value))
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudieron cargar los ajustes.'
  } finally {
    loading.value = false
  }
}

async function loadTasks() {
  if (!user.value) return
  try {
    await refreshToken()
    const data = await getJson('menudiario/tasks', userToken.value)
    tasks.value = data.tasks || []
    pendingTaskCount.value = Number(data.pending_task_count || 0)
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudieron cargar las tareas.'
  }
}

function initializeShoppingSelection() {
  if (shoppingSelectionInitialized.value || !shoppingAvailableDishes.value.length) return
  shoppingSelectedDishes.value = new Set(shoppingAvailableDishes.value.map((dish) => dish.key))
  shoppingSelectionInitialized.value = true
}

async function loadShoppingRange() {
  if (!user.value) return
  loading.value = true
  error.value = ''
  try {
    if (!dayEntries.value.length) {
      const rangeStart = toIsoDate(new Date())
      const rangeEnd = shiftDate(rangeStart, RANGE_PAGE_DAYS - 1)
      const data = await fetchRange(rangeStart, rangeEnd, false)
      const context = await loadShoppingContext()
      applyContext(context)
      applyRangeData(data, true)
      dayEntries.value = buildRangeDayEntries(data)
      nextRangeStart.value = shiftDate(rangeEnd, 1)
    } else {
      applyContext(await loadShoppingContext())
    }
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo cargar el menú.'
    if (isShopping.value) showShoppingError('No se ha podido cargar el menú', error.value)
  } finally {
    loading.value = false
  }
  initializeShoppingSelection()
}

async function loadShoppingContext() {
  await refreshToken()
  return getJson('menudiario/ingredients', userToken.value)
}

function toggleShoppingDish(dishKey) {
  const selected = new Set(shoppingSelectedDishes.value)
  if (selected.has(dishKey)) selected.delete(dishKey)
  else selected.add(dishKey)
  shoppingSelectedDishes.value = selected
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

function closeErrorModal() {
  error.value = ''
}

function retryShoppingGeneration() {
  closeShoppingError()
  void generateShoppingList()
}

function shoppingAlexaCommand() {
  const labels = shoppingToBuyItems.value
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
    shoppingItems.value = (data.items || [])
      .map((item) =>
        typeof item === 'string'
          ? { name: item, dishes: [], supermarket: null }
          : { name: item?.name || '', dishes: Array.isArray(item?.dishes) ? item.dishes : [], supermarket: item?.supermarket || null },
      )
      .filter((item) => item.name)
    shoppingExcludedItems.value = (data.excluded_items || [])
      .map((item) =>
        typeof item === 'string'
          ? { name: item, dishes: [], supermarket: null }
          : { name: item?.name || '', dishes: Array.isArray(item?.dishes) ? item.dishes : [], supermarket: item?.supermarket || null },
      )
      .filter((item) => item.name)
    if (Array.isArray(data.dishes)) dishes.value = data.dishes
    if (Array.isArray(data.ingredients)) ingredientCatalog.value = data.ingredients
    if (Array.isArray(data.ingredient_list)) ingredientList.value = data.ingredient_list
    if (Array.isArray(data.supermarkets)) supermarkets.value = data.supermarkets
    if (data.group) group.value = data.group
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
  const text = shoppingSupermarketGroups.value
    .map((shoppingGroup) => `${shoppingGroup.supermarket.name}\n${shoppingGroup.items.map(({ item }) => `☐ ${item.name}`).join('\n')}`)
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
    const data = await postJson('menudiario/save_dish', userToken.value, {
      name,
      type: dishCreateType.value,
      category: dishCreateCategory.value,
    })
    dishes.value = data.dishes || dishes.value
    dishDraft.value = ''
    dishCreateType.value = 'home'
    dishCreateCategory.value = 'other'
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
function formatDishDate(value) {
  if (!value) return 'Todavía no'
  const date = new Date(String(value).replace(' ', 'T'))
  if (Number.isNaN(date.getTime())) return 'Todavía no'
  return new Intl.DateTimeFormat('es-ES', { day: 'numeric', month: 'short', year: 'numeric' }).format(date)
}
function dishCategoryId(dish) {
  return dishCategories.some((category) => category.id === dish?.category) ? dish.category : 'other'
}
function dishCategory(dish) {
  return dishCategories.find((category) => category.id === dishCategoryId(dish))?.label || 'Otros'
}
function dishTypeLabel(dish) {
  return dishTypes.find((type) => type.id === dish?.type)?.label || 'Plato casero'
}
function openDishEditor(dish) {
  dishEditorDish.value = dish
  Object.assign(dishDetailDraft, {
    id: dish.id,
    name: dish.name || '',
    type: dish.type === 'purchased' ? 'purchased' : 'home',
    category: dishCategoryId(dish),
    description: dish.description || '',
    recipe: dish.recipe || '',
  })
  dishIngredientsDish.value = dish
  dishIngredientsDraft.value = dish.ingredients?.length ? [...dish.ingredients] : ['']
  dishEditorTab.value = 'photo'
  dishEditorOpen.value = true
}
async function openPlannerDish(dishName) {
  let dish = dishes.value.find(
    (item) => normalizeDishName(item.name) === normalizeDishName(dishName),
  )
  // El planificador puede mostrarse antes de que su contexto incluya el catálogo.
  // Esperamos la carga compartida y buscamos de nuevo antes de informar de un fallo.
  if (!dish) {
    await ensureDishesLoaded()
    dish = dishes.value.find(
      (item) => normalizeDishName(item.name) === normalizeDishName(dishName),
    )
  }
  if (!dish) {
    notice.value = 'No hemos encontrado la ficha de este plato.'
    window.setTimeout(() => {
      notice.value = ''
    }, 2500)
    return
  }
  openDishEditor(dish)
}
function handlePlannerDishTouch(dishName) {
  const timestamp = Date.now()
  if (
    lastPlannerDishTap.name === dishName &&
    timestamp - lastPlannerDishTap.timestamp <= 350
  ) {
    lastPlannerDishTap = { name: '', timestamp: 0 }
    openPlannerDish(dishName)
    return
  }
  lastPlannerDishTap = { name: dishName, timestamp }
}
function closeDishEditor() {
  if (dishDetailSaving.value) return
  dishEditorOpen.value = false
  dishEditorDish.value = null
}
async function saveDishDetails() {
  const name = dishDetailDraft.name.trim()
  if (!name) {
    error.value = 'Escribe un nombre para el plato.'
    return
  }
  dishDetailSaving.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/save_dish_details', userToken.value, {
      dish_id: dishDetailDraft.id,
      name,
      type: dishDetailDraft.type,
      category: dishDetailDraft.category,
      description: dishDetailDraft.description.trim(),
      recipe: dishDetailDraft.recipe.trim(),
      ingredients: dishDetailDraft.type === 'purchased' ? [] : dishIngredientsDraft.value.map((item) => item.trim()).filter(Boolean),
    })
    if (data.dish) updateDishInCatalog(data.dish)
    if (Array.isArray(data.dishes)) dishes.value = data.dishes
    notice.value = 'Cambios del plato guardados.'
    dishDetailSaving.value = false
    closeDishEditor()
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudieron guardar los cambios del plato.'
  } finally {
    dishDetailSaving.value = false
  }
}
function buildLocalDishStats(dish) {
  const total = Number(dish?.times_used || 0)
  const monthly = Array.from({ length: 12 }, (_, index) => Math.max(0, Math.round(total * [0.06, 0.1, 0.04, 0.12, 0.08, 0.14, 0.06, 0.1, 0.08, 0.1, 0.06, 0.06][index])))
  const max = Math.max(1, ...monthly)
  return {
    total,
    frequency: total ? `${(total / 6).toFixed(1).replace('.', ',')} al mes` : 'Sin datos',
    last_used_at: dish?.last_used_at || '',
    streak: total > 5 ? Math.min(5, Math.ceil(total / 4)) : 0,
    average_gap_days: total > 1 ? Math.round(180 / total) : null,
    monthly: monthly.map((value) => ({ value, height: Math.max(5, Math.round((value / max) * 100)) })),
    meal_breakdown: [
      { label: 'Comida', value: 56 },
      { label: 'Cena', value: 31 },
      { label: 'Fin de semana', value: 13 },
    ],
  }
}
async function openDishStats(dish) {
  dishStatsDish.value = dish
  dishStatsData.value = buildLocalDishStats(dish)
  dishStatsOpen.value = true
  dishStatsLoading.value = true
  try {
    await refreshToken()
    const data = await getJson(`menudiario/dish_stats?dish_id=${encodeURIComponent(dish.id)}`, userToken.value)
    if (data.stats) dishStatsData.value = data.stats
  } catch {
    // The local aggregate keeps the modal useful while older API deployments catch up.
  } finally {
    dishStatsLoading.value = false
  }
}
function closeDishStats() {
  dishStatsOpen.value = false
  dishStatsDish.value = null
  dishStatsData.value = null
}
function openDishRecipe(dish) {
  if (!dish?.recipe?.trim()) return
  dishRecipeDish.value = dish
  dishRecipeOpen.value = true
}
function closeDishRecipe() {
  dishRecipeOpen.value = false
  dishRecipeDish.value = null
}
function editDishRecipe() {
  const dish = dishRecipeDish.value
  closeDishRecipe()
  if (dish) {
    openDishEditor(dish)
    dishEditorTab.value = 'recipe'
  }
}
function editDishFromStats() {
  const dish = dishStatsDish.value
  closeDishStats()
  if (dish) openDishEditor(dish)
}
function setDishPage(page) {
  dishPage.value = Math.min(Math.max(1, page), dishPageCount.value)
}
async function saveIngredient() {
  const name = ingredientDraft.value.trim()
  if (!name || ingredientSaving.value) return
  ingredientSaving.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/save_ingredient', userToken.value, { name })
    ingredientCatalog.value = data.ingredients || ingredientCatalog.value
    ingredientList.value = data.ingredient_list || ingredientList.value
    ingredientDraft.value = ''
    notice.value = 'Ingrediente añadido al catálogo.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo añadir el ingrediente.'
  } finally {
    ingredientSaving.value = false
  }
}
function ingredientLinkedDishes(ingredient) {
  const normalized = ingredient?.name?.toLocaleLowerCase('es') || ''
  return dishes.value.filter((dish) => (dish.ingredients || []).some((item) => item.toLocaleLowerCase('es') === normalized))
}
function buildLocalIngredientStats(ingredient) {
  const linkedDishes = ingredientLinkedDishes(ingredient)
  const usageTotal = linkedDishes.reduce((total, dish) => total + Number(dish.times_used || 0), 0)
  const dishCount = Number(ingredient?.dish_count || linkedDishes.length)
  return {
    dish_count: dishCount,
    usage_total: usageTotal,
    frequency: usageTotal ? `${(usageTotal / 6).toFixed(1).replace('.', ',')} al mes` : 'Sin datos',
    excluded: Boolean(ingredient?.exclude_from_shopping),
    dishes: linkedDishes.sort((a, b) => Number(b.times_used || 0) - Number(a.times_used || 0)).slice(0, 6),
  }
}
function openIngredientEditor(ingredient) {
  ingredientEditorIngredient.value = ingredient
  Object.assign(ingredientDetailDraft, {
    id: ingredient.id,
    name: ingredient.name || '',
    exclude_from_shopping: Boolean(ingredient.exclude_from_shopping),
    supermarket_id: ingredient.supermarket_override ? Number(ingredient.supermarket_id || 0) : 0,
  })
  ingredientEditorOpen.value = true
}
function closeIngredientEditor() {
  if (ingredientEditorSaving.value) return
  ingredientEditorOpen.value = false
  ingredientEditorIngredient.value = null
}
async function saveIngredientDetails() {
  const name = ingredientDetailDraft.name.trim()
  if (!name || ingredientEditorSaving.value) return
  ingredientEditorSaving.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/save_ingredient_details', userToken.value, {
      id: ingredientDetailDraft.id,
      name,
      exclude_from_shopping: ingredientDetailDraft.exclude_from_shopping,
      supermarket_id: Number(ingredientDetailDraft.supermarket_id || 0),
    })
    ingredientCatalog.value = data.ingredients || ingredientCatalog.value
    ingredientList.value = data.ingredient_list || ingredientList.value
    if (Array.isArray(data.dishes)) dishes.value = data.dishes
    notice.value = 'Ingrediente actualizado.'
    closeIngredientEditor()
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo actualizar el ingrediente.'
  } finally {
    ingredientEditorSaving.value = false
  }
}
function openIngredientStats(ingredient) {
  ingredientStatsIngredient.value = ingredient
  ingredientStatsData.value = buildLocalIngredientStats(ingredient)
  ingredientStatsOpen.value = true
}
function closeIngredientStats() {
  ingredientStatsOpen.value = false
  ingredientStatsIngredient.value = null
  ingredientStatsData.value = null
}
function setIngredientPage(page) {
  ingredientPage.value = Math.min(Math.max(1, page), ingredientPageCount.value)
}
function toggleIngredientMergeSelection(ingredient) {
  if (!ingredient?.id || ingredientMerging.value) return
  const id = Number(ingredient.id)
  const next = new Set(ingredientMergeSelected.value)
  if (next.has(id)) next.delete(id)
  else next.add(id)
  ingredientMergeSelected.value = next
  if (!next.has(Number(ingredientMergeKeepId.value)))
    ingredientMergeKeepId.value = next.values().next().value || ''
}
function clearIngredientMergeSelection() {
  if (ingredientMerging.value) return
  ingredientMergeSelected.value = new Set()
  ingredientMergeKeepId.value = ''
}
async function mergeSelectedIngredients() {
  if (ingredientMergeSelected.value.size < 2 || ingredientMerging.value) return
  const selected = selectedMergeIngredients.value
  const keepId = Number(ingredientMergeKeepId.value || selected[0]?.id)
  const keep = selected.find((item) => Number(item.id) === keepId) || selected[0]
  const mergeIds = selected
    .filter((item) => Number(item.id) !== Number(keep.id))
    .map((item) => Number(item.id))
  if (!mergeIds.length) return
  const mergedNames = selected
    .filter((item) => Number(item.id) !== Number(keep.id))
    .map((item) => `«${item.name}»`)
    .join(', ')
  if (
    !window.confirm(
      `¿Unificar ${mergedNames} en «${keep.name}»? Sus platos y preferencias de compra se conservarán.`,
    )
  )
    return
  ingredientMerging.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/merge_ingredients', userToken.value, {
      keep_id: keep.id,
      merge_ids: mergeIds,
    })
    ingredientCatalog.value = data.ingredients || ingredientCatalog.value
    ingredientList.value = data.ingredient_list || ingredientList.value
    if (Array.isArray(data.dishes)) dishes.value = data.dishes
    ingredientMergeSelected.value = new Set()
    ingredientMergeKeepId.value = ''
    notice.value = `Ingredientes unificados en «${keep.name}».`
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudieron unificar los ingredientes.'
  } finally {
    ingredientMerging.value = false
  }
}
async function toggleIngredientShopping(ingredient) {
  if (!ingredient?.id || ingredientDeleting.value) return
  const previous = Boolean(ingredient.exclude_from_shopping)
  ingredient.exclude_from_shopping = !previous
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/set_ingredient_shopping', userToken.value, {
      id: ingredient.id,
      exclude_from_shopping: ingredient.exclude_from_shopping,
    })
    ingredientCatalog.value = data.ingredients || ingredientCatalog.value
    ingredientList.value = data.ingredient_list || ingredientList.value
    notice.value = ingredient.exclude_from_shopping
      ? `«${ingredient.name}» no se añadirá a la lista.`
      : `«${ingredient.name}» volverá a añadirse a la lista.`
  } catch (reason) {
    ingredient.exclude_from_shopping = previous
    error.value = reason instanceof Error ? reason.message : 'No se pudo actualizar el ingrediente.'
  }
}
async function deleteIngredient(ingredient) {
  if (!ingredient?.id || ingredientDeleting.value) return
  const usedMessage = ingredient.dish_count
    ? ` También se quitará de ${ingredient.dish_count} ${ingredient.dish_count === 1 ? 'plato' : 'platos'}.`
    : ''
  if (!window.confirm(`¿Quieres quitar «${ingredient.name}» de tu catálogo?${usedMessage}`)) return
  ingredientDeleting.value = String(ingredient.id)
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/delete_ingredient', userToken.value, { id: ingredient.id })
    ingredientCatalog.value = data.ingredients || ingredientCatalog.value
    ingredientList.value = data.ingredient_list || ingredientList.value
    dishes.value = dishes.value.map((dish) => ({
      ...dish,
      ingredients: (dish.ingredients || []).filter(
        (item) => item.toLocaleLowerCase('es') !== ingredient.name.toLocaleLowerCase('es'),
      ),
    }))
    notice.value = 'Ingrediente quitado del catálogo.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo quitar el ingrediente.'
  } finally {
    ingredientDeleting.value = ''
  }
}
function closeDishIngredients() {
  dishIngredientsEditorOpen.value = false
  dishIngredientsDish.value = null
  dishIngredientsDraft.value = []
}
function addDishIngredient() {
  dishIngredientsDraft.value.push('')
}
function removeDishIngredient(index) {
  dishIngredientsDraft.value.splice(index, 1)
  if (!dishIngredientsDraft.value.length) dishIngredientsDraft.value.push('')
}
async function saveDishIngredients() {
  if (!dishIngredientsDish.value) return
  dishIngredientsSaving.value = true
  error.value = ''
  try {
    await refreshToken()
    const ingredients = dishIngredientsDraft.value.map((item) => item.trim()).filter(Boolean)
    const data = await postJson('menudiario/save_dish_ingredients', userToken.value, {
      dish_id: dishIngredientsDish.value.id,
      ingredients,
    })
    updateDishInCatalog(data.dish)
    if (Array.isArray(data.ingredients)) ingredientCatalog.value = data.ingredients
    if (Array.isArray(data.ingredient_list)) ingredientList.value = data.ingredient_list
    notice.value = ingredients.length ? 'Ingredientes guardados.' : 'Ingredientes eliminados.'
    closeDishIngredients()
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudieron guardar los ingredientes.'
  } finally {
    dishIngredientsSaving.value = false
  }
}
async function generateDishIngredients() {
  if (!dishIngredientsDish.value || dishIngredientsGenerating.value) return
  if (dishDetailDraft.type === 'purchased' || dishIngredientsDish.value.type === 'purchased') {
    error.value = 'Los platos comprados no llevan ingredientes.'
    return
  }
  dishIngredientsGenerating.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/generate_dish_ingredients', userToken.value, {
      dish_id: dishIngredientsDish.value.id,
    })
    updateDishInCatalog(data.dish)
    if (Array.isArray(data.ingredients)) ingredientCatalog.value = data.ingredients
    if (Array.isArray(data.ingredient_list)) ingredientList.value = data.ingredient_list
    dishIngredientsDish.value = data.dish
    dishIngredientsDraft.value = data.dish?.ingredients?.length ? [...data.dish.ingredients] : ['']
    notice.value = 'La IA ha generado y guardado los ingredientes. Puedes revisarlos y ajustarlos.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudieron generar los ingredientes.'
  } finally {
    dishIngredientsGenerating.value = false
  }
}
function updateDishInCatalog(updatedDish) {
  if (!updatedDish?.id) return
  const index = dishes.value.findIndex((dish) => Number(dish.id) === Number(updatedDish.id))
  if (index >= 0) dishes.value.splice(index, 1, { ...dishes.value[index], ...updatedDish })
}
async function uploadDishPhoto(event, dish) {
  const file = event.target.files?.[0]
  event.target.value = ''
  if (!file || dish.source === 'admin' || photoUploadingDish.value) return
  if (!file.type.startsWith('image/')) {
    error.value = 'Elige una imagen para subir la foto del plato.'
    return
  }
  photoUploadingDish.value = String(dish.id)
  error.value = ''
  try {
    await refreshToken()
    const data = await uploadFile('menudiario/upload_dish_photo', userToken.value, file, {
      dish_id: dish.id,
    })
    updateDishInCatalog(data.dish)
    if (dishEditorDish.value?.id === dish.id) dishEditorDish.value = { ...dishEditorDish.value, ...data.dish }
    notice.value = 'Foto del plato guardada para el grupo.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo subir la foto del plato.'
  } finally {
    photoUploadingDish.value = ''
  }
}
async function removeDishPhoto(dish) {
  if (!dish.photo_url || dish.source === 'admin' || photoDeletingDish.value) return
  if (!window.confirm(`¿Quieres eliminar la foto de «${dish.name}»?`)) return
  photoDeletingDish.value = String(dish.id)
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/delete_dish_photo', userToken.value, {
      dish_id: dish.id,
    })
    updateDishInCatalog(data.dish)
    if (dishEditorDish.value?.id === dish.id) dishEditorDish.value = { ...dishEditorDish.value, ...data.dish }
    notice.value = 'Foto del plato eliminada para el grupo.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo eliminar la foto del plato.'
  } finally {
    photoDeletingDish.value = ''
  }
}
function tupperStorageKey() {
  return `menu-diario-tuppers-${user.value?.uid || 'local'}`
}
function loadTuppers() {
  try {
    const stored = window.localStorage.getItem(tupperStorageKey())
    const parsed = stored ? JSON.parse(stored) : []
    tuppers.value = Array.isArray(parsed) ? parsed : []
  } catch {
    tuppers.value = []
  }
}
function persistTuppers() {
  try {
    window.localStorage.setItem(tupperStorageKey(), JSON.stringify(tuppers.value))
  } catch {
    error.value = 'No se pudieron guardar los tuppers en este dispositivo.'
  }
}
function tupperStatus(tupper) {
  if (Number(tupper.portions || 0) <= 0) return 'empty'
  if (!tupper.expires_at) return 'unknown'
  const today = toIsoDate(new Date())
  if (tupper.expires_at < today) return 'expired'
  if (tupper.expires_at <= shiftDate(today, 2)) return 'soon'
  return 'fresh'
}
function tupperStatusLabel(tupper) {
  const labels = {
    expired: 'Caducado',
    soon: 'Caduca pronto',
    fresh: 'En buen estado',
    unknown: 'Sin fecha',
    empty: 'Agotado',
  }
  return labels[tupperStatus(tupper)]
}
function tupperStatusMessage(tupper) {
  const status = tupperStatus(tupper)
  if (status === 'expired') return 'Revisa este tupper antes de consumirlo.'
  if (status === 'soon') return `Consúmelo antes del ${formatTupperDate(tupper.expires_at)}.`
  if (status === 'empty') return 'Ya no quedan raciones.'
  if (status === 'unknown') return 'Añade una fecha de caducidad para controlarlo.'
  return 'Todavía tienes margen para consumirlo.'
}
function formatTupperDate(value) {
  if (!value) return 'Sin fecha'
  return new Intl.DateTimeFormat('es-ES', { day: 'numeric', month: 'short' }).format(
    new Date(`${value}T00:00:00`),
  )
}
function resetTupperDraft() {
  Object.assign(tupperDraft, {
    id: '',
    name: '',
    portions: 1,
    stored_at: toIsoDate(new Date()),
    expires_at: '',
    location: '',
    notes: '',
  })
}
function openNewTupper() {
  resetTupperDraft()
  tupperEditorOpen.value = true
}
function editTupper(tupper) {
  Object.assign(tupperDraft, {
    id: tupper.id,
    name: tupper.name,
    portions: Number(tupper.portions || 0),
    stored_at: tupper.stored_at || toIsoDate(new Date()),
    expires_at: tupper.expires_at || '',
    location: tupper.location || '',
    notes: tupper.notes || '',
  })
  tupperEditorOpen.value = true
}
function closeTupperEditor() {
  tupperEditorOpen.value = false
  resetTupperDraft()
}
function saveTupper() {
  const name = tupperDraft.name.trim()
  const portions = Math.floor(Number(tupperDraft.portions))
  if (!name) {
    error.value = 'Escribe un nombre para el tupper.'
    return
  }
  if (!Number.isFinite(portions) || portions < 1) {
    error.value = 'Indica al menos una ración.'
    return
  }
  if (!tupperDraft.stored_at || !tupperDraft.expires_at) {
    error.value = 'Indica cuándo lo guardaste y cuándo caduca.'
    return
  }
  if (tupperDraft.expires_at < tupperDraft.stored_at) {
    error.value = 'La fecha de caducidad no puede ser anterior a la fecha de entrada.'
    return
  }
  const nextTupper = {
    id: tupperDraft.id || `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    name,
    portions,
    stored_at: tupperDraft.stored_at,
    expires_at: tupperDraft.expires_at,
    location: tupperDraft.location.trim(),
    notes: tupperDraft.notes.trim(),
  }
  const existingIndex = tuppers.value.findIndex((tupper) => tupper.id === nextTupper.id)
  if (existingIndex >= 0) tuppers.value.splice(existingIndex, 1, nextTupper)
  else tuppers.value.push(nextTupper)
  persistTuppers()
  closeTupperEditor()
  notice.value = existingIndex >= 0 ? 'Tupper actualizado.' : 'Tupper añadido a la nevera.'
}
function changeTupperPortions(tupper, amount) {
  const nextPortions = Math.max(0, Number(tupper.portions || 0) + amount)
  tupper.portions = nextPortions
  persistTuppers()
}
function deleteTupper(tupper) {
  if (!window.confirm(`¿Quieres borrar «${tupper.name}»?`)) return
  tuppers.value = tuppers.value.filter((item) => item.id !== tupper.id)
  persistTuppers()
  notice.value = 'Tupper borrado.'
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
  if (signingIn.value) return
  signingIn.value = true
  error.value = ''
  try {
    const result = await signInWithGoogle()
    const token = await result.user.getIdToken()
    await postJson('auth/login', token, { id_token: token })
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo iniciar sesión con Google.'
  } finally {
    signingIn.value = false
  }
}
async function logout() {
  stopTelegramPolling()
  await signOut()
  menus.value = new Map()
  rangeDays.value = new Map()
  dayEntries.value = []
  dishes.value = []
  ingredientCatalog.value = []
  ingredientList.value = []
  group.value = null
  dailyOptions.value = []
  nextRangeStart.value = ''
  calendarDays.value = new Map()
  globalAlerts.value = []
  notifications.value = []
  notificationUnreadCount.value = 0
  tasks.value = []
  pendingTaskCount.value = 0
  taskEditorOpen.value = false
  taskFilter.value = 'all'
  notificationsOpen.value = false
  menuOpen.value = false
  shoppingSelectedDishes.value = new Set()
  shoppingSelectionInitialized.value = false
  shoppingItems.value = []
  shoppingExcludedItems.value = []
  supermarkets.value = []
  shoppingChecked.value = new Set()
  ingredientMergeSelected.value = new Set()
  ingredientMergeKeepId.value = ''
  ingredientMerging.value = false
  shoppingErrorDetails.value = ''
  shoppingErrorModal.value = null
  calendarFeedLink.value = ''
  calendarFeedLoading.value = false
  photoUploadingDish.value = ''
  photoDeletingDish.value = ''
  tuppers.value = []
  tupperSearch.value = ''
  tupperFilter.value = 'all'
  tupperEditorOpen.value = false
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
      breakfast_time: preferences.breakfast_time || null,
      lunch_time: preferences.lunch_time || null,
      dinner_time: preferences.dinner_time || null,
      default_reminder_enabled: preferences.default_reminder_enabled,
      default_reminder_time: preferences.default_reminder_time,
      notification_enabled: preferences.notification_enabled,
      notification_types: preferences.notification_types,
    })
    if (data.group) group.value = data.group
    preferences.enabled_meals =
      data.group?.enabled_meals || data.preferences?.enabled_meals || preferences.enabled_meals
    preferences.breakfast_time = data.preferences?.breakfast_time || ''
    preferences.lunch_time = data.preferences?.lunch_time || ''
    preferences.dinner_time = data.preferences?.dinner_time || ''
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

async function loadCalendarFeedLink() {
  if (calendarFeedLoading.value || !user.value) return
  calendarFeedLoading.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await getJson('menudiario/ical_link', userToken.value)
    calendarFeedLink.value = data.url || ''
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo preparar el enlace del calendario.'
  } finally {
    calendarFeedLoading.value = false
  }
}
async function copyCalendarFeedLink() {
  if (!calendarFeedLink.value) return
  try {
    await navigator.clipboard.writeText(calendarFeedLink.value)
    notice.value = 'Enlace del calendario copiado.'
  } catch {
    error.value = 'No se pudo copiar el enlace. Selecciónalo manualmente.'
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
async function openEditor(dayKey, requestedWeek = '') {
  await ensureDishesLoaded()
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
function mealDraftSummary(meal) {
  const items = draftDay.value?.meals?.[meal]?.items || []
  const count = items.filter((item) => String(item).trim()).length
  if (!count) return 'Añade un plato para empezar'
  return `${count} ${count === 1 ? 'plato añadido' : 'platos añadidos'}`
}
function mealMoreOptionsSummary(meal) {
  const currentMeal = draftDay.value?.meals?.[meal]
  if (!currentMeal) return 'Avisos y nota'
  const parts = []
  if (currentMeal.alerts.length) {
    parts.push(
      `${currentMeal.alerts.length} ${currentMeal.alerts.length === 1 ? 'aviso' : 'avisos'}`,
    )
  }
  if (String(currentMeal.note || '').trim()) parts.push('nota')
  return parts.length ? parts.join(' · ') : 'Añadir aviso o nota'
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
function hasDishSuggestion(name) {
  return dishes.value.some((dish) => String(dish.name) === String(name))
}
function hasIngredientSuggestion(name) {
  return ingredientCatalog.value.some((ingredient) => String(ingredient.name) === String(name))
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
const alertEditorOpen = ref(null)
const settingsTabs = computed(() =>
  [
    { id: 'configuration', label: 'Configuración', icon: PhGear },
    { id: 'group', label: 'Grupo', icon: PhUsers },
    { id: 'alerts', label: 'Avisos', icon: PhBell, ownerOnly: true },
    { id: 'options', label: 'Opciones', icon: PhNote },
    { id: 'telegram', label: 'Telegram', icon: PhTelegramLogo },
  ].filter((tab) => !tab.ownerOnly || isGroupOwner.value),
)
const alertAccordionItems = computed(() => [
  ...(alertEditorOpen.value === 'new' ? [{ id: 'new', alert: null }] : []),
  ...globalAlerts.value.map((alert) => ({ id: Number(alert.id), alert })),
])
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
async function saveGroupSupermarket() {
  if (!isGroupOwner.value || !group.value?.default_supermarket_id || saving.value) return
  saving.value = true
  try {
    await refreshToken()
    const data = await postJson('menudiario/save_group_supermarket', userToken.value, {
      supermarket_id: Number(group.value.default_supermarket_id),
    })
    group.value = data.group || group.value
    if (Array.isArray(data.supermarkets)) supermarkets.value = data.supermarkets
    if (Array.isArray(data.ingredient_list)) ingredientList.value = data.ingredient_list
    notice.value = 'Supermercado del grupo actualizado.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo actualizar el supermercado del grupo.'
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
function openNewAlert() {
  resetAlertDraft()
  alertEditorOpen.value = 'new'
}
function closeAlertEditor() {
  alertEditorOpen.value = null
  resetAlertDraft()
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
  alertEditorOpen.value = Number(alert.id)
}
function toggleAlertEditor(alert) {
  if (alertEditorOpen.value === Number(alert.id)) closeAlertEditor()
  else editAlert(alert)
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
    closeAlertEditor()
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
    if (Number(alertDraft.id) === Number(id)) closeAlertEditor()
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
function alertActionKey(meal, alert) {
  return [meal, alert.type, alert.alert_id ?? alert.source_index ?? alert.id].join(':')
}
async function sendAlertNow(meal, alert) {
  const actionKey = alertActionKey(meal, alert)
  if (sendingAlertKey.value || !draftDay.value) return
  sendingAlertKey.value = actionKey
  error.value = ''
  try {
    const saved = await saveDay(false)
    if (!saved) return
    await refreshToken()
    const data = await postJson('telegram/send_alert_now', userToken.value, {
      week_start: draftWeekStart.value,
      day_date: draftDayKey.value,
      meal,
      alert_type: alert.type,
      alert_id: alert.type === 'global' ? alert.alert_id : 0,
      custom_index: alert.type === 'custom' ? alert.source_index : null,
    })
    notice.value = `Aviso enviado (${data.sent} ${data.sent === 1 ? 'persona' : 'personas'}).`
    window.setTimeout(() => {
      notice.value = ''
    }, 4000)
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo enviar el aviso.'
  } finally {
    sendingAlertKey.value = ''
  }
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
function taskStatusLabel(status) {
  return taskStatuses.find((item) => item.id === status)?.label || 'Pendiente'
}
function taskImportanceLabel(importance) {
  return taskImportances.find((item) => item.id === importance)?.label || 'Media'
}
function formatTaskDueDate(value) {
  if (!value) return 'Sin fecha de fin'
  const date = new Date(String(value).replace(' ', 'T'))
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat('es-ES', { dateStyle: 'medium', timeStyle: 'short' }).format(date)
}
function taskReminderLabel(reminder) {
  if (reminder.type === 'daily') return `Diario · ${reminder.time || '09:00'}`
  if (reminder.type === 'at_due') return 'A la fecha y hora de fin'
  const days = Number(reminder.days_before || 0)
  return `${days} ${days === 1 ? 'día' : 'días'} antes · ${reminder.time || '09:00'}`
}
function openNewTask() {
  Object.assign(taskDraft, {
    id: '', title: '', description: '', assigned_all: true, assigned_uid: '', status: 'pending',
    importance: 'medium', due_at: '', reminders: [],
  })
  taskEditorOpen.value = true
}
function editTask(task) {
  Object.assign(taskDraft, { ...task, reminders: (task.reminders || []).map((reminder) => ({ ...reminder })) })
  taskEditorOpen.value = true
}
function closeTaskEditor() {
  if (!taskSaving.value) taskEditorOpen.value = false
}
function addTaskReminder(type = 'before') {
  taskDraft.reminders.push({ type, days_before: type === 'before' ? 1 : 0, time: '09:00', enabled: true })
}
function removeTaskReminder(index) {
  taskDraft.reminders.splice(index, 1)
}
async function saveTask(closeAfter = true) {
  if (!taskDraft.title.trim()) return
  taskSaving.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/save_task', userToken.value, { task: { ...taskDraft } })
    tasks.value = data.tasks || tasks.value
    pendingTaskCount.value = Number(data.pending_task_count || 0)
    if (closeAfter) taskEditorOpen.value = false
    notice.value = taskDraft.id ? 'Tarea actualizada.' : 'Tarea creada.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo guardar la tarea.'
  } finally {
    taskSaving.value = false
  }
}
async function changeTaskStatus(task, status) {
  const previous = { ...taskDraft }
  Object.assign(taskDraft, { ...task, status, reminders: (task.reminders || []).map((reminder) => ({ ...reminder })) })
  await saveTask(false)
  Object.assign(taskDraft, previous)
}
async function deleteTask(task) {
  if (!window.confirm(`¿Borrar la tarea «${task.title}»?`)) return
  taskSaving.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/delete_task', userToken.value, { id: task.id })
    tasks.value = data.tasks || tasks.value
    pendingTaskCount.value = Number(data.pending_task_count || 0)
    notice.value = 'Tarea borrada.'
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo borrar la tarea.'
  } finally {
    taskSaving.value = false
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
function startDishDrag(event, dayKey, meal, dish, requestedWeek = '') {
  dishDragSource.value = { week_start: requestedWeek, day_date: dayKey, meal, dish }
  dropTarget.value = null
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/plain', dish)
  }
}
function clearDishDrag() {
  dishDragSource.value = null
  dropTarget.value = null
}
function dragOverMeal(dayKey, meal, requestedWeek = '') {
  if (!dishDragSource.value || dishDragSource.value.day_date === dayKey) {
    dropTarget.value = null
    return
  }
  dropTarget.value = { day_date: dayKey, meal, week_start: requestedWeek }
}
function dragOverDay(dayKey, requestedWeek = '') {
  if (!dishDragSource.value || dishDragSource.value.day_date === dayKey) {
    dropTarget.value = null
    return
  }
  dropTarget.value = {
    day_date: dayKey,
    meal: dishDragSource.value.meal,
    week_start: requestedWeek,
  }
}
function isDropTargetDay(dayKey, requestedWeek = '') {
  return dropTarget.value?.day_date === dayKey && dropTarget.value?.week_start === requestedWeek
}
function isDropTarget(dayKey, meal, requestedWeek = '') {
  return (
    dropTarget.value?.day_date === dayKey &&
    dropTarget.value?.meal === meal &&
    dropTarget.value?.week_start === requestedWeek
  )
}
async function dropDish(dayKey, meal, requestedWeek = '') {
  const source = dishDragSource.value
  clearDishDrag()
  if (!source) return
  if (source.day_date === dayKey) {
    notice.value = 'Mueve el plato a otro día.'
    window.setTimeout(() => {
      notice.value = ''
    }, 2500)
    return
  }
  saving.value = true
  error.value = ''
  try {
    await refreshToken()
    const data = await postJson('menudiario/move_dish', userToken.value, {
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
    notice.value = 'Plato movido.'
    window.setTimeout(() => {
      notice.value = ''
    }, 2500)
  } catch (reason) {
    error.value = reason instanceof Error ? reason.message : 'No se pudo mover el plato.'
  } finally {
    saving.value = false
  }
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
function goToIngredients() {
  menuOpen.value = false
  router.push({ name: 'ingredients' })
}
function goToIngredientMerge() {
  menuOpen.value = false
  router.push({ name: 'ingredient-merge' })
}
function goToTuppers() {
  menuOpen.value = false
  router.push({ name: 'tuppers' })
}
function goToShopping() {
  menuOpen.value = false
  router.push({ name: 'shopping' })
}
function goToCalendar() {
  menuOpen.value = false
  router.push({ name: 'calendar' })
}
function goToTasks() {
  menuOpen.value = false
  router.push({ name: 'tasks' })
}

function navigateTo(name) {
  const routes = {
    dashboard: goToDashboard,
    dishes: goToDishes,
    ingredients: goToIngredients,
    'ingredient-merge': goToIngredientMerge,
    tuppers: goToTuppers,
    shopping: goToShopping,
    calendar: goToCalendar,
    tasks: goToTasks,
    settings: goToSettings,
  }
  routes[name]?.()
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

function focusMainContent() {
  document.getElementById('main-content')?.focus({ preventScroll: true })
}

function dismissHeaderPanels() {
  menuOpen.value = false
  notificationsOpen.value = false
}

function handleHeaderEscape(event) {
  if (event.key !== 'Escape' || document.querySelector('dialog[open]')) return
  const trigger = menuOpen.value ? '.menu-trigger' : notificationsOpen.value ? '.notification-trigger' : null
  if (!trigger) return
  dismissHeaderPanels()
  document.querySelector(trigger)?.focus()
}

function navigateDishTabs(event) {
  if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return
  const tabs = [...event.currentTarget.querySelectorAll('[role="tab"]:not(:disabled)')]
  const current = tabs.indexOf(document.activeElement)
  if (current < 0) return
  event.preventDefault()
  const index = event.key === 'Home' ? 0 : event.key === 'End' ? tabs.length - 1
    : (current + (event.key === 'ArrowRight' ? 1 : -1) + tabs.length) % tabs.length
  tabs[index].click()
  tabs[index].focus()
}

const pageTitles = {
  dashboard: 'Planificador', dishes: 'Mis platos', ingredients: 'Ingredientes',
  'ingredient-merge': 'Fusionar ingredientes', tuppers: 'Mis tuppers', shopping: 'Lista de la compra',
  calendar: 'Calendario', tasks: 'Tareas', settings: 'Ajustes', 'shared-day': 'Menú compartido',
}
watch(() => route.name, async (name, previous) => {
  document.title = `${pageTitles[name] || 'Planificador'} · Menu Diario`
  dismissHeaderPanels()
  if (previous) {
    await nextTick()
    focusMainContent()
    window.scrollTo({ top: 0, behavior: 'instant' })
  }
}, { immediate: true })

async function loadRouteData(name = route.name) {
  if (!user.value) return
  if (name === 'dashboard') await loadDashboardRange()
  else if (name === 'dishes') await loadDishes()
  else if (name === 'ingredients' || name === 'ingredient-merge') await loadIngredients()
  else if (name === 'shopping') await loadShoppingRange()
  else if (name === 'calendar') await loadCalendarMonth()
  else if (name === 'tasks') await loadTasks()
  else if (name === 'settings') await loadSettingsContext()
}

watch(() => route.name, (name) => {
  if (user.value) void loadRouteData(name)
})

watch(notice, (message) => {
  if (noticeTimer) window.clearTimeout(noticeTimer)
  noticeTimer = null
  if (!message) return
  noticeTimer = window.setTimeout(() => {
    noticeTimer = null
    if (notice.value === message) notice.value = ''
  }, 4000)
})

watch([dishSearch, dishFilter, dishSort, dishesPerPage], () => {
  dishPage.value = 1
})

watch([ingredientSearch, ingredientFilter, ingredientSort, ingredientsPerPage], () => {
  ingredientPage.value = 1
})

watch(() => dishDetailDraft.type, (type) => {
  if (type === 'purchased' && dishEditorTab.value === 'ingredients') dishEditorTab.value = 'photo'
})

watch(calendarMonth, () => {
  if (user.value && isCalendar.value) void loadCalendarMonth()
})

onMounted(async () => {
  window.addEventListener('keydown', handleHeaderEscape)
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
        loadTuppers()
        if (inviteFromUrl) goToSettings()
        await loadRouteData(route.name)
      } else loading.value = false
    })
  } catch (reason) {
    authReady.value = true
    loading.value = false
    error.value = reason instanceof Error ? reason.message : 'No se pudo inicializar Firebase.'
  }
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleHeaderEscape)
  window.removeEventListener('scroll', loadMoreOnScroll)
  if (installPromptHandler) window.removeEventListener('beforeinstallprompt', installPromptHandler)
  if (appInstalledHandler) window.removeEventListener('appinstalled', appInstalledHandler)
  stopTelegramPolling()
  if (rouletteTimer) window.clearTimeout(rouletteTimer)
  if (noticeTimer) window.clearTimeout(noticeTimer)
})
</script>

<template>
  <div class="app-shell" @click="dismissHeaderPanels">
    <a class="skip-link" href="#main-content" @click.prevent="focusMainContent">Saltar al contenido</a>
    <AppLoadingScreen :visible="!authReady && !isShared" :asset="publicAsset" />
    <AppHeader
      :user="user"
      :base-url="baseUrl"
      :asset="publicAsset"
      :route-name="route.name"
      :menu-open="menuOpen"
      :notifications-open="notificationsOpen"
      :notifications="notifications"
      :unread-count="notificationUnreadCount"
      :format-notification-date="formatNotificationDate"
      @navigate="navigateTo"
      @toggle-menu="menuOpen = !menuOpen; notificationsOpen = false"
      @toggle-notifications="notificationsOpen = !notificationsOpen; menuOpen = false"
      @mark-all-read="markAllNotificationsRead"
      @mark-read="markNotificationRead"
      @logout="logout"
    />
    <!--
    <header class="topbar">
      <a
        v-if="user"
        :href="baseUrl"
        class="brand-mark brand-link"
        aria-label="Ir al planificador"
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
          :aria-label="menuOpen ? 'Cerrar menú' : 'Abrir menú'"
          aria-controls="main-navigation"
          @click.stop="menuOpen = !menuOpen; notificationsOpen = false"
        >
          <PhList :size="22" weight="regular" /><span>Menú</span>
        </button>
        <nav v-if="menuOpen" id="main-navigation" class="navigation-panel" aria-label="Navegación principal" @click.stop>
          <button
            type="button"
            :class="{ active: route.name === 'dashboard' }" :aria-current="route.name === 'dashboard' ? 'page' : undefined"
            @click="goToDashboard"
          >
            <PhHouse :size="19" weight="regular" /><span>Planificador</span></button
          ><button type="button" :class="{ active: isDishes }" :aria-current="isDishes ? 'page' : undefined" @click="goToDishes">
            <PhForkKnife :size="19" weight="regular" /><span>Mis platos</span></button
          ><button type="button" :class="{ active: isIngredients }" :aria-current="isIngredients ? 'page' : undefined" @click="goToIngredients">
            <PhLeaf :size="19" weight="regular" /><span>Ingredientes</span></button
          ><button type="button" :class="{ active: isIngredientMerge }" :aria-current="isIngredientMerge ? 'page' : undefined" @click="goToIngredientMerge">
            <PhArrowsClockwise :size="19" weight="regular" /><span>Fusionar ingredientes</span></button
          ><button type="button" :class="{ active: isTuppers }" :aria-current="isTuppers ? 'page' : undefined" @click="goToTuppers">
            <PhCookingPot :size="19" weight="regular" /><span>Mis tuppers</span></button
          ><button type="button" :class="{ active: isShopping }" :aria-current="isShopping ? 'page' : undefined" @click="goToShopping">
            <PhShoppingCart :size="19" weight="regular" /><span>Lista de la compra</span></button
          ><button type="button" :class="{ active: isCalendar }" :aria-current="isCalendar ? 'page' : undefined" @click="goToCalendar">
            <PhCalendarBlank :size="19" weight="regular" /><span>Calendario</span></button
          ><button type="button" :class="{ active: isTasks }" :aria-current="isTasks ? 'page' : undefined" @click="goToTasks">
            <PhListChecks :size="19" weight="regular" /><span>Tareas</span></button
          ><button type="button" :class="{ active: isSettings }" :aria-current="isSettings ? 'page' : undefined" @click="goToSettings">
            <PhGear :size="19" weight="regular" /><span>Ajustes</span>
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
            @click.stop="notificationsOpen = !notificationsOpen; menuOpen = false"
          >
            <PhBell :size="22" weight="regular" /><span
              v-if="hasUnreadNotifications"
              class="notification-badge"
              >{{ notificationUnreadCount > 99 ? '99+' : notificationUnreadCount }}</span
            >
          </button>
          <div v-if="notificationsOpen" id="notifications-panel" class="notifications-panel" @click.stop>
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
    </header>-->

    <div v-if="notice" class="snackbar" role="status" aria-live="polite">
      <PhCheckCircle :size="20" weight="fill" aria-hidden="true" />
      <span>{{ notice }}</span>
    </div>

    <AppInstallBanner
      :visible="installBannerVisible && !isStandalone"
      :asset="publicAsset"
      @install="installApp"
      @dismiss="dismissInstallBanner"
    />
    <!-- <aside v-if="installBannerVisible && !isStandalone" class="install-banner" aria-live="polite">
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
    </aside> -->

    <main id="main-content" tabindex="-1" :class="{ 'settings-main': isSettings }">
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
        <button class="google-button" :disabled="signingIn" :aria-busy="signingIn" @click="login">
          <span class="google-g"><PhGoogleLogo :size="18" weight="bold" aria-hidden="true" /></span>
          {{ signingIn ? 'Abriendo Google…' : 'Continuar con Google' }}
        </button>
      </section>

      <template v-else-if="user">
        <section v-if="isDishes" class="catalog-page dishes-redesign-page">
          <div class="page-heading catalog-heading dishes-page-heading">
            <div>
              <p class="eyebrow">TU CATÁLOGO</p>
              <h1>Mis platos</h1>
              <p class="muted">Aquí tienes todos tus platos. Añade, edita y organízalos para crear menús a tu medida.</p>
            </div>
            <button class="primary-button" :aria-expanded="dishCreateOpen" aria-controls="dish-create-form" @click="dishCreateOpen = !dishCreateOpen">
              <PhPlus :size="18" weight="regular" /> Añadir plato
            </button>
          </div>

          <form v-if="dishCreateOpen" id="dish-create-form" ref="dishForm" class="dish-create-form dishes-create-inline" @submit.prevent="saveDish">
            <PhPlus :size="20" weight="regular" aria-hidden="true" />
            <input v-model="dishDraft" type="text" maxlength="190" placeholder="Ej.: Curry de garbanzos" aria-label="Nombre del nuevo plato" autofocus />
            <label class="select-field dish-create-type-field">
              <span class="sr-only">Tipo del nuevo plato</span>
              <select v-model="dishCreateType" aria-label="Tipo del nuevo plato">
                <option v-for="dishType in dishTypes" :key="dishType.id" :value="dishType.id">{{ dishType.label }}</option>
              </select>
              <PhCaretDown :size="16" aria-hidden="true" />
            </label>
            <label class="select-field dish-create-category-field">
              <span class="sr-only">Categoría del nuevo plato</span>
              <select v-model="dishCreateCategory" aria-label="Categoría del nuevo plato">
                <option v-for="dishCategoryOption in dishCategories" :key="dishCategoryOption.id" :value="dishCategoryOption.id">{{ dishCategoryOption.label }}</option>
              </select>
              <PhCaretDown :size="16" aria-hidden="true" />
            </label>
            <button class="primary-button" :disabled="saving || !dishDraft.trim()">{{ saving ? 'Guardando…' : 'Guardar' }}</button>
          </form>

          <div class="catalog-toolbar dishes-toolbar">
            <label class="search-field dishes-search-field">
              <PhMagnifyingGlass :size="19" weight="regular" aria-hidden="true" />
              <input v-model="dishSearch" type="search" placeholder="Buscar platos, ingredientes, etiquetas…" aria-label="Buscar platos" />
            </label>
            <label class="select-field">
              <span class="sr-only">Filtrar platos</span>
              <select v-model="dishFilter" aria-label="Filtrar platos">
                <option value="all">Todos los platos</option>
                <option value="favorites">Solo favoritos</option>
                <option value="with-ingredients">Con ingredientes</option>
                <option value="used">Ya utilizados</option>
                <option v-for="dishCategoryOption in dishCategories" :key="dishCategoryOption.id" :value="dishCategoryOption.id">{{ dishCategoryOption.label }}</option>
              </select>
              <PhCaretDown :size="16" aria-hidden="true" />
            </label>
            <label class="select-field dishes-sort-field">
              <span class="sr-only">Ordenar platos</span>
              <select v-model="dishSort" aria-label="Ordenar platos">
                <option value="popular">Más usados</option>
                <option value="name">Nombre</option>
                <option value="recent">Uso reciente</option>
              </select>
              <PhCaretDown :size="16" aria-hidden="true" />
            </label>
          </div>

          <div v-if="loading" class="dish-table" aria-busy="true" aria-label="Cargando mis platos">
            <div v-for="row in 6" :key="row" class="dish-table-row dish-table-skeleton">
              <span class="skeleton-dish-photo"></span><span class="skeleton-line"></span><span class="skeleton-line"></span>
            </div>
          </div>
          <div v-else-if="!sortedDishes.length" class="empty-state dishes-empty-state">
            <PhForkKnife :size="34" weight="regular" />
            <h2>{{ dishSearch || dishFilter !== 'all' ? 'No hay coincidencias' : 'Tu lista está vacía' }}</h2>
            <p>{{ dishSearch || dishFilter !== 'all' ? 'Prueba con otro término o limpia los filtros.' : 'Añade tu primer plato para tenerlo siempre a mano.' }}</p>
            <button v-if="dishSearch || dishFilter !== 'all'" type="button" class="secondary-button" @click="dishSearch = ''; dishFilter = 'all'">Limpiar búsqueda y filtros</button>
          </div>
          <div v-else class="dish-table" role="table" aria-label="Listado de platos">
            <div class="dish-table-head" role="row">
              <span role="columnheader">Plato</span>
              <span role="columnheader">Ingredientes</span>
              <span role="columnheader" class="dish-recipe-heading">Receta</span>
              <span role="columnheader" class="dish-action-heading">Editar</span>
              <span role="columnheader" class="dish-action-heading">Estadísticas</span>
              <span role="columnheader" class="dish-favorite-heading" aria-label="Favorito"><PhHeart :size="20" /></span>
            </div>
            <div v-for="dish in pagedDishes" :key="dish.id" class="dish-table-row" role="row">
              <div class="dish-name-cell" role="cell">
                <a v-if="dish.photo_url" class="dish-table-photo" :href="dish.photo_url" target="_blank" rel="noreferrer" :title="`Ver foto de ${dish.name}`"><img :src="dish.photo_url" :alt="`Foto de ${dish.name}`" /></a>
                <div v-else class="dish-table-photo dish-table-photo-empty"><PhForkKnife :size="20" /></div>
                <div><strong>{{ dish.name }}</strong><small>{{ dishCategory(dish) }} · {{ dishTypeLabel(dish) }} · {{ dish.times_used || 0 }} {{ dish.times_used === 1 ? 'uso' : 'usos' }}</small></div>
              </div>
              <div class="dish-ingredients-cell" role="cell">
                <template v-if="dish.type === 'purchased'">
                  <span class="ingredient-pill purchased-pill">Se compra preparado</span>
                </template>
                <template v-else-if="dish.ingredients?.length">
                  <span v-for="ingredient in dish.ingredients.slice(0, 3)" :key="ingredient" class="ingredient-pill">{{ ingredient }}</span>
                  <span v-if="dish.ingredients.length > 3" class="ingredient-pill ingredient-pill-more">+{{ dish.ingredients.length - 3 }}</span>
                </template>
                <span v-else class="detail-empty">Sin ingredientes</span>
              </div>
              <div class="dish-recipe-cell" role="cell">
                <button v-if="dish.recipe?.trim()" type="button" class="recipe-read-button" :aria-label="`Leer receta de ${dish.name}`" @click="openDishRecipe(dish)"><PhBookOpen :size="17" /> <span>Leer receta</span></button>
                <span v-else class="detail-empty">Sin receta</span>
              </div>
              <div class="dish-action-cell" role="cell"><button type="button" class="table-action-button" :disabled="dish.group_photo_only" :aria-label="dish.group_photo_only ? `Foto compartida de ${dish.name}` : `Editar ${dish.name}`" :title="dish.group_photo_only ? 'Foto compartida por el grupo' : 'Editar plato'" @click="openDishEditor(dish)"><PhPencilSimple :size="18" /></button></div>
              <div class="dish-action-cell" role="cell"><button type="button" class="table-action-button" :disabled="dish.group_photo_only" :aria-label="`Ver estadísticas de ${dish.name}`" title="Ver estadísticas" @click="openDishStats(dish)"><PhChartBar :size="19" /></button></div>
              <div class="dish-action-cell" role="cell"><button type="button" class="favorite-button table-favorite-button" :disabled="dish.group_photo_only" :class="{ active: dish.is_favorite }" :aria-pressed="Boolean(dish.is_favorite)" :aria-label="dish.is_favorite ? `Quitar ${dish.name} de favoritos` : `Añadir ${dish.name} a favoritos`" :title="dish.is_favorite ? 'Quitar de favoritos' : 'Añadir de favoritos'" @click="toggleDishFavorite(dish)"><PhHeart :size="21" :weight="dish.is_favorite ? 'fill' : 'regular'" /></button></div>
            </div>
          </div>
          <div v-if="!loading && sortedDishes.length" class="dish-pagination">
            <span>Mostrando {{ dishPageStart }}–{{ dishPageEnd }} de {{ sortedDishes.length }} platos</span>
            <div class="pagination-controls">
              <button type="button" class="pagination-button" :disabled="dishPage === 1" aria-label="Página anterior" @click="setDishPage(dishPage - 1)"><PhCaretLeft :size="17" /></button>
              <button v-for="page in dishPageNumbers" :key="page" type="button" class="pagination-button" :class="{ active: dishPage === page }" :aria-current="dishPage === page ? 'page' : undefined" :aria-label="`Página ${page}`" @click="setDishPage(page)">{{ page }}</button>
              <button type="button" class="pagination-button" :disabled="dishPage === dishPageCount" aria-label="Página siguiente" @click="setDishPage(dishPage + 1)"><PhCaretRight :size="17" /></button>
            </div>
          </div>
        </section>
        <section v-else-if="isIngredients" class="ingredients-page ingredients-redesign-page">
          <div class="page-heading ingredients-heading ingredients-redesign-heading">
            <div>
              <p class="eyebrow">CATÁLOGO DE COMPRA</p>
              <h1>Ingredientes</h1>
              <p class="muted">Gestiona tus ingredientes una sola vez y reutilízalos en todos tus platos.</p>
            </div>
            <button type="button" class="secondary-button" @click="goToIngredientMerge"><PhArrowsClockwise :size="17" /> Fusionar ingredientes</button>
          </div>
          <form class="ingredient-create-form ingredients-create-inline" @submit.prevent="saveIngredient">
            <PhPlus :size="20" weight="regular" aria-hidden="true" />
            <input v-model="ingredientDraft" type="text" maxlength="190" placeholder="Ej.: aceite de oliva" aria-label="Nombre del nuevo ingrediente" />
            <button class="primary-button" :disabled="ingredientSaving || !ingredientDraft.trim()">{{ ingredientSaving ? 'Guardando…' : 'Añadir ingrediente' }}</button>
          </form>
          <div class="ingredients-toolbar ingredients-redesign-toolbar">
            <label class="search-field ingredients-search-field"><PhMagnifyingGlass :size="19" weight="regular" aria-hidden="true" /><input v-model="ingredientSearch" type="search" placeholder="Buscar ingredientes" aria-label="Buscar ingredientes" /></label>
            <label class="select-field"><span class="sr-only">Filtrar ingredientes</span><select v-model="ingredientFilter" aria-label="Filtrar ingredientes"><option value="all">Todos los ingredientes</option><option value="used">En platos</option><option value="unused">Sin platos</option><option value="excluded">No comprar</option></select><PhCaretDown :size="16" aria-hidden="true" /></label>
            <label class="select-field ingredient-sort-field"><span class="sr-only">Ordenar ingredientes</span><select v-model="ingredientSort" aria-label="Ordenar ingredientes"><option value="name">Nombre</option><option value="usage">Más utilizados</option></select><PhCaretDown :size="16" aria-hidden="true" /></label>
          </div>
          <div v-if="loading" class="loading-card" role="status">Cargando ingredientes…</div>
          <div v-else-if="!sortedIngredients.length" class="empty-state ingredients-empty-state">
            <PhLeaf :size="34" weight="regular" />
            <h2>{{ ingredientList.length ? 'No hay coincidencias' : 'Tu catálogo está vacío' }}</h2>
            <p>{{ ingredientList.length ? 'Prueba con otro nombre o limpia los filtros.' : 'Añade ingredientes para reutilizarlos al editar tus platos.' }}</p>
            <button v-if="ingredientSearch || ingredientFilter !== 'all'" type="button" class="secondary-button" @click="ingredientSearch = ''; ingredientFilter = 'all'">Limpiar búsqueda y filtros</button>
          </div>
          <div v-else class="ingredient-table" role="table" aria-label="Listado de ingredientes">
            <div class="ingredient-table-head" role="row"><span role="columnheader">Ingrediente</span><span role="columnheader">Platos</span><span role="columnheader">Usos</span><span role="columnheader">Supermercado</span><span role="columnheader">Lista de la compra</span><span role="columnheader" class="ingredient-action-heading">Editar</span><span role="columnheader" class="ingredient-action-heading">Estadísticas</span><span role="columnheader" class="ingredient-action-heading" aria-label="Eliminar"></span></div>
            <div v-for="ingredient in pagedIngredients" :key="ingredient.id" class="ingredient-table-row" role="row">
              <div class="ingredient-name-cell" role="cell"><span class="ingredient-table-icon"><PhLeaf :size="19" /></span><div><strong>{{ ingredient.name }}</strong><small>{{ ingredient.exclude_from_shopping ? 'Excluido de la compra' : 'Disponible para la compra' }}</small></div></div>
              <div class="ingredient-number-cell ingredient-dishes-cell" role="cell"><strong>{{ ingredient.dish_count || 0 }}</strong><small>{{ ingredient.dish_count === 1 ? 'plato' : 'platos' }}</small></div>
              <div class="ingredient-number-cell ingredient-usage-cell" role="cell"><strong>{{ ingredientLinkedDishes(ingredient).reduce((total, dish) => total + Number(dish.times_used || 0), 0) }}</strong><small>usos estimados</small></div>
              <div class="ingredient-supermarket-cell" role="cell">
                <span class="ingredient-supermarket-logo" :title="ingredient.supermarket?.name || 'Supermercado del grupo'">
                  <img :class="{ 'supermarket-logo-dark': isDarkSupermarketLogo(ingredient.supermarket) }" :src="supermarketLogo(ingredient.supermarket)" :alt="`Supermercado: ${ingredient.supermarket?.name || 'del grupo'}`" />
                </span>
              </div>
              <div class="ingredient-shopping-cell" role="cell"><button type="button" class="ingredient-shopping-toggle" :class="{ active: ingredient.exclude_from_shopping }" :aria-pressed="ingredient.exclude_from_shopping" :title="ingredient.exclude_from_shopping ? 'Volver a añadir a la lista de la compra' : 'No añadir a la lista de la compra'" @click.stop.prevent="toggleIngredientShopping(ingredient)"><PhShoppingCart :size="16" /><span>{{ ingredient.exclude_from_shopping ? 'No comprar' : 'Comprar' }}</span></button></div>
              <div class="ingredient-action-cell" role="cell"><button type="button" class="table-action-button" :aria-label="`Editar ${ingredient.name}`" title="Editar ingrediente" @click="openIngredientEditor(ingredient)"><PhPencilSimple :size="18" /></button></div>
              <div class="ingredient-action-cell" role="cell"><button type="button" class="table-action-button" :aria-label="`Ver estadísticas de ${ingredient.name}`" title="Ver estadísticas" @click="openIngredientStats(ingredient)"><PhChartBar :size="19" /></button></div>
              <div class="ingredient-action-cell" role="cell"><button type="button" class="ingredient-delete-button" :disabled="ingredientDeleting === String(ingredient.id)" :aria-label="`Quitar ${ingredient.name}`" title="Quitar del catálogo" @click="deleteIngredient(ingredient)"><PhTrash :size="18" weight="regular" /></button></div>
            </div>
          </div>
          <div v-if="sortedIngredients.length" class="ingredient-pagination"><span>Mostrando {{ ingredientPageStart }}–{{ ingredientPageEnd }} de {{ sortedIngredients.length }} ingredientes</span><div class="pagination-controls"><button type="button" class="pagination-button" :disabled="ingredientPage === 1" aria-label="Página anterior de ingredientes" @click="setIngredientPage(ingredientPage - 1)"><PhCaretLeft :size="17" /></button><button v-for="page in ingredientPageNumbers" :key="page" type="button" class="pagination-button" :class="{ active: ingredientPage === page }" :aria-current="ingredientPage === page ? 'page' : undefined" :aria-label="`Página ${page}`" @click="setIngredientPage(page)">{{ page }}</button><button type="button" class="pagination-button" :disabled="ingredientPage === ingredientPageCount" aria-label="Página siguiente de ingredientes" @click="setIngredientPage(ingredientPage + 1)"><PhCaretRight :size="17" /></button></div></div>
        </section>
        <section v-else-if="isIngredientMerge" class="ingredient-merge-page">
          <div class="page-heading ingredient-merge-page-heading">
            <div>
              <p class="eyebrow">GESTIÓN DEL CATÁLOGO</p>
              <h1>Fusionar ingredientes</h1>
              <p class="muted">
                Selecciona manualmente dos o más ingredientes que representen lo mismo y decide
                qué nombre conservar.
              </p>
            </div>
            <button type="button" class="secondary-button" @click="goToIngredients">
              <PhArrowLeft :size="17" /> Volver a Ingredientes
            </button>
          </div>
          <div v-if="!ingredientList.length" class="empty-state ingredients-empty-state">
            <PhLeaf :size="34" weight="regular" />
            <h2>No hay ingredientes para fusionar</h2>
            <p>Añade ingredientes desde la página de Ingredientes.</p>
          </div>
          <div v-else class="ingredient-merge-layout">
            <section class="ingredient-merge-picker" aria-labelledby="ingredient-merge-picker-title">
              <div class="ingredient-merge-picker-heading">
                <div>
                  <h2 id="ingredient-merge-picker-title">Selecciona los ingredientes</h2>
                  <p>La selección es completamente manual.</p>
                </div>
                <span class="ingredient-merge-selection-count">
                  {{ ingredientMergeSelected.size }} seleccionados
                </span>
              </div>
              <label class="search-field ingredient-merge-search"
                ><PhMagnifyingGlass :size="19" weight="regular" aria-hidden="true" /><input
                  v-model="ingredientMergeSearch"
                  type="search"
                  placeholder="Buscar ingredientes"
                  aria-label="Buscar ingredientes para fusionar" /></label
              >
              <div v-if="!filteredMergeIngredients.length" class="ingredient-merge-no-results">
                No hay ingredientes que coincidan con la búsqueda.
              </div>
              <div v-else class="ingredient-merge-options">
                <label
                  v-for="ingredient in filteredMergeIngredients"
                  :key="ingredient.id"
                  class="ingredient-merge-option"
                  :class="{ selected: ingredientMergeSelected.has(Number(ingredient.id)) }"
                >
                  <input
                    type="checkbox"
                    :checked="ingredientMergeSelected.has(Number(ingredient.id))"
                    @change="toggleIngredientMergeSelection(ingredient)"
                  />
                  <span class="ingredient-merge-option-check"><PhCheck :size="14" weight="bold" /></span>
                  <span class="ingredient-merge-option-copy">
                    <strong>{{ ingredient.name }}</strong>
                    <small>
                      {{ ingredient.dish_count }}
                      {{ ingredient.dish_count === 1 ? 'plato' : 'platos' }}
                      <span v-if="ingredient.exclude_from_shopping"> · no añadir</span>
                    </small>
                  </span>
                </label>
              </div>
            </section>
            <aside class="ingredient-merge-summary">
              <div class="ingredient-merge-summary-icon"><PhArrowsClockwise :size="24" /></div>
              <h2>Fusionar selección</h2>
              <p v-if="ingredientMergeSelected.size < 2">
                Selecciona al menos dos ingredientes para poder fusionarlos.
              </p>
              <template v-else>
                <p>
                  Los platos pasarán a usar un único ingrediente. La marca de exclusión se
                  conservará si alguno de los seleccionados la tiene.
                </p>
                <label class="ingredient-merge-keep-field">
                  <span>Nombre que se conservará</span>
                  <select v-model.number="ingredientMergeKeepId">
                    <option
                      v-for="ingredient in selectedMergeIngredients"
                      :key="ingredient.id"
                      :value="ingredient.id"
                    >
                      {{ ingredient.name }}
                    </option>
                  </select>
                </label>
                <button
                  type="button"
                  class="primary-button ingredient-merge-submit"
                  :disabled="ingredientMerging"
                  @click="mergeSelectedIngredients"
                >
                  <PhArrowsClockwise :size="17" />
                  {{ ingredientMerging ? 'Fusionando…' : 'Fusionar ingredientes' }}
                </button>
                <button
                  type="button"
                  class="secondary-button ingredient-merge-clear"
                  :disabled="ingredientMerging"
                  @click="clearIngredientMergeSelection"
                >
                  Limpiar selección
                </button>
              </template>
            </aside>
          </div>
        </section>
        <section v-else-if="isTuppers" class="tuppers-page">
          <div class="page-heading tuppers-heading">
            <div>
              <p class="eyebrow">ORGANIZA TU NEVERA</p>
              <h1>Mis tuppers</h1>
              <p class="muted">
                Lleva el control de tus raciones y descubre de un vistazo qué tienes que consumir
                primero.
              </p>
            </div>
            <button type="button" class="primary-button" @click="openNewTupper">
              <PhPlus :size="18" weight="regular" /> Añadir tupper
            </button>
          </div>
          <section class="tupper-summary" aria-label="Resumen de tuppers">
            <article class="tupper-summary-card">
              <div class="tupper-summary-icon"><PhCookingPot :size="21" /></div>
              <div>
                <strong>{{ tupperStats.containers }}</strong
                ><span>tuppers guardados</span>
              </div>
            </article>
            <article class="tupper-summary-card">
              <div class="tupper-summary-icon portions"><PhForkKnife :size="21" /></div>
              <div>
                <strong>{{ tupperStats.portions }}</strong
                ><span>raciones disponibles</span>
              </div>
            </article>
            <article class="tupper-summary-card warning">
              <div class="tupper-summary-icon soon"><PhWarningCircle :size="21" /></div>
              <div>
                <strong>{{ tupperStats.soon }}</strong
                ><span>para consumir pronto</span>
              </div>
            </article>
          </section>
          <div class="tuppers-toolbar">
            <label class="search-field"
              ><PhMagnifyingGlass :size="19" weight="regular" aria-hidden="true" /><input
                v-model="tupperSearch"
                type="search"
                placeholder="Buscar tupper, ubicación o nota"
                aria-label="Buscar en mis tuppers"
            /></label>
            <div class="tupper-filters" aria-label="Filtrar tuppers">
              <button
                v-for="filter in [
                  { id: 'all', label: 'Todos' },
                  { id: 'available', label: 'Disponibles' },
                  { id: 'soon', label: 'Pronto' },
                  { id: 'expired', label: 'Caducados' },
                ]"
                :key="filter.id"
                type="button"
                :class="{ active: tupperFilter === filter.id }" :aria-pressed="tupperFilter === filter.id"
                @click="tupperFilter = filter.id"
              >
                {{ filter.label }}
              </button>
            </div>
          </div>
          <div v-if="!filteredTuppers.length" class="empty-state tupper-empty-state">
            <div class="tupper-empty-icon"><PhCookingPot :size="34" weight="regular" /></div>
            <h2>
              {{ tuppers.length ? 'No hay tuppers con este filtro' : 'Tu nevera empieza aquí' }}
            </h2>
            <p>
              {{
                tuppers.length
                  ? 'Prueba con otra búsqueda o cambia el filtro para ver el resto.'
                  : 'Anota lo que guardes y tendrás siempre a mano sus raciones y fechas.'
              }}
            </p>
            <button
              v-if="!tuppers.length"
              type="button"
              class="primary-button"
              @click="openNewTupper"
            >
              <PhPlus :size="18" /> Añadir mi primer tupper
            </button>
          </div>
          <section v-else class="tuppers-grid" aria-label="Listado de tuppers">
            <article
              v-for="tupper in filteredTuppers"
              :key="tupper.id"
              class="tupper-card"
              :class="`status-${tupperStatus(tupper)}`"
            >
              <div class="tupper-card-header">
                <div class="tupper-card-icon"><PhCookingPot :size="22" weight="regular" /></div>
                <span class="tupper-status">{{ tupperStatusLabel(tupper) }}</span>
                <div class="tupper-card-actions">
                  <button
                    type="button"
                    class="card-icon-button"
                    :aria-label="`Editar ${tupper.name}`"
                    title="Editar"
                    @click="editTupper(tupper)"
                  >
                    <PhNotePencil :size="18" />
                  </button>
                  <button
                    type="button"
                    class="card-icon-button danger"
                    :aria-label="`Borrar ${tupper.name}`"
                    title="Borrar"
                    @click="deleteTupper(tupper)"
                  >
                    <PhX :size="18" />
                  </button>
                </div>
              </div>
              <h2>{{ tupper.name }}</h2>
              <p v-if="tupper.notes" class="tupper-notes">{{ tupper.notes }}</p>
              <div class="tupper-portion-row">
                <div>
                  <strong>{{ tupper.portions }}</strong
                  ><span>{{ tupper.portions === 1 ? 'ración' : 'raciones' }}</span>
                </div>
                <div class="portion-controls" aria-label="Cambiar raciones">
                  <button
                    type="button"
                    aria-label="Restar una ración"
                    :disabled="!tupper.portions"
                    @click="changeTupperPortions(tupper, -1)"
                  >
                    −
                  </button>
                  <button
                    type="button"
                    aria-label="Añadir una ración"
                    @click="changeTupperPortions(tupper, 1)"
                  >
                    +
                  </button>
                </div>
              </div>
              <div class="tupper-dates">
                <div>
                  <span>Guardado</span><strong>{{ formatTupperDate(tupper.stored_at) }}</strong>
                </div>
                <div>
                  <span>Caduca</span><strong>{{ formatTupperDate(tupper.expires_at) }}</strong>
                </div>
              </div>
              <div class="tupper-card-footer">
                <span v-if="tupper.location"><PhHouse :size="15" /> {{ tupper.location }}</span>
                <span v-else><PhHouse :size="15" /> Nevera</span>
                <small>{{ tupperStatusMessage(tupper) }}</small>
              </div>
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
          <div class="shopping-layout">
            <section class="shopping-builder shopping-selection-panel" aria-labelledby="shopping-builder-title">
              <div class="shopping-section-heading">
                <div class="shopping-section-icon">
                  <PhCalendarCheck :size="22" weight="regular" />
                </div>
                <div>
                  <p class="eyebrow">PRÓXIMOS PLATOS</p>
                  <h2 id="shopping-builder-title">¿Qué vas a cocinar?</h2>
                  <p class="muted">
                    Todos tus próximos platos están seleccionados. Desmarca los que no vayas a cocinar.
                  </p>
                </div>
              </div>
              <div v-if="loading" class="shopping-skeleton-list" aria-hidden="true">
                <div v-for="day in 7" :key="day" class="shopping-day-option skeleton-shopping-day">
                  <span class="skeleton-square"></span>
                  <span class="skeleton-line skeleton-shopping-title"></span>
                  <span class="skeleton-line skeleton-shopping-meta"></span>
                </div>
              </div>
              <div v-else-if="!shoppingAvailableDishes.length" class="shopping-empty">
                <PhCalendarBlank :size="30" weight="regular" />
                <strong>Aún no hay platos próximos</strong>
                <span>Añade platos a tu planificador para preparar una lista.</span>
              </div>
              <div v-else class="shopping-meal-selection">
                <button
                  v-for="dish in shoppingAvailableDishes"
                  :key="dish.key"
                  type="button"
                  class="shopping-meal-option"
            :class="{ selected: shoppingSelectedDishes.has(dish.key) }"
                  :aria-pressed="shoppingSelectedDishes.has(dish.key)"
                  @click="toggleShoppingDish(dish.key)"
                >
                  <span class="shopping-meal-check"><PhCheck :size="15" weight="bold" /></span>
                  <span class="meal-icon"><component :is="mealIcons[dish.meal]" :size="19" /></span>
                  <span class="shopping-meal-option-copy">
                    <small
                      >{{ formatDay(dish.date) }} · {{ mealLabels[dish.meal] }} ·
                      {{ dish.isPurchased ? 'plato comprado' : `${dish.ingredientCount} ${dish.ingredientCount === 1 ? 'ingrediente' : 'ingredientes'}` }}</small
                    >
                    <strong>{{ dish.dish }}</strong>
                  </span>
                </button>
              </div>
              <div class="shopping-selection-footer">
                <span
                  ><PhForkKnife :size="18" /> {{ shoppingSelectedDishes.size }} de
                  {{ shoppingAvailableDishes.length }} platos seleccionados</span
                >
                <span class="shopping-selection-note">Puedes cambiar esta selección cuando quieras.</span>
              </div>
              <div class="shopping-wizard-actions">
                <span>La lista se generará con los platos marcados</span>
                <button
                  type="button"
                  class="primary-button"
                  :disabled="!shoppingMeals.length || shoppingGenerating"
                  @click="generateShoppingList"
                >
                  Generar lista <PhSparkle :size="17" weight="fill" />
                </button>
              </div>
            </section>
            <section class="shopping-result" aria-labelledby="shopping-result-title">
              <div class="shopping-section-heading">
                <div class="shopping-section-icon result-icon">
                  <PhShoppingCart :size="22" weight="regular" />
                </div>
                <div>
                  <p class="eyebrow">RESULTADO</p>
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
              <div v-else-if="shoppingItems.length || shoppingExcludedItems.length" class="shopping-result-content">
                <div class="shopping-result-toolbar">
                  <span
                    ><strong>{{ shoppingItems.length - shoppingChecked.size }}</strong> por
                    comprar</span
                  >
                  <button v-if="shoppingItems.length" type="button" class="secondary-button" @click="copyShoppingList">
                    <PhNote :size="17" /> Copiar lista
                  </button>
                  <a
                    v-if="shoppingItems.length"
                    class="secondary-button shopping-alexa-link"
                    :href="shoppingAlexaUrl"
                    @click.prevent="sendShoppingListToAlexa"
                  >
                    <PhSpeakerHigh :size="17" /> Enviar a Alexa
                  </a>
                </div>
                <section v-for="shoppingGroup in shoppingSupermarketGroups" :key="shoppingGroup.supermarket.id" class="shopping-supermarket-group">
                  <div class="shopping-supermarket-heading">
                    <img :class="{ 'supermarket-logo-dark': isDarkSupermarketLogo(shoppingGroup.supermarket) }" :src="supermarketLogo(shoppingGroup.supermarket)" :alt="`Logo de ${shoppingGroup.supermarket.name}`" />
                    <div><strong>{{ shoppingGroup.supermarket.name }}</strong><small>{{ shoppingGroup.items.length }} {{ shoppingGroup.items.length === 1 ? 'producto' : 'productos' }}</small></div>
                  </div>
                  <div class="shopping-items-list">
                    <label
                      v-for="entry in shoppingGroup.items"
                      :key="`${entry.item.name}-${entry.index}`"
                      class="shopping-item"
                      :class="{ checked: shoppingItemChecked(entry.index) }"
                    >
                      <input
                        type="checkbox"
                        :checked="shoppingItemChecked(entry.index)"
                        @change="toggleShoppingItem(entry.index)"
                      />
                      <span class="shopping-item-check"><PhCheck :size="14" weight="bold" /></span>
                      <span class="shopping-item-copy">
                        <strong>{{ entry.item.name }}</strong>
                        <small v-if="entry.item.dishes?.length">{{ entry.item.dishes.join(' · ') }}</small>
                      </span>
                    </label>
                  </div>
                </section>
                <div v-if="shoppingExcludedItems.length" class="shopping-excluded-section">
                  <div class="shopping-excluded-heading">
                    <PhShoppingCart :size="17" />
                    <strong>No añadir a la compra</strong>
                    <small>Marcados así en Ingredientes</small>
                  </div>
                  <div class="shopping-items-list shopping-disabled-items">
                    <div v-for="item in shoppingExcludedItems" :key="`excluded-${item.name}`" class="shopping-item disabled-shopping-item" aria-disabled="true">
                      <span class="shopping-item-check"><PhX :size="13" weight="bold" /></span>
                      <span class="shopping-item-copy">
                        <strong>{{ item.name }}</strong>
                        <small v-if="item.dishes?.length">{{ item.dishes.join(' · ') }}</small>
                      </span>
                    </div>
                  </div>
                </div>
                <div class="shopping-result-actions">
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
                <p>Selecciona los platos que vas a cocinar y pulsa «Generar lista».</p>
              </div>
            </section>
          </div>
          <dialog
            v-if="shoppingErrorModal"
            v-modal="closeShoppingError"
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
            <div v-if="calendarLoading" class="calendar-skeleton-grid" aria-hidden="true">
              <div v-for="week in 5" :key="week" class="calendar-skeleton-week">
                <div v-for="day in 7" :key="day" class="calendar-skeleton-cell">
                  <span class="skeleton-circle"></span>
                  <span class="skeleton-line skeleton-calendar-dot"></span>
                </div>
              </div>
            </div>
            <div v-else class="calendar-grid">
              <div v-for="week in calendarWeeks" :key="week[0].isoDate" class="calendar-week">
                <button
                  v-for="cell in week"
                  :key="cell.isoDate"
                  type="button"
                  class="calendar-day"
                  :class="calendarDayClass(cell)"
                  :aria-label="`${calendarDateLabel(cell.date)}${calendarDayHasMeals(cell.day) ? ' · Con comidas planificadas' : ' · Sin comidas'}`"
                  :aria-current="cell.isoDate === toIsoDate(new Date()) ? 'date' : undefined"
                  :disabled="!calendarDayHasMeals(cell.day)"
                  @click="openCalendarDay(cell)"
                >
                  <span class="calendar-number">{{ cell.date.getDate() }}</span
                  ><span v-if="calendarDayHasMeals(cell.day)" class="calendar-meals"
                    ><span
                      v-for="meal in allMeals.filter((key) => cell.day?.meals?.[key]?.items?.length)"
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
        <section v-else-if="isTasks" class="tasks-page">
          <div class="page-heading tasks-heading">
            <div>
              <p class="eyebrow">ORGANIZA EL DÍA A DÍA</p>
              <h1>Tareas</h1>
              <p class="muted">Crea tareas para ti o para todo el grupo y recibe avisos antes de que llegue el momento.</p>
            </div>
            <button type="button" class="primary-button" @click="openNewTask"><PhPlus :size="18" /> Nueva tarea</button>
          </div>
          <div class="tasks-toolbar">
            <div class="task-filters" aria-label="Filtrar tareas">
              <button v-for="filter in [{ id: 'all', label: 'Todas' }, ...taskStatuses]" :key="filter.id" type="button" :class="{ active: taskFilter === filter.id }" :aria-pressed="taskFilter === filter.id" @click="taskFilter = filter.id">
                {{ filter.label }}<span v-if="filter.id === 'pending' && pendingTaskCount">{{ pendingTaskCount }}</span>
              </button>
            </div>
          </div>
          <div v-if="!filteredTasks.length" class="empty-state tasks-empty-state">
            <PhListChecks :size="38" weight="regular" />
            <h2>{{ taskFilter === 'all' ? 'Aún no hay tareas' : 'No hay tareas en este estado' }}</h2>
            <p>{{ taskFilter === 'all' ? 'Crea la primera y comparte la organización con tu grupo.' : 'Prueba otro filtro o crea una tarea nueva.' }}</p>
            <button v-if="taskFilter === 'all'" type="button" class="primary-button" @click="openNewTask"><PhPlus :size="18" /> Crear tarea</button>
          </div>
          <section v-else class="tasks-grid" aria-label="Listado de tareas">
            <article v-for="task in filteredTasks" :key="task.id" class="task-card" :class="[`task-${task.importance}`, `task-status-${task.status}`]">
              <div class="task-card-topline">
                <span class="task-importance"><i></i>{{ taskImportanceLabel(task.importance) }}</span>
                <div class="task-card-actions">
                  <button type="button" class="card-icon-button" :aria-label="`Editar ${task.title}`" title="Editar" @click="editTask(task)"><PhPencilSimple :size="18" /></button>
                  <button type="button" class="card-icon-button danger" :aria-label="`Borrar ${task.title}`" title="Borrar" @click="deleteTask(task)"><PhTrash :size="18" /></button>
                </div>
              </div>
              <h2>{{ task.title }}</h2>
              <p v-if="task.description" class="task-description">{{ task.description }}</p>
              <div class="task-meta">
                <span><PhUsers :size="16" /> {{ task.assigned_all ? 'Todo el grupo' : (task.assigned_email || 'Usuario asignado') }}</span>
                <span :class="{ overdue: task.status === 'pending' && task.due_at && new Date(String(task.due_at).replace(' ', 'T')) < new Date() }"><PhClock :size="16" /> {{ formatTaskDueDate(task.due_at) }}</span>
                <span v-if="task.reminders?.length" :title="task.reminders.map(taskReminderLabel).join(', ')"><PhBell :size="16" /> {{ task.reminders.length }} {{ task.reminders.length === 1 ? 'aviso' : 'avisos' }}</span>
              </div>
              <div class="task-card-footer">
                <label class="task-status-select"><span class="sr-only">Estado de {{ task.title }}</span><select :value="task.status" @change="changeTaskStatus(task, $event.target.value)"><option v-for="status in taskStatuses" :key="status.id" :value="status.id">{{ status.label }}</option></select><PhCaretDown :size="15" /></label>
                <small>{{ taskStatusLabel(task.status) }}</small>
              </div>
            </article>
          </section>
        </section>
        <template v-else-if="isDashboard">
          <h1 class="sr-only">Planificador de comidas</h1>
          <button v-if="pendingTaskCount" type="button" class="dashboard-task-notice" @click="goToTasks">
            <span class="dashboard-task-notice-icon"><PhListChecks :size="20" /></span>
            <span><strong>{{ pendingTaskCount }} {{ pendingTaskCount === 1 ? 'tarea pendiente' : 'tareas pendientes' }}</strong><small>Revísalas y marca las que ya estén hechas.</small></span>
            <PhArrowRight :size="19" />
          </button>
          <section
            v-if="loading"
            class="week-grid dashboard-skeleton-grid"
            aria-busy="true"
            aria-label="Cargando tu menú"
          >
            <article v-for="day in 7" :key="day" class="day-card skeleton-day-card">
              <header class="day-header">
                <div class="day-heading-copy">
                  <span class="skeleton-line skeleton-day-name"></span>
                  <span class="skeleton-line skeleton-day-date"></span>
                </div>
                <span class="skeleton-pill"></span>
              </header>
              <div class="meal-list">
                <div v-for="meal in allMeals" :key="meal" class="meal-card skeleton-meal-card">
                  <span class="skeleton-circle"></span>
                  <div class="meal-content">
                    <span class="skeleton-line skeleton-meal-label"></span>
                    <span class="skeleton-line skeleton-meal-title"></span>
                    <span class="skeleton-line skeleton-meal-meta"></span>
                  </div>
                </div>
              </div>
              <span class="skeleton-edit"></span>
            </article>
          </section>
          <section v-else-if="dashboardLoadError" class="empty-state" role="status">
            <PhWarningCircle :size="32" aria-hidden="true" />
            <h2>No hemos podido cargar tu menú</h2>
            <p>{{ dashboardLoadError }}</p>
            <button type="button" class="primary-button" @click="loadDashboardRange">Volver a intentar</button>
          </section>
          <section v-else class="week-grid">
            <article
              v-for="day in dayEntries"
              :key="`${day.weekStart}-${day.isoDate}`"
              class="day-card"
              :class="{
                today: day.isoDate === toIsoDate(new Date()),
                'drop-target': isDropTargetDay(day.isoDate, day.weekStart),
              }"
              @dragenter.prevent="dragOverDay(day.isoDate, day.weekStart)"
              @dragover.prevent="dragOverDay(day.isoDate, day.weekStart)"
              @drop="dropDish(day.isoDate, dishDragSource?.meal || enabledMeals[0], day.weekStart)"
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
                    filled: hasItems(day.isoDate, meal, day.weekStart),
                    'drop-target': isDropTarget(day.isoDate, meal, day.weekStart),
                  }"
                  @dragenter.stop.prevent="dragOverMeal(day.isoDate, meal, day.weekStart)"
                  @dragover.stop.prevent="dragOverMeal(day.isoDate, meal, day.weekStart)"
                  @drop.stop="dropDish(day.isoDate, meal, day.weekStart)"
                >
                  <span class="meal-icon" aria-hidden="true"
                    ><component :is="mealIcons[meal]" :size="21" weight="regular"
                  /></span>
                  <div class="meal-content">
                    <div class="meal-top">
                      <span class="meal-name">{{ mealLabels[meal] }}</span>
                    </div>
                    <div
                      v-if="currentDay(day.isoDate, day.weekStart).meals[meal].items.length"
                      class="dish-list"
                    >
                      <span
                        v-for="dish in currentDay(day.isoDate, day.weekStart).meals[meal].items"
                        :key="dish"
                        class="dish-chip"
                        draggable="true"
                        role="button"
                        tabindex="0"
                        :title="`Arrastra ${dish} a otro día. Haz doble clic o doble toque para abrir su ficha.`"
                        @dragstart.stop="
                          startDishDrag($event, day.isoDate, meal, dish, day.weekStart)
                        "
                        @dragend="clearDishDrag"
                        @dblclick.stop="openPlannerDish(dish)"
                        @touchend.stop="handlePlannerDishTouch(dish)"
                        @keydown.enter.stop="openPlannerDish(dish)"
                        @keydown.space.prevent.stop="openPlannerDish(dish)"
                        >{{ dish }}</span
                      >
                    </div>
                    <button
                      v-if="!currentDay(day.isoDate, day.weekStart).meals[meal].items.length"
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
              <button class="edit-day" :aria-label="`Editar menú del ${formatDay(day.date)}`" @click="openEditor(day.isoDate, day.weekStart)">
                Editar día <PhArrowRight :size="17" weight="regular" />
              </button>
            </article>
            <div class="infinite-status" aria-live="polite">
              <div v-if="loadingMore" class="spinner"></div>
              {{ loadingMore ? 'Cargando más días…' : 'Sigue bajando para ver más días' }}
            </div>
          </section>
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


    <dialog v-if="taskEditorOpen" v-modal="closeTaskEditor" class="modal-backdrop" @click.self="closeTaskEditor">
      <form class="modal-card task-editor-card" @submit.prevent="saveTask()">
        <div class="modal-header">
          <div><p class="eyebrow">GESTIÓN DEL GRUPO</p><h2>{{ taskDraft.id ? 'Editar tarea' : 'Nueva tarea' }}</h2></div>
          <button type="button" class="icon-button" aria-label="Cerrar editor" :disabled="taskSaving" @click="closeTaskEditor"><PhX :size="22" /></button>
        </div>
        <div class="task-editor-scroll">
          <label class="field-label"><span>Nombre de la tarea *</span><input v-model="taskDraft.title" maxlength="190" required autofocus placeholder="Ej.: Comprar detergente" /></label>
          <label class="field-label"><span>Descripción</span><textarea v-model="taskDraft.description" rows="4" maxlength="5000" placeholder="Añade los detalles que hagan falta."></textarea></label>
          <div class="task-editor-grid">
            <label class="field-label"><span>Estado</span><select v-model="taskDraft.status"><option v-for="status in taskStatuses" :key="status.id" :value="status.id">{{ status.label }}</option></select></label>
            <label class="field-label"><span>Importancia</span><select v-model="taskDraft.importance"><option v-for="importance in taskImportances" :key="importance.id" :value="importance.id">{{ importance.label }}</option></select></label>
            <label class="field-label"><span>Fecha y hora de fin</span><input v-model="taskDraft.due_at" type="datetime-local" /></label>
            <label class="field-label"><span>Asignada a</span><select v-model="taskDraft.assigned_uid" :disabled="taskDraft.assigned_all"><option value="">Selecciona un usuario</option><option v-for="member in group?.members || []" :key="member.uid" :value="member.uid">{{ member.email || member.uid }}</option></select></label>
          </div>
          <label class="task-all-members-check"><input v-model="taskDraft.assigned_all" type="checkbox" /> <span><strong>Asignar a todo el grupo</strong><small>Los avisos se enviarán a todos los miembros.</small></span></label>
          <section class="task-reminders-editor">
            <div class="task-reminders-heading"><div><span class="field-kicker">AVISOS</span><h3>¿Cuándo avisar?</h3></div><button type="button" class="secondary-button" @click="addTaskReminder('before')"><PhPlus :size="16" /> Añadir aviso</button></div>
            <p v-if="!taskDraft.reminders.length" class="field-help">Puedes añadir un aviso diario, uno o varios días antes o justo al llegar la fecha de fin.</p>
            <div v-for="(reminder, index) in taskDraft.reminders" :key="index" class="task-reminder-editor-row">
              <label class="field-label"><span>Tipo</span><select v-model="reminder.type"><option value="daily">Diario</option><option value="before">Antes de la fecha</option><option value="at_due" :disabled="!taskDraft.due_at">A la fecha y hora de fin</option></select></label>
              <label v-if="reminder.type === 'before'" class="field-label"><span>Días antes</span><input v-model.number="reminder.days_before" type="number" min="0" max="30" /></label>
              <label v-if="reminder.type !== 'at_due'" class="field-label"><span>Hora</span><input v-model="reminder.time" type="time" /></label>
              <span v-else class="task-reminder-due-hint">Se enviará cuando llegue la fecha y hora de fin.</span>
              <button type="button" class="icon-button task-reminder-remove" aria-label="Quitar aviso" @click="removeTaskReminder(index)"><PhTrash :size="17" /></button>
            </div>
          </section>
        </div>
        <div class="modal-footer"><button type="button" class="secondary-button" :disabled="taskSaving" @click="closeTaskEditor">Cancelar</button><button type="submit" class="primary-button" :disabled="taskSaving || !taskDraft.title.trim()">{{ taskSaving ? 'Guardando…' : 'Guardar tarea' }}</button></div>
      </form>
    </dialog>

    <dialog v-if="dishEditorOpen" v-modal="closeDishEditor" class="modal-backdrop dish-modal-backdrop" @click.self="closeDishEditor">
      <form class="modal-card dish-editor-card" @submit.prevent="saveDishDetails">
        <div class="modal-header dish-editor-header">
          <div>
            <p class="eyebrow">FICHA DEL PLATO</p>
            <h2>Editar plato</h2>
          </div>
          <button type="button" class="icon-button" aria-label="Cerrar editor" :disabled="dishDetailSaving" @click="closeDishEditor"><PhX :size="22" /></button>
        </div>
        <div class="dish-editor-tabs" @keydown="navigateDishTabs" role="tablist" aria-label="Secciones del plato">
          <button type="button" id="dish-tab-photo" role="tab" aria-controls="dish-editor-panel" :tabindex="dishEditorTab === 'photo' ? 0 : -1" :aria-selected="dishEditorTab === 'photo'" :class="{ active: dishEditorTab === 'photo' }" @click="dishEditorTab = 'photo'"><PhCamera :size="17" /> Foto</button>
          <button type="button" id="dish-tab-ingredients" role="tab" aria-controls="dish-editor-panel" :tabindex="dishEditorTab === 'ingredients' ? 0 : -1" :aria-selected="dishEditorTab === 'ingredients'" :class="{ active: dishEditorTab === 'ingredients' }" :disabled="dishDetailDraft.type === 'purchased'" @click="dishEditorTab = 'ingredients'"><PhList :size="17" /> Ingredientes</button>
          <button type="button" id="dish-tab-description" role="tab" aria-controls="dish-editor-panel" :tabindex="dishEditorTab === 'description' ? 0 : -1" :aria-selected="dishEditorTab === 'description'" :class="{ active: dishEditorTab === 'description' }" @click="dishEditorTab = 'description'"><PhNotePencil :size="17" /> Descripción</button>
          <button type="button" id="dish-tab-recipe" role="tab" aria-controls="dish-editor-panel" :tabindex="dishEditorTab === 'recipe' ? 0 : -1" :aria-selected="dishEditorTab === 'recipe'" :class="{ active: dishEditorTab === 'recipe' }" @click="dishEditorTab = 'recipe'"><PhChefHat :size="17" /> Receta</button>
        </div>
        <div id="dish-editor-panel" class="dish-editor-scroll" role="tabpanel" :aria-labelledby="`dish-tab-${dishEditorTab}`" tabindex="0">
          <div v-if="dishEditorTab === 'photo'" class="dish-editor-photo-layout">
            <div class="dish-editor-photo-column">
              <span class="field-kicker">FOTO DEL PLATO</span>
              <a v-if="dishEditorDish?.photo_url" class="dish-editor-photo" :href="dishEditorDish.photo_url" target="_blank" rel="noreferrer"><img :src="dishEditorDish.photo_url" :alt="`Foto de ${dishEditorDish.name}`" /></a>
              <div v-else class="dish-editor-photo dish-editor-photo-empty"><PhForkKnife :size="38" /></div>
              <label class="photo-upload-button"><PhCamera :size="17" /> {{ dishEditorDish?.photo_url ? 'Cambiar foto' : 'Subir una foto' }}<input type="file" accept="image/*" capture="environment" :disabled="Boolean(photoUploadingDish) || dishEditorDish?.source === 'admin' || dishEditorDish?.group_photo_only" @change="uploadDishPhoto($event, dishEditorDish)" /></label>
              <button v-if="dishEditorDish?.photo_url" type="button" class="photo-remove-button" :disabled="Boolean(photoDeletingDish) || dishEditorDish?.group_photo_only" @click="removeDishPhoto(dishEditorDish)"><PhTrash :size="16" /> {{ photoDeletingDish ? 'Eliminando…' : 'Eliminar foto' }}</button>
              <small class="field-help">JPG, PNG o WebP · Máximo 10 MB</small>
            </div>
            <div class="dish-editor-fields">
              <label class="field-label"><span>Nombre del plato *</span><input v-model="dishDetailDraft.name" maxlength="190" required /></label>
              <label class="field-label"><span>Tipo de plato</span><select v-model="dishDetailDraft.type"><option v-for="dishType in dishTypes" :key="dishType.id" :value="dishType.id">{{ dishType.label }}</option></select></label>
              <label class="field-label"><span>Categoría</span><select v-model="dishDetailDraft.category"><option v-for="dishCategoryOption in dishCategories" :key="dishCategoryOption.id" :value="dishCategoryOption.id">{{ dishCategoryOption.label }}</option></select></label>
              <p v-if="dishDetailDraft.type === 'purchased'" class="dish-purchased-help"><PhShoppingCart :size="17" /> Se añadirá «{{ dishDetailDraft.name }}» directamente a la lista de la compra.</p>
              <label class="dish-editor-check"><input type="checkbox" :checked="dishEditorDish?.is_favorite" disabled /> <span>Marcado como plato favorito</span></label>
              <p v-if="dishEditorDish?.source === 'admin'" class="field-help">Las fotos de las sugerencias iniciales no se pueden reemplazar.</p>
              <p v-else-if="dishEditorDish?.group_photo_only" class="field-help">Foto compartida por otro miembro del grupo. Añade este plato a tu catálogo para poder gestionarlo.</p>
            </div>
          </div>
          <div v-else-if="dishEditorTab === 'ingredients' && dishDetailDraft.type !== 'purchased'" class="dish-editor-tab-content">
            <div class="dish-tab-intro"><div><span class="field-kicker">INGREDIENTES</span><h3>Lo que necesitas para prepararlo</h3></div><button type="button" class="secondary-button" @click="generateDishIngredients"><PhSparkle :size="17" weight="fill" /> Generar con IA</button></div>
            <p class="muted">Añádelos uno a uno; se reutilizarán en tu lista de la compra.</p>
            <div class="dish-ingredients-list">
              <label v-for="(_, index) in dishIngredientsDraft" :key="index" class="ingredient-row"><span>{{ index + 1 }}</span><select v-select2="{ value: dishIngredientsDraft[index], placeholder: 'Busca o escribe un ingrediente', onChange: (value) => (dishIngredientsDraft[index] = value) }" :aria-label="`Ingrediente ${index + 1}`" class="ingredient-select"><option v-if="dishIngredientsDraft[index] && !hasIngredientSuggestion(dishIngredientsDraft[index])" :value="dishIngredientsDraft[index]">{{ dishIngredientsDraft[index] }}</option><option v-for="ingredient in ingredientCatalog" :key="ingredient.id || ingredient.name" :value="ingredient.name">{{ ingredient.name }}</option></select><button type="button" class="icon-button ingredient-remove-button" :aria-label="`Eliminar ingrediente ${index + 1}`" @click="removeDishIngredient(index)"><PhTrash :size="17" /></button></label>
            </div>
            <button type="button" class="secondary-button add-ingredient-button" @click="addDishIngredient"><PhPlus :size="17" /> Añadir ingrediente</button>
          </div>
          <div v-else-if="dishEditorTab === 'ingredients'" class="dish-editor-tab-content dish-purchased-notice"><PhShoppingCart :size="34" /><h3>Este plato se compra preparado</h3><p>No necesita ingredientes. En la lista de la compra aparecerá «{{ dishDetailDraft.name }}» como un artículo independiente.</p></div>
          <div v-else-if="dishEditorTab === 'description'" class="dish-editor-tab-content"><label class="field-label"><span>Descripción breve</span><textarea v-model="dishDetailDraft.description" rows="8" maxlength="1000" placeholder="Cuenta qué hace especial a este plato, cuándo sueles prepararlo o con qué acompañarlo."></textarea></label><p class="field-help">Una frase clara ayuda a elegirlo cuando estés planificando la semana.</p></div>
          <div v-else class="dish-editor-tab-content"><label class="field-label"><span>Receta</span><textarea v-model="dishDetailDraft.recipe" rows="12" maxlength="5000" placeholder="1. Prepara los ingredientes…\n2. Cocina a fuego medio…\n3. Sirve y disfruta."></textarea></label><p class="field-help">Puedes escribir pasos, tiempos y trucos de cocina.</p></div>
        </div>
        <div class="modal-footer dish-editor-footer"><button type="button" class="secondary-button" :disabled="dishDetailSaving" @click="closeDishEditor">Cancelar</button><button type="submit" class="primary-button" :disabled="dishDetailSaving">{{ dishDetailSaving ? 'Guardando…' : 'Guardar cambios' }}</button></div>
      </form>
    </dialog>

    <dialog v-if="dishStatsOpen" v-modal="closeDishStats" class="modal-backdrop dish-modal-backdrop" @click.self="closeDishStats">
      <section class="modal-card dish-stats-card">
        <div class="modal-header dish-stats-header">
          <div><p class="eyebrow">ANÁLISIS DEL PLATO</p><h2>{{ dishStatsDish?.name }}</h2></div>
          <button type="button" class="icon-button" aria-label="Cerrar estadísticas" @click="closeDishStats"><PhX :size="22" /></button>
        </div>
        <div v-if="dishStatsData" class="dish-stats-scroll">
          <div class="stats-hero"><div class="dish-stats-photo"><img v-if="dishStatsDish?.photo_url" :src="dishStatsDish.photo_url" :alt="`Foto de ${dishStatsDish.name}`" /><PhForkKnife v-else :size="30" /></div><div><span class="stats-category">{{ dishCategory(dishStatsDish || {}) }}</span><p>{{ dishStatsLoading ? 'Actualizando datos…' : 'Así encaja este plato en tus hábitos.' }}</p></div><PhHeart :size="27" :weight="dishStatsDish?.is_favorite ? 'fill' : 'regular'" class="stats-heart" /></div>
          <h3>Estadísticas de consumo</h3>
          <div class="stats-kpi-grid"><div class="stats-kpi"><span>Veces que lo has comido</span><strong>{{ dishStatsData.total }}</strong><small>en total</small></div><div class="stats-kpi"><span>Frecuencia</span><strong>{{ dishStatsData.frequency }}</strong><small>promedio</small></div><div class="stats-kpi"><span>Última vez</span><strong>{{ formatDishDate(dishStatsData.last_used_at) }}</strong><small>fecha registrada</small></div><div class="stats-kpi"><span>Racha actual</span><strong>{{ dishStatsData.streak || 0 }}</strong><small>semanas seguidas</small></div></div>
          <div class="stats-section"><div class="stats-section-heading"><h3>Evolución mensual</h3><span>últimos 12 meses</span></div><div class="stats-chart" aria-label="Gráfico de usos por mes"><div v-for="(month, index) in dishStatsData.monthly" :key="index" class="stats-chart-column"><span class="stats-chart-bar" :style="{ height: `${month.height}%` }"></span><small>{{ statsMonthLabels[index] }}</small></div></div></div>
          <div class="stats-section"><div class="stats-section-heading"><h3>Momentos favoritos</h3><span>cuándo lo eliges</span></div><div class="stats-breakdown"><div v-for="item in dishStatsData.meal_breakdown" :key="item.label" class="stats-breakdown-row"><span>{{ item.label }}</span><div class="stats-breakdown-track"><i :style="{ width: `${item.value}%` }"></i></div><strong>{{ item.value }}%</strong></div></div></div>
          <div class="stats-extra"><div><PhClock :size="19" /><span>Tiempo medio entre usos</span><strong>{{ dishStatsData.average_gap_days ? `${dishStatsData.average_gap_days} días` : '—' }}</strong></div><div><PhChartBar :size="19" /><span>Ingredientes guardados</span><strong>{{ dishStatsDish?.ingredients?.length || 0 }}</strong></div></div>
        </div>
        <div class="modal-footer dish-stats-footer"><button type="button" class="secondary-button" @click="closeDishStats">Cerrar</button><button type="button" class="primary-button" @click="editDishFromStats">Editar plato <PhPencilSimple :size="17" /></button></div>
      </section>
    </dialog>

    <dialog v-if="dishRecipeOpen" v-modal="closeDishRecipe" class="modal-backdrop dish-modal-backdrop" @click.self="closeDishRecipe">
      <section class="modal-card dish-recipe-card">
        <div class="modal-header dish-recipe-header">
          <div>
            <p class="eyebrow">RECETA DEL PLATO</p>
            <h2>{{ dishRecipeDish?.name }}</h2>
          </div>
          <button type="button" class="icon-button" aria-label="Cerrar receta" @click="closeDishRecipe"><PhX :size="22" /></button>
        </div>
        <div class="dish-recipe-scroll">
          <div class="dish-recipe-meta"><span class="stats-category">{{ dishCategory(dishRecipeDish || {}) }}</span><span>{{ dishTypeLabel(dishRecipeDish || {}) }}</span></div>
          <p class="dish-recipe-text">{{ dishRecipeDish?.recipe }}</p>
        </div>
        <div class="modal-footer dish-recipe-footer"><button type="button" class="secondary-button" @click="closeDishRecipe">Cerrar</button><button type="button" class="primary-button" @click="editDishRecipe">Editar receta <PhPencilSimple :size="17" /></button></div>
      </section>
    </dialog>

    <dialog v-if="ingredientEditorOpen" v-modal="closeIngredientEditor" class="modal-backdrop dish-modal-backdrop" @click.self="closeIngredientEditor">
      <form class="modal-card ingredient-editor-card" @submit.prevent="saveIngredientDetails">
        <div class="modal-header ingredient-editor-header">
          <div><p class="eyebrow">FICHA DEL INGREDIENTE</p><h2>Editar ingrediente</h2></div>
          <button type="button" class="icon-button" aria-label="Cerrar editor de ingrediente" :disabled="ingredientEditorSaving" @click="closeIngredientEditor"><PhX :size="22" /></button>
        </div>
        <div class="ingredient-editor-content">
          <div class="ingredient-editor-icon"><PhLeaf :size="34" /></div>
          <label class="field-label"><span>Nombre del ingrediente *</span><input v-model="ingredientDetailDraft.name" maxlength="190" required /></label>
          <label class="field-label"><span>Supermercado</span><span class="supermarket-select ingredient-editor-supermarket-select"><img :class="{ 'supermarket-logo-dark': isDarkSupermarketLogo(ingredientEditorSupermarket) }" :src="supermarketLogo(ingredientEditorSupermarket)" :alt="`Logo de ${ingredientEditorSupermarket?.name || 'supermercado'}`" /><select v-model.number="ingredientDetailDraft.supermarket_id" aria-label="Supermercado del ingrediente"><option value="0">{{ group?.default_supermarket?.name || 'Del grupo' }}</option><option v-for="supermarket in supermarkets" :key="supermarket.id" :value="supermarket.id">{{ supermarket.name }}</option></select></span><small class="field-help">Si eliges «Del grupo», usará el supermercado por defecto del grupo.</small></label>
          <label class="ingredient-editor-check"><input v-model="ingredientDetailDraft.exclude_from_shopping" type="checkbox" /><span><strong>No añadir a la lista de la compra</strong><small>Este ingrediente seguirá disponible en tus platos, pero no se propondrá al generar compras.</small></span></label>
        </div>
        <div class="modal-footer ingredient-editor-footer"><button type="button" class="secondary-button" :disabled="ingredientEditorSaving" @click="closeIngredientEditor">Cancelar</button><button type="submit" class="primary-button" :disabled="ingredientEditorSaving">{{ ingredientEditorSaving ? 'Guardando…' : 'Guardar cambios' }}</button></div>
      </form>
    </dialog>

    <dialog v-if="ingredientStatsOpen" v-modal="closeIngredientStats" class="modal-backdrop dish-modal-backdrop" @click.self="closeIngredientStats">
      <section class="modal-card ingredient-stats-card">
        <div class="modal-header ingredient-stats-header">
          <div><p class="eyebrow">ANÁLISIS DEL INGREDIENTE</p><h2>{{ ingredientStatsIngredient?.name }}</h2></div>
          <button type="button" class="icon-button" aria-label="Cerrar estadísticas del ingrediente" @click="closeIngredientStats"><PhX :size="22" /></button>
        </div>
        <div v-if="ingredientStatsData" class="ingredient-stats-scroll">
          <div class="ingredient-stats-hero"><div class="ingredient-stats-icon"><PhLeaf :size="30" /></div><div><span class="stats-category">{{ ingredientStatsData.excluded ? 'No comprar' : 'En la lista de la compra' }}</span><p>Así se utiliza este ingrediente en tu catálogo.</p></div></div>
          <div class="stats-kpi-grid ingredient-stats-kpis"><div class="stats-kpi"><span>Platos relacionados</span><strong>{{ ingredientStatsData.dish_count }}</strong><small>en tu catálogo</small></div><div class="stats-kpi"><span>Usos estimados</span><strong>{{ ingredientStatsData.usage_total }}</strong><small>según tus menús</small></div><div class="stats-kpi"><span>Frecuencia</span><strong>{{ ingredientStatsData.frequency }}</strong><small>promedio</small></div><div class="stats-kpi"><span>Estado de compra</span><strong>{{ ingredientStatsData.excluded ? 'Excluido' : 'Activo' }}</strong><small>preferencia actual</small></div></div>
          <div class="stats-section"><div class="stats-section-heading"><h3>Platos donde aparece</h3><span>más utilizados primero</span></div><div v-if="ingredientStatsData.dishes.length" class="ingredient-stats-dishes"><div v-for="dish in ingredientStatsData.dishes" :key="dish.id" class="ingredient-stats-dish"><span class="ingredient-stats-dish-icon"><PhForkKnife :size="17" /></span><span>{{ dish.name }}</span><strong>{{ dish.times_used || 0 }} {{ dish.times_used === 1 ? 'uso' : 'usos' }}</strong></div></div><p v-else class="detail-empty ingredient-stats-empty">Todavía no está asociado a ningún plato.</p></div>
        </div>
        <div class="modal-footer ingredient-stats-footer"><button type="button" class="secondary-button" @click="closeIngredientStats">Cerrar</button><button type="button" class="primary-button" @click="closeIngredientStats">Volver al catálogo</button></div>
      </section>
    </dialog>

    <dialog
      v-if="dishIngredientsEditorOpen"
      v-modal="closeDishIngredients"
      class="modal-backdrop"
      @click.self="closeDishIngredients"
    >
      <form class="modal-card dish-ingredients-editor-card" @submit.prevent="saveDishIngredients">
        <div class="modal-header">
          <div>
            <p class="eyebrow">INGREDIENTES DEL PLATO</p>
            <h2>{{ dishIngredientsDish?.name }}</h2>
          </div>
          <button
            type="button"
            class="icon-button"
            aria-label="Cerrar"
            :disabled="dishIngredientsSaving || dishIngredientsGenerating"
            @click="closeDishIngredients"
          >
            <PhX :size="22" weight="regular" />
          </button>
        </div>
        <div class="dish-ingredients-editor-scroll">
          <p class="muted">
            Añádelos uno a uno o deja que la IA proponga una lista. Se guardarán para preparar tus
            próximas compras.
          </p>
          <div class="dish-ingredients-list">
            <label v-for="(_, index) in dishIngredientsDraft" :key="index" class="ingredient-row">
              <span>{{ index + 1 }}</span>
              <select
                v-select2="{
                  value: dishIngredientsDraft[index],
                  placeholder: 'Busca o escribe un ingrediente',
                  onChange: (value) => (dishIngredientsDraft[index] = value),
                }"
                :aria-label="`Ingrediente ${index + 1}`"
                class="ingredient-select"
              >
                <option
                  v-if="dishIngredientsDraft[index] && !hasIngredientSuggestion(dishIngredientsDraft[index])"
                  :value="dishIngredientsDraft[index]"
                >
                  {{ dishIngredientsDraft[index] }}
                </option>
                <option
                  v-for="ingredient in ingredientCatalog"
                  :key="ingredient.id || ingredient.name"
                  :value="ingredient.name"
                >
                  {{ ingredient.name }}
                </option>
              </select>
              <button
                type="button"
                class="icon-button ingredient-remove-button"
                aria-label="Eliminar ingrediente"
                @click="removeDishIngredient(index)"
              >
                <PhTrash :size="17" />
              </button>
            </label>
          </div>
          <button type="button" class="secondary-button add-ingredient-button" @click="addDishIngredient">
            <PhPlus :size="17" /> Añadir ingrediente
          </button>
        </div>
        <div class="modal-footer dish-ingredients-footer">
          <button
            type="button"
            class="secondary-button"
            :disabled="dishIngredientsSaving || dishIngredientsGenerating"
            @click="generateDishIngredients"
          >
            <PhSparkle :size="17" weight="fill" />
            {{ dishIngredientsGenerating ? 'Generando…' : 'Generar con IA' }}
          </button>
          <div>
            <button
              type="button"
              class="secondary-button"
              :disabled="dishIngredientsSaving || dishIngredientsGenerating"
              @click="closeDishIngredients"
            >
              Cancelar
            </button>
            <button type="submit" class="primary-button" :disabled="dishIngredientsSaving || dishIngredientsGenerating">
              {{ dishIngredientsSaving ? 'Guardando…' : 'Guardar ingredientes' }}
            </button>
          </div>
        </div>
      </form>
    </dialog>

    <dialog v-if="tupperEditorOpen" v-modal="closeTupperEditor" class="modal-backdrop" @click.self="closeTupperEditor">
      <form class="modal-card tupper-editor-card" @submit.prevent="saveTupper">
        <div class="modal-header">
          <div>
            <p class="eyebrow">{{ tupperDraft.id ? 'EDITAR TUPPER' : 'NUEVO TUPPER' }}</p>
            <h2>{{ tupperDraft.id ? 'Actualiza sus datos' : 'Añade algo a la nevera' }}</h2>
          </div>
          <button type="button" class="icon-button" aria-label="Cerrar" @click="closeTupperEditor">
            <PhX :size="22" weight="regular" />
          </button>
        </div>
        <div class="tupper-editor-scroll">
          <label class="field-label">Qué has guardado *<input v-model="tupperDraft.name" type="text" maxlength="100" placeholder="Ej.: Lentejas con verduras" autofocus /></label>
          <div class="tupper-form-grid">
            <label class="field-label">Raciones *<input v-model="tupperDraft.portions" type="number" min="1" max="99" step="1" inputmode="numeric" /></label>
            <label class="field-label">Dónde está <input v-model="tupperDraft.location" type="text" maxlength="60" placeholder="Ej.: Balda de arriba" /></label>
          </div>
          <div class="tupper-form-grid">
            <label class="field-label">Lo guardé el *<input v-model="tupperDraft.stored_at" type="date" required /></label>
            <label class="field-label">Caduca el *<input v-model="tupperDraft.expires_at" type="date" required /></label>
          </div>
          <label class="field-label">Nota <textarea v-model="tupperDraft.notes" rows="3" maxlength="240" placeholder="Ej.: descongelar la noche anterior"></textarea></label>
          <p class="tupper-form-hint"><PhCheckCircle :size="17" /> Se guarda en este navegador, asociado a tu cuenta.</p>
        </div>
        <div class="modal-footer">
          <button type="button" class="secondary-button" @click="closeTupperEditor">Cancelar</button>
          <button type="submit" class="primary-button">{{ tupperDraft.id ? 'Guardar cambios' : 'Guardar tupper' }}</button>
        </div>
      </form>
    </dialog>

    <dialog v-if="editorOpen" v-modal="closeEditor" class="modal-backdrop day-editor-backdrop" @click.self="closeEditor">
      <div class="modal-card day-editor-card">
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
        <div
          class="editor-scroll"
          :class="`meal-count-${enabledMeals.length}`"
        >
          <section
            v-if="dailyOptions.filter((option) => option.active).length"
            class="editor-options"
            aria-labelledby="day-conditions-title"
          >
            <div class="editor-section-heading">
              <div>
                <span class="editor-section-kicker">CONTEXTO</span>
                <strong id="day-conditions-title">Condiciones del día</strong>
              </div>
              <span class="editor-section-count"
                >{{ draftDay.option_ids.length }} seleccionadas</span
              >
            </div>
            <div class="option-check-list">
              <label
                v-for="option in dailyOptions.filter((item) => item.active)"
                :key="option.id"
                class="option-check"
              >
                <input
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
                >
              </label>
            </div>
          </section>
          <div v-for="meal in enabledMeals" :key="meal" class="editor-meal">
            <div class="editor-meal-heading">
              <span class="editor-meal-title">
                <span class="editor-meal-icon"
                  ><component
                    :is="mealIcons[meal]"
                    :size="19"
                    weight="regular"
                    aria-hidden="true" /></span
                ><span>
                  <strong>{{ mealLabels[meal] }}</strong>
                  <small>{{ mealDraftSummary(meal) }}</small>
                </span>
              </span>
              <button class="text-button meal-add-button" @click="addDish(meal)">
                <PhPlus :size="16" weight="regular" /> Añadir plato
              </button>
            </div>
            <div v-if="draftDay.meals[meal].items.length" class="editor-dishes">
              <div
                v-for="(_, itemIndex) in draftDay.meals[meal].items"
                :key="itemIndex"
                class="dish-input-row"
              >
                <select
                  v-select2="{
                    value: draftDay.meals[meal].items[itemIndex],
                    placeholder: `Busca o escribe un plato para ${mealLabels[meal].toLowerCase()}`,
                    onChange: (value) => (draftDay.meals[meal].items[itemIndex] = value),
                  }"
                  :aria-label="`Plato para ${mealLabels[meal].toLowerCase()}`"
                  class="dish-select"
                >
                  <option
                    v-if="draftDay.meals[meal].items[itemIndex] && !hasDishSuggestion(draftDay.meals[meal].items[itemIndex])"
                    :value="draftDay.meals[meal].items[itemIndex]"
                  >
                    {{ draftDay.meals[meal].items[itemIndex] }}
                  </option>
                  <option v-for="dish in dishes" :key="dish.id" :value="dish.name">{{ dish.name }}</option>
                </select><button
                  class="remove-button"
                  title="Quitar plato"
                  :aria-label="`Quitar plato ${itemIndex + 1} de ${mealLabels[meal].toLowerCase()}`"
                  @click="removeDish(meal, itemIndex)"
                >
                  <PhX :size="17" weight="regular" />
                </button>
              </div>
            </div>
            <details class="meal-more-options">
              <summary>
                <span class="more-options-summary-copy">
                  <span class="more-options-icon"><PhGear :size="16" weight="regular" /></span>
                  <span
                    ><strong>Avisos y nota</strong
                    ><small>{{ mealMoreOptionsSummary(meal) }}</small></span
                  >
                </span>
                <PhCaretDown :size="17" weight="bold" class="more-options-chevron" />
              </summary>
              <div class="more-options-content">
                <div class="more-options-section-heading">
                  <div>
                    <strong>Avisos</strong>
                    <small>Activa recordatorios para esta comida.</small>
                  </div>
                  <button
                    type="button"
                    class="add-alert-button compact-add-alert"
                    @click="addCustomAlert(meal)"
                  >
                    <PhPlus :size="15" weight="regular" /> Añadir aviso
                  </button>
                </div>
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
                        type="button"
                        class="send-alert-button"
                        :disabled="Boolean(sendingAlertKey) || saving"
                        @click="sendAlertNow(meal, alert)"
                      >
                        <PhLightning :size="14" weight="regular" />
                        {{
                          sendingAlertKey === alertActionKey(meal, alert)
                            ? 'Enviando…'
                            : 'Enviar ahora'
                        }}</button
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
                          placeholder="Texto del aviso"
                        /><span class="field-hint"
                          >Variables: %fecha · %platos · %comida · %aviso</span
                        ></label
                      ></template
                    >
                  </div>
                </div>
                <label class="field-label meal-note-field"
                  >Nota de la comida<span class="field-hint"
                    >Algo que quieras recordar solo para esta comida</span
                  ><textarea
                    v-model="draftDay.meals[meal].note"
                    rows="2"
                    placeholder="Ej.: dejar preparado la noche anterior"
                  ></textarea>
                </label>
              </div>
            </details>
          </div>
          <label class="field-label day-notes-field"
            >Notas del día<textarea
              v-model="draftDay.notes"
              rows="3"
              placeholder="Preparación, compras o recordatorios para todo el día"
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
          <div class="day-save-actions">
            <button class="secondary-button" :disabled="saving" @click="closeEditor">Cancelar</button>
            <button class="primary-button" :disabled="saving || remindingGroup" @click="saveDay">
              {{ saving ? 'Guardando…' : 'Guardar día' }}
            </button>
          </div>
        </div>
      </div>
    </dialog>

    <dialog
      v-if="rouletteOpen"
      v-modal="closeRoulette"
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
          <section class="calendar-export-settings settings-section-card">
            <div class="section-heading">
              <div>
                <p class="eyebrow">CALENDARIO</p>
                <h3>Horarios de tus comidas</h3>
              </div>
              <PhCalendarCheck :size="23" weight="duotone" aria-hidden="true" />
            </div>
            <p class="muted">
              Configura una hora para que el evento tenga duración. Si lo dejas vacío, se añadirá
              como evento de día completo.
            </p>
            <div class="meal-time-settings">
              <label v-for="meal in allMeals" :key="meal" class="field-label"
                >{{ mealLabels[meal] }}<input
                  v-model="preferences[`${meal}_time`]"
                  type="time"
                  :aria-label="`Hora de ${mealLabels[meal].toLowerCase()}`"
              /></label>
            </div>
            <button
              v-if="!calendarFeedLink"
              type="button"
              class="secondary-button calendar-export-button"
              :disabled="calendarFeedLoading"
              @click="loadCalendarFeedLink"
            >
              <PhCalendarCheck :size="18" />
              {{ calendarFeedLoading ? 'Preparando enlace…' : 'Crear enlace para mi calendario' }}
            </button>
            <div v-else class="calendar-feed-link-box">
              <label class="field-label"
                >Enlace privado del calendario<input :value="calendarFeedLink" readonly
              /></label>
              <div class="calendar-feed-actions">
                <button type="button" class="secondary-button" @click="copyCalendarFeedLink">
                  Copiar enlace
                </button>
                <a class="primary-button" :href="calendarFeedLink" target="_blank" rel="noreferrer"
                  >Abrir enlace</a
                >
              </div>
            </div>
            <small class="settings-note calendar-export-note"
              >Añade este enlace como calendario suscrito. Se actualizará con tus cambios durante
              los próximos 12 meses.</small
            >
          </section>
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
            <button class="text-button" @click="openNewAlert">Nuevo</button>
          </div>
          <p class="muted">
            Crea avisos reutilizables y decide en qué comidas aparecen por defecto.
          </p>
          <div class="alert-admin-list">
            <template v-for="entry in alertAccordionItems" :key="entry.id">
              <div
                class="alert-admin-row"
                :class="{ 'alert-admin-row-open': alertEditorOpen === entry.id }"
              >
                <span class="alert-admin-icon" aria-hidden="true">
                  <PhPlus v-if="entry.id === 'new'" :size="20" weight="regular" />
                  <component v-else :is="alertIcon(entry.alert)" :size="20" weight="regular" />
                </span>
                <div class="alert-admin-title">
                  <strong>{{ entry.id === 'new' ? 'Nuevo aviso' : entry.alert.name }}</strong
                  ><small v-if="entry.alert"
                    >{{ entry.alert.time }} · {{ alertDayOffsetLabel(entry.alert.day_offset) }} ·
                    {{
                      entry.alert.scope === 'all'
                        ? 'Todas las comidas'
                        : mealLabels[entry.alert.scope]
                    }}<span v-if="entry.alert.default_enabled"> · Activo por defecto</span></small
                  ><small v-else>Configura un aviso reutilizable</small>
                </div>
                <button
                  class="text-button"
                  :aria-expanded="alertEditorOpen === entry.id"
                  @click="entry.id === 'new' ? closeAlertEditor() : toggleAlertEditor(entry.alert)"
                >
                  {{
                    alertEditorOpen === entry.id
                      ? 'Cerrar'
                      : entry.id === 'new'
                        ? 'Nuevo'
                        : 'Editar'
                  }}
                </button>
                <button
                  v-if="entry.alert"
                  class="remove-button"
                  title="Borrar aviso"
                  @click="deleteAlert(entry.alert.id)"
                >
                  <PhX :size="16" weight="regular" />
                </button>
              </div>
              <div v-if="alertEditorOpen === entry.id" class="alert-accordion-panel">
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
                    <p class="alert-variable-hint">
                      Variables disponibles: <code>%fecha</code>, <code>%platos</code>,
                      <code>%comida</code> y <code>%aviso</code>.
                    </p>
                  </div>
                  <div class="alert-form-row">
                    <label class="field-label"
                      >Hora<input v-model="alertDraft.time" type="time" /></label
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
                      >Orden<input
                        v-model.number="alertDraft.order"
                        type="number"
                        min="0"
                        max="9999"
                    /></label>
                  </div>
                  <button class="primary-button" :disabled="saving" @click="saveAlert">
                    {{ alertDraft.id ? 'Actualizar aviso' : 'Crear aviso' }}
                  </button>
                </div>
              </div>
            </template>
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
          <form v-if="group" class="group-supermarket-card" @submit.prevent="saveGroupSupermarket">
            <div class="group-supermarket-copy">
              <p class="eyebrow">COMPRA</p>
              <h4>Supermercado por defecto</h4>
              <span>{{ isGroupOwner ? 'Los ingredientes usarán este supermercado salvo que les asignes otro.' : 'Los ingredientes del grupo parten de este supermercado.' }}</span>
            </div>
            <label class="supermarket-select group-supermarket-select">
              <img :class="{ 'supermarket-logo-dark': isDarkSupermarketLogo(group.default_supermarket) }" :src="supermarketLogo(group.default_supermarket)" :alt="`Logo de ${group.default_supermarket?.name || 'supermercado'}`" />
              <select v-model.number="group.default_supermarket_id" :disabled="!isGroupOwner" aria-label="Supermercado por defecto del grupo">
                <option v-for="supermarket in supermarkets" :key="supermarket.id" :value="supermarket.id">{{ supermarket.name }}</option>
              </select>
            </label>
            <button v-if="isGroupOwner" type="submit" class="secondary-button" :disabled="saving">Guardar</button>
          </form>
          <div class="group-code">
            <code>{{ group.invite_code }}</code
            ><button class="secondary-button" @click="copyInviteLink">Copiar enlace</button>
          </div>
          <form v-if="isGroupOwner" class="inline-form" @submit.prevent="inviteMember">
            <input v-model="inviteEmail" aria-label="Correo electrónico de la persona a invitar" autocomplete="email" type="email" placeholder="Email para invitar" /><button
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
            <input v-model="joinCode" aria-label="Código de invitación al grupo" autocapitalize="characters" spellcheck="false" maxlength="8" placeholder="Código de otro grupo" /><button
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

    </main>

    <dialog
      v-if="error && !isShopping"
      v-modal="closeErrorModal"
      class="modal-backdrop error-backdrop"
      @click.self="closeErrorModal"
    >
      <div class="modal-card error-modal">
        <div class="modal-header">
          <div class="error-modal-heading">
            <div class="error-modal-icon"><PhWarningCircle :size="24" /></div>
            <div>
              <p class="eyebrow">ERROR</p>
              <h2>No se ha podido completar la acción</h2>
            </div>
          </div>
          <button
            type="button"
            class="icon-button"
            aria-label="Cerrar error"
            @click="closeErrorModal"
          >
            <PhX :size="22" />
          </button>
        </div>
        <p class="error-modal-message">{{ error }}</p>
        <div class="modal-footer">
          <button type="button" class="secondary-button" @click="closeErrorModal">Cerrar</button>
        </div>
      </div>
    </dialog>

    <dialog
      v-if="calendarDetailOpen"
      v-modal="() => { calendarDetailOpen = false }"
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
  </div>
</template>
