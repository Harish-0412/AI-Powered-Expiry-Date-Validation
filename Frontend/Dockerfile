# Start from the official Node.js Alpine base image
FROM node:20-alpine

# Set working directory inside the container
WORKDIR /app

# Copy dependency definition files
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Copy application source code
COPY . .

# Build the production Next.js app
RUN npm run build

# Expose Next.js port
EXPOSE 3000

# Start the Next.js production server
CMD ["npm", "run", "start"]
