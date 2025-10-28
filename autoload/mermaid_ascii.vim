" vim-mermaid-ascii - Autoload functions
" Maintainer: normen
" Version: 3.0.0
" 
" This version inserts rendered ASCII in a separate code block below the mermaid block

" State tracking
let s:auto_render_enabled = 0

" Find all mermaid blocks in the buffer
function! mermaid_ascii#FindMermaidBlocks()
  let blocks = []
  let in_mermaid = 0
  let in_render = 0
  let start_line = 0
  let render_start = 0
  let block_content = []
  
  let lnum = 1
  while lnum <= line('$')
    let line = getline(lnum)
    
    if line =~# '^```mermaid\s*$'
      let in_mermaid = 1
      let start_line = lnum
      let block_content = []
      let render_start = 0
    elseif in_mermaid && line =~# '^```\s*$'
      let in_mermaid = 0
      " Check if next block is a render block
      if lnum + 1 <= line('$') && getline(lnum + 1) =~# '^```mermaid-ascii-render\s*$'
        let render_start = lnum + 1
        let in_render = 1
      endif
      
      if !in_render
        call add(blocks, {
          \ 'mermaid_start': start_line,
          \ 'mermaid_end': lnum,
          \ 'render_start': 0,
          \ 'render_end': 0,
          \ 'content': block_content,
          \ 'rendered': 0
          \ })
      endif
    elseif in_render && line =~# '^```\s*$'
      let in_render = 0
      call add(blocks, {
        \ 'mermaid_start': start_line,
        \ 'mermaid_end': start_line + len(block_content) + 1,
        \ 'render_start': render_start,
        \ 'render_end': lnum,
        \ 'content': block_content,
        \ 'rendered': 1
        \ })
    elseif in_mermaid
      call add(block_content, line)
    endif
    
    let lnum += 1
  endwhile
  
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

" Render a single block by inserting ASCII after the mermaid block
function! mermaid_ascii#RenderBlock(block)
  if a:block.rendered
    " Already has a render block, update it
    call mermaid_ascii#UpdateRenderBlock(a:block)
    return 1
  endif
  
  " Render the mermaid content
  let rendered = mermaid_ascii#RenderMermaid(a:block.content)
  
  if empty(rendered)
    return 0
  endif
  
  " Insert render block after the mermaid block
  let insert_line = a:block.mermaid_end
  let render_block = ['```mermaid-ascii-render'] + rendered + ['```']
  
  call append(insert_line, render_block)
  
  return 1
endfunction

" Update an existing render block
function! mermaid_ascii#UpdateRenderBlock(block)
  " Get current content from buffer
  let current_content = getline(a:block.mermaid_start + 1, a:block.mermaid_end - 1)
  
  " Render the mermaid content
  let rendered = mermaid_ascii#RenderMermaid(current_content)
  
  if empty(rendered)
    return 0
  endif
  
  " Get old rendered content
  let old_rendered = getline(a:block.render_start + 1, a:block.render_end - 1)
  
  " Check if rendered output actually changed
  if rendered == old_rendered
    " No changes in output, don't update
    return 0
  endif
  
  " Save cursor position and view
  let save_cursor = getcurpos()
  let save_view = winsaveview()
  
  " Delete old render block content (keep the markers)
  let old_content_start = a:block.render_start + 1
  let old_content_end = a:block.render_end - 1
  
  if old_content_end >= old_content_start
    execute old_content_start . ',' . old_content_end . 'delete'
  endif
  
  " Insert new rendered content
  call append(a:block.render_start, rendered)
  
  " Restore cursor position and view
  call winrestview(save_view)
  call setpos('.', save_cursor)
  
  " File has been modified (we changed the render block)
  " Don't restore the modified flag - let it be set
  
  return 1
endfunction

" Unrender a single block by removing the render block
function! mermaid_ascii#UnrenderBlock(block)
  if !a:block.rendered
    return
  endif
  
  " Delete the entire render block
  execute a:block.render_start . ',' . a:block.render_end . 'delete'
endfunction

" Render all mermaid blocks in the buffer
function! mermaid_ascii#RenderAll()
  let blocks = mermaid_ascii#FindMermaidBlocks()
  
  if empty(blocks)
    echo 'No mermaid blocks found'
    return
  endif
  
  " Process blocks in reverse order to maintain line numbers
  let num_rendered = 0
  for block in reverse(copy(blocks))
    if mermaid_ascii#RenderBlock(block)
      let num_rendered += 1
    endif
  endfor
  
  " Enable auto-rendering
  let s:auto_render_enabled = 1
  
  echo 'Rendered ' . num_rendered . ' mermaid block(s)'
endfunction

" Unrender all mermaid blocks
function! mermaid_ascii#UnrenderAll()
  let blocks = mermaid_ascii#FindMermaidBlocks()
  
  " Only process blocks that have render blocks
  let rendered_blocks = filter(copy(blocks), 'v:val.rendered')
  
  if empty(rendered_blocks)
    echo 'No rendered blocks found'
    return
  endif
  
  " Process in reverse order to maintain line numbers
  for block in reverse(rendered_blocks)
    call mermaid_ascii#UnrenderBlock(block)
  endfor
  
  " Disable auto-rendering
  let s:auto_render_enabled = 0
  
  echo 'Unrendered ' . len(rendered_blocks) . ' mermaid block(s)'
endfunction

" Toggle rendering state
function! mermaid_ascii#Toggle()
  let blocks = mermaid_ascii#FindMermaidBlocks()
  let has_rendered = 0
  
  for block in blocks
    if block.rendered
      let has_rendered = 1
      break
    endif
  endfor
  
  if has_rendered
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
    let in_mermaid = lnum >= block.mermaid_start && lnum <= block.mermaid_end
    let in_render = block.rendered && lnum >= block.render_start && lnum <= block.render_end
    
    if in_mermaid || in_render
      if block.rendered
        call mermaid_ascii#UnrenderBlock(block)
        echo 'Block unrendered'
      else
        if mermaid_ascii#RenderBlock(block)
          echo 'Block rendered'
        endif
      endif
      return
    endif
  endfor
  
  echo 'Cursor is not in a mermaid block'
endfunction

" Handle cursor movement for auto-updating
function! mermaid_ascii#OnCursorMoved()
  if !s:auto_render_enabled
    return
  endif
  
  " Get current block
  let blocks = mermaid_ascii#FindMermaidBlocks()
  let lnum = line('.')
  
  " Track if we're in any mermaid block
  let in_any_block = 0
  
  for block in blocks
    if !block.rendered
      continue
    endif
    
    let in_mermaid = lnum >= block.mermaid_start && lnum <= block.mermaid_end
    
    if in_mermaid
      let in_any_block = 1
      " Track which block we're in
      let b:last_in_mermaid_block = block.mermaid_start
      return
    endif
  endfor
  
  " Only update if we just left a mermaid block
  if exists('b:last_in_mermaid_block') && !in_any_block
    " Find the block we were in
    for block in blocks
      if block.rendered && b:last_in_mermaid_block == block.mermaid_start
        " Update the content and render
        call mermaid_ascii#UpdateRenderBlock(block)
        break
      endif
    endfor
    
    " Clear the tracking variable
    unlet b:last_in_mermaid_block
  endif
endfunction
