" vim-mermaid-ascii - Autoload functions
" Maintainer: normen
" Version: 1.0.0

" State tracking
let s:mermaid_blocks = {}
let s:rendered_state = {}
let s:current_block = -1
let s:auto_render_enabled = 0

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

" Render a single block
function! mermaid_ascii#RenderBlock(block_idx)
  let block = s:mermaid_blocks[a:block_idx]
  
  " Already rendered?
  if get(s:rendered_state, a:block_idx, 0)
    return
  endif
  
  " Render the mermaid content
  let rendered = mermaid_ascii#RenderMermaid(block.content)
  
  if empty(rendered)
    return
  endif
  
  " Store the original content
  let s:mermaid_blocks[a:block_idx].rendered = rendered
  
  " Save modified state
  let l:was_modified = &modified
  
  " Replace the lines
  let start = block.start
  let end = block.end
  
  " Delete the block (including ``` markers) without triggering autocmds
  noautocmd execute start . ',' . end . 'delete'
  
  " Insert rendered content at the same position
  noautocmd call append(start - 1, rendered)
  
  " Restore modified state
  let &modified = l:was_modified
  
  " Update block positions
  let line_diff = len(rendered) - (end - start + 1)
  let s:mermaid_blocks[a:block_idx].rendered_start = start
  let s:mermaid_blocks[a:block_idx].rendered_end = start + len(rendered) - 1
  
  " Adjust positions of subsequent blocks
  for idx in keys(s:mermaid_blocks)
    if idx > a:block_idx
      let s:mermaid_blocks[idx].start += line_diff
      let s:mermaid_blocks[idx].end += line_diff
      if has_key(s:mermaid_blocks[idx], 'rendered_start')
        let s:mermaid_blocks[idx].rendered_start += line_diff
        let s:mermaid_blocks[idx].rendered_end += line_diff
      endif
    endif
  endfor
  
  " Mark as rendered
  let s:rendered_state[a:block_idx] = 1
endfunction

" Unrender a single block (restore original mermaid code)
function! mermaid_ascii#UnrenderBlock(block_idx)
  let block = s:mermaid_blocks[a:block_idx]
  
  " Not rendered?
  if !get(s:rendered_state, a:block_idx, 0)
    return
  endif
  
  " Save modified state
  let l:was_modified = &modified
  
  " Get positions
  let start = block.rendered_start
  let end = block.rendered_end
  
  " Delete rendered lines without triggering autocmds
  noautocmd execute start . ',' . end . 'delete'
  
  " Restore original mermaid block
  let original = ['```mermaid'] + block.content + ['```']
  noautocmd call append(start - 1, original)
  
  " Restore modified state
  let &modified = l:was_modified
  
  " Update positions
  let line_diff = len(original) - (end - start + 1)
  let s:mermaid_blocks[a:block_idx].start = start
  let s:mermaid_blocks[a:block_idx].end = start + len(original) - 1
  
  " Remove rendered position tracking
  if has_key(s:mermaid_blocks[a:block_idx], 'rendered_start')
    unlet s:mermaid_blocks[a:block_idx].rendered_start
  endif
  if has_key(s:mermaid_blocks[a:block_idx], 'rendered_end')
    unlet s:mermaid_blocks[a:block_idx].rendered_end
  endif
  
  " Adjust positions of subsequent blocks
  for idx in keys(s:mermaid_blocks)
    if idx > a:block_idx
      let s:mermaid_blocks[idx].start += line_diff
      let s:mermaid_blocks[idx].end += line_diff
      if has_key(s:mermaid_blocks[idx], 'rendered_start')
        let s:mermaid_blocks[idx].rendered_start += line_diff
        let s:mermaid_blocks[idx].rendered_end += line_diff
      endif
    endif
  endfor
  
  " Mark as not rendered
  let s:rendered_state[a:block_idx] = 0
endfunction

" Render all mermaid blocks in the buffer
function! mermaid_ascii#RenderAll()
  " Find all blocks
  let blocks = mermaid_ascii#FindMermaidBlocks()
  
  if empty(blocks)
    echo 'No mermaid blocks found'
    return
  endif
  
  " Store blocks
  let s:mermaid_blocks = {}
  let s:rendered_state = {}
  let idx = 0
  for block in blocks
    let s:mermaid_blocks[idx] = block
    let idx += 1
  endfor
  
  " Render each block (in reverse order to maintain line numbers)
  for idx in reverse(range(len(blocks)))
    call mermaid_ascii#RenderBlock(idx)
  endfor
  
  " Enable auto-rendering
  let s:auto_render_enabled = 1
  
  echo 'Rendered ' . len(blocks) . ' mermaid block(s) - auto-rendering enabled'
