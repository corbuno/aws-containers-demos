FROM node:19-alpine3.17

# Create app directory
WORKDIR /usr/src/app

# Copy application code
COPY webapp ./

# Install nodejs dependencies
RUN npm install

# Indicate whih port will be open by nodejs
EXPOSE 8080

CMD [ "node", "server.js" ]
