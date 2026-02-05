# Configuración de Variables de Entorno OAuth2

## 🌍 Configuración por Entorno

### Local (Desarrollo)
```bash
# application.yml usa valores por defecto
# No es necesario configurar variables de entorno
OAUTH2_ISSUER_URI=https://localhost:5556/dex
OAUTH2_JWK_SET_URI=https://localhost:5556/dex/keys
```

### Docker Compose
```yaml
# docker-compose.yml
services:
  ms-data:
    environment:
      OAUTH2_ISSUER_URI: https://ms-data-dex:5556/dex
      OAUTH2_JWK_SET_URI: https://ms-data-dex:5556/dex/keys
```

**Nota**: Usa el nombre del servicio (`ms-data-dex`) como hostname dentro de la red Docker.

### Docker Standalone
```bash
docker run -d \
  --name ms-data-app \
  -p 8080:8080 \
  -e OAUTH2_ISSUER_URI=https://dex.example.com/dex \
  -e OAUTH2_JWK_SET_URI=https://dex.example.com/dex/keys \
  ms-data-template:latest
```

### Kubernetes

#### ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ms-data-oauth2-config
  namespace: production
data:
  OAUTH2_ISSUER_URI: "https://dex.prod.example.com/dex"
  OAUTH2_JWK_SET_URI: "https://dex.prod.example.com/dex/keys"
```

#### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ms-data
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ms-data
  template:
    metadata:
      labels:
        app: ms-data
    spec:
      containers:
      - name: ms-data
        image: ms-data-template:1.0.0
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: ms-data-oauth2-config
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### AWS ECS

#### Task Definition
```json
{
  "family": "ms-data",
  "containerDefinitions": [
    {
      "name": "ms-data",
      "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/ms-data:latest",
      "memory": 512,
      "cpu": 256,
      "environment": [
        {
          "name": "OAUTH2_ISSUER_URI",
          "value": "https://dex.prod.example.com/dex"
        },
        {
          "name": "OAUTH2_JWK_SET_URI",
          "value": "https://dex.prod.example.com/dex/keys"
        }
      ],
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ]
    }
  ]
}
```

### Azure Container Apps
```bash
az containerapp create \
  --name ms-data \
  --resource-group myResourceGroup \
  --environment myEnvironment \
  --image myregistry.azurecr.io/ms-data:latest \
  --target-port 8080 \
  --ingress external \
  --env-vars \
    OAUTH2_ISSUER_URI=https://dex.azure.example.com/dex \
    OAUTH2_JWK_SET_URI=https://dex.azure.example.com/dex/keys
```

### Google Cloud Run
```bash
gcloud run deploy ms-data \
  --image gcr.io/my-project/ms-data:latest \
  --platform managed \
  --region us-central1 \
  --set-env-vars OAUTH2_ISSUER_URI=https://dex.gcp.example.com/dex,OAUTH2_JWK_SET_URI=https://dex.gcp.example.com/dex/keys \
  --memory 512Mi \
  --cpu 1
```

### Heroku
```bash
# Añadir variables de entorno
heroku config:set OAUTH2_ISSUER_URI=https://dex.heroku.example.com/dex
heroku config:set OAUTH2_JWK_SET_URI=https://dex.heroku.example.com/dex/keys
```

## 🔐 Gestión de Secretos

### Kubernetes Secrets
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: oauth2-secrets
type: Opaque
stringData:
  issuer-uri: "https://dex.prod.example.com/dex"
  jwk-set-uri: "https://dex.prod.example.com/dex/keys"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ms-data
spec:
  template:
    spec:
      containers:
      - name: ms-data
        env:
        - name: OAUTH2_ISSUER_URI
          valueFrom:
            secretKeyRef:
              name: oauth2-secrets
              key: issuer-uri
        - name: OAUTH2_JWK_SET_URI
          valueFrom:
            secretKeyRef:
              name: oauth2-secrets
              key: jwk-set-uri
```