endfunction

" Unrender all mermaid blocks
function! mermaid_ascii#UnrenderAll()
  if empty(s:mermaid_blocks)
    echo 'No rendered mermaid blocks'
    return
  endif
  
  " Disable auto-rendering
  let s:auto_render_enabled = 0
  
  " Unrender each block (in reverse order)
  for idx in reverse(sort(keys(s:mermaid_blocks), {a, b -> a - b}))
    call mermaid_ascii#UnrenderBlock(idx)
  endfor
  
  echo 'Unrendered all mermaid blocks - auto-rendering disabled'
endfunction

" Toggle rendering state
function! mermaid_ascii#Toggle()
  " Check if we have any rendered blocks
  let has_rendered = 0
  for state in values(s:rendered_state)
    if state
      let has_rendered = 1
      break
    endif
  endfor
  
  if has_rendered || s:auto_render_enabled
    call mermaid_ascii#UnrenderAll()
  else
    call mermaid_ascii#RenderAll()
  endif
endfunction

" Find which block the cursor is in
function! mermaid_ascii#GetBlockAtCursor()
  let lnum = line('.')
  
  for [idx, block] in items(s:mermaid_blocks)
    if get(s:rendered_state, idx, 0)
      " Check rendered position
      if has_key(block, 'rendered_start') && lnum >= block.rendered_start && lnum <= block.rendered_end
        return str2nr(idx)
      endif
    else
      " Check original position
      if lnum >= block.start && lnum <= block.end
        return str2nr(idx)
      endif
    endif
  endfor
  
  return -1
endfunction

" Toggle a single block at cursor position
function! mermaid_ascii#ToggleBlock()
  " Initialize blocks if not already done
  if empty(s:mermaid_blocks)
    let blocks = mermaid_ascii#FindMermaidBlocks()
    if empty(blocks)
      echo 'No mermaid blocks found'
      return
    endif
    let idx = 0
    for block in blocks
      let s:mermaid_blocks[idx] = block
      let idx += 1
    endfor
  endif
  
  let current_block = mermaid_ascii#GetBlockAtCursor()
  
  if current_block < 0
    echo 'Cursor is not in a mermaid block'
    return
  endif
  
  if get(s:rendered_state, current_block, 0)
    " Block is rendered, unrender it
    call mermaid_ascii#UnrenderBlock(current_block)
    echo 'Block unrendered'
  else
    " Block is not rendered, render it
    " First update content from buffer
    let block = s:mermaid_blocks[current_block]
    let new_content = getline(block.start + 1, block.end - 1)
    let s:mermaid_blocks[current_block].content = new_content
    call mermaid_ascii#RenderBlock(current_block)
    echo 'Block rendered'
  endif
endfunction

" Handle cursor movement
function! mermaid_ascii#OnCursorMoved()
  " Only process if auto-rendering is enabled
  if !s:auto_render_enabled
    return
  endif
  
  " Check if auto-toggle is enabled
  let auto_toggle = get(g:, 'mermaid_ascii_auto_toggle', 1)
  if !auto_toggle
    return
  endif
  
  let current_block = mermaid_ascii#GetBlockAtCursor()
  
  " If we moved into a rendered block, unrender it
  if current_block >= 0 && current_block != s:current_block
    if get(s:rendered_state, current_block, 0)
      call mermaid_ascii#UnrenderBlock(current_block)
      " Update the block content from the buffer
      let block = s:mermaid_blocks[current_block]
      let new_content = getline(block.start + 1, block.end - 1)
      let s:mermaid_blocks[current_block].content = new_content
    endif
  endif
  
  " If we left a block, render it again
  if s:current_block >= 0 && current_block != s:current_block
    if !get(s:rendered_state, s:current_block, 0)
      " Update content before rendering
      let block = s:mermaid_blocks[s:current_block]
      let new_content = getline(block.start + 1, block.end - 1)
      let s:mermaid_blocks[s:current_block].content = new_content
      call mermaid_ascii#RenderBlock(s:current_block)
    endif
  endif
  
  let s:current_block = current_block
endfunction
