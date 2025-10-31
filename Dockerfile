FROM node:24-bullseye-slim AS base

RUN corepack enable

FROM base AS production_buildstage

WORKDIR /home/node/app
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn .yarn

RUN yarn install --immutable

COPY --chown=node:node . ./
RUN npm run build

FROM base AS production

RUN apt-get update && \
    apt-get install -y postgresql-client && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /home/node/app && \
    chown node:node /home/node/app

ENV NODE_ENV=production

WORKDIR /home/node/app
COPY --chown=node:node package.json yarn.lock .yarnrc.yml entrypoint.sh ./
COPY --chown=node:node .yarn .yarn
RUN chmod +x entrypoint.sh

USER node
RUN yarn workspaces focus --production

COPY --from=production_buildstage /home/node/app/dist /home/node/app/dist

CMD ["./entrypoint.sh"]

FROM base AS development

WORKDIR /home/node/app
