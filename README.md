# Dockerized Jottacloud Client

> [!NOTE]
> I no longer use Jottacloud with Docker, so I will no longer maintain this repository.
> Check out [bluet/docker-jottacloud](https://github.com/bluet/docker-jottacloud) which seems to still be maintained.

Docker of Jottacloud client side backup daemon with jotta-cli and jottad inside.

Jottacloud is a Cloud Storage (backup) service provider, which offers [unlimited storage space](https://www.jottacloud.com/en/pricing.html) for personal use.

Support platforms: linux/amd64, linux/arm64

## Docker compose usage example

You should ensure that `/etc/timezone` and `/etc/localtime` are set to the correct values for the host machine, and mount those as volumes.

```
  jottacloud:
    container_name: jottacloud
    restart: unless-stopped
    image: ghcr.io/haakemon/docker-jottacloud:vX.X.X
    environment:
      - JOTTA_TOKEN_FILE=/run/secrets/jotta_token
      - JOTTA_DEVICE=DeviceName
      - GLOBAL_IGNORE=comma-separated,paths-to-ignore,globally # without quotes
    secrets:
      - jotta_token
    networks:
      - t2_proxy
    volumes:
      - /etc/timezone:/etc/timezone:ro # ensure timezone is same as host
      - /etc/localtime:/etc/localtime:ro # ensure localtime is same as host
      - "/jottacloud/config:/data/jottad"
      # Backup directories:
      - "/photos:/backup/photos:ro"
      - "/documents:/backup/documents:ro"
```

## Volume mount-points
Path | Description
------------ | -------------
/data/jottad | Config and data. In order to keep login status and track backup progress, please use a persistent volume.
/backup/ | Data you want to backup.

## ENV variables
A token is required and can be obtained from the Jottacloud dashboard [Settings -> Security](https://www.jottacloud.com/web/secure).

Name | Default | Description
------------ | ------------ | ------------
JOTTA_TOKEN |  | access token for Jottacloud. Should prefer to use `JOTTA_TOKEN_FILE`` instead.
JOTTA_TOKEN_FILE | | An alternative to `JOTTA_TOKEN`, so you can use docker secrets. Set this to the path to the secret file, f.ex `JOTTA_TOKEN_FILE=/run/secrets/jotta_token`. If both `JOTTA_TOKEN` and `JOTTA_TOKEN_FILE` is set, `JOTTA_TOKEN_FILE` will take priority.
JOTTA_DEVICE | `docker-jottacloud` | Device name of the backup machine.  Used for identifying which machine these backup data belongs to.
JOTTA_SCANINTERVAL | `12h` | Interval time of the scan-and-backup. Should be a number followed by `h` for hours `m` for minutes or `s` for seconds. Example: `2h` for every 2 hours, or `2h30m` every 2,5 hours.
STARTUP_TIMEOUT | `15` | How many seconds to wait before retry startup.
GLOBAL_IGNORE | | A comma separated list of paths for paths to ignore. This list is applied globally. See [details about ignoring files in the documentation](https://docs.jottacloud.com/en/articles/1437235-ignoring-files-and-folders-from-backup-with-jottacloud-cli). Currently the `--backup` parameter is not supported in this image.

# Official configuration guide of jotta-cli
- [Jottacloud CLI Configuration
](https://docs.jottacloud.com/en/articles/2750154-jottacloud-cli-configuration)
- [Ignoring files and folders from backup with Jottacloud CLI](https://docs.jottacloud.com/en/articles/1437235-ignoring-files-and-folders-from-backup-with-jottacloud-cli)

# Credit
This is a fork from [bluet/docker-jottacloud](https://github.com/bluet/docker-jottacloud) with some minor adjustments
