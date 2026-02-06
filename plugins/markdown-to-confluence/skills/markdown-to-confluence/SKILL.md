---
name: markdown-to-confluence
description: Convert Markdown documents to Confluence Storage Format (XHTML-based XML) for uploading to Atlassian Confluence. Use when the user needs to convert a Markdown file to Confluence format, create a Confluence page from markdown, or asks about markdown to Confluence conversion. Handles the specific mix of HTML elements, Confluence macros, and storage format requirements.
---

# Markdown to Confluence Converter

Convert Markdown documents to Confluence Storage Format for creating or updating Confluence pages.

## Overview

This skill provides tools and knowledge for converting Markdown files to Confluence Storage Format - the XHTML-based XML format required by Atlassian Confluence. The conversion handles standard markdown syntax and produces valid Confluence-compatible output.

## When to Use This Skill

Trigger this skill when:
- Converting Markdown files to Confluence Storage Format
- Creating Confluence pages from existing markdown documentation
- Updating Confluence pages with markdown content
- The user mentions "Confluence" and "markdown" together
- The user wants to upload markdown to Confluence
- The user asks about converting documentation to Confluence format

## Quick Start

> **Script location:** The conversion script is bundled with this skill. Locate it with the `find` command shown below.

### Basic Conversion

Convert a markdown file to Confluence Storage Format:

```bash
# First, locate the script
SCRIPT=$(find ~/.claude ~/.config/claude-code ~/dev -path "*/markdown-to-confluence/scripts/md_to_confluence.py" 2>/dev/null | head -1)

# Run the conversion
python "$SCRIPT" input.md output.xml
```

The output file contains valid Confluence Storage Format XML.

### In-Memory Conversion

For direct conversion without files:

```python
from scripts.md_to_confluence import MarkdownToConfluence

converter = MarkdownToConfluence()
confluence_xml = converter.convert(markdown_text)
```

## Conversion Workflow

### 1. Prepare the Markdown

Ensure the markdown file uses standard syntax:
- Use `#` for headings
- Use `**` or `__` for bold, `*` or `_` for italic
- Use fenced code blocks with ` ``` ` for code
- Use standard list syntax with `-`, `*`, or numbers
- Use `|` table syntax for tables

### 2. Run the Converter

Execute the conversion script:

```bash
# Locate the script (if not already done above)
SCRIPT=$(find ~/.claude ~/.config/claude-code ~/dev -path "*/markdown-to-confluence/scripts/md_to_confluence.py" 2>/dev/null | head -1)
python "$SCRIPT" document.md confluence_output.xml
```

Or convert inline if working with text directly:

```python
converter = MarkdownToConfluence()
result = converter.convert(markdown_content)
```

### 3. Review the Output

Check that the generated XML:
- Is well-formed (all tags closed)
- Preserves the intended formatting
- Handles special characters correctly
- Uses appropriate Confluence macros

### 4. Use in Confluence

The output can be:
- Copied into Confluence's storage format editor
- Sent via Atlassian API (if available)
- Used with Confluence CLI tools
- Uploaded programmatically

## Supported Markdown Features

The converter handles these markdown elements:

### Text Formatting
- **Bold**: `**text**` or `__text__` → `<strong>text</strong>`
- *Italic*: `*text*` or `_text_` → `<em>text</em>`
- ~~Strikethrough~~: `~~text~~` → `<s>text</s>`
- `Inline code`: `` `code` `` → `<code>code</code>`

### Document Structure
- **Headings**: `#` through `######` → `<h1>` through `<h6>`
- **Paragraphs**: Automatic `<p>` tag wrapping
- **Line breaks**: Preserved in output
- **Horizontal rules**: `---`, `***`, or `___` → `<hr />`

### Lists
- **Unordered lists**: Lines starting with `-`, `*`, or `+`
  - Converted to `<ul><li>...</li></ul>`
- **Ordered lists**: Lines starting with `1.`, `2.`, etc.
  - Converted to `<ol><li>...</li></ol>`
- **Nested lists**: Supported with proper indentation

### Code Blocks

Fenced code blocks with language specification:

