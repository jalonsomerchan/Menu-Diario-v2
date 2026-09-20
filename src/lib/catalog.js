export function filterAndSortDishes(
  dishes,
  { query, filter, favoritesOnly, sort, categories, categoryId, categoryLabel },
) {
  const normalizedQuery = query.trim().toLocaleLowerCase('es')
  return [...dishes]
    .filter(
      (dish) =>
        (!favoritesOnly || dish.is_favorite) &&
        (filter !== 'favorites' || dish.is_favorite) &&
        (filter !== 'with-ingredients' || dish.ingredients?.length) &&
        (filter !== 'used' || Number(dish.times_used || 0) > 0) &&
        (!categories.some((category) => category.id === filter) || categoryId(dish) === filter) &&
        (!normalizedQuery ||
          `${dish.name} ${categoryLabel(dish)} ${(dish.ingredients || []).join(' ')}`
            .toLocaleLowerCase('es')
            .includes(normalizedQuery)),
    )
    .sort((a, b) => {
      if (sort === 'name') return a.name.localeCompare(b.name, 'es')
      if (sort === 'recent')
        return String(b.last_used_at || '').localeCompare(String(a.last_used_at || ''))
      return (
        Number(b.is_favorite) - Number(a.is_favorite) ||
        Number(b.times_used || 0) - Number(a.times_used || 0) ||
        a.name.localeCompare(b.name, 'es')
      )
    })
}

export function filterAndSortIngredients(ingredients, { query, filter, sort }) {
  const normalizedQuery = query.trim().toLocaleLowerCase('es')
  return [...ingredients]
    .filter((ingredient) => {
      const dishCount = Number(ingredient.dish_count || 0)
      if (filter === 'used' && dishCount === 0) return false
      if (filter === 'unused' && dishCount > 0) return false
      if (filter === 'excluded' && !ingredient.exclude_from_shopping) return false
      return !normalizedQuery || ingredient.name.toLocaleLowerCase('es').includes(normalizedQuery)
    })
    .sort((a, b) =>
      sort === 'usage'
        ? Number(b.dish_count || 0) - Number(a.dish_count || 0) ||
          a.name.localeCompare(b.name, 'es')
        : a.name.localeCompare(b.name, 'es'),
    )
}

export function pagination(items, page, perPage) {
  const pageCount = Math.max(1, Math.ceil(items.length / perPage))
  const start = (page - 1) * perPage
  return {
    pageCount,
    items: items.slice(start, start + perPage),
    first: items.length ? start + 1 : 0,
    last: Math.min(page * perPage, items.length),
    pages: Array.from({ length: pageCount }, (_, index) => index + 1).slice(0, 5),
  }
}
