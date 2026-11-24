# 🌿 LeafCare AI

Aplicación móvil multiplataforma que ayuda a cuidar plantas usando inteligencia artificial. El usuario toma una foto de una hoja, la app identifica la especie, analiza su estado de salud y le devuelve recomendaciones concretas de riego, luz y sustrato. Todo el historial queda guardado en su cuenta, organizado por grupos.

**Proyecto Final — Desarrollo Móvil**
Repositorio: `https://github.com/CrissCB/LeafCare-AI.git` · Rama principal de trabajo: `develop`.

---

## ✨ Funcionalidad

### Autenticación y seguridad
- Registro e inicio de sesión con correo y contraseña.
- Verificación de correo electrónico y recuperación de contraseña (flujo PKCE).
- Inicio de sesión con Google.
- Seguridad adicional con verificación en dos pasos (2FA) y tabla `user_security`.

### Gestión de plantas
- Pantalla **Mis plantas** con filtros por grupos (por ejemplo: *Mi jardín*, *Sala*, *Balcón*).
- Crear, editar y eliminar grupos; cada grupo tiene un ícono representativo.
- Alta, edición y detalle de plantas con ficha botánica, imagen principal y estado de salud.
- Panel de **Estadísticas** con el historial de salud de las plantas.

### Escáner botánico con IA (funcionalidad principal)
Dos modos de uso:

| Modo | Flujo |
|---|---|
| **Nueva planta** | Elegir grupo → foto o galería → identificación + diagnóstico → guardar en la colección. |
| **Diagnóstico de salud** | Elegir grupo → elegir planta registrada → foto → diagnóstico + alerta IA. |

Regla de negocio: **no se puede escanear sin un grupo seleccionado** y, en diagnóstico, tampoco sin una planta elegida.

Pipeline de análisis:

1. Verificación de conexión a internet y compresión de la imagen a 1024 px / calidad 82.
2. **Pl@ntNet** identifica la especie. Si la confianza es menor al 50 %, el flujo se corta y se pide una foto mejor.
3. **Perenual** aporta la ficha botánica solo si la especie está en el índice local (IDs ≤ 3000 del plan gratuito).
4. **Google Gemini** analiza la imagen y devuelve un JSON con `health_score`, color de estado, diagnóstico, cuidados y acción sugerida. El modelo se configura en `lib/core/constants/api_constants.dart`.
5. Guardado en Supabase: imagen en Storage, registros en `user_plants` y `plant_scans`; en diagnóstico también se crea una fila en `ia_alerts`.

### Alertas, recordatorios y contenido
- Alertas generadas por la IA con resumen completo del diagnóstico.
- Recordatorios de cuidado por día.
- Blog con feed RSS de jardinería en español.
- Perfil con métricas, ajustes de cuenta, seguridad y ayuda.

### Navegación
Cinco pestañas principales: **Inicio, Alertas, Escanear, Blog y Perfil**, más rutas internas como `/plants`, `/plant/:id` y `/stats`.

---

## 🛠️ Tecnologías

| Capa | Tecnología |
|---|---|
| App | Flutter / Dart (SDK Dart ^3.13.5) |
| UI | Material Design, Google Fonts, flutter_svg, fl_chart |
| Estado | flutter_bloc (Bloc / Cubit) |
| Navegación | go_router con guardas de autenticación y `StatefulShellRoute` |
| Backend | Supabase: Auth (PKCE), Postgres, Storage y Row Level Security |
| IA y datos botánicos | Pl@ntNet API, Perenual API, Google Gemini |
| Imágenes | image_picker, flutter_image_compress, cached_network_image |
| HTTP / RSS | http, xml |
| Configuración | flutter_dotenv (archivo `.env`, ignorado por Git) |
| Persistencia local | flutter_secure_storage, shared_preferences |
| Plataformas | Android, iOS y Web |

