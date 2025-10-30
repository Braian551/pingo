# 🚀 Firebase CI/CD Setup

## ✅ Estado Actual

- ✅ **Firebase SDK**: Configurado en `android/`
- ✅ **Keystore**: `android/release-keystore.jks` (contraseña: `Braian8052`)
- ✅ **GitHub Actions**: Workflow actualizado para usar Firebase Token
- ✅ **Firebase Token**: Generado exitosamente

## 🔑 Paso 1: Generar Token Firebase CI

### Opción A: En tu máquina local (Recomendado)

1. **Instalar Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Generar token**:
   ```bash
   firebase login:ci
   ```

3. **Autenticación**: Se abre el navegador, inicia sesión con Google

4. **Copiar token**: Firebase te da un token largo (ej: `1/ABC123...`)

### Opción B: Si hay problemas con Node.js

```bash
# Usar npx para evitar problemas de versión
npx firebase-tools@latest login:ci
```

## 🔐 Paso 2: Configurar Secretos en GitHub

Ve a tu repositorio en GitHub:

1. **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret**

## 🔑 Paso 1: Generar Token Firebase CI

### Opción A: En tu máquina local (Recomendado)

1. **Instalar Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Generar token**:
   ```bash
   firebase login:ci
   ```

3. **Autenticación**: Se abre el navegador, inicia sesión con Google

4. **Copiar token**: Firebase te da un token largo (ej: `1/ABC123...`)

### Opción B: Si hay problemas con Node.js

```bash
# Usar npx para evitar problemas de versión
npx firebase-tools@latest login:ci
```

## 🔐 Paso 2: Configurar Secretos en GitHub

Ve a tu repositorio en GitHub:

1. **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret**

### 📄 Valores Específicos para tu proyecto:

| Nombre | Valor | Descripción |
|--------|-------|-------------|
| `FIREBASE_APP_ID` | `1:608568990460:android:ffc242ecae35c28d17d579` | ID de tu app Firebase |
| `FIREBASE_TOKEN` | *Genera con `firebase login:ci`* | Token de autenticación CI |
| `GOOGLE_SERVICES_JSON_BASE64` | `ewogICJwcm9qZWN0X2luZm8iOiB7CiAgICAicHJvamVjdF9udW1iZXIiOiAiNjA4NTY4OTkwNDYwIiwKICAgICJwcm9qZWN0X2lkIjogInBpbmctZ28tOGEzZGYiLAogICAgInN0b3JhZ2VfYnVja2V0IjogInBpbmctZ28tOGEzZGYuZmlyZWJhc2VzdG9yYWdlLmFwcCIKICB9LAogICJjbGllbnQiOiBbCiAgICB7CiAgICAgICJjbGllbnRfaW5mbyI6IHsKICAgICAgICAibW9iaWxlc2RrX2FwcF9pZCI6ICIxOjYwODU2ODk5MDQ2MDphbmRyb2lkOmZmYzI0MmVjYWUzNWMyOGQxN2Q1NzkiLAogICAgICAgICJhbmRyb2lkX2NsaWVudF9pbmZvIjogewogICAgICAgICAgInBhY2thZ2VfbmFtZSI6ICJjb20uZXhhbXBsZS5waW5nX2dvIgogICAgICAgIH0KICAgICAgfSwKICAgICAgIm9hdXRoX2NsaWVudCI6IFtdLAogICAgICAiYXBpX2tleSI6IFsKICAgICAgICB7CiAgICAgICAgICAiY3VycmVudF9rZXkiOiAiQUl6YVN5RE9yaW54cUE2SDFEN1paTmxGN2ZKcHQ0ekYydEs4blZjIgogICAgICAgIH0KICAgICAgXSwKICAgICAgInNlcnZpY2VzIjogewogICAgICAgICJhcHBpbnZpdGVfc2VydmljZSI6IHsKICAgICAgICAgICJvdGhlcl9wbGF0Zm9ybV9vYXV0aF9jbGllbnQiOiBbXQogICAgICAgIH0KICAgICAgfQogICAgfQogIF0sCiAgImNvbmZpZ3VyYXRpb25fdmVyc2lvbiI6ICIxIgp9` | google-services.json en base64 |
| `KEYSTORE_BASE64` | `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` | keystore .jks en base64 |
| `KEYSTORE_PASSWORD` | `Braian8052` | Contraseña del keystore |
| `KEY_ALIAS` | `key_alias` | Alias de la clave |
| `KEY_PASSWORD` | `Braian8052` | Contraseña de la clave |

