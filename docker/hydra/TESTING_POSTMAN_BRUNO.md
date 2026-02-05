# 🧪 Testing Ory Hydra con Postman/Bruno

## 📋 Guía Completa de Pruebas

### 🔑 Credenciales de los Clientes

| Cliente | Client ID | Client Secret |
|---------|-----------|---------------|
| **MS Data** | `63029b8e-874e-4062-909c-d6391becba4f` | `ms-data-client-secret-change-in-production` |
| **Web App** | `8adcb1e3-6899-4ca2-9a35-01e3983f73ae` | `web-app-client-secret-change-in-production` |
| **Test** | `250372be-ff9f-4fd0-ac69-ee900adc458d` | `test-client-secret` |

---

## 🎯 Flujo 1: Client Credentials Grant

### Paso 1: Obtener Access Token

**Endpoint**: `POST http://localhost:4444/oauth2/token`

#### Opción A: Usando Basic Auth (Recomendado)

**Postman/Bruno Configuration**:
- **Method**: POST
- **URL**: `http://localhost:4444/oauth2/token`
- **Auth Type**: Basic Auth
  - Username: `63029b8e-874e-4062-909c-d6391becba4f`
  - Password: `ms-data-client-secret-change-in-production`
- **Headers**:
  - `Content-Type: application/x-www-form-urlencoded`
- **Body** (x-www-form-urlencoded):
  - `grant_type`: `client_credentials`
  - `scope`: `openid profile email` (opcional)

**cURL equivalente**:
```bash
curl -X POST http://localhost:4444/oauth2/token \
  -u "63029b8e-874e-4062-909c-d6391becba4f:ms-data-client-secret-change-in-production" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "scope=openid profile email"
```

**Respuesta esperada**:
```json
{
  "access_token": "ory_at_xxxxxxxxxxxxxxxxxx",
  "expires_in": 86400,
  "scope": "openid profile email",
  "token_type": "bearer"
}
```

#### Opción B: Usando client_secret_post

⚠️ **Nota**: Por defecto, Hydra espera `client_secret_basic`. Para usar `client_secret_post`, debes configurar el cliente explícitamente.

**Body** (x-www-form-urlencoded):
- `grant_type`: `client_credentials`
- `client_id`: `63029b8e-874e-4062-909c-d6391becba4f`
- `client_secret`: `ms-data-client-secret-change-in-production`
- `scope`: `openid profile email`

---

## 🌐 Flujo 2: Authorization Code Flow

### Paso 1: Obtener Authorization Code

**Endpoint**: `GET http://localhost:4444/oauth2/auth`

**Postman/Bruno Configuration**:
- **Method**: GET
- **URL**: `http://localhost:4444/oauth2/auth`
- **Query Parameters**:
  - `client_id`: `63029b8e-874e-4062-909c-d6391becba4f`
  - `redirect_uri`: `http://localhost:8080/callback`
  - `response_type`: `code`
  - `scope`: `openid profile email`
  - `state`: `random-state-string` (para seguridad)

⚠️ **Nota**: Este paso requiere un navegador para el login del usuario. Hydra redirigirá a una URL de login.

### Paso 2: Intercambiar Code por Token

**Endpoint**: `POST http://localhost:4444/oauth2/token`

**Postman/Bruno Configuration**:
- **Method**: POST
- **URL**: `http://localhost:4444/oauth2/token`
- **Auth Type**: Basic Auth
  - Username: `63029b8e-874e-4062-909c-d6391becba4f`
  - Password: `ms-data-client-secret-change-in-production`
- **Headers**:
  - `Content-Type: application/x-www-form-urlencoded`
- **Body** (x-www-form-urlencoded):
  - `grant_type`: `authorization_code`
  - `code`: `<código obtenido en paso 1>`
  - `redirect_uri`: `http://localhost:8080/callback`

**Respuesta esperada**:
```json
{
  "access_token": "ory_at_xxxxxxxxxxxxxxxxxx",
  "expires_in": 86400,
  "id_token": "eyJhbGciOiJSUzI1NiIs...",
  "refresh_token": "ory_rt_xxxxxxxxxxxxxxxxxx",
  "scope": "openid profile email",
  "token_type": "bearer"
}
```

---

## 🔄 Flujo 3: Refresh Token

### Renovar Access Token

**Endpoint**: `POST http://localhost:4444/oauth2/token`

**Postman/Bruno Configuration**:
- **Method**: POST
- **URL**: `http://localhost:4444/oauth2/token`
- **Auth Type**: Basic Auth
  - Username: `63029b8e-874e-4062-909c-d6391becba4f`
  - Password: `ms-data-client-secret-change-in-production`
- **Headers**:
  - `Content-Type: application/x-www-form-urlencoded`
- **Body** (x-www-form-urlencoded):
  - `grant_type`: `refresh_token`
  - `refresh_token`: `<refresh_token obtenido previamente>`

**Respuesta esperada**:
```json
{
  "access_token": "ory_at_nuevo_token",
  "expires_in": 86400,
  "refresh_token": "ory_rt_nuevo_token",
  "scope": "openid profile email",
  "token_type": "bearer"
}
```

