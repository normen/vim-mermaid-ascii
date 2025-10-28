" vim-mermaid-ascii - Autoload functions
" Maintainer: normen
" Version: 2.0.0
" 
" This version uses folding with custom foldtext to display rendered diagrams
" without modifying the actual buffer content.

" State tracking
let s:mermaid_blocks = {}
let s:fold_cache = {}

" Find all mermaid blocks in the buffer
function! mermaid_ascii#FindMermaidBlocks()
  let blocks = []
  let in_block = 0
  let start_line = 0
  let block_content = []
  
  for lnum in range(1, line('$'))
    let line = getline(lnum)
    
    if line =~# '^```mermaid\s*$'
      let in_block = 1
      let start_line = lnum
      let block_content = []
    elseif in_block && line =~# '^```\s*$'
      let in_block = 0
      call add(blocks, {
        \ 'start': start_line,
        \ 'end': lnum,
        \ 'content': block_content
        \ })
    elseif in_block
      call add(block_content, line)
    endif
  endfor
  
  return blocks
endfunction

" Render mermaid code to ASCII using mermaid-ascii
function! mermaid_ascii#RenderMermaid(content)
  let bin = get(g:, 'mermaid_ascii_bin', 'mermaid-ascii')
  let options = get(g:, 'mermaid_ascii_options', '')
  
  " Check if binary exists
  if !executable(bin)
    echohl ErrorMsg
    echo 'mermaid-ascii binary not found. Please install it first.'
    echohl None
    return []
  endif
  
  " Create temporary file with mermaid content
  let temp_file = tempname() . '.mermaid'
  call writefile(a:content, temp_file)
  
  " Run mermaid-ascii
  let cmd = bin . ' ' . options . ' -f ' . shellescape(temp_file)
  let output = systemlist(cmd)
  
  " Clean up
  call delete(temp_file)
  
  if v:shell_error != 0
    echohl ErrorMsg
    echo 'Error rendering mermaid diagram: ' . join(output, "\n")
    echohl None
    return []
  endif
  
  return output
endfunction

" Custom fold text function that displays one line at a time from rendered output
function! mermaid_ascii#FoldText()
  let fold_start = v:foldstart
  let fold_end = v:foldend
  
  " Check if this fold has cached rendered content
  let cache_key = bufnr('%') . ':' . fold_start . '-' . fold_end
  if has_key(s:fold_cache, cache_key)
    let lines = s:fold_cache[cache_key]
    " Calculate which line of the rendered output to show
    " v:foldstart is the current line in the fold being displayed
    let rel_line = v:foldstart - fold_start
    if rel_line < len(lines)
      return lines[rel_line]
    endif
  endif
  
  " Default fallback - show original line
  return getline(v:foldstart)
endfunction

" Render a single block by creating a fold
function! mermaid_ascii#RenderBlock(start, end, content)
  " Render the mermaid content
  let rendered = mermaid_ascii#RenderMermaid(a:content)
  
  if empty(rendered)
    return 0
  endif
  
  " Cache the rendered output
  let cache_key = bufnr('%') . ':' . a:start . '-' . a:end
  let s:fold_cache[cache_key] = rendered
  
  " Create a fold for this block
  execute a:start . ',' . a:end . 'fold'
  
  " Close the fold to show rendered content
  execute a:start . 'foldclose'
  
  return 1
endfunction

" Unrender a block by removing the fold
function! mermaid_ascii#UnrenderBlock(start, end)
  let cache_key = bufnr('%') . ':' . a:start . '-' . a:end
  if has_key(s:fold_cache, cache_key)
    unlet s:fold_cache[cache_key]
  endif
  
  " Delete the fold
  execute a:start . ',' . a:end . 'foldopen!'
endfunction

" Render all mermaid blocks in the buffer
function! mermaid_ascii#RenderAll()
  " Save current settings
  let w:mermaid_saved_fdm = get(w:, 'mermaid_saved_fdm', &l:foldmethod)
  let w:mermaid_saved_fen = get(w:, 'mermaid_saved_fen', &l:foldenable)
  
  " Set up folding
  setlocal foldmethod=manual
  setlocal foldenable
  setlocal foldtext=mermaid_ascii#FoldText()
  
  " Find all blocks
  let blocks = mermaid_ascii#FindMermaidBlocks()
  
  if empty(blocks)
    echo 'No mermaid blocks found'
    return
  endif
  
  " Clear existing folds
  normal! zE
  
  " Render each block
  let rendered_rendered_count . 0
  for block in blocks
    if mermaid_ascii#RenderBlock(block.start, block.end, block.content)
      let rendered_count += 1
    endif
  endfor
  
  echo 'Rendered ' . rendered_count . ' mermaid block(s) - original content preserved'
endfunction

" Unrender all mermaid blocks
function! mermaid_ascii#UnrenderAll()
  " Clear all folds
  normal! zE
  
  " Clear cache for this buffer
  let buf_prefix = bufnr('%') . ':'
  for key in keys(s:fold_cache)
    if key =~# '^' . buf_prefix
      unlet s:fold_cache[key]
    endif
  endfor
  
  " Restore settings if saved
  if exists('w:mermaid_saved_fdm')
    let &l:foldmethod = w:mermaid_saved_fdm
    unlet w:mermaid_saved_fdm
  endif
  if exists('w:mermaid_saved_fen')
    let &l:foldenable = w:mermaid_saved_fen
    unlet w:mermaid_saved_fen
  endif
  
  echo 'Unrendered all mermaid blocks'
endfunction

" Toggle rendering state
function! mermaid_ascii#Toggle()
  " Check if we have any folds in cache for this buffer
  let buf_prefix = bufnr('%') . ':'
  let has_folds = 0
  for key in keys(s:fold_cache)
    if key =~# '^' . buf_prefix
      let has_folds = 1
      break
    endif
  endfor
  
  if has_folds
    call mermaid_ascii#UnrenderAll()
  else
    call mermaid_ascii#RenderAll()
  endif
endfunction

" Toggle current block
function! mermaid_ascii#ToggleBlock()
  let blocks = mermaid_ascii#FindMermaidBlocks()
  
  if empty(blocks)
    echo 'No mermaid blocks found'
    return
  endif
  
  let lnum = line('.')
  
  " Find block containing current line
  for block in blocks
    if lnum >= block.start && lnum <= block.end
      let cache_key = bufnr('%') . ':' . block.start . '-' . block.end
      
      if has_key(s:fold_cache, cache_key)
        " Block is rendered, unrender it
        call mermaid_ascii#UnrenderBlock(block.start, block.end)
        echo 'Block unrendered'
      else
        " Block is not rendered, render it
        if &l:foldmethod !=# 'manual'
          let w:mermaid_saved_fdm = &l:foldmethod
          let w:mermaid_saved_fen = &l:foldenable
          setlocal foldmethod=manual
          setlocal foldenable
          setlocal foldtext=mermaid_ascii#FoldText()
        endif
        
        if mermaid_ascii#RenderBlock(block.start, block.end, block.content)
          echo 'Block rendered'
        endif
      endif
      return
    endif
  endfor
  
  echo 'Cursor is not in a mermaid block'
endfunction
