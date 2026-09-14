# Menu Diario

Aplicación Vue 3 + Vite para planificar las comidas.

## Recommended IDE Setup

[VS Code](https://code.visualstudio.com/) + [Vue (Official)](https://marketplace.visualstudio.com/items?itemName=Vue.volar) (and disable Vetur).

## Recommended Browser Setup

- Chromium-based browsers (Chrome, Edge, Brave, etc.):
  - [Vue.js devtools](https://chromewebstore.google.com/detail/vuejs-devtools/nhdogjmejiglipccpnnnanhbledajbpd)
  - [Turn on Custom Object Formatter in Chrome DevTools](http://bit.ly/object-formatters)
- Firefox:
  - [Vue.js devtools](https://addons.mozilla.org/en-US/firefox/addon/vue-js-devtools/)
  - [Turn on Custom Object Formatter in Firefox DevTools](https://fxdx.dev/firefox-devtools-custom-object-formatters/)

## Customize configuration

See [Vite Configuration Reference](https://vite.dev/config/).

## Project Setup

```sh
npm install
```

### Compile and Hot-Reload for Development

```sh
npm run dev
```

### Compile and Minify for Production

```sh
npm run build
```

### Lint with [ESLint](https://eslint.org/)

```sh
npm run lint
```

## PWA

La aplicación incluye manifest, iconos instalables, service worker para la shell offline y metadatos para iOS/Android. Para probar la instalación en local, genera una build y sirve `dist` con `npm run preview`; la instalación requiere HTTPS o `localhost`.

## Despliegue en GitHub Pages

El workflow de [GitHub Actions](.github/workflows/deploy.yml) publica automáticamente la carpeta `dist` en GitHub Pages cada vez que se actualiza `main`. La configuración detecta automáticamente el nombre del repositorio para usar la base `/Menu-Diario-v2/` y genera `404.html` para mantener funcionando las rutas de Vue Router.

En el repositorio, configura estos secretos en `Settings → Secrets and variables → Actions` para activar el acceso con Google en producción:

- `VITE_FIREBASE_API_KEY`
- `VITE_FIREBASE_AUTH_DOMAIN`
- `VITE_FIREBASE_PROJECT_ID`
- `VITE_FIREBASE_APP_ID`

Opcionalmente, crea la variable `VITE_API_BASE` si la API no es `https://alon.one/api`. En `Settings → Pages`, selecciona **GitHub Actions** como método de publicación.
