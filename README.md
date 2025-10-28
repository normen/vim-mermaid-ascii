# vim-mermaid-ascii

A Vim plugin that renders Mermaid diagrams as ASCII art. The rendered diagrams are **saved in the file** as special code blocks, making them viewable anywhere - GitHub, text editors, or printed documents.

## Features

- **Portable**: Rendered ASCII saved in file - viewable without the plugin
- **Auto-update**: Edit mermaid code, move cursor away → render updates
- **Manual control**: Update individual or all diagrams when you want
- **Smooth**: No cursor jumping, no spurious "modified" flags

## Quick Start

```vim
" 1. Create a mermaid block
" Use a regular markdown code fence for the diagram:
   ```mermaid
   graph LR
   A --> B
   ```

" 2. Create render block
:MermaidAsciiToggleBlock    " or <Leader>mb

" 3. Edit and it auto-updates when you leave the block!
```

## Installation

**vim-plug**:
```vim
Plug 'normen/vim-mermaid-ascii'
```

**Vundle**:
```vim
Plugin 'normen/vim-mermaid-ascii'
```

**Requires**: [mermaid-ascii](https://github.com/AlexanderGrooff/mermaid-ascii) binary in PATH

## Commands

| Command | Key | Description |
|---------|-----|-------------|
| `:MermaidAsciiRender` | `<Leader>mr` | Toggle auto-update on/off |
| `:MermaidAsciiUpdate` | `<Leader>mu` | Update current block |
| `:MermaidAsciiUpdateAll` | `<Leader>ma` | Update all blocks |
| `:MermaidAsciiToggleBlock` | `<Leader>mb` | Create/remove current render block |
| `:MermaidAsciiToggle` | `<Leader>mt` | Create/remove all render blocks |

See `:help mermaid-ascii` for full documentation.

## Configuration

```vim
" Path to mermaid-ascii binary (default: 'mermaid-ascii')
let g:mermaid_ascii_bin = '/path/to/mermaid-ascii'

" Disable auto-update (default: 1)
let g:mermaid_ascii_auto_update = 0

" Custom mermaid-ascii options (default: '')
let g:mermaid_ascii_options = '--borderPadding 2'

" Disable default mappings (default: 0)
let g:mermaid_ascii_no_mappings = 1
```

**Custom mappings** - disable defaults and define your own:
```vim
let g:mermaid_ascii_no_mappings = 1

nnoremap <Leader>ma :MermaidAsciiRender<CR>
nnoremap <Leader>mc :MermaidAsciiUpdate<CR>
nnoremap <Leader>mu :MermaidAsciiUpdateAll<CR>
nnoremap <Leader>mt :MermaidAsciiToggleBlock<CR>
```

## How It Works

The plugin creates `mermaid-ascii-render` blocks containing the ASCII art:

```markdown
    ```mermaid
    graph LR
    A --> B
    ```

    ```mermaid-ascii-render
    ┌───┐     ┌───┐
    │   │     │   │
    │ A ├────►│ B │
    │   │     │   │
    └───┘     └───┘
    ```
```

Both blocks are saved in the file and viewable anywhere!

## License

MIT License - see LICENSE file
