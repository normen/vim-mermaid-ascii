" vim-mermaid-ascii - Render mermaid diagrams as ASCII art
" Maintainer: normen
" Version: 3.0.0

if exists('g:loaded_mermaid_ascii')
  finish
endif
let g:loaded_mermaid_ascii = 1

" Save cpoptions
let s:save_cpo = &cpo
set cpo&vim

" Configuration
if !exists('g:mermaid_ascii_bin')
  let g:mermaid_ascii_bin = 'mermaid-ascii'
endif

if !exists('g:mermaid_ascii_options')
  let g:mermaid_ascii_options = ''
endif

if !exists('g:mermaid_ascii_auto_update')
  let g:mermaid_ascii_auto_update = 1
endif

" Commands
command! MermaidAsciiRender call mermaid_ascii#RenderAll()
command! MermaidAsciiUnrender call mermaid_ascii#UnrenderAll()
command! MermaidAsciiToggle call mermaid_ascii#Toggle()
command! MermaidAsciiToggleBlock call mermaid_ascii#ToggleBlock()

" Default mappings
if !exists('g:mermaid_ascii_no_mappings') || !g:mermaid_ascii_no_mappings
  nnoremap <silent> <Leader>mr :MermaidAsciiRender<CR>
  nnoremap <silent> <Leader>mu :MermaidAsciiUnrender<CR>
  nnoremap <silent> <Leader>mt :MermaidAsciiToggle<CR>
  nnoremap <silent> <Leader>mb :MermaidAsciiToggleBlock<CR>
endif

" Auto-update when cursor leaves mermaid block
if get(g:, 'mermaid_ascii_auto_update', 1)
  augroup MermaidAscii
    autocmd!
    autocmd CursorMoved,CursorMovedI * call mermaid_ascii#OnCursorMoved()
  augroup END
endif

" Restore cpoptions
let &cpo = s:save_cpo
unlet s:save_cpo
