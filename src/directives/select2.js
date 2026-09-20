import $ from 'jquery'
import select2 from 'select2'

select2(window, $)

const instances = new WeakMap()
const language = { noResults: () => 'No hay coincidencias', searching: () => 'Buscando…' }

/** Bridges Vue state with Select2 while keeping picker behaviour consistent on touch devices. */
export const vSelect2 = {
  mounted(element, binding) {
    const $element = $(element)
    const instance = { $element, state: binding.value, change: null }
    instance.change = () => instance.state.onChange($element.val() || '')
    $element.select2({
      tags: true,
      width: '100%',
      placeholder: instance.state.placeholder,
      dropdownParent: $element.closest('.modal-card'),
      language,
    })
    $element.on('change.select2-menu-diario', instance.change)
    $element.val(instance.state.value || null).trigger('change.select2')
    instances.set(element, instance)
  },
  updated(element, binding) {
    const instance = instances.get(element)
    if (!instance) return
    instance.state = binding.value
    const nextValue = binding.value.value || null
    if (($.trim(instance.$element.val() || '') || null) !== nextValue)
      instance.$element.val(nextValue).trigger('change.select2')
  },
  unmounted(element) {
    const instance = instances.get(element)
    if (!instance) return
    instance.$element.off('change.select2-menu-diario', instance.change)
    instance.$element.select2('destroy')
    instances.delete(element)
  },
}
