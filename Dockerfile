FROM node:10

WORKDIR /srv

COPY package.json /srv/
COPY package-lock.json /srv/

RUN mkdir /srv/node_modules \
    && chown -R node /srv/node_modules

USER node
RUN npm install --production

USER root
COPY app /srv/app

RUN mkdir -p /srv/app/admin/build \
    && chown -R node /srv/app/admin/build \
    && chown -R node /srv/app/admin/src \
    && mkdir -p /srv/app/files/temp \
    && chown -R node /srv/app/files/temp \
    && mkdir -p /srv/app/routes/temp \
    && chown -R node /srv/app/routes/temp

USER node
RUN npm run build

EXPOSE 3000

CMD ["./app/bin/www"]
