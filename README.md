
# IN PROGRESS: SEL-735 Meter FTP Download Script
This repository contains a Bash script, `sel-meter-ftp-download.sh`, designed to automate the process of downloading files from an SEL meter via FTP. The script ensures efficient and secure transfer of files from the SEL-735 meter to your local system.

## Prerequisites
Before running this script, ensure you have the following:

- A Unix-like environment (Linux, macOS, or a Unix-like terminal in Windows)
- FTP access credentials (username and password) for the SEL-735 meter
- The following must be installed on your system:
    - `lftp` — [Download lftp](https://lftp.yar.ru/get.html)
    - `jq` — [Download jq](https://jqlang.github.io/jq/download/)

## Installation
1. Clone the repository or download the script directly to your local machine.

    ```bash
    git clone -b ot-dev-ftp-meter-download git@github.com:acep-uaf/data-ducks-STREAM.git

    cd data-ducks-STREAM

    cd CLI_METER 
    ```

2. Make the script executable:

    ```bash
    chmod +x sel-meter-ftp-download.sh
    ```

## Configuration
1. Copy the contents of `.env.example` into a new `.env` file in the same directory as the script.

2. Replace the default/empty values with your FTP server details.

3. Make sure that only the owner can read and write to `.env`.
    ```bash
    chmod 600 .env
    ```

## Usage
To run the script, simply execute it from the command line:

```bash
./sel-meter-ftp-download.sh
```
The script will prompt you to enter the FTP username and password. After authentication, it will begin downloading files from the SEL meter to the specified local directory.

