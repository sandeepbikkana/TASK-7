# Docker – Learning Notes

This document summarizes understanding of Docker in depth, including **why it exists**, how it differs from **virtual machines**, its **architecture**, and practical topics like **Dockerfiles, commands, networking, volumes, and Docker Compose**.

---

## 1. What Problem Does Docker Solve?

Modern applications are made of many moving parts: application code, runtimes, libraries, OS-level dependencies, configuration, environment variables, etc. Moving such an app from:

- a developer’s laptop → CI server → staging → production  
often leads to:

- “It works on my machine” issues  
- Configuration drift between environments  
- Slow and fragile deployment processes

### 1.1 Key Problems Before Docker

1. **Environment Drift**  
   - Different OS versions, installed packages, and configs cause bugs that are hard to reproduce.
   - One server might have `Python 3.10`, another `3.8`, or missing system libraries.

2. **Dependency Hell**  
   - Multiple apps needing different versions of the same dependency on the same host.
   - Risk of breaking one app when updating libraries for another.

3. **Heavy & Slow Virtual Machines**  
   - VMs require a full guest OS per app stack.
   - Slow boot times and high resource usage (CPU, RAM, disk).

4. **Complex Deployment & Scaling**  
   - Deployment scripts tied to specific OS environments.
   - Scaling requires provisioning full VMs, which is slow and expensive.

### 1.2 How Docker Solves These

- **Containerization**: Package app + its dependencies as a **container image**.
- **Consistency**: The same image is used everywhere (dev, test, prod).
- **Speed**: Containers start in seconds (no full OS boot).
- **Isolation**: Each container has its own filesystem, processes, network namespace.
- **Efficiency**: All containers on a host share the **same OS kernel**, reducing overhead.

---

## 2. Virtual Machines vs Docker Containers

### 2.1 Conceptual Difference

**Virtual Machine:**
- Emulates hardware and runs a full guest OS.
- Each VM has its own kernel, drivers, OS, and applications.

**Container:**
- Shares the host OS kernel.
- Isolated at process, filesystem, and network level.
- Uses OS features like namespaces & cgroups.

### 2.2 Layer Comparison

**Virtual Machine Stack:**
- Physical Hardware  
- Host OS  
- Hypervisor (e.g., VMware, Hyper-V)  
- Guest OS (per VM)  
- Application + Dependencies  

**Container Stack:**
- Physical Hardware  
- Host OS  
- Docker Engine / Container Runtime  
- Containers (app + dependencies, **no full OS** per container)

### 2.3 Practical Differences

| Aspect              | Virtual Machines                         | Docker Containers                                      |
|---------------------|------------------------------------------|--------------------------------------------------------|
| OS per instance     | Full guest OS                            | Shared host kernel                                     |
| Resource overhead   | High (GBs of RAM & disk)                 | Low (MBs, lightweight)                                 |
| Startup time        | Seconds to minutes                       | Usually milliseconds to seconds                        |
| Isolation           | Strong (hypervisor-based)                | Strong, but kernel is shared                           |
| Use cases           | Different OSes, strong isolation         | Microservices, CI/CD, scalable cloud-native apps       |
| Density             | Fewer VMs per host                       | Many containers per host                               |

### 2.4 When to Use What

- **VMs**:
  - Need different OS types (Linux + Windows).
  - Need hard multi-tenant isolation.
- **Containers**:
  - Microservices architecture.
  - CI/CD pipelines.
  - Quickly spinning up consistent dev/test environments.

---

## 3. Docker Architecture – What Gets Installed?

When Docker is installed, several components work together:

### 3.1 Main Components

1. **Docker Daemon (`dockerd`)**
   - Runs in the background.
   - Responsible for:
     - Building images
     - Running and stopping containers
     - Managing networks and volumes
   - Listens on a **REST API** (usually a Unix socket or TCP).

2. **Docker CLI (`docker`)**
   - Command-line tool you use.
   - When you run `docker run ...`, it sends a request to the **Docker Daemon**.

3. **Container Runtime**
   - Low-level software used by Docker Daemon to actually run containers.
   - Typically `containerd` and `runc`.

4. **Images**
   - Read-only templates used to create containers.
   - Built from Dockerfiles or pulled from registries.

5. **Registries**
   - Remote stores for images (e.g., Docker Hub, private registries).
   - `docker push` / `docker pull` interact with registries.

6. **Networks & Volumes**
   - Docker-managed networks: allow containers to talk to each other.
   - Volumes: handle persistent data storage for containers.

