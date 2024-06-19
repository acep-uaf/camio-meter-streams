# SEL-735 Meter Event Data Pipeline

This repository contains a set of Bash scripts that make up a data pipeline, designed to automate the process of interacting with an SEL-735 meter. The pipeline is divided into two main executable scripts:

1. **`data_pipeline.sh`**: Handles the first four steps:
    - Connecting to the meter via FTP
    - Downloading new files
    - Organizing and creating metadata
    - Compressing data

2. **`archive_pipeline.sh`**: Handles the final step:
    - Archiving and transferring event data to the Data Acquisition System (DAS)


## Prerequisites
Ensure you have the following before running the pipeline:
- Unix-like environment (Linux, macOS, or a Unix-like Windows terminal)
- Able to `ssh` to the **ot-dev** and **das.lab.acep.uaf.edu** servers
- FTP credentials for the meter
- Meter Configuration
- Installed on `camio-ot-dev`:
    - `lftp` — FTP Operations
    - `yq` - YAML Parsing
    - `zip` - Compressing Data
    - `rsync` — Transfering Data
    - `jq` — JSON Parsing

## Installation
1. You must be connected to the `camio-ot-dev` server. See **camio-ot-dev(SSH)** in the [ACEP Wiki](https://wiki.acep.uaf.edu/en/teams/data-ducts/aetb).

2. Clone the repository:

    ```bash
    git clone git@github.com:acep-uaf/camio-meter-streams.git
    cd camio-meter-streams/cli_meter
    ```

    **Note**: You can check your SSH connection with `ssh -T git@github.com`

## Configuration

### Data Pipeline Configuration
1. Navigate to the `config` directory and copy the `config.yml.example` file to a new `config.yml` file:

    ```bash
    cd config
    cp config.yml.example config.yml
    ```

2. **Update** the `config.yml` file with the FTP credentials and meter configuration data.

3. Secure the `config.yml` file so that only the owner can read and write:

    ```bash
    chmod 600 config.yml
    ```

### Archive Pipeline Configuration
1. Navigate to the `config` directory and copy the `archive_config.yml.example` file to a new `archive_config.yml` file:

    ```bash
    cd config
    cp archive_config.yml.example archive_config.yml
    ```

2. **Update** the `archive_config.yml` file with the necessary broker information, as well as source and destination details.

3. Secure the `archive_config.yml` file so that only the owner can read and write:

    ```bash
    chmod 600 archive_config.yml
    ```

## Execution
To run the data pipeline and then transfer data to the Data Acquisition System (DAS):

1. **Run the Data Pipeline First**

    Execute the `data_pipeline` script from the `cli_meter` directory. The script requires a configuration file specified via the `-c/--config` flag. If this is your first time running the pipeline, the initial download may take a few hours. To pause the download safely, see: [How to Stop the Pipeline](#how-to-stop-the-pipeline)

    ### Command

    ```bash
    ./data_pipeline.sh -c /path/to/config.yml
    ```

    ### Optional Flag 
    Optionally, you can use the `-d/--download_dir` flag to override the download directory from the config file.

    ```bash
    ./data_pipeline.sh -c /path/to/config.yml -d /path/to/download/dir/
    ```

2. **Run the Archive Pipeline**

    After the `data_pipeline` script completes, execute the `archive_pipeline` script from the `cli_meter` directory. The script requires a configuration file specified via the `-c/--config` flag.

    ### Command

    ```bash
    ./archive_pipeline.sh -c /path/to/archive_config.yml
    ```
    #### Notes
    The **rsync** uses the `--exclude` flag to exclude the `working` directory to ensure only complete files are transfered. 

## How to Stop the Pipeline

When you need to stop the pipeline:

- **To Stop Safely/Pause Download**: 
  - Use `Ctrl+C` to interrupt the process. 
  - If you would like to resume the download, rerun the `data_pipeline`command.The download will resume from where it left off, provided the same config file (`-c`)and download path (`-d`) are used.
- **Avoid Using `Ctrl+Z`**: 
  - **Do not** use `Ctrl+Z` to suspend the process, as it may cause the pipeline to end without properly closing the FTP connection.
