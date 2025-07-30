
# Project Overview and Purpose

This project is a collection of scripts for various auditing and management tasks, covering areas like Intune compliance, mailbox auditing, Office 365 reporting, and macOS system cleanup.

## Global Prerequisites

- **PowerShell Modules**: Ensure you have PowerShell installed on your machine. The following modules are required:
  - `Microsoft.Graph` for Graph API interactions
  - `ExchangeOnlineManagement` for Exchange Online connections


## Instructions for Cloning and Locating Scripts

1. **Clone the Repository**:
   ```sh
   git clone https://github.com/jonathancostin/script
   ```

2. **Navigate to Scripts**:
   Scripts are organized by purpose in various subdirectories. Examples include:
   - `/audits` for auditing scripts.
   - `/mac` for macOS related scripts, such as cleanup tasks.
   - `/office` for handling Office 365 tasks.


## Reference Subdirectory READMEs

Each subdirectory contains a `README.md` for more detailed information:
- [Intune Compliance Audit](audits/intuneaudits/readme.md)
- [Mailbox Audit](audits/mailboxaudit/README.md)
- [Mega Audit](audits/megaaudit/README.md)
- [Office Audits](audits/officeaudits/README.md)
- [macOS Logging and Cleanup](mac/logging/LOGGING_FRAMEWORK_README.md)
- [Office Tasks](office/README.md)