---

## 🔍 Endpoints Adicionales

### 1. Token Introspection

**Endpoint**: `POST http://localhost:4445/admin/oauth2/introspect`

**Postman/Bruno Configuration**:
- **Method**: POST
- **URL**: `http://localhost:4445/admin/oauth2/introspect`
- **Headers**:
  - `Content-Type: application/x-www-form-urlencoded`
- **Body** (x-www-form-urlencoded):
  - `token`: `<access_token a verificar>`

**Respuesta esperada**:
```json
{
  "active": true,
  "client_id": "63029b8e-874e-4062-909c-d6391becba4f",
  "exp": 1738800000,
  "iat": 1738713600,
  "iss": "http://localhost:4444",
  "scope": "openid profile email",
  "sub": "63029b8e-874e-4062-909c-d6391becba4f",
  "token_type": "Bearer"
}
```

### 2. Token Revocation

**Endpoint**: `POST http://localhost:4444/oauth2/revoke`

**Postman/Bruno Configuration**:
- **Method**: POST
- **URL**: `http://localhost:4444/oauth2/revoke`
- **Auth Type**: Basic Auth
  - Username: `63029b8e-874e-4062-909c-d6391becba4f`
  - Password: `ms-data-client-secret-change-in-production`
- **Headers**:
  - `Content-Type: application/x-www-form-urlencoded`
- **Body** (x-www-form-urlencoded):
  - `token`: `<token a revocar>`
  - `token_type_hint`: `access_token` o `refresh_token`

### 3. OpenID Configuration

**Endpoint**: `GET http://localhost:4444/.well-known/openid-configuration`

**Postman/Bruno Configuration**:
- **Method**: GET
- **URL**: `http://localhost:4444/.well-known/openid-configuration`
- **Headers**: Ninguno necesario

**Respuesta**: Configuración completa de OpenID Connect

### 4. JWK Set (Claves públicas)

**Endpoint**: `GET http://localhost:4444/.well-known/jwks.json`

**Postman/Bruno Configuration**:
- **Method**: GET
- **URL**: `http://localhost:4444/.well-known/jwks.json`
- **Headers**: Ninguno necesario

---

## 🧪 Usar el Token con tu API

### Llamar a API Protegida

**Endpoint**: `GET http://localhost:8080/api/protected/data`

**Postman/Bruno Configuration**:
- **Method**: GET
- **URL**: `http://localhost:8080/api/protected/data`
- **Auth Type**: Bearer Token
  - Token: `<access_token obtenido de Hydra>`

**Alternativamente (manual)**:
- **Headers**:
  - `Authorization: Bearer ory_at_xxxxxxxxxxxxxxxxxx`

---

## 📦 Variables de Entorno en Postman/Bruno

### Crear Environment

**Variables sugeridas**:

```json
{
  "hydra_url": "http://localhost:4444",
  "hydra_admin_url": "http://localhost:4445",
  "api_url": "http://localhost:8080",
  "client_id": "63029b8e-874e-4062-909c-d6391becba4f",
  "client_secret": "ms-data-client-secret-change-in-production",
  "access_token": "",
  "refresh_token": "",
  "redirect_uri": "http://localhost:8080/callback"
}
```

### Usar Variables

En Postman/Bruno usa:
- URL: `{{hydra_url}}/oauth2/token`
- Basic Auth Username: `{{client_id}}`
- Basic Auth Password: `{{client_secret}}`

### Script Post-Request (Postman)

Para guardar el token automáticamente:

```javascript
// En la pestaña "Tests" de la request
if (pm.response.code === 200) {
    const response = pm.response.json();
    pm.environment.set("access_token", response.access_token);
    if (response.refresh_token) {
        pm.environment.set("refresh_token", response.refresh_token);
    }
    console.log("Token guardado:", response.access_token);
}
```

---

## 🐛 Troubleshooting

### Error: "invalid_client"

**Causa**: Client ID o Secret incorrectos

**Solución**:
1. Verificar que estés usando el Client ID UUID correcto
2. Verificar el secreto
3. Asegurarte de usar Basic Auth, no Body

### Error: "unsupported_grant_type"

**Causa**: Grant type no permitido para ese cliente

**Solución**: Verificar que el cliente tenga el grant type configurado:
```bash
docker-compose exec hydra hydra get client <client-id> \
  --endpoint http://localhost:4445
```

### Error: "invalid_scope"

**Causa**: Scope solicitado no permitido

**Solución**: Usa solo scopes configurados: `openid`, `offline`, `profile`, `email`

---

## ✅ Checklist de Pruebas

- [ ] Obtener token con Client Credentials Grant
- [ ] Verificar que el token tiene formato JWT
- [ ] Verificar tiempo de expiración (24h)
- [ ] Introspeccionar token
- [ ] Usar token para llamar a API protegida
- [ ] Revocar token
- [ ] Verificar que token revocado ya no funciona

---

## 📖 Referencias

- [Ory Hydra OAuth2 API](https://www.ory.sh/docs/hydra/reference/api)
- [OAuth 2.0 RFC](https://datatracker.ietf.org/doc/html/rfc6749)
- [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
