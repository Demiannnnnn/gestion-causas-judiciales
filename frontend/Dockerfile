# DOCKERFILE del Frontend

# Usar una imagen base de Node.js para desarrollo
FROM node:16-alpine

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar package.json y package-lock.json para instalar dependencias
COPY package*.json ./

# Instalar las dependencias del proyecto
RUN npm install

# Copiar el resto de los archivos de la aplicación
COPY . .

# Switch to the non-root user provided by the node image
USER node

# Exponer el puerto 3000 para el servidor de desarrollo de React
EXPOSE 3000

# Comando para iniciar la aplicación en modo de desarrollo
CMD ["npm", "start"]