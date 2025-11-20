FROM tomcat:10.1-jdk17

# Eliminar aplicaciones por defecto
RUN rm -rf /usr/local/tomcat/webapps/*

# Copiar WAR como ROOT
COPY target/*.war /usr/local/tomcat/webapps/ROOT.war

# Crear script de inicio
RUN cat > /usr/local/tomcat/bin/start-custom.sh << 'EOF'
#!/bin/bash
set -e

HTTP_PORT=${PORT:-8080}

echo "================================="
echo "🔧 Configurando Tomcat..."
echo "================================="

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

exec catalina.sh run
EOF

RUN chmod +x /usr/local/tomcat/bin/start-custom.sh

ENV CATALINA_OPTS="-Xmx512m -XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8080

CMD ["/bin/bash", "/usr/local/tomcat/bin/start-custom.sh"]