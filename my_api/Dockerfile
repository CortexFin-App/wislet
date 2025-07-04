# Stage 1: Compile the application
FROM dart:stable AS build

WORKDIR /app

# Install Dart Frog CLI
RUN dart pub global activate dart_frog_cli

# Copy all project files
COPY . .

# Get dependencies
RUN dart pub get

# Generate production build (this creates the .dart_frog folder)
RUN dart_frog build

# Compile the generated server entrypoint into a single executable
RUN dart compile exe build/bin/server.dart -o build/server

# Stage 2: Create the minimal production image from scratch
FROM scratch

# Copy the compiled executable from the build stage
COPY --from=build /app/build/server /app/server

# Copy runtime dependencies for Dart executable
COPY --from=build /runtime/ /

# Expose the port
EXPOSE 8080

# The command to run the executable
CMD ["/app/server"]