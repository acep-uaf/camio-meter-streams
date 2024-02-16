# IN PROGRESS: SEL-735 Meter Data Pipeline

This repository contains a set of Bash scripts that make up a data pipeline, designed to automate the process of interacting with an SEL-735 meter. The pipeline handles tasks such as connecting to the meter via FTP, downloading files, organizing and renaming data, and archiving the files for further use.

## Prerequisites
Ensure you have the following before running the pipeline:

- A Unix-like environment (Linux, macOS, or a Unix-like terminal in Windows)
- FTP access credentials (username and password) for the SEL-735 meter
- The following must be installed on your system:
    - `ftp` or `lftp` — for FTP operations
    - `jq` — if working with JSON data

## Installation
1. Clone the repository to your local machine and navigate to the CLI_METER directory:

    ```bash
    git clone [repo url]
    cd data-ducks-STREAM/CLI_METER
    ```

2. Make all scripts executable:

    ```bash
    chmod +x *.sh
    ```

    This will ensure that all `.sh` files in the directory are executable.

## Configuration
1. Copy the template environment variables file to a new `.env` file:

    ```bash
    cp .env.example .env
    ```

2. Update the `.env` file with your FTP server details.

3. Secure the `.env` file so that only the owner can read and write:

    ```bash
    chmod 600 .env
    ```

## Usage
To start the data pipeline, execute the `data-pipeline.sh` script:

```bash
./data_pipeline.sh
```

## rsync 

created a service to run for moving files (see stream.sh script)
service name is rsync_stream.service


With this unit file, `systemd` will manage your script as a service, meaning you can start, stop, restart, and check the status of the service using `systemctl` commands.

To start the service:
```bash
sudo systemctl start your-service-name.service
```

To stop the service:
```bash
sudo systemctl stop your-service-name.service
```

To enable the service to start on boot:
```bash
sudo systemctl enable your-service-name.service
```

To disable the service from starting on boot:
```bash
sudo systemctl disable your-service-name.service
```

To check the status of the service:
```bash
sudo systemctl status your-service-name.service
```