### AWS Secrets Manager
```bash
# Crear secreto
aws secretsmanager create-secret \
  --name oauth2-config \
  --secret-string '{
    "OAUTH2_ISSUER_URI":"https://dex.prod.example.com/dex",
    "OAUTH2_JWK_SET_URI":"https://dex.prod.example.com/dex/keys"
  }'

# Usar en ECS Task Definition
{
  "secrets": [
    {
      "name": "OAUTH2_ISSUER_URI",
      "valueFrom": "arn:aws:secretsmanager:region:account:secret:oauth2-config:OAUTH2_ISSUER_URI::"
    },
    {
      "name": "OAUTH2_JWK_SET_URI",
      "valueFrom": "arn:aws:secretsmanager:region:account:secret:oauth2-config:OAUTH2_JWK_SET_URI::"
    }
  ]
}
```

### Azure Key Vault
```bash
# Crear secretos
az keyvault secret set \
  --vault-name myKeyVault \
  --name OAUTH2-ISSUER-URI \
  --value "https://dex.prod.example.com/dex"

az keyvault secret set \
  --vault-name myKeyVault \
  --name OAUTH2-JWK-SET-URI \
  --value "https://dex.prod.example.com/dex/keys"

# Usar en Container App
az containerapp create \
  --name ms-data \
  --secrets \
    oauth2-issuer-uri=keyvaultref:https://myKeyVault.vault.azure.net/secrets/OAUTH2-ISSUER-URI,identityref:/subscriptions/.../managedIdentities/myIdentity \
    oauth2-jwk-set-uri=keyvaultref:https://myKeyVault.vault.azure.net/secrets/OAUTH2-JWK-SET-URI,identityref:/subscriptions/.../managedIdentities/myIdentity \
  --env-vars \
    OAUTH2_ISSUER_URI=secretref:oauth2-issuer-uri \
    OAUTH2_JWK_SET_URI=secretref:oauth2-jwk-set-uri
```

### Google Secret Manager
```bash
# Crear secretos
echo -n "https://dex.prod.example.com/dex" | \
  gcloud secrets create oauth2-issuer-uri --data-file=-

echo -n "https://dex.prod.example.com/dex/keys" | \
  gcloud secrets create oauth2-jwk-set-uri --data-file=-

# Usar en Cloud Run
gcloud run deploy ms-data \
  --set-secrets OAUTH2_ISSUER_URI=oauth2-issuer-uri:latest,OAUTH2_JWK_SET_URI=oauth2-jwk-set-uri:latest
```

## 📋 Checklist de Configuración

- [ ] Variables de entorno definidas para el entorno
- [ ] URLs de Dex accesibles desde la aplicación
- [ ] Certificados SSL válidos (o deshabilitados en dev)
- [ ] Healthcheck configurado
- [ ] Secretos gestionados de forma segura
- [ ] Logs configurados para debugging
- [ ] Variables validadas en startup

## 🧪 Validación

### Verificar Variables de Entorno
```bash
# En el contenedor
docker exec ms-data-app env | grep OAUTH2

# Debería mostrar:
# OAUTH2_ISSUER_URI=https://ms-data-dex:5556/dex
# OAUTH2_JWK_SET_URI=https://ms-data-dex:5556/dex/keys
```

### Verificar Conectividad con Dex
```bash
# Desde el contenedor
docker exec ms-data-app curl -k https://ms-data-dex:5556/dex/.well-known/openid-configuration

# Debería responder con la configuración de Dex
```

### Verificar Logs de Inicio
```bash
docker logs ms-data-app | grep -i oauth2

# Debería mostrar:
# OAuth2ResourceServerJwtConfiguration : Issuer URI: https://ms-data-dex:5556/dex
```

## ⚙️ Troubleshooting

### Error: "Unable to resolve configuration with issuer-uri"
**Causa**: No puede conectar con Dex

**Solución**:
1. Verificar que Dex está corriendo
2. Verificar que la URL es accesible desde el contenedor
3. Verificar certificados SSL

### Error: Variables de entorno no se aplican
**Causa**: Mal nombradas o no exportadas

**Solución**:
```bash
# Verificar que están exportadas
echo $OAUTH2_ISSUER_URI

# Verificar en docker-compose
docker-compose config | grep OAUTH2
```

---

**Configuración lista para cualquier entorno!** ✅
