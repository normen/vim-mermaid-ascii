# vim-mermaid-ascii Features

## Commands

| Command | Description | Keybinding |
|---------|-------------|------------|
| `:MermaidAsciiRender` | Render all mermaid blocks and enable auto-rendering | `<Leader>mr` |
| `:MermaidAsciiUnrender` | Restore all blocks to code and disable auto-rendering | `<Leader>mu` |
| `:MermaidAsciiToggle` | Toggle all blocks and auto-rendering state | `<Leader>mt` |
| `:MermaidAsciiToggleBlock` | Toggle current block only (manual control) | `<Leader>mb` |

## Configuration Options

```vim
" Path to mermaid-ascii binary (default: 'mermaid-ascii')
let g:mermaid_ascii_bin = 'mermaid-ascii'

" Disable cursor movement auto-render/unrender (default: 0)
let g:mermaid_ascii_no_auto = 0

" Disable auto-toggle when cursor enters/leaves blocks (default: 1)
" Set to 0 for manual block-level control
let g:mermaid_ascii_auto_toggle = 1

" Disable default keybindings (default: 0)
let g:mermaid_ascii_no_mappings = 0

" Additional mermaid-ascii CLI options (default: '')
let g:mermaid_ascii_options = '--borderPadding 2 --paddingX 8'
```

## Usage Modes

### Mode 1: Auto-Toggle (Default)
```vim
" This is the default behavior
let g:mermaid_ascii_auto_toggle = 1
```

1. Run `:MermaidAsciiRender` to render all blocks
2. Cursor enters block → automatically shows code
3. Cursor leaves block → automatically re-renders
4. Run `:MermaidAsciiUnrender` to disable auto-rendering

**Best for**: Quick viewing and occasional editing

### Mode 2: Manual Toggle
```vim
" Disable auto-toggle for manual control
let g:mermaid_ascii_auto_toggle = 0
```

1. Run `:MermaidAsciiRender` to render all blocks
2. Use `<Leader>mb` to toggle individual blocks
3. Blocks stay in rendered/unrendered state until manually toggled
4. No automatic changes on cursor movement

**Best for**: Precise control, editing multiple blocks, or reducing visual flickering

### Mode 3: Fully Manual
```vim
" Disable all automatic behavior
let g:mermaid_ascii_no_auto = 1
```

1. Use `:MermaidAsciiToggleBlock` or `<Leader>mb` for each block
2. No cursor movement triggers
3. Complete manual control

**Best for**: Maximum control, performance-sensitive environments

## Workflow Examples

### Quick Preview Workflow
```
1. Open file with mermaid blocks
2. <Leader>mr (render all)
3. Move cursor to view different diagrams
4. <Leader>mb (toggle block to edit)
5. <Leader>mb (toggle back when done)
```

### Editing Workflow
```
1. Open file
2. <Leader>mr (render all)
3. Move cursor into block to edit (auto-shows code if auto-toggle enabled)
4. Edit the mermaid code
5. Move cursor out (auto-renders if auto-toggle enabled)
```

### Manual Control Workflow
```
" In .vimrc: let g:mermaid_ascii_auto_toggle = 0

1. Open file
2. <Leader>mr (render all blocks)
3. Navigate to block you want to edit
4. <Leader>mb (manually toggle to code)
5. Edit the code
6. <Leader>mb (manually toggle to render)
```

## Technical Details

- **No file modifications**: Rendering doesn't mark the file as modified
- **State tracking**: Plugin remembers which blocks are rendered
- **Position tracking**: Correctly handles line number changes
- **Error handling**: Shows clear errors if mermaid-ascii is missing or diagrams fail to render
- **Performance**: Uses `:noautocmd` to avoid triggering unnecessary autocmds
