FROM node:jod-alpine@sha256:8094c002d08262dba12645a3b4a15cd6cd627d30bc782f53229a2ec13ee22a00 AS build_image

WORKDIR /app

ARG TARGETPLATFORM
ENV TARGETPLATFORM=${TARGETPLATFORM:-linux/amd64}

RUN \
  case "${TARGETPLATFORM}" in \
  'linux/arm64' | 'linux/arm/v7') \
  apk add --no-cache python3 make g++ && \
  ln -sf /usr/bin/python3 /usr/bin/python \
  ;; \
  esac

# Ensure we use PNPM instead of Yarn
RUN npm install -g pnpm@10

COPY . ./

# Install all dependencies (including devDependencies)
RUN pnpm install --frozen-lockfile

ARG COMMIT_TAG
ENV COMMIT_TAG=${COMMIT_TAG}

# Build the project using PNPM instead of Yarn
RUN pnpm build

# Clean up to reduce image size
RUN rm -rf src server .next/cache

RUN touch config/DOCKER

RUN echo "{\"commitTag\": \"${COMMIT_TAG}\"}" > committag.json


FROM node:jod-alpine@sha256:8094c002d08262dba12645a3b4a15cd6cd627d30bc782f53229a2ec13ee22a00

WORKDIR /app

RUN apk add --no-cache tzdata tini && rm -rf /tmp/*

# Ensure PNPM is available in the runtime image
RUN npm install -g pnpm@10

# Copy from build image
COPY --from=build_image /app ./

ENTRYPOINT [ "/sbin/tini", "--" ]
CMD [ "pnpm", "start" ]

EXPOSE 5055