### 📄 Valores Base64 (Copiar y pegar):

| Nombre | Valor | Descripción |
|--------|-------|-------------|
| `FIREBASE_APP_ID` | `1:608568990460:android:ffc242ecae35c28d17d579` | ID de tu app Firebase |
| `FIREBASE_SERVICE_ACCOUNT_KEY` | *Ver abajo* | Service Account JSON completo |
| `GOOGLE_SERVICES_JSON_BASE64` | *Ver arriba* | google-services.json en base64 |
| `KEYSTORE_BASE64` | *Ver arriba* | release-keystore.jks en base64 |
| `KEYSTORE_PASSWORD` | `Braian8052` | Contraseña del keystore |
| `KEY_ALIAS` | `key_alias` | Alias de la clave |
| `KEY_PASSWORD` | `Braian8052` | Contraseña de la clave |

### 📄 **FIREBASE_SERVICE_ACCOUNT_KEY (JSON COMPLETO):**
```
ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQiOiAicGluZy1nby04YTNkZiIsCiAgInByaXZhdGVfa2V5X2lkIjogIjI3M2E0NWE0ZmQ5Y2VlNjY5YTQwNjkwZmRjMTA4Y2EwZWI3OWM0ZjkiLAogICJwcml2YXRlX2tleSI6ICItLS0tLUJFR0lOIFBSSVZBVEUgS0VZLS0tLS1cbk1JSUV2Z0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktnd2dnU2tBZ0VBQW9JQkFRRGVZR1JWN3lPSzZtbm9cblVTNVNxT2JjZUkycVUvU0JJYlFVRmtyalluUXJUUUFtVVZyL0ZrVTM4YyswaDFLYm5kY1pnNDRkRmtvblB3WXhcbnowTTFJcVFKMlp4U0c5a2JTSTc0UW0wNFkzd3JnZW4zaU0ycloxdmxBYzlPbEdLMmdBSWQ0dENnMkk2L1ZKN1ZcbnFKUGJoVEZRMUphTUM1MmFUVWRZZnhRSHBqK1czWERXNVNhK2RMMlkvWJh4SWlNNmcwTklqZ21hQnVhNlZ6alFcbnIvVkNOdTQ5VEM3djBWbjFkUGxkSHUwWEVjUlYxb0w2dUFBQTZPa0ZLejlFcGxCZ3YvQWpvREFuTWZZOGYvZHdcbjNwT1IwNGRSalV0Zk9oSW0wa2J0b2RNUGVVQlUyV1g2UnNyT1NGTElPV3lpTXUraGZXOWx3cEYvbTdtMWNoS3JcbmdnWG9rNUdEQWdNQkFBRUNnZ0VBRWNwT1hKMmNEMUgvbFFsaGxsVlMydEorS3VFNmoxWWQ3UGwzbGtkYkdkZTRcbktsaVoyZ3h6RHkyMk96QVVTTVRRMzRhcHlPUHVuTU1yQUxNZklsSWFJM3VZU08xWGFocGM3Ym1LdVZja0tPcmtcbng5dlc4RjU5ZUkyemd3clY5dG00MGFGQ3BZdU5wL3JpRmgrOWJITjBaWTRNV1RuWXF1NkJ4YStzNzR1NlRKeFdcbmJJVjRhczcyUUpIUWswbnhvVGtvUkJIVStXb3IzbUtmd1pUQjZTL3lpMzJhQW9qUDlOTVZnMXVOSGltVXJnd3JcbmZFNWlIWlZKQmtwdFRQenpwc1A4OVZ2RS9Nd1M0dkFza1hCQXFRTWtQS3pmZkUvZTM2aXNMNzY1VHZTbW5KY2JcbjdKdW82cVVWRTdPaXhCZ0tCaGJyOXdRWWtXYm5wTStyeXlxQWpPaFZhUUtCZ1FEdXExRVY1T3FXWkcxR2ZTMktcbmJNVTZqY0ZWbEJSMjhBMjUxaTY3aTl0NnVRbDdvYVR2Y090NWxLbXlDUTB3L0hlME9UbFQrczlNWWtueGgvSHRcbjFwMUZRNWN0SVJ0UnlVNzBuZHpYMnpBbVZiZk1RVFV0bHpLcS9SY3psdjVoWUIzRk1neWRBSUlMYklhdzRsM3hcbmdncE5ORzBRL0p2cGpLYlBLd1VVM2FyNjl3S0JnUUR1aGpUYkxONXM5QUxqT0ZsVXV3MU9KbzVaVnVVa1UwV0lcbnUrSXIvcURNZFVOMUMxYUhvdWZSQW5ZV0cxQkQ0SHRrN0tvTy8zQ2tCNk1SdFY1RmpOYW9SVGZSN01zR1dQZm9cblZJRTNPNXFUNjFNMzNwL1AxU0Jmbml5NTJsVE9sbENyK2pLVnlsdFA5bGpxN2U4b2Y1ZkFUQytWYnljRTI0akhcbjFML0FNaExPMVFLQmdEMzIzcE4zbm13ellLZVhZbFo1RE8rNTFBTWE4Z0U3SytVZXRYMWR2enJxaFlyQ21lYk1cbmcyWktjWkJXaDBVN2x2eUVpdHpCMWtZM2tva1J5WDc5WkZHU1RkS2FzTlFZRnRhdGthTzlOWkFPV3l5OWxVZmpcbjVIUytSdUxQQmZaVUZRYVlpdXZNTVBjMFV2ZmpuWTVSTzhsMW5nZDEvaWl4cXJGSXN3WUsweFJiQW9HQkFPR0tcbndkd2w5MFNyRHpmd0JuaGFUMkNBa01YbHB0TE1jc215YjFFT2V0b2FYK2tEQ1pWRDgxUHRzZCtCZ0VwT3NCOWtcbnNnRndoUUIxd0RwMGQybm9uT21NV2hZRWhJM0IvdGtQWHdmdE1tT0FkN1l5cW9jSmpvMGJza3NqS21JV1BMNEJcbjNXZEthMEdYUGNrWHA3ZHh2dnEwajZJTDhxZGpOMWxOME90WjdmTHBBb0dCQUtNdWFLSitmTU5vTWJ4OVhwV2RcbnoxV3hIRzFXM3p2dmpjbFZ2eTk5RW5DbkkzZUx0OWh6ejVUdThSZ0tGNGMwZVQ0dGpJcncveWNOcnN3Rkt0cXVcbnNqSVprbUlvNTRQTXp4V0ZnNGlMRTB2QWtqWlJkNlkxcFljdC9RMXpFMGt4ejZmWDNMREtBM2tWMHZwaVpBNEFcbnZEaThPd2xkeFdZMEVtU0gxam1JSUQwdFxuLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLVxuIiwKICAiY2xpZW50X2VtYWlsIjogImZpcmViYXNlLWFkbWluc2RrLWZic3ZjQHBpbmctZ28tOGEzZGYuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20iLAogICJjbGllbnRfaWQiOiAiMTAwODk4ODc3NTk2MTE3MzE3MjU5IiwKICAiYXV0aF91cmkiOiAiaHR0cHM6Ly9hY2NvdW50cy5nb29nbGUuY29tL28vb2F1dGgyL2F1dGgiLAogICJ0b2tlbl91cmkiOiAiaHR0cHM6Ly9vYXV0aDIuZ29vZ2xlYXBpcy5jb20vdG9rZW4iLAogICJhdXRoX3Byb3ZpZGVyX3g1MDlfY2VydF91cmwiOiAiaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vb2F1dGgyL3YxL2NlcnRzIiwKICAiY2xpZW50X3g1MDlfY2VydF91cmwiOiAiaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vcm9ib3QvdjEvbWV0YWRhdGEveDUwOS9maXJlYmFzZS1hZG1pbnNkay1mYnN2YyU0MHBpbmctZ28tOGEzZGYuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20iLAogICJ1bml2ZXJzZV9kb21haW4iOiAiZ29vZ2xlYXBpcy5jb20iCn0K
```

