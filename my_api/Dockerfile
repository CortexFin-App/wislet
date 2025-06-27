# Stage 1: Build the application
FROM dart:stable AS build

WORKDIR /app

# Copy and get dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy the rest of the application
COPY . .

# Build the executable from the correct source path
RUN dart compile exe bin/server.dart -o build/bin/server

# Stage 2: Create the minimal production image
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/build/ /app/build/
COPY --from=build /app/public/ /app/public/

# Expose port and run the server
EXPOSE 8080
CMD ["/app/build/bin/server"]