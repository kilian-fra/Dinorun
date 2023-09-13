FROM dart:stable-sdk AS build

WORKDIR /app

ENV PATH="${PATH}:/root/.pub-cache/bin"
RUN dart pub global activate webdev
ADD pubspec.yaml pubspec.yaml
RUN dart pub get
ADD web/ web/
RUN webdev build --output web:build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
