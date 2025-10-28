#!/bin/bash
# Test script for vim-mermaid-ascii plugin

set -e

echo "=== vim-mermaid-ascii Test Script ==="
echo

# Check if mermaid-ascii is installed
if ! command -v mermaid-ascii &> /dev/null; then
    echo "ERROR: mermaid-ascii not found in PATH"
    echo "Please install it first: https://github.com/AlexanderGrooff/mermaid-ascii"
    exit 1
fi

echo "✓ mermaid-ascii found: $(which mermaid-ascii)"
echo

# Create a test markdown file
TEST_FILE="test_diagram.md"
cat > "$TEST_FILE" << 'EOF'
# Test Mermaid Diagram

This is a test file for the vim-mermaid-ascii plugin.

## Simple Flow

```mermaid
graph LR
A --> B
B --> C
```

## Another Diagram

```mermaid
graph TD
Start --> Process
Process --> End
```

Try these commands:
- :MermaidAsciiRender - Render all blocks
- :MermaidAsciiUnrender - Restore original
- :MermaidAsciiToggle or :MermaidAsciiToggleBlock - Toggle rendering
- <Leader>mr - Render (normal mode)
- <Leader>mu - Unrender (normal mode)
- <Leader>mt - Toggle (normal mode)
EOF

echo "Created test file: $TEST_FILE"
echo
echo "To test the plugin, run:"
echo "  vim $TEST_FILE"
echo
echo "Then execute these commands in Vim:"
echo "  :MermaidAsciiRender    # Render the diagrams"
echo "  (move cursor into diagram)  # See original code"
echo "  (move cursor out)           # Auto re-render"
echo "  :MermaidAsciiToggle or :MermaidAsciiToggleBlock    # Toggle all"
echo
echo "=== Test completed successfully ==="