## 🎯 Paso 3: Crear Grupo de Testers

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto → **App Distribution**
3. **Testers & Groups** → **Crear grupo**
4. Nombre: `testers`
5. Agrega correos de testers

## 🚀 Paso 4: Probar el Workflow

Una vez tengas el secreto `FIREBASE_SERVICE_ACCOUNT_KEY` configurado:

```bash
git add .
git commit -m "CI: Firebase setup with service account authentication"
git push origin main
```

## 🔐 Ventajas de Service Account vs Token CI:

- ✅ **Más seguro**: No expira nunca
- ✅ **Más confiable**: No requiere renovación manual
- ✅ **Mejor para CI**: Autenticación directa con Google Cloud
- ✅ **Sin navegador**: No requiere interacción manual

¡Tu CI/CD está completamente configurado con autenticación por Firebase Token! 🚀

---

## 📋 **Guía Paso a Paso: Configurar Cada Secreto**

### 1. **FIREBASE_APP_ID**
**Valor:** `1:608568990460:android:ffc242ecae35c28d17d579`

**Cómo configurarlo:**
1. Ve a tu repositorio en GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. **New repository secret**
4. **Name:** `FIREBASE_APP_ID`
5. **Secret:** `1:608568990460:android:ffc242ecae35c28d17d579`
6. **Add secret**

