# =========================================
# Stage 1: Build the React.js Application
# =========================================
ARG NODE_VERSION=22.14.0-alpine
ARG NGINX_VERSION=alpine3.21

# Use a lightweight Node.js image for building (customizable via ARG)
FROM node:${NODE_VERSION} AS builder

# Set the working directory inside the container
WORKDIR /app

# Install pnpm globally
RUN npm install -g pnpm

# Copy package-related files first to leverage Docker's caching mechanism
COPY --link package.json pnpm-lock.yaml ./

# Install project dependencies using pnpm with force flag to handle lockfile compatibility
RUN pnpm install --force

# Copy the rest of the application source code into the container
COPY --link . .

# Build the React.js application (outputs to /app/dist)
RUN pnpm run build

# =========================================
# Stage 2: Prepare Nginx to Serve Static Files
# =========================================

FROM nginxinc/nginx-unprivileged:${NGINX_VERSION} AS runner

# Use a built-in non-root user for security best practices
USER nginx

# Copy custom Nginx config
COPY --link nginx.conf /etc/nginx/nginx.conf

# Copy the static build output from the build stage to Nginx's default HTML serving directory
COPY --link --from=builder /app/dist /usr/share/nginx/html

# Expose port 8080 to allow HTTP traffic
# Note: The default NGINX container now listens on port 8080 instead of 80 
EXPOSE 8080

# Start Nginx directly with custom config
ENTRYPOINT ["nginx", "-c", "/etc/nginx/nginx.conf"]
CMD ["-g", "daemon off;"]

