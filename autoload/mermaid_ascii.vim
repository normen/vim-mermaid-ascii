" vim-mermaid-ascii - Autoload functions
" Maintainer: normen
" Version: 2.0.0
" 
" This version uses text properties with virtual text to display rendered diagrams

" State tracking
let s:mermaid_blocks = {}
let s:rendered_blocks = {}
let s:prop_type = 'mermaid_ascii_block'

" Initialize text property type
function! s:InitPropType()
  let bufnr = bufnr('%')
  if !empty(prop_type_get(s:prop_type, {'bufnr': bufnr}))
    call prop_type_delete(s:prop_type, {'bufnr': bufnr})
  endif
  call prop_type_add(s:prop_type, {
    \ 'bufnr': bufnr,
    \ 'highlight': 'Conceal'
    \ })
endfunction

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

" Add virtual text using text properties
function! s:AddVirtualText(start_line, end_line, rendered_lines)
  call s:InitPropType()
  
  " Add virtual text below the first line of the mermaid block
  " Each rendered line becomes a separate virtual text property
  for idx in range(len(a:rendered_lines))
    call prop_add(a:start_line, 0, {
      \ 'type': s:prop_type,
      \ 'text': a:rendered_lines[idx],
      \ 'text_align': 'below'
      \ })
  endfor
  
  " Conceal all lines in the mermaid block
  for lnum in range(a:start_line, a:end_line)
    " Use matchaddpos to conceal these lines
    call matchaddpos('Conceal', [lnum], 10, -1, {'conceal': ' '})
  endfor
  
  " Set conceallevel to hide the original text
  setlocal conceallevel=3
  setlocal concealcursor=nvic
endfunction

" Remove virtual text and properties
function! s:RemoveVirtualText(start_line, end_line)
  " Remove text properties
  call prop_remove({
    \ 'type': s:prop_type,
    \ 'bufnr': bufnr('%'),
    \ 'all': v:true
    \ }, a:start_line, a:end_line)
  
  " Clear conceal matches
  call clearmatches()
endfunction

" Render a single block
function! mermaid_ascii#RenderBlock(start, end, content)
  " Render the mermaid content
  let rendered = mermaid_ascii#RenderMermaid(a:content)
  
  if empty(rendered)
    return 0
  endif
  
  " Store in state
  let block_key = bufnr('%') . ':' . a:start . '-' . a:end
  let s:rendered_blocks[block_key] = {
    \ 'start': a:start,
    \ 'end': a:end,
    \ 'rendered': rendered
    \ }
  
  " Add virtual text
  call s:AddVirtualText(a:start, a:end, rendered)
  
  return 1
endfunction

" Unrender a block
function! mermaid_ascii#UnrenderBlock(start, end)
  let block_key = bufnr('%') . ':' . a:start . '-' . a:end
  
  if !has_key(s:rendered_blocks, block_key)
    return
  endif
  
  " Remove virtual text
  call s:RemoveVirtualText(a:start, a:end)
  
  " Remove from state
  unlet s:rendered_blocks[block_key]
endfunction

" Render all mermaid blocks in the buffer
function! mermaid_ascii#RenderAll()
  " Find all blocks
  let blocks = mermaid_ascii#FindMermaidBlocks()
  
  if empty(blocks)
    echo 'No mermaid blocks found'
    return
  endif
  
  " Clear existing rendered blocks
  call mermaid_ascii#UnrenderAll()
  
  " Render each block
  let num_rendered = 0
  for block in blocks
    if mermaid_ascii#RenderBlock(block.start, block.end, block.content)
      let num_rendered += 1
    endif
  endfor
  
  echo 'Rendered ' . num_rendered . ' mermaid block(s) - original content preserved'
endfunction

" Unrender all mermaid blocks
function! mermaid_ascii#UnrenderAll()
  " Remove all properties for this buffer
  let buf_prefix = bufnr('%') . ':'
  for key in keys(s:rendered_blocks)
    if key =~# '^' . buf_prefix
      let block = s:rendered_blocks[key]
      call s:RemoveVirtualText(block.start, block.end)
      unlet s:rendered_blocks[key]
    endif
  endfor
  
  " Reset conceal settings
  setlocal conceallevel=0
  
  echo 'Unrendered all mermaid blocks'
endfunction

" Toggle rendering state
function! mermaid_ascii#Toggle()
  " Check if we have any rendered blocks for this buffer
  let buf_prefix = bufnr('%') . ':'
  let has_rendered = 0
  for key in keys(s:rendered_blocks)
    if key =~# '^' . buf_prefix
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
    if lnum >= block.start && lnum <= block.end
      let block_key = bufnr('%') . ':' . block.start . '-' . block.end
      
      if has_key(s:rendered_blocks, block_key)
        " Block is rendered, unrender it
        call mermaid_ascii#UnrenderBlock(block.start, block.end)
        echo 'Block unrendered'
      else
        " Block is not rendered, render it
        if mermaid_ascii#RenderBlock(block.start, block.end, block.content)
          echo 'Block rendered'
        endif
      endif
      return
    endif
  endfor
  
  echo 'Cursor is not in a mermaid block'
endfunction
