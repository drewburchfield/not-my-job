# Confluence Storage Format Reference

This document provides detailed information about Confluence Storage Format elements for markdown conversion.

## Overview

Confluence Storage Format is an XHTML-based XML format with custom elements for macros and Confluence-specific features. It mixes standard HTML elements with custom `ac:` (Atlassian Confluence) namespaced elements.

## Common Elements

### Text Formatting

| Markdown | Confluence Storage Format |
|----------|---------------------------|
| `**bold**` or `__bold__` | `<strong>bold</strong>` |
| `*italic*` or `_italic_` | `<em>italic</em>` |
| `~~strikethrough~~` | `<s>strikethrough</s>` or `<del>strikethrough</del>` |
| `<u>underline</u>` | `<u>underline</u>` |
| `` `code` `` | `<code>code</code>` |

### Headings

```xml
<h1>Heading 1</h1>
<h2>Heading 2</h2>
<h3>Heading 3</h3>
<h4>Heading 4</h4>
<h5>Heading 5</h5>
<h6>Heading 6</h6>
```

### Paragraphs and Line Breaks

```xml
<p>Paragraph text</p>
<br />  <!-- line break -->
<hr />  <!-- horizontal rule -->
```

### Lists

**Unordered List:**
```xml
<ul>
<li>Item 1</li>
<li>Item 2</li>
</ul>
```

**Ordered List:**
```xml
<ol>
<li>First item</li>
<li>Second item</li>
</ol>
```

**Task List:**
```xml
<ac:task-list>
<ac:task>
<ac:task-status>incomplete</ac:task-status>
<ac:task-body>Task description</ac:task-body>
</ac:task>
<ac:task>
<ac:task-status>complete</ac:task-status>
<ac:task-body>Completed task</ac:task-body>
</ac:task>
</ac:task-list>
```

### Blockquotes

```xml
<blockquote>
<p>Quote text here</p>
</blockquote>
```

### Tables

```xml
<table>
<tbody>
<tr>
<th>Header 1</th>
<th>Header 2</th>
</tr>
<tr>
<td>Cell 1</td>
<td>Cell 2</td>
</tr>
</tbody>
</table>
```

For tables with merged cells:
```xml
<table>
<tbody>
<tr>
<th colspan="2">Merged Header</th>
</tr>
<tr>
<td>Cell 1</td>
<td rowspan="2">Spans 2 rows</td>
</tr>
<tr>
<td>Cell 3</td>
</tr>
</tbody>
</table>
```

## Links

### External Links
```xml
<a href="https://example.com">Link text</a>
```

### Internal Page Links
```xml
<ac:link>
<ri:page ri:content-title="Page Title" />
<ac:plain-text-link-body><![CDATA[Link Text]]></ac:plain-text-link-body>
</ac:link>
```

With space key:
```xml
<ac:link>
<ri:page ri:space-key="MYSPACE" ri:content-title="Page Title" />
<ac:plain-text-link-body><![CDATA[Link Text]]></ac:plain-text-link-body>
</ac:link>
```

### Anchor Links
```xml
<ac:link ac:anchor="anchorname">
<ac:plain-text-link-body><![CDATA[Jump to section]]></ac:plain-text-link-body>
</ac:link>
```

### Attachment Links
```xml
<ac:link>
<ri:attachment ri:filename="document.pdf" />
<ac:plain-text-link-body><![CDATA[Download PDF]]></ac:plain-text-link-body>
</ac:link>
```

## Images

### External Image
```xml
<ac:image>
<ri:url ri:value="https://example.com/image.png" />
</ac:image>
```

### Attached Image
```xml
<ac:image ac:height="250">
<ri:attachment ri:filename="screenshot.png" />
</ac:image>
```

### Image with Attributes
```xml
<ac:image ac:align="center" ac:height="300" ac:width="400" ac:border="true">
<ri:url ri:value="https://example.com/image.png" />
</ac:image>
```

Supported attributes:
- `ac:align` - "left", "center", "right"
- `ac:border` - "true" or "false"
- `ac:height` - pixel height
- `ac:width` - pixel width
- `ac:thumbnail` - "true" for thumbnail view
- `ac:alt` - alt text
- `ac:title` - tooltip text

## Macros

Macros are Confluence's way of adding special functionality. They use the `ac:structured-macro` element.

### Code Block Macro
```xml
<ac:structured-macro ac:name="code">
<ac:parameter ac:name="language">python</ac:parameter>
<ac:plain-text-body><![CDATA[def hello():
    print("Hello, World!")]]></ac:plain-text-body>
</ac:structured-macro>
```

Supported languages: python, java, javascript, sql, bash, xml, json, yaml, etc.

### Info Panel Macro
```xml
<ac:structured-macro ac:name="info">
<ac:rich-text-body>
<p>This is an info panel with <strong>rich text</strong>.</p>
</ac:rich-text-body>
</ac:structured-macro>
```

