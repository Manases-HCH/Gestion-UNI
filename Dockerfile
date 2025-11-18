FROM tomcat:9.0

# Eliminamos aplicaciones por defecto
RUN rm -rf /usr/local/tomcat/webapps/*

# Copiamos tu WAR al servidor
COPY target/UNIVERSIDAD-SW-1.0-SNAPSHOT.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
