FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server
# Bundle the wordbook catalog the server reads at runtime (File('data/...')).
# WORKDIR sets cwd=/app so the relative path resolves to /app/data/.
COPY --from=build /app/data /app/data
WORKDIR /app
EXPOSE 8080
CMD ["/app/bin/server"]
