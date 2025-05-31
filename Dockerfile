FROM node:jod-alpine@sha256:fa5f57793a2553cd6d40ef234d8f51c4c1df73284f14acf877e36bb7801d257c AS build_image

WORKDIR /app

ARG TARGETPLATFORM
ENV TARGETPLATFORM=${TARGETPLATFORM:-linux/amd64}

RUN \
  case "${TARGETPLATFORM}" in \
  'linux/arm64' | 'linux/arm/v7') \
  apk add --no-cache python3 make g++ && \
  ln -s /usr/bin/python3 /usr/bin/python \
  ;; \
  esac

# Ensure we use PNPM instead of Yarn
RUN npm install -g pnpm@9

COPY package.json pnpm-lock.yaml postinstall-win.js ./

# Install all dependencies (including devDependencies)
RUN pnpm install --frozen-lockfile

COPY . ./

ARG COMMIT_TAG
ENV COMMIT_TAG=${COMMIT_TAG}

# Build the project using PNPM instead of Yarn
RUN pnpm build

# Clean up to reduce image size
RUN rm -rf src server .next/cache

RUN touch config/DOCKER

RUN echo "{\"commitTag\": \"main\"}" > committag.json


FROM node:jod-alpine@sha256:fa5f57793a2553cd6d40ef234d8f51c4c1df73284f14acf877e36bb7801d257c

WORKDIR /app

RUN apk add --no-cache tzdata tini && rm -rf /tmp/*

# Ensure PNPM is available in the runtime image
RUN npm install -g pnpm@9

# Copy from build image
COPY --from=build_image /app ./

ENTRYPOINT [ "/sbin/tini", "--" ]
CMD [ "pnpm", "start" ]

EXPOSE 5055
