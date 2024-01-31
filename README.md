# SEL Meter FTP Download Script

This repository contains a Bash script, `ftp-meter-download.sh`, designed to automate the process of downloading files from an SEL meter via FTP. The script ensures efficient and secure transfer of files from the SEL meter to your local system.

## Prerequisites

Before running this script, ensure you have the following:

- A Unix-like environment (Linux, macOS, or a Unix-like terminal in Windows)
- FTP access credentials (username and password) for the SEL meter
- FTP client, `lftp`, installed on your system

## Installation

1. Clone the repository or download the script directly to your local machine.

    ```bash
    git clone https://github.com/acep-uaf/data-ducks-STREAM/tree/ftp-meter-script.git
    
    cd ftp-meter-script
    ```

2. Make the script executable:

    ```bash
    chmod +x sel_meter_ftp_download.sh
    ```

## Configuration

Edit the script, `ftp-meter-download.sh`, to configure the FTP server details, including server address, remote path, and local download path.

```bash
# FTP server details
FTP_SERVER="ftp.example.com"
FTP_REMOTE_PATH="/path/to/ftp/files"
LOCAL_PATH="/local/download/path"
```
## Usage
To run the script, simply execute it from the command line:

```bash
./sel_meter_ftp_download.sh
```
The script will prompt you to enter the FTP username and password. After authentication, it will begin downloading files from the SEL meter to the specified local directory.

