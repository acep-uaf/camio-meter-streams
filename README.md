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
- FTP credentials for the meter
- Meter Configuration
- Must have installed:
    - `lftp`
    - `yq`
    - `zip`
    - `rsync`
    - `jq`

## Installation
1. Clone the repository:

    ```bash
    git clone git@github.com:acep-uaf/camio-meter-streams.git
    cd camio-meter-streams/cli_meter
    ```

    **Note**: You can check your SSH connection with `ssh -T git@github.com`

## Configuration

### General Configuration Steps
1. Navigate to the `config` directory and copy the example configuration file to a new file:

    ```bash
    cd config
    cp config.yml.example config.yml
    cp archive_config.yml.example archive_config.yml
    ```

2. **Update** the configuration files with the necessary details:
    - **`config.yml`**: Add the FTP server credentials and meter configuration data.
    - **`archive_config.yml`**: Add the source and destination directories and other relevant details.

3. Secure the configuration files so that only the owner can read and write:

    ```bash
    chmod 600 config.yml
    chmod 600 archive_config.yml
    ```

## Execution
To run the data pipeline and then transfer data to the Data Acquisition System (DAS):

1. **Run the Data Pipeline First**

    Execute the `data_pipeline` script from the `cli_meter` directory. The script requires a configuration file specified via the `-c/--config` flag. If this is your first time running the pipeline, the initial download may take a few hours. To pause the download safely, see: [How to Stop the Pipeline](#how-to-stop-the-pipeline)

    ### Command

    ```bash
    ./data_pipeline.sh -c config/config.yml
    ```

2. **Run the Archive Pipeline**

    After the `data_pipeline` script completes, execute the `archive_pipeline` script from the `cli_meter` directory. The script requires a configuration file specified via the `-c/--config` flag.

    ### Command

    ```bash
    ./archive_pipeline.sh -c config/archive_config.yml
    ```
    #### Notes
    The **rsync** uses the `--exclude` flag to exclude the `working` directory to ensure only complete files are transfered. 

3. **Run the Cleanup Process (Conditional)**

    If the `archive_pipeline` script completes successfully and the `enable_cleanup` flag is set to true in the archive configuration file, the `cleanup.sh` script will be executed automatically. This script removes outdated event files from `level0` based on the retention period specified in the configuration file.

    If the `enable_cleanup` flag is not enabled, you can run the cleanup manually by passing in the archive configuration file.

    ### Command

    ```bash
    ./cleanup.sh -c config/archive_config.yml
    ```
    
    #### Notes
    Ensure that the `archive_config.yml` file is properly configured with the retention periods for each directory in the cleanup process.

## How to Stop the Pipeline

When you need to stop the pipeline:

- **To Stop Safely/Pause Download**: 
  - Use `Ctrl+C` to interrupt the process. 
  - If interupting the proccess doesn't work try `Ctrl+\` to quit.
  - If you would like to resume the download, rerun the `data_pipeline`command.The download will resume from where it left off, provided the same config file (`-c`)is used.
- **Avoid Using `Ctrl+Z`**: 
  - **Do not** use `Ctrl+Z` to suspend the process, as it may cause the pipeline to end without properly closing the FTP connection.

## Testing (IN PROGRESS)

This repository includes automated tests for the scripts using [Bats (Bash Automated Testing System)](https://github.com/bats-core/bats-core) along with helper libraries: `bats-assert`, `bats-mock`, and `bats-support`. The tests are located in the `test` directory.

### Prerequisites

Ensure you have cloned the repository with its required submodules, they should be located under the `test` and `test/test_helper` directories:
- `bats-core`
- `bats-assert`
- `bats-mock`
- `bats-support`

1. **Clone the repository with submodules**:

    ```bash
    git clone --recurse-submodules git@github.com:acep-uaf/camio-meter-streams.git
    ```

    If you have already cloned the repository without submodules, you can initialize and update them with:

    ```bash
    git submodule update --init --recursive
    ```

### Running the Tests

1. **Navigate to the project directory**:

    ```bash
    cd /path/to/camio-meter-streams/cli_meter
    ```

2. **Run all the tests**:

    ```bash
    bats test
    ```