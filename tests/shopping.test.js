import test from 'node:test'
import assert from 'node:assert/strict'
import {
  buildShoppingList,
  reconcileShoppingSelection,
  shoppingCatalog,
} from '../src/lib/shopping.js'

const store = { id: 1, name: 'Mercadona' }
const otherStore = { id: 2, name: 'Lidl' }
const dishes = [
  { id: 1, name: 'Lentejas', is_mine: true, ingredients: ['Lentejas', 'Cebolla', 'Sal'] },
  { id: 2, name: 'Tortilla', is_mine: true, ingredients: ['Patatas', ' cebolla '] },
  { id: 3, name: 'Pizza preparada', type: 'purchased', ingredients: [] },
  { id: 4, name: 'Crema', ingredients: [] },
  { id: 5, name: 'Lentejas', ingredients: [] },
]
const ingredients = [
  { name: 'Cebolla', supermarket: otherStore },
  { name: 'Sal', exclude_from_shopping: true },
]
const selection = (name, key = name) => ({ dish: name, key })
const list = (names) =>
  buildShoppingList(
    names.map((name) => selection(name)),
    dishes,
    ingredients,
    store,
  )

test('only selected dishes contribute ingredients; common ingredients merge with sources and store', () => {
  const result = list(['Lentejas', 'Tortilla'])
  assert.deepEqual(
    result.items.map((item) => item.name),
    ['Cebolla', 'Lentejas', 'Patatas'],
  )
  assert.deepEqual(result.items[0].dishes, ['Lentejas', 'Tortilla'])
  assert.equal(result.items[0].supermarket.id, 2)
  assert.deepEqual(
    result.excludedItems.map((item) => item.name),
    ['Sal'],
  )
  assert.deepEqual(list(['Tortilla']).excludedItems, [])
  assert.deepEqual(
    list(['Tortilla']).items.map((item) => item.name),
    ['Cebolla', 'Patatas'],
  )
})
test('own catalog entry wins over a same-name group/global dish regardless of input order', () => {
  assert.equal(shoppingCatalog(dishes).get('lentejas').id, 1)
  assert.equal(shoppingCatalog([...dishes].reverse()).get('lentejas').id, 1)
})
test('purchased dishes add the product directly, missing or unknown dishes remain explicit', () => {
  const result = list(['Pizza preparada', 'Crema', 'Plato nuevo'])
  assert.deepEqual(
    result.items.map((item) => item.name),
    ['Pizza preparada'],
  )
  assert.deepEqual(
    result.missingDishes.map((item) => item.name),
    ['Crema', 'Plato nuevo'],
  )
})
test('empty selection clears regular, excluded and missing ingredients', () => {
  assert.deepEqual(list([]), { items: [], excludedItems: [], missingDishes: [] })
})
test('repeated menu dishes merge products without duplicating source names', () => {
  assert.deepEqual(list(['Lentejas', 'Lentejas']).items[0].dishes, ['Lentejas'])
  assert.equal(list(['Crema', 'Crema']).missingDishes.length, 1)
})
test('refresh preserves manual deselection, drops old keys and selects new dishes', () => {
  const before = [selection('A'), selection('B'), selection('C')]
  const after = [selection('B'), selection('A'), selection('D')]
  assert.deepEqual(
    [...reconcileShoppingSelection(after, before, new Set(['A', 'C']), true)],
    ['A', 'D'],
  )
  assert.equal(reconcileShoppingSelection(after, [], new Set(), false).size, 3)
})
