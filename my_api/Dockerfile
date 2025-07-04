# Stage 1: Compile the application
FROM dart:stable AS build

WORKDIR /app

# Install Dart Frog CLI
RUN dart pub global activate dart_frog_cli

# Copy project files
COPY . .

# Get dependencies
RUN dart pub get

# Generate production build
RUN dart_frog build

# Compile the generated server entrypoint
RUN dart compile exe build/bin/server.dart -o build/server


# Stage 2: Create the minimal production image
FROM alpine:latest

# Required for Dart executable to run on Alpine
RUN apk --no-cache add libc6-compat

WORKDIR /app

# Copy the compiled executable from the build stage
COPY --from=build /app/build/server .

# Expose the port
EXPOSE 8080

# Run the executable
CMD ["./server"]