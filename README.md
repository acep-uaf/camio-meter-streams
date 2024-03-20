# SEL-735 Meter Event Data Pipeline (IN PROGRESS 03/13/24)

This repository contains a set of Bash scripts that make up a data pipeline, designed to automate the process of interacting with an SEL-735 meter. The pipeline **currently** handles:
- Connecting to the meter via FTP
- Checking for new event files
- Downloading event files
- Organizing and creating metadata

## Prerequisites
Ensure you have the following before running the pipeline:

- Unix-like environment (Linux, macOS, or a Unix-like Windows terminal)
- Access to the `ot-dev` server with **admin priveledges**, FTP credentials, and meter details.
- Installed on `ot-dev`:
    - `lftp` — FTP operations
    - `jq` — JSON metadata
    - `yq` - YAML config files

## Installation
1. You must be connected to the `ot-dev` server. See **OT-dev(SSH)** in the [ACEP Wiki](https://wiki.acep.uaf.edu/en/teams/data-ducts/aetb).
 
2. Clone the repository and prepare the scripts:

    ```bash
    git clone git@github.com:acep-uaf/data-ducks-STREAM.git
    cd data-ducks-STREAM/cli_meter
    chmod +x *.sh
    ```
    **Note**: You can check your SSH connection with `ssh -T git@github.com`

## Configuration
1. Navigate and copy the `config.yml.example` file to a new `config.yml` file:

    ```bash
    cp config.yml.example config.yml
    ```

2. **Update** the config file with the FTP credentials and meter details.

3. Secure the `config.yml` file so that only the owner can read and write:

    ```bash
    chmod 600 config.yml
    ```

## Usage
You must have admin privledges to run the data pipeline from the `cli_meter` directory:

```bash
sudo ./data_pipeline.sh
```

# rsync Service

Manage file transfers with rsync_stream.service. Use `systemctl` to start, stop, enable, disable, or check the service:

**Service**: `rsync_stream.service` (see `stream.sh`)

**Start**
```bash
sudo systemctl start your-service-name.service
```

**Stop**
```bash
sudo systemctl stop your-service-name.service
```

**Enable on Boot**
```bash
sudo systemctl enable your-service-name.service
```

**Disable on Boot**
```bash
sudo systemctl disable your-service-name.service
```

**Status**
```bash
sudo systemctl status your-service-name.service
```

