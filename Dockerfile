FROM tomcat:9.0-jdk17

# Eliminar aplicaciones por defecto
RUN rm -rf /usr/local/tomcat/webapps/*

# Copiar WAR como ROOT
COPY target/UNIVERSIDAD-SW-1.0-SNAPSHOT.war /usr/local/tomcat/webapps/ROOT.war

# Crear script que configure el puerto dinámico
RUN echo '#!/bin/bash\n\
HTTP_PORT=${PORT:-8080}\n\
sed -i "s/port=\"8080\"/port=\"$HTTP_PORT\"/g" /usr/local/tomcat/conf/server.xml\n\
sed -i "s/port=\"8005\"/port=\"-1\"/g" /usr/local/tomcat/conf/server.xml\n\
echo "✅ Tomcat iniciando en puerto $HTTP_PORT"\n\
exec catalina.sh run\n\
' > /usr/local/tomcat/bin/start.sh && chmod +x /usr/local/tomcat/bin/start.sh

# Variables de optimización
ENV CATALINA_OPTS="-Xmx512m -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8080

CMD ["/usr/local/tomcat/bin/start.sh"]