### 2. **FIREBASE_TOKEN**
**Valor:** *Generado con `firebase login:ci`*

**Cómo generarlo y configurarlo:**
1. **En tu terminal local:**
   ```bash
   npm install -g firebase-tools
   firebase login:ci
   ```
2. **Inicia sesión** en el navegador que se abre
3. **Copia el token** que Firebase te da (empieza con `1/...`)
4. **En GitHub:**
   - **Settings** → **Secrets and variables** → **Actions**
   - **New repository secret**
   - **Name:** `FIREBASE_TOKEN`
   - **Secret:** *Pega el token copiado*
   - **Add secret**

### 3. **GOOGLE_SERVICES_JSON_BASE64**
**Valor:** *Ya está arriba en la documentación*

**Cómo configurarlo:**
1. **Copia el valor base64** de arriba (el que empieza con `ewogICJwcm9qZWN0X2luZm8i...`)
2. **En GitHub:**
   - **Settings** → **Secrets and variables** → **Actions**
   - **New repository secret**
   - **Name:** `GOOGLE_SERVICES_JSON_BASE64`
   - **Secret:** *Pega todo el contenido base64*
   - **Add secret**

### 4. **KEYSTORE_BASE64** (Opcional)
**Valor:** *Ya está arriba en la documentación*

**Cómo configurarlo:**
1. **Copia el valor base64** de arriba (el que empieza con `MIIKqgIBAzCCClQG...`)
2. **En GitHub:**
   - **Settings** → **Secrets and variables** → **Actions**
   - **New repository secret**
   - **Name:** `KEYSTORE_BASE64`
   - **Secret:** *Pega todo el contenido base64*
   - **Add secret**

### 5. **KEYSTORE_PASSWORD** (Opcional)
**Valor:** `Braian8052`

