// Native modal dialogs provide focus containment and make the background inert.
// Keep dismissal in Vue so each editor can protect an in-progress save.
let nextTitleId = 0
const sessions = new WeakMap()

export const vModal = {
  mounted(element, binding) {
    const opener = document.activeElement
    const heading = element.querySelector('h2')
    if (heading) {
      heading.id ||= `modal-title-${++nextTitleId}`
      element.setAttribute('aria-labelledby', heading.id)
    }
    const session = { opener, dismiss: binding.value }
    session.cancel = (event) => {
      event.preventDefault()
      session.dismiss?.()
    }
    sessions.set(element, session)
    element.addEventListener('cancel', session.cancel)
    element.showModal()
  },
  updated(element, binding) {
    sessions.get(element).dismiss = binding.value
  },
  beforeUnmount(element) {
    const session = sessions.get(element)
    element.removeEventListener('cancel', session.cancel)
    element.close()
    if (session.opener?.isConnected) session.opener.focus({ preventScroll: true })
    sessions.delete(element)
  },
}
