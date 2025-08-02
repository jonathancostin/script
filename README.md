
# Project Overview and Purpose

This project is a collection of scripts for various auditing and management tasks, covering areas like Intune compliance, mailbox auditing, Office 365 reporting, and macOS system cleanup.

## Recent Updates

### New Company Selectors
The scripts now include an enhanced company selector system that allows for:
- Dynamic company selection from a predefined list
- Multi-tenant support with improved organization filtering
- Enhanced company-specific configuration management

### Shutdown and URL Polling Logic
Updated polling mechanisms include:
- Improved shutdown procedures for graceful script termination
- Enhanced URL polling with retry logic and timeout handling
- Better error handling for network connectivity issues
- Optimized polling intervals for various API endpoints

### Manual Login Support
New manual authentication options:
- Support for manual login when automated authentication fails
- Interactive authentication prompts for Graph API and Exchange Online
- Fallback mechanisms for MFA-enabled accounts
- Clear instructions for manual credential input

### Automated and Manual Testing
Enhanced testing framework:
- New automated test scripts for validation of core functionality
- Manual testing procedures with step-by-step instructions
- Test result reporting and validation checks
- Continuous integration testing capabilities

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


## Running Tests

### Automated Tests
To run the automated test suite:

1. **PowerShell Scripts**:
   ```powershell
   # Run all automated tests
   ./tests/Run-AutomatedTests.ps1
   
   # Run specific module tests
   ./tests/Test-GraphConnection.ps1
   ./tests/Test-ExchangeConnection.ps1
   ```

2. **Shell Scripts** (macOS/Linux):
   ```bash
   # Run automated tests
   ./tests/run_automated_tests.sh
   
   # Run specific tests
   ./mac/logging/test_signal_handling.sh
   ```

### Manual Tests
For manual testing procedures:

1. **Authentication Testing**:
   - Run any script and verify manual login prompts appear when automated auth fails
   - Test MFA flows with different authentication methods
   - Verify fallback mechanisms work correctly

2. **Company Selector Testing**:
   - Test company selection from the predefined list
   - Verify multi-tenant configurations
   - Check organization filtering functionality

3. **Polling Logic Testing**:
   - Test shutdown procedures during script execution
   - Verify URL polling with network interruptions
   - Check timeout and retry mechanisms

### Test Results
Test results are generated in the following locations:
- Automated test results: `./tests/results/`
- Manual test logs: `./logs/manual_tests/`
- Performance metrics: `./tests/performance/`

## Reference Subdirectory READMEs

Each subdirectory contains a `README.md` for more detailed information:
- [Intune Compliance Audit](audits/intuneaudits/readme.md)
- [Mailbox Audit](audits/mailboxaudit/README.md)
- [Mega Audit](audits/megaaudit/README.md)
- [Office Audits](audits/officeaudits/README.md)
- [macOS Logging and Cleanup](mac/logging/LOGGING_FRAMEWORK_README.md)
- [Office Tasks](office/README.md)