### 3.2 What Gets Installed on Different OSes (High-Level)

- **Linux**:
  - `dockerd`, `docker` CLI, container runtime.
  - Runs natively on the Linux kernel.

- **Windows / macOS (Docker Desktop)**:
  - A lightweight Linux VM is created behind the scenes.
  - Containers actually run inside that VM because Docker needs Linux kernel features.

### 3.3 Request Flow

1. User runs `docker run nginx`.
2. Docker CLI sends a request to Docker Daemon: “run nginx with these options”.
3. Daemon:
   - Pulls `nginx` image if it’s not local.
   - Creates a container from that image.
   - Sets up network, mounts volumes, etc.
   - Starts the container using the runtime.
4. Container runs the process defined by `CMD` or `ENTRYPOINT`.

---

## 4. Dockerfile Deep Dive

A **Dockerfile** is a text file with instructions to build a Docker image.

### 4.1 How Builds Work

- Docker reads the Dockerfile **top to bottom**.
- Each instruction creates a **layer**.
- Docker caches layers; if nothing changed, it reuses them to speed up builds.
- The final image is a stack of layers.

### 4.2 Common Instructions and Their Purpose

Below is a more advanced example Dockerfile:

```dockerfile
# 1. Use a lightweight base image
FROM node:18-alpine AS builder

# 2. Set build-time arguments (optional)
ARG NODE_ENV=production

# 3. Set environment variables
ENV NODE_ENV=${NODE_ENV}

# 4. Set working directory
WORKDIR /usr/src/app

# 5. Copy only package files first (to use build cache)
COPY package*.json ./

# 6. Install dependencies
RUN npm install

# 7. Copy application source code
COPY . .

# 8. Build the app (for frontend or TypeScript, etc.)
RUN npm run build

# 9. Use a smaller runtime image (multi-stage build)
FROM node:18-alpine AS runtime

# 10. Set working directory in final image
WORKDIR /usr/src/app

# 11. Copy build artifacts and required files from builder stage
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/package*.json ./

# 12. Install only production dependencies
RUN npm install --omit=dev

# 13. Expose application port
EXPOSE 3000

# 14. Set a non-root user (security best-practice)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# 15. Define default command
CMD ["node", "dist/server.js"]


4.3 Explanation of Key Instructions

FROM <image>[:tag]
Sets the base image. Can specify a stage name (e.g. AS builder) for multi-stage builds.

ARG
Build-time variable. Available only at build time, not at runtime (unless passed into ENV).

ENV
Sets environment variables available inside the container at runtime.

WORKDIR
Sets the working directory for subsequent instructions. Creates it if it doesn’t exist.

COPY
Copies files from the build context (the directory you run docker build from) into the image.

RUN
Executes commands at build time (e.g., install packages). The result is baked into the image.

EXPOSE
Documentation for which port the container listens on. Doesn’t publish the port by itself (that happens with -p).

USER
Specifies which user the container runs as (avoiding root in production is a good practice).

CMD vs ENTRYPOINT

CMD defines default arguments or command.

ENTRYPOINT defines the main executable.

Common pattern:

ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]


Then docker run can override only CMD arguments.

HEALTHCHECK (optional but important)

HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:3000/health || exit 1


Helps orchestrators know if the container is healthy.

LABEL

Add metadata, e.g. maintainer, description, version, etc.

4.4 Best Practices

Use small base images (e.g. alpine) when possible.

Use multi-stage builds to reduce final image size.

Use .dockerignore to exclude unneeded files.

Avoid putting secrets (passwords, tokens) directly in Dockerfiles.

5. Key Docker Commands (Deep Dive)

5.1 Basic Info
docker version         # Docker client & server versions
docker info            # Detailed system-wide info

5.2 Image Management
docker pull <image[:tag]>        # Download image
docker build -t myapp:1.0 .      # Build image from Dockerfile
docker images                    # List local images
docker rmi <image-id>            # Remove image
docker tag myapp:1.0 repo/myapp:1.0   # Tag image for registry
docker push repo/myapp:1.0       # Push image to registry

5.3 Container Lifecycle
docker run <image>               # Run in foreground
docker run -d <image>            # Run in detached mode (background)
docker run --name myapp <image>  # Assign a container name
docker run -p 8080:80 nginx      # Map host:port to container:port

docker ps                        # List running containers
docker ps -a                     # List all containers (including stopped)
docker stop <container-id>       # Gracefully stop
docker kill <container-id>       # Force kill
docker rm <container-id>         # Remove container
docker restart <container-id>    # Restart container

5.4 Inspect & Debug
docker logs <container-id>             # View logs
docker logs -f <container-id>          # Follow logs (like tail -f)

docker inspect <container-id-or-name>  # JSON details (config, network, volumes)
docker top <container-id>              # Show running processes inside container

docker exec -it <container-id> sh      # Open shell in container (sh or bash)

5.5 Clean Up
docker system df            # Show disk usage
docker system prune         # Remove unused data (prompt)
docker system prune -af     # Aggressive cleanup (careful!)
docker volume prune         # Remove unused volumes
docker network prune        # Remove unused networks

6. Docker Networking (Deep Dive)

Docker uses Linux networking features to give containers their own network stack.

6.1 Network Drivers

bridge (default for standalone containers)

Containers get an IP on a private bridge network.

Can talk to each other via container name if on same custom bridge.

Host can map ports using -p hostPort:containerPort.

host

Container shares the host’s network stack.

No port mapping; it directly uses host ports.

Useful for performance-sensitive or low-level networking apps.

none

No network access.

Only loopback (localhost inside container).

overlay (for multi-host / Swarm)

Virtual network spanning multiple Docker hosts.

Used mainly with Docker Swarm or similar orchestrators.

6.2 Creating Custom Networks

Custom bridge networks improve service discovery:

docker network create mynet

docker run -d --name db --network mynet postgres
docker run -d --name api --network mynet my-api-image


Within mynet, the api container can reach db using the hostname db.

Docker’s internal DNS resolves container names.

6.3 Port Mapping

-p 8080:80
Host port 8080 → Container port 80.

Example:

docker run -d -p 8080:80 --name webserver nginx


Access http://localhost:8080 on host; it forwards to Nginx on port 80 in the container.

7. Volumes & Persistence (Deep Dive)

By default, a container’s filesystem is ephemeral: if the container is removed, its data is lost.

7.1 Options for Data

Container Layer (ephemeral)

Changes to container’s filesystem are lost when the container is deleted.

Named Volumes

Managed by Docker.

Stored in Docker’s data directory (e.g. /var/lib/docker/volumes/...).

Independent of container lifecycle.

Good for databases and persistent app data.

docker volume create mydata
docker run -v mydata:/var/lib/mysql mysql


Bind Mounts

Map a host directory into the container.

Great for local development.

docker run -v /path/on/host:/app my-image


tmpfs Mounts

Data stored in memory only.

Disappears when container stops.

Good for sensitive or temporary data.

7.2 Volume Use Cases

Databases: MySQL, PostgreSQL, MongoDB store data in volumes.

Development: Bind mount source code so changes reflect live in container.

Backups: Volumes can be backed up/restored on the host.

7.3 Good Practices

Use named volumes for app data in production.

Use bind mounts in development to avoid rebuilding image on every change.

Be aware of file permissions (user inside container vs user on host).

8. Docker Compose (Deep Dive)

Docker Compose is a tool to define and run multi-container applications using a docker-compose.yml file.

8.1 Why Compose?

Without Compose, you’d start each container manually:

docker run ...
docker run ...
docker run ...


With Compose, you define everything in a YAML file and run:

docker compose up

8.2 Example docker-compose.yml
version: "3.9"

services:
  app:
    build: .
    container_name: myapp
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
    depends_on:
      - db
    restart: always

  db:
    image: postgres:15-alpine
    container_name: mydb
    environment:
      - POSTGRES_USER=myuser
      - POSTGRES_PASSWORD=mypass
      - POSTGRES_DB=mydb
    volumes:
      - dbdata:/var/lib/postgresql/data
    restart: always

volumes:
  dbdata:

8.3 Key Compose Concepts

services: Each service corresponds to a container or a group of containers (app, db, cache).

build: Build from Dockerfile in the given context directory.

image: Use an existing image (skip build).

ports: Map ports (host:container).

environment: Set environment variables.

volumes: Attach volumes (named or bind mounts).

depends_on: Start order; ensures db starts before app.

restart: Policy like no, always, on-failure, unless-stopped.

8.4 Common Compose Commands
docker compose up           # Start services (foreground)
docker compose up -d        # Start in detached mode
docker compose down         # Stop and remove containers, networks
docker compose down -v      # Also remove volumes (careful)
docker compose logs         # Show logs for all services
docker compose logs -f app  # Follow logs for specific service
docker compose ps           # Show running services
docker compose build        # Build or rebuild images
