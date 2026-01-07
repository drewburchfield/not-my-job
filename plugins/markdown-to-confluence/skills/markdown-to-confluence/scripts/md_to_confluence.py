#!/usr/bin/env python3
"""
Markdown to Confluence Storage Format Converter

Converts Markdown files to Confluence Storage Format (XHTML-based XML).
Handles the specific mix of HTML, custom Confluence elements, and macros.
"""

import re
import sys
from typing import Dict, List, Tuple
from html import escape


class MarkdownToConfluence:
    """Convert Markdown to Confluence Storage Format."""
    
    def __init__(self):
        self.in_code_block = False
        self.code_language = ""
        self.in_list = False
        self.list_stack: List[str] = []  # Track nested list types
        
    def convert(self, markdown_text: str) -> str:
        """
        Convert markdown text to Confluence Storage Format.
        
        Args:
            markdown_text: The markdown content to convert
            
        Returns:
            Confluence Storage Format XML/XHTML
        """
        lines = markdown_text.split('\n')
        result = []
        i = 0
        
        while i < len(lines):
            line = lines[i]
            
            # Handle code blocks
            if line.strip().startswith('```'):
                i, code_block = self._process_code_block(lines, i)
                result.append(code_block)
                continue
            
            # Handle headings
            if line.startswith('#'):
                result.append(self._convert_heading(line))
                i += 1
                continue
            
            # Handle horizontal rules
            if re.match(r'^(-{3,}|\*{3,}|_{3,})$', line.strip()):
                result.append('<hr />')
                i += 1
                continue
            
            # Handle lists
            if re.match(r'^(\s*)([-*+]|\d+\.)\s+', line):
                i, list_content = self._process_list(lines, i)
                result.append(list_content)
                continue
            
            # Handle blockquotes
            if line.startswith('>'):
                i, blockquote = self._process_blockquote(lines, i)
                result.append(blockquote)
                continue
            
            # Handle tables
            if '|' in line and i + 1 < len(lines) and re.match(r'^\s*\|?[\s:-]+\|', lines[i + 1]):
                i, table = self._process_table(lines, i)
                result.append(table)
                continue
            
            # Handle regular paragraphs and inline formatting
            if line.strip():
                result.append(self._convert_paragraph(line))
            else:
                # Empty lines separate blocks
                if result and result[-1] != '':
                    result.append('')
            
            i += 1
        
        # Clean up multiple empty lines
        output = '\n'.join(result)
        output = re.sub(r'\n{3,}', '\n\n', output)
        return output.strip()
    
    def _process_code_block(self, lines: List[str], start: int) -> Tuple[int, str]:
        """Process a fenced code block."""
        first_line = lines[start].strip()
        language = first_line[3:].strip() or 'none'
        
        code_lines = []
        i = start + 1
        
        while i < len(lines) and not lines[i].strip().startswith('```'):
            code_lines.append(lines[i])
            i += 1
        
        code_content = '\n'.join(code_lines)
        # Escape CDATA content properly
        code_content = code_content.replace(']]>', ']]]]><![CDATA[>')
        
        confluence_code = f'''<ac:structured-macro ac:name="code">
<ac:parameter ac:name="language">{escape(language)}</ac:parameter>
<ac:plain-text-body><![CDATA[{code_content}]]></ac:plain-text-body>
</ac:structured-macro>'''
        
        return (i + 1 if i < len(lines) else i, confluence_code)
    
    def _convert_heading(self, line: str) -> str:
        """Convert markdown heading to Confluence heading."""
        match = re.match(r'^(#{1,6})\s+(.+)$', line)
        if match:
            level = len(match.group(1))
            text = self._convert_inline(match.group(2))
            return f'<h{level}>{text}</h{level}>'
        return line
    
    def _process_list(self, lines: List[str], start: int) -> Tuple[int, str]:
        """Process a list (ordered or unordered)."""
        items = []
        i = start
        list_type = None
        
        while i < len(lines):
            line = lines[i]
            match = re.match(r'^(\s*)([-*+]|\d+\.)\s+(.+)$', line)
            
            if not match:
                # Check if it's a continuation of previous item
                if line.strip() and items and not re.match(r'^(\s*)([-*+]|\d+\.)\s+', line):
                    # Continuation line
                    items[-1] += ' ' + line.strip()
                    i += 1
                    continue
                break
            
            indent = len(match.group(1))
            marker = match.group(2)
            content = match.group(3)
            
            # Determine list type from first item
            if list_type is None:
                list_type = 'ol' if marker[0].isdigit() else 'ul'
            
            items.append(self._convert_inline(content))
            i += 1
        
        # Build list HTML
        list_items = '\n'.join(f'<li>{item}</li>' for item in items)
        return (i, f'<{list_type}>\n{list_items}\n</{list_type}>')
    
    def _process_blockquote(self, lines: List[str], start: int) -> Tuple[int, str]:
        """Process a blockquote."""
        quote_lines = []
        i = start
        
        while i < len(lines) and lines[i].startswith('>'):
            # Remove the '>' and any leading space
            content = re.sub(r'^>\s?', '', lines[i])
            quote_lines.append(content)
            i += 1
        
        quote_content = ' '.join(quote_lines)
        converted_content = self._convert_inline(quote_content)
        
        return (i, f'<blockquote><p>{converted_content}</p></blockquote>')
    
    def _process_table(self, lines: List[str], start: int) -> Tuple[int, str]:
        """Process a markdown table."""
        table_lines = []
        i = start
        
        # Collect all table lines
        while i < len(lines) and '|' in lines[i]:
            table_lines.append(lines[i])
            i += 1
        
        if len(table_lines) < 2:
            return (i, lines[start])
        
        # Parse header
        header_cells = [cell.strip() for cell in table_lines[0].split('|')[1:-1]]
        
        # Skip separator line (line 1)
        
        # Parse body rows
        body_rows = []
        for line in table_lines[2:]:
            cells = [cell.strip() for cell in line.split('|')[1:-1]]
            body_rows.append(cells)
        
        # Build Confluence table
        table_html = '<table>\n<tbody>\n'
        
        # Header row
        table_html += '<tr>\n'
        for cell in header_cells:
            table_html += f'<th>{self._convert_inline(cell)}</th>\n'
        table_html += '</tr>\n'
        
        # Body rows
        for row in body_rows:
            table_html += '<tr>\n'
            for cell in row:
                table_html += f'<td>{self._convert_inline(cell)}</td>\n'
            table_html += '</tr>\n'
        
        table_html += '</tbody>\n</table>'
        
        return (i, table_html)
    
    def _convert_paragraph(self, text: str) -> str:
        """Convert a paragraph with inline formatting."""
        converted = self._convert_inline(text)
        return f'<p>{converted}</p>'
    
    def _convert_inline(self, text: str) -> str:
        """Convert inline markdown formatting to Confluence format."""
        # Escape HTML entities first (but preserve intentional HTML)
        # Don't escape if it looks like it's already HTML
        if not re.search(r'<[a-zA-Z]', text):
            text = escape(text)
        
        # Bold: **text** or __text__
        text = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', text)
        text = re.sub(r'__(.+?)__', r'<strong>\1</strong>', text)
        
        # Italic: *text* or _text_
        text = re.sub(r'\*(.+?)\*', r'<em>\1</em>', text)
        text = re.sub(r'\b_(.+?)_\b', r'<em>\1</em>', text)
        
        # Strikethrough: ~~text~~
        text = re.sub(r'~~(.+?)~~', r'<s>\1</s>', text)
        
        # Inline code: `code`
        text = re.sub(r'`(.+?)`', r'<code>\1</code>', text)
        
        # Links: [text](url)
        text = re.sub(
            r'\[([^\]]+)\]\(([^\)]+)\)',
            lambda m: f'<a href="{m.group(2)}">{m.group(1)}</a>',
            text
        )
        
        # Images: ![alt](url)
        text = re.sub(
            r'!\[([^\]]*)\]\(([^\)]+)\)',
            lambda m: f'<ac:image><ri:url ri:value="{m.group(2)}" /></ac:image>',
            text
        )
        
        return text


def main():
    """Main entry point for the converter."""
    if len(sys.argv) < 2:
        print("Usage: python md_to_confluence.py <markdown_file>")
        print("   or: python md_to_confluence.py <markdown_file> <output_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            markdown_content = f.read()
        
        converter = MarkdownToConfluence()
        confluence_content = converter.convert(markdown_content)
        
        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(confluence_content)
            print(f"✅ Converted {input_file} → {output_file}")
        else:
            print(confluence_content)
            
    except FileNotFoundError:
        print(f"❌ Error: File '{input_file}' not found")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