Dependencias principales declaradas en `leafcare_ia/pubspec.yaml`: `supabase_flutter ^2.18.3`, `flutter_bloc ^9.1.1`, `go_router ^18.1.1`, `http ^1.6.0`, `image_picker ^1.2.4`, `flutter_image_compress ^2.5.1`, `flutter_dotenv ^6.0.1`, `fl_chart ^1.3.0`, `google_fonts ^9.0.0`.

---

## 📁 Estructura del proyecto

```
LeafCare-AI/
└── leafcare_ia/                 # Proyecto Flutter
    ├── lib/
    │   ├── main.dart            # Carga .env e inicializa Supabase
    │   ├── app/                 # app.dart, router, tema
    │   ├── core/                # network/Supabase, constants, utils, widgets
    │   └── features/            # auth, dashboard, plants, scanner,
    │                            # plant_detail, alerts, blog, profile, stats
    │       ├── data/            # datasource, models, repository
    │       └── presentation/    # bloc, screens, widgets
    ├── assets/data/perenual_index.json
    ├── android/ · ios/ · web/
    └── .env                     # NO se sube a Git
```

Cada funcionalidad sigue el mismo patrón: la UI emite eventos, el Bloc habla con el repositorio, el repositorio con el datasource y el datasource con Supabase o las APIs externas.

---

## ✅ Requisitos previos

1. **Flutter SDK** ^3.13.5 (incluye Dart). Verificar con `flutter --version`.
2. **Android Studio / Android SDK** para compilar Android. El proyecto usa `compileSdk = 37` y `targetSdk = 37` en `android/app/build.gradle.kts`, así que se debe tener instalada esa versión del SDK.
3. **Proyecto de Supabase** con:
   - Auth habilitado (correo/contraseña y, si se usa, Google).
   - Tablas: `user_security`, `profiles`, `plant_groups`, `user_plants`, `plant_care_details`, `plant_scans`, `ia_alerts`, `care_reminders`.
   - Bucket de Storage `plant-images` con acceso público de lectura.
   - Row Level Security activo para que cada usuario solo acceda a sus propios datos.
4. **Credenciales de APIs externas**:
   - Supabase (URL y anon key).
   - Pl@ntNet API key.
   - Perenual API key.
   - Google AI Studio (Gemini) API key.

---

## ⚙️ Configuración

1. Clonar el repositorio y ubicarse en la rama `develop`:

   ```bash
   git clone https://github.com/CrissCB/LeafCare-AI.git
   cd LeafCare-AI
   git checkout develop
   cd leafcare_ia
   ```

2. Instalar dependencias:

   ```bash
   flutter pub get
   ```

3. Crear el archivo `leafcare_ia/.env` con estas variables (sin comillas y con tus propios valores):

   ```env
   SUPABASE_URL=
   SUPABASE_ANON_KEY=
   PLANTNET_API_KEY=
   PERENUAL_API_KEY=
   GEMINI_API_KEY=
   ```

   > El archivo `.env` está ignorado por Git en ambos niveles del repositorio. **Nunca subas tus claves.**

4. Asegúrate de que el usuario con el que vas a entrar exista en Supabase Auth y tenga al menos un grupo en `plant_groups`; si no, el escáner pedirá que crees uno primero desde **Mis plantas → + Grupo**.

---

## ▶️ Ejecutar la app

```bash
cd leafcare_ia
flutter run
```

Para ejecutar en el navegador:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Para generar el APK de depuración:

```bash
flutter build apk --debug
```

El APK queda en `leafcare_ia/build/app/outputs/flutter-apk/app-debug.apk`.

Comandos de verificación:

```bash
flutter analyze
flutter test
```

---

## 🔒 Notas de seguridad

- Las claves se leen en tiempo de ejecución desde `.env` mediante `flutter_dotenv`.
- El archivo `.env` y el patrón `.env*` están excluidos por `.gitignore`; el APK se compila con las claves incluidas como asset, así que **no compartas un APK de depuración fuera del equipo**.
- El acceso a datos está restringido por `user_id` mediante Row Level Security en Supabase.

---

## 👥 Autores

Karent y Cristian — Proyecto Final, Desarrollo Móvil.
