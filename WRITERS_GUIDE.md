# TRIKDIS Manual Writer's Guide

Complete guide for creating and editing TRIKDIS product manuals using Markdown, Typora, and MkDocs.

---

## Table of Contents

1. [Writing Standards](#writing-standards)
2. [Document Structure](#document-structure)
3. [Formatting Guidelines](#formatting-guidelines)
4. [GitHub-style Alerts](#github-style-alerts)
5. [Tables](#tables)
6. [Images](#images)
7. [Typora Setup](#typora-setup)
8. [Quality Checklist](#quality-checklist)
9. [Common Patterns](#common-patterns)

---

## Writing Standards

### Language and Tone
- **Clear and concise**: Use simple, direct language
- **Active voice**: "Connect the cable" not "The cable should be connected"
- **Consistent terminology**: Use the same terms throughout (e.g., "control panel" not "alarm panel")
- **Professional tone**: Formal but accessible to technical users

### Technical Writing Best Practices
- **Start with purpose**: Begin each section explaining what the user will accomplish
- **Step-by-step procedures**: Number sequential actions
- **Prerequisites**: Always list what's needed before starting
- **Safety first**: Lead with safety information and warnings

---

## Document Structure

### Standard Manual Layout

With automatic numbering, your headings will display as:

```markdown
## Description                    → 1 Description
Brief overview of the product and its purpose

### Features                     → 1.1 Features  
Key capabilities and benefits

### List of compatible devices   → 1.2 List of compatible devices
Compatibility tables

## Installation                  → 2 Installation
Physical setup and connections

### Requirements                 → 2.1 Requirements
What you need before starting

#### Safety precautions          → 2.1.1 Safety precautions
Safety information

### Wiring diagrams              → 2.2 Wiring diagrams
Connection schematics

## Configuration                 → 3 Configuration
Software setup and settings

### Initial setup                → 3.1 Initial setup
First-time configuration

### Advanced settings            → 3.2 Advanced settings
Optional configurations
```

**Key Benefits:**
- ✅ **Consistent numbering** in both Typora and MkDocs Material
- ✅ **Automatic updates** - no manual renumbering needed
- ✅ **Professional appearance** - matches TRIKDIS standards
- ✅ **Cross-reference friendly** - stable section numbers

### Heading Levels
- **H2 (`##`)**: Major sections (Description, Installation, Configuration)
- **H3 (`###`)**: Subsections (1.1 Installation Process)
- **H4 (`####`)**: Sub-subsections (1.1.1 Wiring Details)
- **H5 (`#####`)**: Minor subdivisions (rare)

---

## Formatting Guidelines

### Text Formatting
- **Bold (`**text**`)**: Product names, UI elements, important terms
  - Example: ***GT*** communicator, **TrikdisConfig** window
- **Italic (`*text*`)**: Emphasis, first use of technical terms
- **Code (`\`text\``)**: Settings, file names, technical values
  - Example: Set `COM1` to `9600 baud`
- **Underline**: Use sparingly, mainly for form fields in tables

### Lists and Procedures

#### Numbered Lists (Procedures)
```markdown
1. Open the **TrikdisConfig** application
2. Select **Connection** → **USB**
3. Click **Connect** to establish communication
4. Navigate to **Settings** → **Communication**
```

#### Bullet Lists (Features/Options)
```markdown
- Supports multiple protocols
- Remote configuration capability
- Real-time monitoring
- Backup communication channels
```

#### Sub-procedures
```markdown
1. Configure the primary channel:
   a. Set IP address to your CMS receiver
   b. Choose port number (usually 2001)
   c. Select protocol (TRIKDIS, SIA, etc.)
2. Test the connection
3. Save settings
```

---

## GitHub-style Alerts

Use these five alert types to highlight important information. The custom CSS ensures they render beautifully in both Typora and exported documents.

### NOTE (Blue)
For helpful information and tips:

```markdown
> [!NOTE]
> The SIM card must be activated before first use. Contact your cellular provider to ensure the card is ready for data transmission.
```

### IMPORTANT (Orange)
For crucial information that affects functionality:

```markdown
> [!IMPORTANT]
> The control panel zone connected to the GT output must be configured as a keyswitch zone for remote control to function properly.
```

### WARNING (Orange)
For actions that could cause problems:

```markdown
> [!WARNING]
> Never disconnect power while firmware is updating. This could permanently damage the device.
```

### TIP (Green)
For helpful suggestions and best practices:

```markdown
> [!TIP]
> Save your configuration to a file before making major changes. This allows you to quickly restore settings if needed.
```

### CAUTION (Red)
For safety-critical information:

```markdown
> [!CAUTION]
> Disconnect mains power before making any wiring connections. Failure to do so may result in electrical shock or equipment damage.
```

### When to Use Each Alert

| Alert Type | Use For | Example |
|------------|---------|---------|
| **NOTE** | Helpful context, explanations | Software requirements, compatibility notes |
| **IMPORTANT** | Critical functional information | Required settings, dependencies |
| **WARNING** | Potential problems or errors | Data loss risks, compatibility issues |
| **TIP** | Best practices, shortcuts | Efficiency suggestions, pro tips |
| **CAUTION** | Safety and damage prevention | Electrical safety, physical damage risks |

---

## Tables

### Basic Table Structure
```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
| Data 4   | Data 5   | Data 6   |
```

### Compatibility Tables
Use consistent formatting for device compatibility:

```markdown
| Manufacturer | Model | Connection Type |
|--------------|-------|----------------|
| DSC® | PC1832, PC1864 | Serial bus |
| PARADOX® | SP6000, SP7000 | Keypad bus |
| Texecom® | Premier Elite | Serial bus |
```

### Settings Tables
For configuration parameters:

```markdown
| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| Baud Rate | 9600 | Communication speed |
| Data Bits | 8 | Number of data bits |
| Stop Bits | 1 | Number of stop bits |
| Parity | None | Error checking method |
```

### Table Guidelines
- **Keep cells concise**: Long text breaks table layout
- **Use consistent formatting**: Same pattern for similar tables
- **Align numbers right**: For easier comparison
- **Use headers**: Always include descriptive column headers

---

## Images

### Image Guidelines
- **File format**: PNG for screenshots, diagrams; JPG for photos
- **Naming**: Descriptive names (`gt-wiring-diagram.png` not `image1.png`)
- **Size**: Optimize for web (typically under 500KB)
- **Alt text**: Include for accessibility

### Image Placement
```markdown
![GT Communicator wiring diagram](gt-wiring-diagram.png)

**Figure 1**: Typical wiring configuration for GT communicator
```

### Screenshots
- **Consistent UI**: Use same OS/browser for all screenshots
- **Highlight important areas**: Use callouts or arrows when helpful
- **Crop appropriately**: Remove unnecessary UI elements

---

## Typora Setup

### Required CSS
Ensure you have the custom `base.user.css` installed at:



```
/Users/local/Library/Application Support/abnerworks.Typora/themes/base.user.css
```

This provides:
- ✅ GitHub-style alerts (NOTE, IMPORTANT, etc.)
- ✅ Professional table borders
- ✅ Dark mode support
- ✅ Improved text wrapping
- ✅ **Automatic heading numbering** (1, 1.1, 1.2.1, etc.)

### Required Typora Settings

> [!IMPORTANT]
> GitHub alerts won't render without enabling this setting in Typora.

**Essential Setup:**
1. **Preferences** → **Markdown** → **Enable GitHub Style Alert** ✅
2. **View** → **File Tree** (keep project structure visible)
3. **Preferences** → **Image** → Store images in folder `./images/` 
4. **Preferences** → **Export** → Include outline in exports

**Typora Version Requirements:**
- Minimum: Typora 1.8 or later
- GitHub alerts supported in 1.8+

### Using GitHub Alerts in Typora

**Correct Syntax:**
```markdown
> [!NOTE]
> Your note content here.
> Multiple lines are supported.
```

**Common Issues:**
- ❌ Alerts not enabled in Preferences → Markdown
- ❌ Older Typora version (< 1.8)
- ❌ Incorrect indentation (alerts can't be indented)
- ❌ Missing blank line after alert

**How to Add Alerts:**
1. **Menu method (Recommended)**: Paragraph → Alert → Select type
2. **Typing method**: Type `> [!NOTE]` and press Enter
3. **Shortcut**: The alert styling will apply automatically once enabled

### Pasting GitHub Alerts from Other Documents

**Problem:** When pasting complete alert paragraphs from previous manuals, they appear as plain text instead of styled alerts.

**Best Solution for Teams:**
1. **Paste the content** (will appear as plain text initially)
2. **Save the file** (Ctrl+S / Cmd+S)
3. **Reopen the file** - all alerts will render with proper formatting
4. Continue editing with properly formatted alerts

**Example Workflow:**
```
Step 1 - Paste: > [!IMPORTANT] The SIM card must be activated before use.
                (shows as plain text)

Step 2 - Save: Ctrl+S (still looks like plain text)

Step 3 - Reopen: File renders with proper blue/orange/red alert styling
```

**Quick Alternative - Menu Method:**
1. **Paste content as plain text** (without the `> [!NOTE]` part)
2. **Select the text** you want to make into an alert
3. **Paragraph** → **Alert** → Choose type (Note, Important, Warning, etc.)
4. **Alert formats instantly** - no save/reopen needed!

**Force Refresh Method:**
- After pasting, try: **View** → **Source Code Mode** → **View** → **Typora Mode**
- This forces Typora to re-parse without closing the file

**For Large Documents with Many Alerts:**
1. Paste entire section as plain text
2. Save file (Ctrl+S) 
3. Reopen file - all alerts format automatically
4. Much faster than manually triggering each alert

**Team Tip:** Create a shared snippet library with common alert patterns that can be quickly inserted via Typora's menu system.

### Live Preview
Typora shows exactly how your manual will look when exported, making it perfect for TRIKDIS documentation workflow. Alerts render with proper colors and styling immediately.

---

## Quality Checklist

Before submitting any manual, verify:

### Content Review
- [ ] **Purpose clear**: Reader understands what the device does
- [ ] **Prerequisites listed**: All requirements stated upfront
- [ ] **Steps numbered**: Procedures are sequential and clear
- [ ] **Safety first**: Warnings and cautions placed appropriately
- [ ] **Terminology consistent**: Same terms used throughout

### Technical Accuracy
- [ ] **Settings verified**: All configuration values tested
- [ ] **Screenshots current**: UI matches latest software version
- [ ] **Links working**: All references point to correct sections
- [ ] **Compatibility updated**: Device lists reflect current support

### Formatting Standards
- [ ] **Alerts used correctly**: Right alert type for each situation
- [ ] **Tables formatted**: Clean borders, consistent alignment
- [ ] **Images optimized**: Appropriate size and quality
- [ ] **Headings consistent**: Proper hierarchy and numbering
- [ ] **Code formatting**: Technical values in backticks

### Export Testing
- [ ] **Typora preview**: Document looks professional
- [ ] **MkDocs compatibility**: Tables and alerts render correctly
- [ ] **Print quality**: PDF export is clean and readable

---

## Common Patterns

### Product Introduction
```markdown
## Description

The **GT** cellular communicator transmits security events from control panels to Central Monitoring Stations and the **Protegus2** mobile application.

**Key Features:**
- Supports major control panel brands (DSC, Paradox, Texecom)
- Dual communication channels for redundancy
- Remote configuration and firmware updates
- Real-time monitoring and notifications
```

### Installation Procedures
```markdown
### Physical Installation

> [!CAUTION]
> Disconnect mains power before making any connections.

**Requirements:**
- Phillips screwdriver
- Wire strippers
- Activated SIM card
- Control panel documentation

**Steps:**
1. Mount the communicator in a secure location
2. Connect power (12V DC, 200mA minimum)
3. Insert activated SIM card
4. Connect to control panel per wiring diagram
```

### Configuration Sections
```markdown
### Initial Configuration

> [!NOTE]
> Ensure the device is powered and connected before configuration.

1. Open **TrikdisConfig** application
2. Select connection method:
   - **USB**: Direct connection via USB cable
   - **TCP/IP**: Remote connection over network
3. Click **Connect** and wait for device detection

> [!IMPORTANT]
> The first connection may take up to 30 seconds while the device initializes.
```

### Troubleshooting Format
```markdown
## Troubleshooting

### Device Not Responding

**Symptoms:** No communication with TrikdisConfig
**Possible Causes:**
- Power supply issues
- USB driver problems
- Incorrect COM port selection

**Solutions:**
1. Verify 12V power supply is connected and working
2. Check Device Manager for COM port assignment
3. Try different USB cable or port

> [!TIP]
> Most connection issues are resolved by checking the power supply first.
```

---

## Final Notes

### Version Control
- **Document changes**: Note what was updated in each revision
- **Date stamps**: Include last modified date
- **Author tracking**: Credit contributors and reviewers

### Collaboration
- **Review process**: Have technical experts verify accuracy
- **User testing**: Test procedures with actual users when possible
- **Feedback integration**: Update based on support team input

### Continuous Improvement
- **Monitor support tickets**: Common issues indicate documentation gaps
- **Update regularly**: Keep pace with firmware and software updates
- **User feedback**: Incorporate suggestions from field technicians

---

*This guide ensures all TRIKDIS manuals maintain professional quality and consistent formatting. For questions about specific formatting or technical writing, consult the documentation team.*