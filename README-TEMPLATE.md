# README Template and Style Guide

This document serves as both a template for creating consistent README files and a style guide for Markdown formatting conventions.

---

## README Structure Template

### 1. Overview
**Purpose**: Provide a clear, concise description of what the script/project does.

```markdown
# [Script/Project Name]

Brief one-line description of what this script/project accomplishes.

## What it does
- Key functionality point 1
- Key functionality point 2  
- Key functionality point 3

## Key Features
- Feature 1 with brief explanation
- Feature 2 with brief explanation
```

### 2. Prerequisites & Dependencies
**Purpose**: List all requirements before installation/usage.

```markdown
## Prerequisites & Dependencies

### System Requirements
- Operating System: [specify versions if applicable]
- Shell: [zsh, PowerShell, etc.]
- [Other system requirements]

### Required Software
- [Software 1] (version X.X or higher)
- [Software 2] (specific version if required)

### Required Permissions
- [Permission type 1]
- [Permission type 2]

### PowerShell Modules (if applicable)
- Microsoft.Graph (for connect-mggraph)
- ExchangeOnlineManagement (for connect-exchangeonline)
```

### 3. Installation / Setup
**Purpose**: Provide step-by-step installation and configuration instructions.

```markdown
## Installation / Setup

### Download
1. Clone or download the script to: `/users/jonathan/files/10scripts/`
2. Make executable (if applicable): `chmod +x script-name.sh`

### Configuration
1. [Configuration step 1]
2. [Configuration step 2]
3. Edit configuration variables in the script header if needed

### First-time Setup
1. [Any one-time setup steps]
2. [Authentication setup if required]
```

### 4. Usage & Parameters
**Purpose**: Document how to run the script and all available options.

```markdown
## Usage & Parameters

### Basic Usage
```bash
./script-name.sh [OPTIONS] [ARGUMENTS]
```

### Parameters
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-h, --help` | flag | No | - | Show help message |
| `-v, --verbose` | flag | No | false | Enable verbose output |
| `-f, --file` | string | Yes | - | Input file path |

### Examples of Parameter Usage
```bash
# Basic usage
./script-name.sh -f input.txt

# Verbose mode
./script-name.sh -v -f input.txt

# Show help
./script-name.sh --help
```
```

### 5. Examples
**Purpose**: Provide practical, real-world usage examples.

```markdown
## Examples

### Example 1: Basic Operation
```bash
./script-name.sh -f data.csv
```
**Expected Output:**
```
Processing data.csv...
✓ Processed 100 records
✓ Output saved to results.txt
```

### Example 2: Advanced Usage
```bash
./script-name.sh -v --output-format json -f large-dataset.csv
```
**What this does:**
- Processes large-dataset.csv in verbose mode
- Outputs results in JSON format

### Example 3: Error Handling
```bash
./script-name.sh -f nonexistent.txt
```
**Expected Output:**
```
❌ Error: File 'nonexistent.txt' not found
See --help for usage information
```
```

### 6. Troubleshooting
**Purpose**: Address common issues and their solutions.

```markdown
## Troubleshooting

### Common Issues

#### Issue: "Permission denied" error
**Cause:** Script lacks execute permissions
**Solution:**
```bash
chmod +x script-name.sh
```

#### Issue: "Command not found" error  
**Cause:** Required dependency not installed
**Solution:**
1. Check Prerequisites & Dependencies section
2. Install missing software
3. Verify PATH configuration

#### Issue: PowerShell connection failures
**Cause:** Authentication modules not connected
**Solution:**
```powershell
Connect-MgGraph -Scopes "Directory.Read.All"
Connect-ExchangeOnline
```

### Debug Mode
Enable debug output for troubleshooting:
```bash
./script-name.sh --debug -f input.txt
```

### Getting Help
- Check the examples section above
- Run `./script-name.sh --help`
- Review error messages carefully
```

### 7. Version & Contact
**Purpose**: Provide version information and contact details.

```markdown
## Version & Contact

### Version Information
- **Current Version:** 1.0.0
- **Last Updated:** [YYYY-MM-DD]
- **Compatibility:** [OS/Shell versions tested]

### Changelog
#### v1.0.0 (YYYY-MM-DD)
- Initial release
- [Feature 1]
- [Feature 2]

### Author & Contact
- **Author:** [Name]
- **Created:** [YYYY-MM-DD]
- **Location:** `/users/jonathan/files/10scripts/`

### Support
For issues or questions:
1. Check the Troubleshooting section
2. Review the examples
3. [Additional contact information if applicable]
```

---

## Markdown Style Guide

### Headers
- Use `#` for main title (H1) - only one per document
- Use `##` for major sections (H2)
- Use `###` for subsections (H3)
- Use `####` for sub-subsections (H4)
- Always include a space after `#` symbols
- Use sentence case for headers (capitalize first word and proper nouns only)

### Code Formatting

#### Inline Code
- Use single backticks for inline code: `variable_name`
- Use for file names, commands, and short code snippets

#### Code Blocks
- Use triple backticks with language specification:
```bash
#!/bin/bash
echo "Hello World"
```

#### Common Language Tags
- `bash` - for shell scripts and commands
- `powershell` - for PowerShell commands  
- `json` - for JSON data
- `yaml` - for YAML configuration
- `text` - for plain text output

### Lists

#### Unordered Lists
- Use `-` for primary bullets
- Use `  -` (2 spaces) for nested bullets
- Maintain consistent spacing

#### Ordered Lists
1. Use `1.` format for numbered lists
2. Markdown will auto-number subsequent items
3. Use consistent indentation for sub-items

### Tables
```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
```

### Emphasis
- Use `**bold**` for important terms and headings
- Use `*italic*` for emphasis
- Use `***bold italic***` sparingly

### Links and References
- Use descriptive link text: `[installation guide](link)`
- Avoid "click here" or generic text

### Visual Elements

#### Status Indicators
- ✅ Success/Completed
- ❌ Error/Failed  
- ⚠️ Warning/Caution
- ℹ️ Information/Note
- 🔧 Configuration/Setup

#### Separators
Use `---` for horizontal rules to separate major sections.

### File Paths and Commands
- Always use full paths when referencing script locations: `/users/jonathan/files/10scripts/`
- Use code formatting for all file paths and commands
- Be specific about shell requirements (zsh, PowerShell)

### Best Practices
1. Keep lines under 80 characters when possible
2. Use consistent spacing (blank line before/after headers)
3. Include practical examples for every feature
4. Test all code examples before documenting
5. Update version information with each change
6. Use present tense for descriptions ("processes files" not "will process files")

---

## Template Usage Instructions

1. Copy the template structure above
2. Replace bracketed placeholders `[like this]` with actual values
3. Remove sections that don't apply to your script
4. Follow the Markdown style conventions consistently
5. Test all examples before finalizing
6. Save to `/users/jonathan/files/10scripts/` directory

This template ensures consistency across all script documentation while maintaining clarity and usability.
