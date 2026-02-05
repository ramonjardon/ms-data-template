#!/bin/bash

# Script para verificar qué autoconfiguraciones están activas en Spring Boot
# y detectar posibles candidatos a exclusión

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Verificación de Autoconfiguraciones Spring Boot"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "1️⃣  Verificando dependencias potencialmente problemáticas..."
echo ""

# Verificar Gson
echo "📦 Gson (librería JSON alternativa a Jackson):"
if ./mvnw dependency:tree | grep -q "gson"; then
    echo "   ⚠️  ENCONTRADO - Puede causar conflictos con Jackson"
    echo "   Dependencias que lo traen:"
    ./mvnw dependency:tree | grep -B 3 gson | head -20
    echo ""
    echo "   💡 Considera excluir: GsonAutoConfiguration.class"
    echo ""
else
    echo "   ✅ NO encontrado - No hay conflicto con Jackson"
    echo ""
fi

# Verificar base de datos
echo "🗄️  Dependencias de Base de Datos:"
if ./mvnw dependency:tree | grep -q "jdbc\|jpa\|hibernate"; then
    echo "   ⚠️  ENCONTRADAS - Si no usas DB, considera excluir"
    ./mvnw dependency:tree | grep -E "jdbc|jpa|hibernate" | head -10
    echo ""
    echo "   💡 Considera excluir:"
    echo "      - DataSourceAutoConfiguration.class"
    echo "      - HibernateJpaAutoConfiguration.class"
    echo ""
else
    echo "   ✅ NO encontradas - No necesitas excluir"
    echo ""
fi

# Verificar templates
echo "🌐 Template Engines:"
if ./mvnw dependency:tree | grep -qE "thymeleaf|freemarker|mustache"; then
    echo "   ⚠️  ENCONTRADOS - Para REST API pura, no son necesarios"
    ./mvnw dependency:tree | grep -E "thymeleaf|freemarker|mustache" | head -10
    echo ""
    echo "   💡 Considera excluir la autoconfiguración correspondiente"
    echo ""
else
    echo "   ✅ NO encontrados - Perfecto para REST API"
    echo ""
fi

# Verificar Actuator
echo "📊 Spring Boot Actuator:"
if ./mvnw dependency:tree | grep -q "spring-boot-actuator"; then
    echo "   ✅ ENCONTRADO - Endpoints de monitoreo disponibles"
    echo "   💡 Si no lo necesitas en producción, considera excluir"
    echo ""
else
    echo "   ✅ NO encontrado - Reduce superficie de ataque"
    echo ""
fi

# Verificar mensajería
echo "📧 Sistemas de Mensajería:"
if ./mvnw dependency:tree | grep -qE "kafka|rabbitmq|jms|amqp"; then
    echo "   ⚠️  ENCONTRADOS"
    ./mvnw dependency:tree | grep -E "kafka|rabbitmq|jms|amqp" | head -10
    echo ""
    echo "   💡 Si no los usas, considera excluir"
    echo ""
else
    echo "   ✅ NO encontrados"
    echo ""
fi

# Verificar Session
echo "🗂️  Spring Session:"
if ./mvnw dependency:tree | grep -q "spring-session"; then
    echo "   ⚠️  ENCONTRADO - Para JWT stateless, no es necesario"
    echo "   💡 Considera excluir: SessionAutoConfiguration.class"
    echo ""
else
    echo "   ✅ NO encontrado - Perfecto para API stateless con JWT"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Resumen de Recomendaciones"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Contar problemas
ISSUES=0

if ./mvnw dependency:tree | grep -q "gson"; then
    ISSUES=$((ISSUES+1))
fi

if ./mvnw dependency:tree | grep -q "jdbc\|jpa\|hibernate"; then
    ISSUES=$((ISSUES+1))
fi

if ./mvnw dependency:tree | grep -qE "thymeleaf|freemarker|mustache"; then
    ISSUES=$((ISSUES+1))
fi

if ./mvnw dependency:tree | grep -q "spring-session"; then
    ISSUES=$((ISSUES+1))
fi

if [ $ISSUES -eq 0 ]; then
    echo "✅ Tu proyecto está LIMPIO"
    echo ""
    echo "No necesitas excluir ninguna autoconfiguración."
    echo "Spring Boot solo cargará lo necesario."
    echo ""
    echo "Recomendación:"
    echo "  @SpringBootApplication  // Sin exclusiones"
else
    echo "⚠️  Se encontraron $ISSUES dependencias que podrían no estar en uso"
    echo ""
    echo "Revisa la salida anterior y considera:"
    echo "1. Excluir las autoconfiguraciones que no necesitas"
    echo "2. O mejor, excluir las dependencias transitivas del pom.xml"
    echo ""
    echo "Ejemplo de exclusión en @SpringBootApplication:"
    echo ""
    echo "@SpringBootApplication(exclude = {"

    if ./mvnw dependency:tree | grep -q "gson"; then
        echo "    GsonAutoConfiguration.class,"
    fi

    if ./mvnw dependency:tree | grep -q "jdbc\|jpa\|hibernate"; then
        echo "    DataSourceAutoConfiguration.class,"
        echo "    HibernateJpaAutoConfiguration.class,"
    fi

    if ./mvnw dependency:tree | grep -q "spring-session"; then
        echo "    SessionAutoConfiguration.class,"
    fi

    echo "})"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Para más información, consulta: SPRINGBOOT_EXCLUSIONS.md"
echo ""
