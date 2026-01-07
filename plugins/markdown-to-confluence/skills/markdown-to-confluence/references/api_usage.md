# Atlassian API Usage for Confluence

This document explains how to use the available Atlassian tools to create or update Confluence pages with converted markdown content.

## Available Tools

Claude has access to Atlassian MCP tools that can:
- Search for Confluence pages and spaces
- Fetch page content
- Get Confluence metadata

The tools use Rovo Search and can interact with Confluence Cloud instances.

## Workflow for Creating/Updating Pages

### 1. Search for Existing Page or Space

Use the `search` tool to find pages or spaces:

```python
# Example search query
search(query="space:MYSPACE title:My Page Title")
```

### 2. Fetch Page Details

Use the `fetch` tool with an ARI (Atlassian Resource Identifier):

```python
# Example ARI format
fetch(id="ari:cloud:confluence:cloudId:page/123456")
```

### 3. Convert Markdown to Storage Format

Use the `md_to_confluence.py` script:

```bash
python scripts/md_to_confluence.py input.md output.xml
```

This produces Confluence Storage Format XML that can be sent to the API.

## Important Notes

### Storage Format Requirements

1. **Valid XML**: The content must be well-formed XML
2. **Proper escaping**: Use HTML entities for special characters
3. **Closed tags**: All tags must be properly closed
4. **Namespaces**: Use correct `ac:` and `ri:` prefixes

### Working with the API

When creating or updating pages programmatically:

1. **Get Cloud ID**: Use `getAccessibleAtlassianResources` tool to find the cloudId
2. **Search for space/page**: Use the search tool to find the target location
3. **Convert markdown**: Use the conversion script
4. **Prepare payload**: Format the storage format content for the API

### Content Structure

A typical Confluence page body looks like:

```json
{
  "value": "<p>Your converted content here</p>",
  "representation": "storage"
}
```

## Example Workflow

```bash
# 1. Convert markdown to Confluence format
python scripts/md_to_confluence.py my-document.md confluence-content.xml

# 2. The output can then be used in API calls
# (This would typically be done through the Atlassian tools available to Claude)
```

## Limitations

- Claude cannot directly call the Confluence REST API to create pages
- The conversion creates the proper storage format
- The user must then use the Atlassian tools or copy the content to Confluence

## Tips for Best Results

1. **Validate XML**: Ensure the output is valid XML before sending
2. **Test with simple content first**: Start with basic formatting
3. **Handle images properly**: Images need to be uploaded as attachments first
4. **Use proper resource identifiers**: Internal links need correct ARIs
5. **Check permissions**: Ensure you have permission to create/edit pages

## Common Issues

### Issue: Special Characters Breaking XML
**Solution**: Ensure all `&`, `<`, `>`, `"` are properly escaped

### Issue: Code Blocks Not Rendering
**Solution**: Use proper CDATA sections and escape `]]>` sequences

### Issue: Lists Not Formatting Correctly
**Solution**: Ensure proper `<ul>`/`<ol>` nesting and close all `<li>` tags

### Issue: Tables Missing Borders
**Solution**: Tables in Confluence storage format don't need special border attributes

### Issue: Images Not Appearing
**Solution**: Images from external URLs use `<ri:url>`, attached images use `<ri:attachment>`
