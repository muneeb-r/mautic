#!/bin/sh
set -eu

# Railway permits one volume per service. Keep Mautic's three writable paths
# under that mount while leaving the official image's application code intact.
if [ -n "${RAILWAY_VOLUME_MOUNT_PATH:-}" ]; then
    data_dir="$RAILWAY_VOLUME_MOUNT_PATH"

    for relative_path in config var/logs docroot/media; do
        image_path="/var/www/html/$relative_path"
        data_path="$data_dir/$relative_path"

        mkdir -p "$(dirname "$data_path")" "$data_path"

        if [ ! -e "$data_path/.railway-initialized" ]; then
            if [ -d "$image_path" ] && [ ! -L "$image_path" ]; then
                cp -a "$image_path/." "$data_path/"
            fi
            chown -R www-data:www-data "$data_path"
            touch "$data_path/.railway-initialized"
        fi

        if [ ! -L "$image_path" ]; then
            if [ -e "$image_path" ]; then
                mv "$image_path" "${image_path}.image"
            fi
            ln -s "$data_path" "$image_path"
        fi
    done

    install -d -o www-data -g www-data \
        "$data_dir/docroot/media/files" "$data_dir/docroot/media/images"

    # The official entrypoint checks these paths with stat and reads local.php
    # from MAUTIC_VOLUME_CONFIG. Point it at the real volume directories.
    export MAUTIC_VOLUME_CONFIG="$data_dir/config"
    export MAUTIC_VOLUME_LOGS="$data_dir/var/logs"
    export MAUTIC_VOLUME_MEDIA="$data_dir/docroot/media"
    export MAUTIC_VOLUME_FILES="$data_dir/docroot/media/files"
    export MAUTIC_VOLUME_IMAGES="$data_dir/docroot/media/images"
fi

exec /entrypoint.sh "$@"
