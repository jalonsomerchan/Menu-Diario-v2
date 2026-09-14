import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', name: 'dashboard' },
    { path: '/platos', name: 'dishes' },
    { path: '/calendario', name: 'calendar' },
    { path: '/ajustes', name: 'settings' },
    { path: '/compartir/:token', name: 'shared-day' },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
})

export default router
