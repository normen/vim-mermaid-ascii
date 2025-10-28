# Command Reference

## New Command Structure (v3.1)

### Auto-Processing Control

| Command | Keybinding | Description |
|---------|------------|-------------|
| `:MermaidAsciiRender` | `<Leader>mr` | **Toggle auto-processing** on/off (doesn't render anything) |

### Manual Updates

| Command | Keybinding | Description |
|---------|------------|-------------|
| `:MermaidAsciiUpdate` | `<Leader>mu` | Update current block manually |
| `:MermaidAsciiUpdateAll` | `<Leader>ma` | Update all rendered blocks manually |

### Render Block Management

| Command | Keybinding | Description |
|---------|------------|-------------|
| `:MermaidAsciiToggleBlock` | `<Leader>mb` | Create/remove render block for current diagram |
| `:MermaidAsciiToggle` | `<Leader>mt` | Create/remove all render blocks |
| `:MermaidAsciiUnrender` | - | Remove all render blocks |

## Workflow Examples

### Auto-Processing Workflow (Default)
```
1. :MermaidAsciiToggleBlock   (or <Leader>mb) - Create render block
2. Auto-processing is on by default
3. Edit mermaid code
4. Move cursor away → Auto-updates!
```

### Manual Workflow
```
1. :MermaidAsciiToggleBlock   (or <Leader>mb) - Create render block
2. :MermaidAsciiRender        (or <Leader>mr) - Disable auto-processing
3. Edit mermaid code
4. :MermaidAsciiUpdate        (or <Leader>mu) - Update manually
```

### Batch Workflow
```
1. :MermaidAsciiToggle        (or <Leader>mt) - Create all render blocks
2. Edit multiple diagrams
3. :MermaidAsciiUpdateAll     (or <Leader>ma) - Update all at once
```

## Configuration

```vim
" Disable auto-update on cursor movement (default: 1)
let g:mermaid_ascii_auto_update = 0
```

When `g:mermaid_ascii_auto_update = 0`, use manual update commands only.
