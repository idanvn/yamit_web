# Static business card — no build step, no runtime deps. The image is just the
# assets plus a hardened nginx. Single stage is correct here: there is nothing
# to compile or bundle, so a builder stage would add layers for no benefit.
#
# nginx-unprivileged: official nginx that runs as uid/gid 101 and listens on
# 8080 instead of 80. Lets us run non-root + read-only + cap_drop ALL without
# any extra setcap dance. Pinned to a minor version (never :latest).
FROM nginxinc/nginx-unprivileged:1.27-alpine

# Server config replaces the default vhost (also a :8080 listener).
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Content. Copied last because it changes most often — keeps the (tiny) base
# layers cached across rebuilds.
COPY index.html              /usr/share/nginx/html/index.html
COPY accessibility.html      /usr/share/nginx/html/accessibility.html
COPY contact.vcf             /usr/share/nginx/html/contact.vcf
COPY public/                 /usr/share/nginx/html/public/

EXPOSE 8080

# Image-level healthcheck so `docker run` (outside compose) is also covered.
# busybox wget ships in the alpine base; --spider does a HEAD-style check.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost:8080/healthz || exit 1

# Base image already sets USER 101 and the nginx entrypoint/CMD.
