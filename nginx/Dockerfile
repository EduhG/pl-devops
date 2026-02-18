FROM nginx:1.27-alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/nginx.conf

# Non-root nginx
RUN addgroup -g 1000 app \
    && adduser -G app -g app -s /bin/sh -D app

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
