# Match app/release_metadata.json. The official Apache image includes the
# Mautic runtime, PHP extensions, built assets, and its startup scripts.
FROM mautic/mautic:7.2.1-apache

USER root

# Apache otherwise guesses a Railway container hostname and logs AH00558.
RUN printf 'ServerName localhost\n' > /etc/apache2/conf-available/server-name.conf \
    && a2enconf server-name

# mod_php needs prefork. A second enabled MPM causes Apache's AH00534 crash.
RUN set -eu; \
    for module in event worker; do \
        if [ -e "/etc/apache2/mods-enabled/mpm_${module}.load" ]; then \
            a2dismod "mpm_${module}"; \
        fi; \
    done; \
    a2enmod mpm_prefork; \
    apache2ctl -t; \
    apache2-foreground -t

COPY --chmod=755 railway-entrypoint.sh /railway-entrypoint.sh

ENV PORT=80
EXPOSE 80

ENTRYPOINT ["/railway-entrypoint.sh"]
