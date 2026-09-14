const firebaseVersion = '12.6.0'

const config = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || import.meta.env.PUBLIC_FIREBASE_API_KEY || '',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || import.meta.env.PUBLIC_FIREBASE_AUTH_DOMAIN || '',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || import.meta.env.PUBLIC_FIREBASE_PROJECT_ID || 'alonsoftware',
  appId: import.meta.env.VITE_FIREBASE_APP_ID || import.meta.env.PUBLIC_FIREBASE_APP_ID || '',
}

let appPromise
let authPromise

function importFirebaseModule(name) {
  return import(/* @vite-ignore */ `https://www.gstatic.com/firebasejs/${firebaseVersion}/firebase-${name}.js`)
}

export function hasFirebaseConfig() {
  return Boolean(config.apiKey && config.authDomain && config.projectId && config.appId)
}

export async function getFirebaseAuth() {
  if (!hasFirebaseConfig()) throw new Error('Falta la configuración pública de Firebase.')
  appPromise ||= importFirebaseModule('app').then((module) => module.initializeApp(config))
  authPromise ||= Promise.all([appPromise, importFirebaseModule('auth')]).then(([app, authModule]) => ({
    auth: authModule.getAuth(app),
    authModule,
  }))
  return authPromise
}

export async function signInWithGoogle() {
  const { auth, authModule } = await getFirebaseAuth()
  const provider = new authModule.GoogleAuthProvider()
  provider.setCustomParameters({ prompt: 'select_account' })
  return authModule.signInWithPopup(auth, provider)
}

export async function signOut() {
  const { auth, authModule } = await getFirebaseAuth()
  return authModule.signOut(auth)
}

export async function observeAuth(callback) {
  const { auth, authModule } = await getFirebaseAuth()
  return authModule.onAuthStateChanged(auth, callback)
}