**Cómo configurarlo:**
1. **En GitHub:**
   - **Settings** → **Secrets and variables** → **Actions**
   - **New repository secret**
   - **Name:** `KEYSTORE_PASSWORD`
   - **Secret:** `Braian8052`
   - **Add secret**

### 6. **KEY_ALIAS** (Opcional)
**Valor:** `key_alias`

**Cómo configurarlo:**
1. **En GitHub:**
   - **Settings** → **Secrets and variables** → **Actions**
   - **New repository secret**
   - **Name:** `KEY_ALIAS`
   - **Secret:** `key_alias`
   - **Add secret**

### 7. **KEY_PASSWORD** (Opcional)
**Valor:** `Braian8052`

**Cómo configurarlo:**
1. **En GitHub:**
   - **Settings** → **Secrets and variables** → **Actions**
   - **New repository secret**
   - **Name:** `KEY_PASSWORD`
   - **Secret:** `Braian8052`
   - **Add secret**

## 🎯 **Después de Configurar Todos los Secretos:**

```bash
git add .
git commit -m "CI: Firebase setup with token authentication"
git push origin main
```

## � **Verificar Configuración:**

1. **Ve a GitHub** → Tu repositorio → **Actions**
2. **Haz click** en el workflow que se ejecutó
3. **Verifica** que todos los pasos pasen correctamente
4. **Revisa** que se suba a Firebase App Distribution

## 🆘 **Problemas Comunes:**

### "firebase: command not found"
```bash
# Instala Firebase CLI
npm install -g firebase-tools
```

### "Cannot authenticate"
- Verifica que el `FIREBASE_TOKEN` esté correcto
- Asegúrate de que tengas acceso al proyecto Firebase

### "Keystore not found"
- Los secretos opcionales del keystore son necesarios para builds firmados
- Sin ellos, el build fallará

¿Necesitas ayuda con algún secreto específico o tienes algún error?

## 🎯 Paso 3: Probar el Workflow

1. **Push a main**:
   ```bash
   git add .
   git commit -m "Setup Firebase CI/CD"
   git push origin main
   ```

2. **Ver progreso**: Ve a **Actions** en tu repositorio

3. **Resultado**: APK y AAB subidos a Firebase App Distribution

## 📱 Paso 4: Configurar Testers

En Firebase Console:

1. **App Distribution** → **Testers & Groups**
2. **Crear grupo**: "testers"
3. **Agregar emails** de testers
4. **Notificaciones**: Automáticas cuando se suba nueva versión

## 🛠️ Solución de Problemas

### Error: "Firebase CLI incompatible"
```bash
# Actualizar Node.js a v20+
# O usar npx
npx firebase-tools@latest login:ci
```

### Error: "App ID not found"
- Verificar que el secreto `FIREBASE_APP_ID` esté correcto
- Asegurarse que la app Android esté registrada en Firebase

### Error: "Keystore not found"
- El keystore está en `android/release-keystore.jks`
- Asegurarse que no se subió al repositorio (está en `.gitignore`)

## 📊 Workflow Detalles

### Triggers:
- Push a `main`
- Pull Request a `main`

### Build Steps:
1. **Setup Flutter** (v3.24.0)
2. **Setup Java** (v17)
3. **Install dependencies**
4. **Build APK** (release)
5. **Build AAB** (release)
6. **Authenticate** con Firebase
7. **Upload** APK a App Distribution
8. **Upload** AAB a App Distribution

### Grupos:
- **APK**: Para tests internos rápidos
- **AAB**: Para Play Store (recomendado)

## 🎉 Resultado Final

Una vez configurado, cada push a `main` automáticamente:

- ✅ **Build** la app en release
- ✅ **Firma** con keystore seguro
- ✅ **Sube** a Firebase App Distribution
- ✅ **Notifica** a testers
- ✅ **Lista** para distribución

¡Tu pipeline de CI/CD está listo! 🚀