````markdown
```python
def hello():
    print("Hello, World!")
```
````

Converted to Confluence code macro:
```xml
<ac:structured-macro ac:name="code">
<ac:parameter ac:name="language">python</ac:parameter>
<ac:plain-text-body><![CDATA[def hello():
    print("Hello, World!")]]></ac:plain-text-body>
</ac:structured-macro>
```

Supported languages include: python, java, javascript, typescript, bash, sql, json, xml, yaml, html, css, and many more.

### Blockquotes

```markdown
> This is a quote
```

Converted to:
```xml
<blockquote><p>This is a quote</p></blockquote>
```

### Tables

Standard markdown tables:

```markdown
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
| Cell 3   | Cell 4   |
```

Converted to Confluence table format with proper `<table>`, `<tbody>`, `<tr>`, `<th>`, and `<td>` tags.

### Links and Images

- **External links**: `[text](url)` → `<a href="url">text</a>`
- **Images**: `![alt](url)` → Confluence image format with `<ac:image><ri:url>`

## Understanding Confluence Storage Format

Confluence Storage Format is an XHTML-based XML format with custom elements for Confluence-specific features.

### Key Characteristics

1. **Standard HTML elements**: `<p>`, `<strong>`, `<em>`, `<ul>`, `<ol>`, `<table>`, `<h1>`-`<h6>`
2. **Confluence macros**: `<ac:structured-macro>` for special features like code blocks, info panels
3. **Resource identifiers**: `<ri:url>`, `<ri:page>`, `<ri:attachment>` for links and images
4. **Valid XML requirement**: All tags must be properly closed and characters escaped

### Element Namespaces

- `ac:` - Atlassian Confluence elements (macros, layouts, etc.)
- `ri:` - Resource Identifiers (links to pages, images, attachments)
- Standard HTML - No namespace prefix

### Reference Documentation

For comprehensive Confluence Storage Format details:
- **Format specifications**: Read `references/confluence_format.md` for complete element reference
- **API integration**: Read `references/api_usage.md` for working with Atlassian tools

Load these references when working with advanced features:
- Custom macros (info panels, expand macros, table of contents)
- Page layouts (multi-column sections)
- Internal page links with resource identifiers
- Attachment references
- Special formatting needs

## Advanced Features

### Adding Confluence-Specific Elements

For features not in standard markdown, add raw Confluence Storage Format directly in your markdown:

```markdown
# My Document

Regular markdown content here.

<ac:structured-macro ac:name="info">
<ac:rich-text-body>
<p>This is an info panel with special formatting.</p>
</ac:rich-text-body>
</ac:structured-macro>

More markdown content.
```

The converter preserves these elements in the output.

### Common Confluence Macros

Useful macros to add manually:

**Info Panel:**
```xml
<ac:structured-macro ac:name="info">
<ac:rich-text-body><p>Information here</p></ac:rich-text-body>
</ac:structured-macro>
```

**Warning Panel:**
```xml
<ac:structured-macro ac:name="warning">
<ac:rich-text-body><p>Warning message</p></ac:rich-text-body>
</ac:structured-macro>
```

**Collapsible Section:**
```xml
<ac:structured-macro ac:name="expand">
<ac:parameter ac:name="title">Click to expand</ac:parameter>
<ac:rich-text-body><p>Hidden content</p></ac:rich-text-body>
</ac:structured-macro>
```

**Table of Contents:**
```xml
<ac:structured-macro ac:name="toc">
<ac:parameter ac:name="maxLevel">3</ac:parameter>
</ac:structured-macro>
```

See `references/confluence_format.md` for complete macro reference.

## Best Practices

### Creating Markdown for Confluence

1. **Use standard syntax**: Stick to widely-supported markdown features
2. **Specify code languages**: Always include language identifier in code blocks
3. **Keep tables simple**: Complex tables may need manual adjustment
4. **Use full URLs for images**: External images need complete URLs
5. **Test incrementally**: Convert and test small sections first

### After Conversion

