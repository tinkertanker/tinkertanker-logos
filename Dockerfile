FROM nginxinc/nginx-unprivileged:1.29-alpine

USER root

COPY --chmod=644 nginx.conf /etc/nginx/conf.d/default.conf
COPY --chmod=644 site /usr/share/nginx/html
COPY --chmod=644 logos /usr/share/nginx/html/logos

RUN chmod 755 /usr/share/nginx/html/logos

USER 101

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1

