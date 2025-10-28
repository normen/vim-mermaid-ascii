# vim-mermaid-ascii Features

## Overview

vim-mermaid-ascii renders Mermaid diagrams as ASCII art **without modifying the buffer**. The rendered diagrams are display-only using Vim's folding mechanism.

## Key Principle: Buffer Never Modified

**IMPORTANT**: The plugin uses Vim folds to display rendered ASCII art. Your original mermaid code is NEVER changed in the buffer. When you save the file, only the mermaid code is written - never the rendered ASCII art.

## Commands

| Command | Description | Keybinding |
|---------|-------------|------------|
| `:MermaidAsciiRender` | Create folds showing ASCII art for all mermaid blocks | `<Leader>mr` |
| `:MermaidAsciiUnrender` | Remove all folds, show original code | `<Leader>mu` |
| `:MermaidAsciiToggle` | Toggle all blocks between folded/unfolded | `<Leader>mt` |
| `:MermaidAsciiToggleBlock` | Toggle current block only | `<Leader>mb` |

## Configuration Options

```vim
" Path to mermaid-ascii binary (default: 'mermaid-ascii')
let g:mermaid_ascii_bin = 'mermaid-ascii'

" Disable default keybindings (default: 0)
let g:mermaid_ascii_no_mappings = 0

" Additional mermaid-ascii CLI options (default: '')
let g:mermaid_ascii_options = '--borderPadding 2 --paddingX 8'
```

## How It Works

1. **Rendering**: Creates a fold over the ```mermaid``` block
2. **Display**: Custom foldtext shows the rendered ASCII diagram
3. **Editing**: Open the fold with `zo` (standard Vim) or `:MermaidAsciiToggleBlock`
4. **Saving**: File always contains original mermaid code, never ASCII art

## Usage Workflow

### Basic Workflow
```
1. Open file with mermaid blocks
2. :MermaidAsciiRender          " Creates folds with ASCII art
3. Navigate and view diagrams   " Folds show rendered output
4. :w                           " Save - writes original mermaid code!
```

### Editing a Diagram
```
1. Position cursor on a rendered (folded) block
2. zo                           " Open fold (standard Vim command)
   OR
   <Leader>mb                   " Toggle block
3. Edit the mermaid code
4. :MermaidAsciiRender          " Re-render
   OR
   <Leader>mb                   " Toggle block to re-render
```

### Working with Folds
Standard Vim fold commands work:
- `zo` - Open fold under cursor
- `zc` - Close fold under cursor
- `za` - Toggle fold under cursor
- `zR` - Open all folds
- `zM` - Close all folds

## Example

### Before Rendering
```markdown
# My Diagram

```mermaid
graph LR
A --> B
B --> C
```
```

### After :MermaidAsciiRender
The mermaid block appears folded, displaying:
```
# My Diagram

┌───┐     ┌───┐     ┌───┐
│   │     │   │     │   │
│ A ├────►│ B ├────►│ C │
│   │     │   │     │   │
└───┘     └───┘     └───┘
```

### When You Save
The file written to disk contains:
```markdown
# My Diagram

```mermaid
graph LR
A --> B
B --> C
```
```

**The ASCII art is never saved!**

## Technical Details

- **Implementation**: Uses Vim's manual folding with custom foldtext
- **Cache**: Rendered output cached per-buffer in memory
- **Performance**: Only renders when explicitly requested
- **Safety**: Buffer content never modified - fold is display-only
- **Compatibility**: Works with Vim 8.0+ and Neovim

## Migration from v1.x

Version 2.0 is a breaking change. The old version modified the buffer content.

### What Changed
- Rendering now uses folds instead of replacing buffer text
- Removed auto-toggle on cursor movement
- Removed configuration options: `g:mermaid_ascii_no_auto`, `g:mermaid_ascii_auto_toggle`
- Buffer is never modified - rendered diagrams are display-only

### Benefits
- Never accidentally save ASCII art instead of mermaid code
- No buffer modification flag issues
- Simpler, more predictable behavior
- Uses native Vim folding features

### What You Need to Do
If upgrading from v1.x:
1. Remove `g:mermaid_ascii_no_auto` and `g:mermaid_ascii_auto_toggle` from your vimrc
2. Learn fold commands: `zo`, `zc`, `za` for opening/closing folds
3. Use `:MermaidAsciiToggleBlock` instead of relying on auto-toggle

## Advantages of Fold-Based Approach

✅ **Safety**: Impossible to accidentally save rendered ASCII art
✅ **Simplicity**: Uses standard Vim folding - familiar to users  
✅ **No Side Effects**: Buffer modification state unaffected
✅ **Performance**: Only renders on explicit command
✅ **Flexibility**: Standard fold commands work as expected