1. **Validate XML**: Ensure output is well-formed XML
2. **Check special characters**: Verify proper escaping of `&`, `<`, `>`, `"`
3. **Review formatting**: Check that formatting matches intentions
4. **Test in Confluence**: Preview if possible before final upload

### Performance Tips

- For large documents, convert in sections
- Use the script for batch conversion of multiple files
- Cache converted output if reusing content

## Troubleshooting

### Issue: Special Characters Break Output

**Symptom**: XML parsing errors or garbled text  
**Cause**: Unescaped HTML entities  
**Solution**: The converter handles escaping automatically, but verify special cases. Check for `&`, `<`, `>`, `"` in plain text.

### Issue: Code Blocks Don't Render Correctly

**Symptom**: Code appears as plain text  
**Cause**: Missing language identifier or CDATA issues  
**Solution**: Always specify language in fenced code blocks: ` ```python `

### Issue: Lists Not Formatting Correctly

**Symptom**: Lists appear flat or unnested  
**Cause**: Inconsistent indentation in markdown  
**Solution**: Use consistent 2 or 4 space indentation for nested lists

### Issue: Tables Missing Headers or Borders

**Symptom**: Table header row looks like regular row  
**Cause**: Missing or malformed separator line  
**Solution**: Ensure second line has proper format: `|---|---|`

### Issue: Links Not Working

**Symptom**: Links appear as plain text  
**Cause**: Malformed link syntax or special Confluence link requirements  
**Solution**: 
- External links: Use `[text](https://url)` format
- Internal Confluence links: May need manual conversion to `<ac:link>` format with resource identifiers (see references)

### Issue: Images Don't Appear

**Symptom**: Broken image or empty space  
**Cause**: Image path or Confluence attachment issues  
**Solution**:
- External images: Use full URL `![alt](https://example.com/image.png)`
- Attached images: Upload separately and use `<ri:attachment>` format

## Examples

### Example 1: Technical Documentation

**Input markdown:**
```markdown
# API Documentation

## Authentication

Use Bearer token authentication.

## Endpoints

### GET /api/users

Retrieve user list.

**Response:**

```json
{
  "users": [
    {"id": 1, "name": "Alice"}
  ]
}
```
```

**Output**: Confluence Storage Format with proper headings, bold text, and syntax-highlighted JSON code block.

### Example 2: Project Documentation

**Input markdown:**
```markdown
# Project Overview

## Features

- Feature A
- Feature B
- Feature C

## Status

| Component | Status |
|-----------|--------|
| Backend   | Complete |
| Frontend  | In Progress |

See [documentation](https://example.com/docs) for details.
```

**Output**: Confluence format with lists, tables, and external links properly formatted.

## Technical Details

### Script Architecture

The converter (`scripts/md_to_confluence.py`):
- **Self-contained**: No external dependencies beyond Python standard library
- **Line-by-line processing**: Efficient handling of large files
- **State machine**: Tracks context (in code block, in list, etc.)
- **Robust**: Handles edge cases and nested structures

### XML Requirements

Confluence requires:
- Well-formed XML (all tags closed)
- Proper namespace usage (`ac:`, `ri:`)
- Self-closing tags for empty elements (`<br />`, `<hr />`)
- CDATA sections for code and special content
- HTML entity escaping for text content

### Extending the Converter

To add support for additional markdown features:

1. Identify the markdown pattern to detect
2. Determine the Confluence Storage Format equivalent
3. Add detection and conversion logic in the appropriate method
4. Test with sample content
5. Update documentation

## Known Limitations

- **Complex nested lists**: Very deeply nested lists (4+ levels) may need review
- **Extended markdown**: Some extended syntax (footnotes, definition lists) not supported
- **Confluence-specific features**: Advanced macros and layouts need manual addition
- **Internal links**: Links to other Confluence pages require manual conversion to resource identifiers
- **Attachments**: Images and files must be uploaded separately then referenced

## Resources Summary

This skill includes:

- **scripts/md_to_confluence.py**: Main conversion script
- **references/confluence_format.md**: Complete Confluence Storage Format reference
- **references/api_usage.md**: Guide for using Atlassian API tools

Consult the reference documents when working with advanced features or troubleshooting conversion issues.
