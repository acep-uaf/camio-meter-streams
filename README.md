# SEL-735 Meter and SCADA Data Pipeline

This repository contains a set of Bash scripts designed to automate the retrieval and organization of event data from SEL-735 meters, the synchronization of SCADA data between directories, and the archival of data to a dedicated remote server.

## Pipeline Overview
Each of the following scripts are executed seperately and have their own config file.

1. **`data_pipeline.sh`**
    
    Handles fetching and organizing raw event data from SEL-735 meters via FTP:
    - Connects to the meter
    - Downloads new event data
    - Organizes directory structure and creates metadata
    - Adds checksums
    - Compresses raw data into `.zip`
    - Generates `.message` file to be ingest by [data-streams-das-mqtt-pub](https://github.com/acep-uaf/data-streams-das-mqtt-pub)

1. **`sync-scada-data.sh`**

    Synchronizes SCADA data from a source directory to a destination directory:
    - Supports syncing data over a configurable number of past months
    - **TO DO**: Exclude current days data to avoid syncing partially written files.

1. **`archive_pipeline.sh`**

    Transfers downloaded and processed meter data to a dedicated server:
    - Uses `rsync` to transfer data to remote server
    - Automatically triggers a cleanup script if enabled via config

## Installation

1. Ensure you have the following before running the pipeline:
    - Unix-like environment (Linux, macOS, or a Unix-like Windows terminal)
    - FTP credentials for the meter
    - Meter Configuration
    - Must have installed: `lftp`, `yq`, `zip`, `rsync`, `jq`

1. Clone the repository:

    ```bash
    git clone git@github.com:acep-uaf/camio-meter-streams.git
    cd camio-meter-streams/cli_meter
    ```

## Configuration

Each script uses its own YAML configuration file located in the `config/` directory.

1. **Navigate to the config directory and copy the example configuration files:**

    ```bash
    cd config
    cp config.yml.example config.yml
    cp archive_config.yml.example archive_config.yml
    cp scada_config.yml.example scada_config.yml
    ```

1. **Update each configuration file**
	- `config.yml` — used by `data_pipeline.sh`
	- `archive_config.yml` — used by `archive_pipeline.sh`
	- `scada_config.yml` — used by `sync-scada-data.sh`

1. **Secure the configuration files**

    ```bash
    chmod 600 config.yml archive_config.yml scada_config.yml
    ```
## Usage

This pipeline can be used in two ways:
1.	**Manually**, by executing the scripts directly from the command line
1.	**Automatically**, by running it as a scheduled systemd service managed through Chef

### Automated Execution via systemd and Chef

In production environments, each pipeline script is run automatically using a dedicated `systemd` **service** and **timer** pair, configured through custom default attributes defined in the Chef cookbook.

Each configuration file has a corresponding Chef data bag that defines its values. All configuration data is centrally managed through Chef data bags and vaults. To make changes, update the appropriate Chef-managed data bags and cookbooks.

**Cookbooks**:
- [acep-camio-streams](https://github.com/acep-devops/acep-camio-streams/tree/main)
- [acep-devops-chef](https://github.com/acep-devops/acep-devops-chef/tree/main)

### Manual Execution
To run the data pipeline and then transfer data to the target server:

1. **Data Pipeline (Event Data)**
    ```sh
    ./data_pipeline.sh -c config/config.yml
    ```
1. **Sync SCADA Data**
    ```sh
    ./sync-scada-data.sh -c config/scada-sync.yml
    ```

1. **Archive Pipeline**
    ```sh
    ./archive_pipeline.sh -c config/archive_config.yml
    ```
    **Note:** `rsync` uses the `--exclude` flag to exclude the `working/` directory to ensure only complete files are transfered. 

1. **Run the Cleanup Process (Conditional)**
    The cleanup script removes outdated event files based on the retention period specified in the configuration file.

    If `enable_cleanup` is set to `true` in `archive_config.yml`, `cleanup.sh` runs automatically after `archive_pipeline.sh`. 
    
    Otherwise, you can run it manually: 

    ```bash
    ./cleanup.sh -c config/archive_config.yml
    ```
    
    **Note:** Ensure `archive_config.yml` specifies retention periods for each directory.

## How to Stop the Pipeline

When you need to stop the pipeline:

- **To Stop Safely/Pause Download**: 
  - Use `Ctrl+C` to interrupt the process. 
  - If interupting the proccess doesn't work try `Ctrl+\` to quit.
  - If you would like to resume the download, rerun the `data_pipeline`command.The download will resume from where it left off, provided the same config file (`-c`)is used.
- **Avoid Using `Ctrl+Z`**: 
  - **Do not** use `Ctrl+Z` to suspend the process, as it may cause the pipeline to end without properly closing the FTP connection.

## Testing

This repository includes automated tests for the scripts using [Bats (Bash Automated Testing System)](https://bats-core.readthedocs.io/en/stable/) along with helper libraries: `bats-assert`, `bats-mock`, and `bats-support`. The tests are located in the `test` directory and are automatically run on all pull requests using **Github Actions** to ensure code quality and functionality.

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

### Adding Tests
When making changes to the pipeline, it is essential to add or update tests to cover the new or modified functionality. Follow these steps to add tests:

1. **Locate the appropriate test file:**

    Navigate to the `test` directory and identify the test file that corresponds to the functionality you're modifying. If no such file exists, create a new test file using the `.bats` extension (e.g., `my_script_test.bats`).
2. **Write your tests:**
    
    Use `bats-assert`, `bats-mock`, and `bats-support` helper libraries to write comprehensive tests. Refer to the [bats-core documentation](https://bats-core.readthedocs.io/en/stable/writing-tests.html). 

    If your tests require shared variables or helper functions, define them in `test/test-helper/commons.bash` to ensure consistency and reusability across multiple test files. For example:

    ```bash
    # commons.bash
    MY_VARIABLE="common value"
    function my_helper_function {
        echo "This is a helper function"
    }
    ```

    Example test structure:
    ```bash
    @test "description of the test case" {  
        # Arrange  
        # Set up any necessary environment or input data.  

        # Act  
        result=$(command-to-test)  

        # Assert  
        assert_success  
        assert_output "expected output"  
    }  
    ```
3. **Run your tests locally:**
    
    Ensure your new tests pass locally by running `bats test`.

4. **Commit and push your changes:**
    
    Include your test updates in the same pull request as the code changes.

### Continuous Testing with GitHub Actions
All tests in the repository are automatically executed through GitHub Actions on every pull request. This ensures that all contributions meet quality and functionality standards before merging. Ensure your pull request passes all tests to avoid delays in the review process.