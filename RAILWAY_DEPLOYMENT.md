# Mautic on Railway

This checkout reports Mautic **7.2.1** in `app/release_metadata.json`. The
`Dockerfile` runs the matching official `mautic/mautic:7.2.1-apache` release,
which includes its PHP dependencies and built assets. It does not build or
copy this source checkout into the image. If you change Mautic source code,
build a custom image for those changes separately.

The previous deployment's `AH00534: apache2: Configuration error: More than
one MPM loaded` means Apache had multiple multiprocessing modules enabled.
The Dockerfile keeps `mpm_prefork` for Apache with PHP and checks Apache's
configuration during the build. The later `Mautic is not installed, skipping
migrations` line is expected until the initial installation is completed.

## Railway setup

1. If Railway is connected directly to this `mautic` repository, leave the
   service **Root Directory** at `/`. If it is connected to the parent
   `packaging` repository, set **Root Directory** to `/mautic`. Railway detects
   `Dockerfile` at the selected root. Clear any old build or start command
   override so the image entrypoint starts.
2. Connect a MySQL service compatible with Mautic 7.2.1 (MySQL 8.4 or newer,
   or MariaDB 10.11 or newer).
3. Set these variables on the Mautic service. Replace `MySQL` below with the
   exact name of your Railway database service:

   ```text
   MAUTIC_DB_HOST=${{MySQL.MYSQLHOST}}
   MAUTIC_DB_PORT=${{MySQL.MYSQLPORT}}
   MAUTIC_DB_DATABASE=${{MySQL.MYSQLDATABASE}}
   MAUTIC_DB_USER=${{MySQL.MYSQLUSER}}
   MAUTIC_DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}
   DOCKER_MAUTIC_ROLE=mautic_web
   PORT=80
   ```

   Use `MAUTIC_DB_DATABASE`; the official image does not list
   `MAUTIC_DB_NAME` as its database name variable. Keep the database host and
   port in separate variables.

4. Attach **one Railway volume** to the Mautic service at `/data`. Railway
   sets `RAILWAY_VOLUME_MOUNT_PATH` for the container. The wrapper entrypoint
   stores `config`, `var/logs`, and `docroot/media` on that volume, then starts
   the official Mautic entrypoint. Set `RAILWAY_RUN_UID=0` if the volume
   reports a permissions error; the entrypoint assigns ownership of its data
   directories to `www-data`. If the current deployment already has Mautic
   data on a volume, move that data into the matching `/data` directories
   before changing its mount path.
5. Generate a public domain for the Mautic service and route it to port 80.
   After the first successful deploy, open that domain and complete the Mautic
   installer. Use the same database details as above if the installer asks.

The web role serves the UI. Mautic's [official image documentation](https://github.com/mautic/docker-mautic#roles)
describes separate cron and worker roles for scheduled campaigns and queues.
Plan those roles separately after the web installation is healthy; each
Railway service has its own single volume and volumes cannot be shared across
services.

## Checks

- The build should report `Syntax OK` from `apache2ctl -t`.
- Deploy logs should reach Apache startup without `AH00534`.
- The installer should load at the Railway domain. After completing it,
  restart the service and confirm that its configuration and uploaded media
  are still present.

References: [Apache MPM rules](https://httpd.apache.org/docs/current/mpm.html),
[official Mautic image and variables](https://github.com/mautic/docker-mautic),
[Railway Dockerfile detection](https://docs.railway.com/builds/dockerfiles),
[Railway volumes](https://docs.railway.com/volumes).
