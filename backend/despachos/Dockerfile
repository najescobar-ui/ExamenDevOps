# syntax=docker/dockerfile:1

### Build stage: compila el JAR con Maven + JDK 17 ###
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build

# Copia el pom primero para cachear la descarga de dependencias
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

# Copia el codigo y empaqueta (tests se corren en el pipeline de CI)
COPY src ./src
RUN mvn -B -q clean package -DskipTests

### Runtime stage: imagen minima solo con el JRE ###
FROM amazoncorretto:17-alpine AS runtime
WORKDIR /app

# Usuario sin privilegios (no ejecutar como root)
RUN addgroup -S app && adduser -S app -G app

COPY --from=build /build/target/*.jar app.jar
USER app

EXPOSE 8081
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