Other panel types:
- `ac:name="note"` - Note panel (blue)
- `ac:name="warning"` - Warning panel (yellow)
- `ac:name="tip"` - Tip panel (green)
- `ac:name="info"` - Info panel (blue)

### Expand Macro (Collapsible Section)
```xml
<ac:structured-macro ac:name="expand">
<ac:parameter ac:name="title">Click to expand</ac:parameter>
<ac:rich-text-body>
<p>Hidden content here</p>
</ac:rich-text-body>
</ac:structured-macro>
```

### Table of Contents Macro
```xml
<ac:structured-macro ac:name="toc">
<ac:parameter ac:name="maxLevel">3</ac:parameter>
</ac:structured-macro>
```

### Status Macro
```xml
<ac:structured-macro ac:name="status">
<ac:parameter ac:name="colour">Green</ac:parameter>
<ac:parameter ac:name="title">DONE</ac:parameter>
</ac:structured-macro>
```

Colors: Red, Yellow, Green, Blue, Grey

## Page Layouts

Confluence supports multi-column layouts:

### Single Column
```xml
<ac:layout>
<ac:layout-section ac:type="single">
<ac:layout-cell>
<p>Content here</p>
</ac:layout-cell>
</ac:layout-section>
</ac:layout>
```

### Two Equal Columns
```xml
<ac:layout>
<ac:layout-section ac:type="two_equal">
<ac:layout-cell>
<p>Left column</p>
</ac:layout-cell>
<ac:layout-cell>
<p>Right column</p>
</ac:layout-cell>
</ac:layout-section>
</ac:layout>
```

### Two Columns with Left Sidebar
```xml
<ac:layout>
<ac:layout-section ac:type="two_left_sidebar">
<ac:layout-cell>
<p>Narrow left sidebar (~30%)</p>
</ac:layout-cell>
<ac:layout-cell>
<p>Wide right content (~70%)</p>
</ac:layout-cell>
</ac:layout-section>
</ac:layout>
```

### Three Equal Columns
```xml
<ac:layout>
<ac:layout-section ac:type="three_equal">
<ac:layout-cell>
<p>Column 1</p>
</ac:layout-cell>
<ac:layout-cell>
<p>Column 2</p>
</ac:layout-cell>
<ac:layout-cell>
<p>Column 3</p>
</ac:layout-cell>
</ac:layout-section>
</ac:layout>
```

Layout types:
- `single` - 1 cell
- `two_equal` - 2 equal cells
- `two_left_sidebar` - narrow left + wide right
- `two_right_sidebar` - wide left + narrow right
- `three_equal` - 3 equal cells
- `three_with_sidebars` - narrow + wide + narrow

## Emojis

```xml
<ac:emoticon ac:name="smile" />
<ac:emoticon ac:name="sad" />
<ac:emoticon ac:name="thumbs-up" />
<ac:emoticon ac:name="thumbs-down" />
<ac:emoticon ac:name="warning" />
<ac:emoticon ac:name="tick" />
<ac:emoticon ac:name="cross" />
<ac:emoticon ac:name="heart" />
<ac:emoticon ac:name="star" />
```

## Special Characters

Common symbols that need proper encoding:
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `—` (em dash) → `&#8212;` or `&mdash;`
- `–` (en dash) → `&#8211;` or `&ndash;`

## CDATA Sections

Use CDATA for code blocks and content with special characters:

```xml
<ac:plain-text-body><![CDATA[
Content with <special> characters and "quotes"
]]></ac:plain-text-body>
```

**Important:** If your content contains `]]>`, escape it as: `]]]]><![CDATA[>`

## Best Practices

1. **Always close tags** - Confluence Storage Format is XML, so all tags must be properly closed
2. **Use self-closing tags** - For empty elements like `<br />`, `<hr />`, `<img />`
3. **Escape HTML entities** - Always escape `&`, `<`, `>`, `"` in text content
4. **Validate XML** - The output must be valid XML
5. **Use proper namespaces** - `ac:` for Confluence elements, `ri:` for resource identifiers
6. **Preserve whitespace in code** - Use `<ac:plain-text-body>` with CDATA for code blocks
7. **Rich text in macros** - Use `<ac:rich-text-body>` for formatted content in macros
8. **Plain text in links** - Use `<ac:plain-text-link-body>` with CDATA for link text

## Common Conversion Pitfalls

1. **Nested bold/italic** - Be careful with order: `<strong><em>text</em></strong>`
2. **Lists in lists** - Nest properly with correct indentation
3. **Tables without tbody** - Always wrap rows in `<tbody>`
4. **Unclosed tags** - Will cause parsing errors
5. **Unescaped HTML** - Can break the XML structure
6. **Code language names** - Use lowercase (python, not Python)
7. **Empty table cells** - Must have at least a space or `<br />`
