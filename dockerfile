#Dockerfile
FROM node:18.16.0-alpine
RUN apk update && apk upgrade
WORKDIR /app
COPY . /app
ENV NODE_ENV=prod
EXPOSE 8180
RUN npm i
CMD cd /app ; node src/server.js -D FOREGROUND



