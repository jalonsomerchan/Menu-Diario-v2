import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import 'select2/dist/css/select2.css'
import './styles.css'
import './usability.css'
import { registerServiceWorker } from './pwa'

const app = createApp(App)

app.use(createPinia())
app.use(router)

app.mount('#app')

registerServiceWorker()
