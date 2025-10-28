# Agent Development Guide

This document provides comprehensive information for AI coding agents working on vim-mermaid-ascii. It captures the architecture, design decisions, patterns, and lessons learned during development.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [File Structure](#file-structure)
4. [Key Concepts](#key-concepts)
5. [Implementation Patterns](#implementation-patterns)
6. [Common Pitfalls](#common-pitfalls)
7. [Testing Approach](#testing-approach)
8. [Design Decisions](#design-decisions)
9. [Evolution History](#evolution-history)
10. [Code Examples](#code-examples)

---

## Project Overview

### Purpose
Vim plugin that renders Mermaid diagrams as ASCII art using the external `mermaid-ascii` binary. Rendered diagrams are saved in the file as special code blocks, making them viewable anywhere (GitHub, text editors, printed documents).

### Core Philosophy
- **Persistence**: Rendered ASCII saved in file, not just displayed
- **Safety**: Original mermaid code always preserved
- **User Control**: Manual and automatic workflows
- **Vim Native**: Uses standard Vim features, no exotic dependencies

### Target Use Case
Developer writes mermaid diagrams in markdown, wants to see ASCII renders inline, and share files where renders are visible without the plugin.

---

## Architecture

### Component Overview

```
vim-mermaid-ascii/
├── plugin/mermaid_ascii.vim      # Plugin initialization, commands, mappings
├── autoload/mermaid_ascii.vim    # Core functionality (lazy-loaded)
└── doc/mermaid-ascii.txt         # Vim help documentation
```

### Data Flow

```
User edits mermaid code
    ↓
OnCursorMoved() detects cursor leaving block
    ↓
UpdateRenderBlock() called
    ↓
RenderMermaid() shells out to mermaid-ascii binary
    ↓
Compare new render with old render in file
    ↓
If different: Delete old, insert new (silently)
    ↓
Restore cursor position and window view
```

### State Management

**Global State (script-local variables in autoload):**
- `s:auto_render_enabled` - Boolean: is auto-update active?

**No Block Caching:** Blocks are discovered fresh each time via `FindMermaidBlocks()`. This ensures we always work with current buffer state.

**Why No Caching?**
- Line numbers change when editing
- Simpler code, fewer bugs
- Performance is fine (finding blocks is fast)

---

## File Structure

### plugin/mermaid_ascii.vim

**Responsibility:** Plugin initialization and user interface
- Define commands
- Set up default mappings
- Configure autocmds
- Minimal code (51 lines)

**Key Pattern:** Only define interface, delegate to autoload functions

```vim
command! MermaidAsciiRender call mermaid_ascii#ToggleAuto()
```

### autoload/mermaid_ascii.vim

**Responsibility:** All core functionality
- Block discovery
- Rendering logic
- Update logic
- Auto-update handling

**Key Pattern:** Autoload for lazy loading - only loaded when commands are used

### doc/mermaid-ascii.txt

**Responsibility:** Comprehensive user documentation
- Vim help format
- All commands documented
- Workflow examples
- Configuration reference

---

## Key Concepts

### Block Discovery

A "block" is a dictionary with these keys:
```vim
{
  'mermaid_start': line_number,    " Start of ```mermaid
  'mermaid_end': line_number,      " End of ``` (closing mermaid)
  'render_start': line_number,     " Start of ```mermaid-ascii-render (0 if none)
  'render_end': line_number,       " End of ``` (closing render) (0 if none)
  'content': ['line1', 'line2'],   " Mermaid code (no markers)
  'rendered': 0 or 1               " Boolean: has render block?
}
```

**Discovery Algorithm:**
1. Scan buffer line by line
2. Track state: in_mermaid, in_render
3. When closing ``` found, check if next block is render block
4. Build block dictionary
5. Return list of blocks

### File Format

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

**Marker:** `mermaid-ascii-render` identifies render blocks
- Never edit render blocks manually
- Plugin manages them
- Both blocks saved in file

### Rendering Process

1. **Shell out to binary:**
   ```vim
   let output = systemlist('mermaid-ascii -f tempfile')
   ```

2. **Check for changes:**
   ```vim
   let old_rendered = getline(start + 1, end - 1)
   if rendered == old_rendered
     return 0  " No update needed
   endif
   ```

3. **Update silently:**
   ```vim
   silent execute old_start . ',' . old_end . 'delete'
   call append(render_start, rendered)
   ```

4. **Preserve cursor:**
   ```vim
   let save_cursor = getcurpos()
   let save_view = winsaveview()
   " ... do work ...
   call winrestview(save_view)
   call setpos('.', save_cursor)
   ```

---

## Implementation Patterns

### Pattern 1: Silent Operations

**Problem:** Vim shows "X lines deleted" which triggers hit-enter prompt

**Solution:**
```vim
silent execute '10,20delete'  " Not: execute '10,20delete'
```

**Where Used:**
- `UnrenderBlock()`
- `UpdateRenderBlock()`

### Pattern 2: Cursor Preservation

**Problem:** Editing buffer moves cursor, disrupts user

**Solution:**
```vim
let save_cursor = getcurpos()
let save_view = winsaveview()
" ... modify buffer ...
call winrestview(save_view)
call setpos('.', save_cursor)
```

**Where Used:**
- `UpdateRenderBlock()`
- Any function that modifies buffer

### Pattern 3: Change Detection

**Problem:** Don't want to update if nothing changed (spurious modified flag)

**Solution:** Compare rendered OUTPUT, not source
```vim
let old_rendered = getline(render_start + 1, render_end - 1)
if rendered == old_rendered
  return 0  " No update
endif
```

**Why This Works:**
- Whitespace-only changes don't trigger update
- Only visual changes cause update
- Prevents spurious updates when scrolling

### Pattern 4: Auto-Update Guard

**Problem:** Don't update while cursor is IN the block (would interrupt editing)

**Solution:** Track last block, only update when cursor LEAVES
```vim
if in_mermaid
  let b:last_in_mermaid_block = block.mermaid_start
  return  " Don't update yet
endif

" Only update if we just left a block
if exists('b:last_in_mermaid_block') && !in_any_block
  " Update the block we left
endif
```

### Pattern 5: Reverse Iteration

**Problem:** Deleting/inserting lines changes line numbers of later blocks

**Solution:** Process blocks in reverse order
```vim
for block in reverse(copy(blocks))
  call mermaid_ascii#RenderBlock(block)
endfor
```

---

## Common Pitfalls

### Pitfall 1: Buffer Modification Without Silent

**Symptom:** Hit-enter prompt appears
**Cause:** Vim shows messages for delete operations
**Fix:** Use `silent execute` for all delete/substitute

### Pitfall 2: Not Preserving Cursor

**Symptom:** Cursor jumps when auto-updating
**Cause:** Buffer modifications move cursor
**Fix:** Save/restore cursor position AND window view

### Pitfall 3: Modified Flag Management

**Symptom:** File marked as modified when it shouldn't be
**Cause:** Trying to restore &modified flag even when we DID change content
**Fix:** Only compare RENDERED output, let Vim set modified naturally

### Pitfall 4: Updating While Editing

**Symptom:** Can't scroll with 'k' through mermaid blocks
**Cause:** Auto-update triggers while cursor is IN block
**Fix:** Only update when cursor LEAVES block

### Pitfall 5: Using Vim Built-in Variable Names

**Symptom:** `E46: Variable "count" kann nur gelesen werden`
**Cause:** `count` is a Vim built-in variable (read-only)
**Fix:** Use different name like `num_rendered`

### Pitfall 6: Comparing Stale Content

**Symptom:** Auto-update never triggers
**Cause:** Comparing current buffer with stale cached content
**Fix:** Compare rendered OUTPUT (from buffer) not source content

---

## Testing Approach

### Manual Testing

Since this is a Vim plugin, testing is primarily manual:

1. **Create test file:**
   ```bash
   vim test_render_blocks.md
   ```

2. **Test scenarios:**
   - Create render block
   - Edit mermaid, move away → auto-updates?
   - Scroll through with 'k' → cursor jumps?
   - File marked modified? → only when content changes?
   - Toggle block → requires ENTER press?

3. **Test edge cases:**
   - Multiple blocks
   - Empty mermaid code
   - Invalid mermaid syntax
   - Very large diagrams
   - No mermaid-ascii binary

### Automated Testing

**test.sh:** Basic smoke test
```bash
#!/bin/bash
# Check binary exists
# Create test file
# Echo instructions
```

**Not Included:** Full automated tests
- Vim plugin testing is complex
- Manual testing is effective for this plugin size
- Future: Could use vader.vim or vimrunner

---

## Design Decisions

### Decision 1: Render Blocks in File vs Display-Only

**Options Considered:**
1. Virtual text (v2.0 approach) - display only
2. Folding with custom foldtext - display only
3. Render blocks in file (v3.0 approach) - persistent

**Chosen:** #3 - Render blocks in file

**Rationale:**
- Viewable without plugin (GitHub, cat, print)
- Simpler implementation
- No complex virtual text or folding tricks
- User can see renders anywhere

**Trade-offs:**
- Adds lines to file (acceptable)
- Render blocks take up space (acceptable)
- Need to manage render blocks (worth it)

### Decision 2: Auto vs Manual Update

**Chosen:** Both workflows supported

**Why:**
- Auto: Convenient for quick edits
- Manual: Control for slow renders or many edits
- Toggle between modes: `MermaidAsciiRender`

**Implementation:**
- `g:mermaid_ascii_auto_update` config
- `s:auto_render_enabled` state
- `OnCursorMoved()` autocmd

### Decision 3: Command Structure (v3.1)

**Options:**
1. Single command does everything
2. Separate commands for separate concerns

**Chosen:** #2 - Separate commands

**Rationale:**
- `MermaidAsciiRender` - toggle auto (no rendering)
- `MermaidAsciiUpdate` - update current block
- `MermaidAsciiUpdateAll` - update all blocks
- `MermaidAsciiToggleBlock` - create/remove render block

**Why:**
- Separation of concerns
- Enable auto without forcing immediate render
- Fine-grained control

### Decision 4: No Block Caching

**Why Not Cache:**
- Line numbers change constantly
- State synchronization is hard
- Bugs from stale state
- Performance fine without caching

**Discovery is Cheap:**
- Simple line-by-line scan
- No performance issues observed

### Decision 5: Compare Rendered Output

**Why Not Compare Source:**
- Source comparison needs cache (see Decision 4)
- Whitespace changes shouldn't trigger update
- Only care if VISUAL output changed

**Benefits:**
- No stale cache issues
- Smarter update logic
- Prevents spurious updates

---

## Evolution History

### v1.x - Buffer Replacement Approach

**Concept:** Replace mermaid code with ASCII in buffer

**Problems:**
- File marked as modified after rendering
- Could accidentally save ASCII instead of mermaid
- Auto-toggle behavior confusing

**Lessons:**
- Modifying buffer content is fraught with issues
- Need to preserve original source

### v2.0 - Virtual Text Approach

**Concept:** Use Vim text properties with virtual text

**Implementation:**
- Conceal mermaid lines
- Show virtual text with rendered ASCII
- Buffer never modified

**Problems:**
- Only showed one render block at a time
- Complex implementation
- Required Vim 9.1+ features
- Not viewable outside Vim

**Lessons:**
- Display-only has limitations
- Virtual text doesn't support multi-line well for this use case
- Portability matters

**Branch:** `virtual-text-approach` (archived)

### v3.0 - Render Blocks in File

**Concept:** Insert `mermaid-ascii-render` blocks with ASCII

**Why Better:**
- Viewable anywhere
- Simple implementation
- Both source and render preserved
- No complex Vim features needed

**Initial Issues:**
1. Cursor jumping → Fixed with cursor preservation
2. Spurious modified flags → Fixed with output comparison
3. Auto-update broken → Fixed with output comparison
4. Hit-enter prompts → Fixed with silent execute

### v3.1 - Command Restructure

**Change:** Separate auto-toggle from rendering

**Rationale:**
- Enable auto without forcing render
- Add manual update commands
- Better user control

**New Commands:**
- `MermaidAsciiUpdate` - update current
- `MermaidAsciiUpdateAll` - update all
- `MermaidAsciiRender` - just toggle auto (doesn't render)

---

## Code Examples

### Example 1: Finding Blocks

```vim
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
      " Check if next block is render block
      if lnum + 1 <= line('$') && getline(lnum + 1) =~# '^```mermaid-ascii-render\s*$'
        let render_start = lnum + 1
        let in_render = 1
      endif
      
      if !in_render
        " Create block without render
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
      " Create block with render
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
```

### Example 2: Cursor-Safe Update

```vim
function! mermaid_ascii#UpdateRenderBlock(block)
  " Get current content
  let current_content = getline(a:block.mermaid_start + 1, a:block.mermaid_end - 1)
  
  " Render
  let rendered = mermaid_ascii#RenderMermaid(current_content)
  if empty(rendered)
    return 0
  endif
  
  " Check if changed
  let old_rendered = getline(a:block.render_start + 1, a:block.render_end - 1)
  if rendered == old_rendered
    return 0  " No change
  endif
  
  " CRITICAL: Save cursor and view
  let save_cursor = getcurpos()
  let save_view = winsaveview()
  
  " Update (silently!)
  let old_start = a:block.render_start + 1
  let old_end = a:block.render_end - 1
  if old_end >= old_start
    silent execute old_start . ',' . old_end . 'delete'
  endif
  call append(a:block.render_start, rendered)
  
  " CRITICAL: Restore cursor and view
  call winrestview(save_view)
  call setpos('.', save_cursor)
  
  return 1
endfunction
```

### Example 3: Auto-Update Guard

```vim
function! mermaid_ascii#OnCursorMoved()
  if !s:auto_render_enabled
    return
  endif
  
  let blocks = mermaid_ascii#FindMermaidBlocks()
  let lnum = line('.')
  let in_any_block = 0
  
  " Check if we're IN a mermaid block
  for block in blocks
    if !block.rendered
      continue
    endif
    
    let in_mermaid = lnum >= block.mermaid_start && lnum <= block.mermaid_end
    
    if in_mermaid
      let in_any_block = 1
      let b:last_in_mermaid_block = block.mermaid_start
      return  " CRITICAL: Don't update while inside!
    endif
  endfor
  
  " Only update if we JUST LEFT a block
  if exists('b:last_in_mermaid_block') && !in_any_block
    for block in blocks
      if block.rendered && b:last_in_mermaid_block == block.mermaid_start
        call mermaid_ascii#UpdateRenderBlock(block)
        break
      endif
    endfor
    unlet b:last_in_mermaid_block
  endif
endfunction
```

---

## Tips for AI Agents

### When Adding Features

1. **Read existing code first** - understand patterns
2. **Follow established patterns** - consistency matters
3. **Test edge cases** - multiple blocks, empty content, etc.
4. **Preserve cursor** - always save/restore for buffer modifications
5. **Use silent** - for any execute that might show messages
6. **Update docs** - both vim help and README

### When Fixing Bugs

1. **Understand the symptom** - what exactly is wrong?
2. **Find root cause** - don't patch symptoms
3. **Check similar code** - might have same bug elsewhere
4. **Test the fix** - manually verify it works
5. **Commit with context** - explain the bug and fix

### When Refactoring

1. **One thing at a time** - don't mix refactoring with features
2. **Preserve behavior** - ensure tests still pass
3. **Update comments** - explain new approach
4. **Git history** - clear commits showing evolution

### Vim-Specific Gotchas

1. **Variable scoping:** `s:var` (script), `b:var` (buffer), `w:var` (window), `g:var` (global)
2. **Line numbers:** 1-indexed, not 0-indexed
3. **Ranges:** `10,20` is inclusive of both endpoints
4. **Regex:** `=~#` for case-sensitive match, `=~?` for case-insensitive
5. **Silent:** Suppresses messages, essential for clean UX
6. **Autoload:** Functions in `autoload/` use `#` separator: `mermaid_ascii#Function()`

---

## Future Improvements

### Potential Enhancements

1. **Syntax highlighting** for render blocks (treat as ASCII art)
2. **Multiple render formats** (not just ASCII, maybe HTML or SVG links)
3. **Diff view** showing what changed in mermaid code
4. **Batch mode** render all on file load (opt-in)
5. **Error reporting** better UX for render failures
6. **Undo integration** single undo step for render operations

### Known Limitations

1. **No async rendering** - blocks on mermaid-ascii binary
2. **No caching** - re-renders every time (acceptable performance)
3. **Single file scope** - doesn't track renders across files (by design)
4. **No conflict resolution** - if user edits render block manually, it's overwritten

---

## Conclusion

This plugin demonstrates key Vim plugin development patterns:
- Minimal plugin file, fat autoload
- Silent operations for clean UX
- Cursor preservation for smooth editing
- Change detection to avoid spurious updates
- Clear separation of concerns

The evolution from v1→v2→v3 shows how user feedback drives better design. The final approach (render blocks in file) is simplest and most useful.

**Key Takeaway:** Sometimes the simple solution (text in file) beats the clever solution (virtual text). Prioritize user value over technical elegance.

---

*Last Updated: 2025-10-28*
*Version: 3.1.0*
