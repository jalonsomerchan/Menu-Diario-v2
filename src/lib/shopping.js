// Match complete names, never the position of a dish in a list.
export function shoppingName(value) {
  return String(value || '')
    .trim()
    .replace(/\s+/g, ' ')
    .toLocaleLowerCase('es')
    .normalize('NFC')
}

export function shoppingCatalog(dishes) {
  const catalog = new Map()
  const priority = (dish) =>
    Number(Boolean(dish.is_mine)) * 4 +
    Number(Boolean(dish.ingredients?.length)) * 2 +
    Number(!dish.group_photo_only)
  for (const dish of dishes) {
    const key = shoppingName(dish.name)
    if (!key) continue
    const current = catalog.get(key)
    if (!current || priority(dish) > priority(current)) catalog.set(key, dish)
  }
  return catalog
}

export function buildShoppingList(selectedDishes, dishes, ingredients, defaultSupermarket) {
  const catalog = shoppingCatalog(dishes)
  const ingredientCatalog = new Map(ingredients.map((item) => [shoppingName(item.name), item]))
  const items = new Map()
  const excluded = new Map()
  const missing = new Map()
  for (const selection of selectedDishes) {
    const name = selection.dish
    const dish = catalog.get(shoppingName(name))
    const purchased = dish?.type === 'purchased'
    const names = purchased ? [name] : dish?.ingredients || []
    if (!names.some((ingredient) => shoppingName(ingredient))) {
      missing.set(shoppingName(name), { name, dish })
      continue
    }
    for (const ingredient of names) {
      const key = shoppingName(ingredient)
      if (!key) continue
      const saved = purchased ? null : ingredientCatalog.get(key)
      const target = saved?.exclude_from_shopping ? excluded : items
      if (!target.has(key))
        target.set(key, {
          key,
          name: saved?.name || String(ingredient).trim(),
          dishes: [],
          supermarket: saved?.supermarket || defaultSupermarket || { id: 0, name: 'Supermercado' },
        })
      const item = target.get(key)
      if (!item.dishes.includes(name)) item.dishes.push(name)
    }
  }
  const sort = (values) => [...values].sort((a, b) => a.name.localeCompare(b.name, 'es'))
  return {
    items: sort(items.values()),
    excludedItems: sort(excluded.values()),
    missingDishes: [...missing.values()],
  }
}

export function reconcileShoppingSelection(available, previousAvailable, selected, initialized) {
  const previous = new Set(previousAvailable.map((dish) => dish.key))
  return new Set(
    available
      .filter((dish) => !initialized || selected.has(dish.key) || !previous.has(dish.key))
      .map((dish) => dish.key),
  )
}
