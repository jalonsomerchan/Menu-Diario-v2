import {
  PhBarbell,
  PhBell,
  PhCalendarCheck,
  PhChefHat,
  PhClock,
  PhCoffee,
  PhCookingPot,
  PhForkKnife,
  PhLeaf,
  PhLightning,
  PhListChecks,
  PhMoon,
  PhNote,
  PhShoppingCart,
  PhSmiley,
  PhStar,
  PhSun,
  PhTag,
  PhUsers,
  PhWarningCircle,
  PhAlarm,
} from '@phosphor-icons/vue'

export const mealLabels = { breakfast: 'Desayuno', lunch: 'Comida', dinner: 'Cena' }
export const allMeals = ['breakfast', 'lunch', 'dinner']
export const mealIcons = { breakfast: PhCoffee, lunch: PhForkKnife, dinner: PhMoon }
export const dishTypes = [
  { id: 'home', label: 'Plato casero' },
  { id: 'purchased', label: 'Plato comprado' },
]
export const dishCategories = [
  { id: 'cold', label: 'Plato frío' },
  { id: 'hot', label: 'Plato caliente' },
  { id: 'dessert', label: 'Postre' },
  { id: 'breakfast', label: 'Desayuno' },
  { id: 'other', label: 'Otros' },
]
export const optionIcons = {
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
export const optionIconOptions = [
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
export const notificationTypes = [
  { id: 'meal_added', label: 'Comidas añadidas' },
  { id: 'meal_updated', label: 'Comidas modificadas' },
  { id: 'meal_moved', label: 'Comidas movidas' },
  { id: 'group', label: 'Actividad del grupo' },
  { id: 'reminder', label: 'Recordatorios programados' },
]
export const taskStatuses = [
  { id: 'pending', label: 'Pendiente' },
  { id: 'parked', label: 'Aparcada' },
  { id: 'completed', label: 'Completada' },
  { id: 'cancelled', label: 'Cancelada' },
]
export const taskImportances = [
  { id: 'low', label: 'Baja' },
  { id: 'medium', label: 'Media' },
  { id: 'high', label: 'Alta' },
]
export const alertIconOptions = [
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
