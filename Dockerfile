FROM node:iron-alpine3.19 AS build_image

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

#COPY package.json yarn.lock ./
RUN CYPRESS_INSTALL_BINARY=0 yarn install --network-timeout 1000000

COPY . ./

ARG COMMIT_TAG
ENV COMMIT_TAG=${COMMIT_TAG}

RUN npm install -g pnpm
RUN yarn build

# remove development dependencies
RUN yarn install --production --ignore-scripts --prefer-offline

RUN rm -rf src server .next/cache

RUN touch config/DOCKER

RUN echo "{\"commitTag\": \"main\"}" > committag.json


FROM node:iron-alpine3.19

WORKDIR /app

RUN apk add --no-cache tzdata tini && rm -rf /tmp/*

# copy from build image
COPY --from=build_image /app ./

ENTRYPOINT [ "/sbin/tini", "--" ]
CMD [ "yarn", "start" ]



EXPOSE 5055
