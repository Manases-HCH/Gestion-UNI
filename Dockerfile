FROM tomcat:9.0-jdk17

# Eliminar aplicaciones por defecto
RUN rm -rf /usr/local/tomcat/webapps/*

# Copiar WAR como ROOT
COPY target/*.war /usr/local/tomcat/webapps/ROOT.war

# Crear script de inicio de forma más robusta
RUN cat > /usr/local/tomcat/bin/start-custom.sh << 'EOF'
#!/bin/bash
set -e

# Puerto dinámico de Render
HTTP_PORT=${PORT:-8080}

echo "================================="
echo "🔧 Configurando Tomcat..."
echo "================================="

# Modificar server.xml
sed -i "s/port=\"8080\"/port=\"$HTTP_PORT\"/g" /usr/local/tomcat/conf/server.xml
sed -i "s/port=\"8005\"/port=\"-1\"/g" /usr/local/tomcat/conf/server.xml

echo "✅ Puerto HTTP: $HTTP_PORT"
echo "✅ Puerto shutdown: DESHABILITADO"
echo "================================="
echo "📦 Contenido de webapps:"
ls -lh /usr/local/tomcat/webapps/
echo "================================="
echo "🚀 Iniciando Tomcat..."
echo "================================="

# Iniciar Tomcat
exec catalina.sh run
EOF

# Dar permisos de ejecución
RUN chmod +x /usr/local/tomcat/bin/start-custom.sh

# Variables de optimización
ENV CATALINA_OPTS="-Xmx512m -XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8080

# Ejecutar script con bash explícito
CMD ["/bin/bash", "/usr/local/tomcat/bin/start-custom.sh"]