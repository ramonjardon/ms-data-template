# 🧪 Colección Bruno/Postman - Ory Hydra

## 📦 Contenido

Esta carpeta contiene una colección completa de requests para probar Ory Hydra OAuth2.

## 📋 Requests Incluidas

1. **Client Credentials - Get Token** ✅
   - Obtener access token con client credentials
   - Guarda automáticamente el token en variables

2. **Introspect Token** 🔍
   - Validar si un token es válido
   - Ver información del token

3. **Revoke Token** ❌
   - Revocar un token
   - Para logout o invalidación

4. **Call Protected API** 🔐
   - Ejemplo de uso del token
   - Llamar a endpoint protegido

5. **OpenID Configuration** ⚙️
   - Descubrir configuración de Hydra
   - Ver endpoints disponibles

6. **Get JWK Set** 🔑
   - Obtener claves públicas
   - Para validación de firmas JWT

## 🚀 Cómo Usar

### Con Bruno

1. **Instalar Bruno** (si no lo tienes):
   ```bash
   # macOS
   brew install bruno
   
   # O descarga desde https://www.usebruno.com/downloads
   ```

2. **Abrir la colección**:
   ```bash
   cd docker/hydra/bruno-collection
   bruno open
   ```

3. **Ejecutar requests**:
   - Abre Bruno
   - La colección aparecerá en el sidebar
   - Click en "1. Client Credentials - Get Token"
   - Click en "Send"
   - El token se guarda automáticamente

### Con Postman

1. **Importar colección**:
   - Abrir Postman
   - File → Import
   - Seleccionar todos los archivos `.bru`
   - Postman los convertirá automáticamente

2. **Configurar variables**:
   - Click en "Environments"
   - Crear nuevo environment "Hydra Local"
   - Añadir variables (ver abajo)

## 🔧 Variables de Entorno

Configura estas variables en tu environment:

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `hydra_url` | `http://localhost:4444` | URL pública de Hydra |
| `hydra_admin_url` | `http://localhost:4445` | URL admin de Hydra |
| `api_url` | `http://localhost:8080` | URL de tu API |
| `client_id` | `63029b8e-874e-4062-909c-d6391becba4f` | ID del cliente OAuth2 |
| `client_secret` | `ms-data-client-secret-change-in-production` | Secret del cliente |
| `access_token` | *(se llena automáticamente)* | Token actual |
| `refresh_token` | *(se llena automáticamente)* | Refresh token |
| `redirect_uri` | `http://localhost:8080/callback` | URI de callback |

## 📖 Flujo de Trabajo Recomendado

### Flujo Básico

1. **Obtener Token**
   ```
   1. Client Credentials - Get Token
   ```

2. **Validar Token**
   ```
   2. Introspect Token
   ```

3. **Usar Token**
   ```
   4. Call Protected API
   ```

4. **Revocar Token** (opcional)
   ```
   3. Revoke Token
   ```

### Descubrimiento

Para conocer la configuración de Hydra:

```
5. OpenID Configuration
6. Get JWK Set
```

## 🎯 Ejemplos de Uso

### Obtener Token Rápidamente

1. Abre "1. Client Credentials - Get Token"
2. Click "Send"
3. El token se guarda en `{{access_token}}`
4. Listo para usar en otros requests

### Probar API Protegida

1. Ejecuta "1. Client Credentials - Get Token"
2. Ejecuta "4. Call Protected API"
3. Deberías ver la respuesta de tu API

### Verificar Token

1. Ejecuta "1. Client Credentials - Get Token"
2. Ejecuta "2. Introspect Token"
3. Verás:
   - `active: true`
   - Información del cliente
   - Tiempo de expiración

## 🐛 Troubleshooting

### Error: "Connection refused"

**Causa**: Hydra no está corriendo

**Solución**:
```bash
cd /ruta/al/proyecto
docker-compose up -d hydra
```

### Error: "invalid_client"

**Causa**: Client ID o Secret incorrectos

**Solución**:
1. Verificar variables en el environment
2. Ejecutar `./setup-clients.sh` si es necesario

### Token no se guarda automáticamente

**Bruno**: El script post-response debería funcionar automáticamente

**Postman**: Añade este script en la pestaña "Tests":
```javascript
if (pm.response.code === 200) {
    const response = pm.response.json();
    pm.environment.set("access_token", response.access_token);
    if (response.refresh_token) {
        pm.environment.set("refresh_token", response.refresh_token);
    }
}
```

## 📚 Referencias

- [Bruno Documentation](https://docs.usebruno.com/)
- [Postman Documentation](https://learning.postman.com/)
- [Ory Hydra API Reference](https://www.ory.sh/docs/hydra/reference/api)

## ✅ Checklist de Pruebas

- [ ] Obtener token con Client Credentials
- [ ] Introspeccionar token
- [ ] Llamar a API protegida con token
- [ ] Revocar token
- [ ] Ver OpenID Configuration
- [ ] Obtener JWK Set
- [ ] Verificar que token revocado no funciona

---

**¡Colección lista para usar!** 🎉
