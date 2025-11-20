FROM tomcat:9.0-jdk17

# Eliminar aplicaciones por defecto
RUN rm -rf /usr/local/tomcat/webapps/*

# Copiar WAR como ROOT
COPY target/*.war /usr/local/tomcat/webapps/ROOT.war

# Crear script de inicio con puerto dinámico
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Obtener puerto de Render (o 8080 por defecto)\n\
HTTP_PORT=${PORT:-8080}\n\
\n\
echo "================================="\n\
echo "🔧 Configurando Tomcat..."\n\
echo "================================="\n\
\n\
# Modificar server.xml ANTES de iniciar Tomcat\n\
sed -i "s/port=\"8080\"/port=\"$HTTP_PORT\"/g" /usr/local/tomcat/conf/server.xml\n\
sed -i "s/port=\"8005\"/port=\"-1\"/g" /usr/local/tomcat/conf/server.xml\n\
\n\
echo "✅ Puerto HTTP: $HTTP_PORT"\n\
echo "✅ Puerto shutdown: DESHABILITADO"\n\
echo "================================="\n\
echo "📦 Contenido de webapps:"\n\
ls -lh /usr/local/tomcat/webapps/\n\
echo "================================="\n\
echo "🚀 Iniciando Tomcat..."\n\
echo "================================="\n\
\n\
# Iniciar Tomcat\n\
exec catalina.sh run\n\
' > /usr/local/tomcat/bin/start-custom.sh && chmod +x /usr/local/tomcat/bin/start-custom.sh

# Variables de optimización
ENV CATALINA_OPTS="-Xmx512m -XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8080

# Usar nuestro script personalizado
CMD ["/usr/local/tomcat/bin/start-custom.sh"]