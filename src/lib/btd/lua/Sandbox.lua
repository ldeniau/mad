-----------------------------------------------------------------------------
-- Sandbox utilities.
-- (c) 2008 Wim Langers (www.adrias.biz), except where noted otherwise
-- License : propietary
-- @release 0.0.0
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Class definition.
-----------------------------------------------------------------------------
local M = {}

-----------------------------------------------------------------------------
-- Accept table values.
-- Only keys present in the mask will be withheld, all others are deleted.
-- Mask entries :
-- - for functions : gMask[functionname] == nil
--   => function is disabled
-- - for tables :
--   - gMask[tablename] == nil
--      => table is disabled
--   - gMask[tablename] != nil and != table
--     => table is enabled (and all it's functions)
--   - gMask[tablename] == table
--     => activate is recursively called on the table
--
-- @param   table   table to mask
-- @param   mask    mask
-- @return          masked values
-----------------------------------------------------------------------------
local function accept(table,mask,restore)
  local restore = restore or {}
  for k,v in pairs(table) do
    if type(k) == "table" and type(mask[k]) == "table" then
      restore = activate(v,mask[k],restore)
    elseif mask[k] == nil then
      restore[k] = v
      table[k] = nil
    end
  end
  return restore
end

-----------------------------------------------------------------------------
-- Reject table values.
-- Only keys not present in the mask will be withheld, all others are deleted.
-- Mask entries :
-- - single values : disable the function or table in the environment
-- - tables : result in recursively calling the function
--
-- @param   table   table to mask
-- @param   mask    mask
-- @return          masked values
-----------------------------------------------------------------------------
local function reject(table,mask,restore)
  local restore = restore or {}
  for k,v in pairs(mask) do
    if type(v) == "table" and type(table[k]) == "table" then
      restore = deactivate(table[k],v,restore)
    else
      restore[k] = table[k]
      table[k] = nil
    end
  end
  return restore
end

-----------------------------------------------------------------------------
-- Walk directory structure.
-- Recursively walk directory structure and perform the requested task.
-- Uses Lua pattern matching.
-- @param   dir         source directory
-- @param   pattern     filename matcher pattern as a regex
-- @param   task        task (function) to be performed, with :
--                      - parameters found directory, found file
--                      - upon returning a non nil value the file will be
--                        added to the list of processed files
-- @return              list of processed files
-----------------------------------------------------------------------------
local function walk(dir,pattern,task)
  dir = string.match(dir,'.*/$') or (dir..'/')
  local list = {}
  for file in lfs.dir(dir) do
    if file ~= '.' and file ~= '..' then
      if string.find(dir..file,pattern) then table.insert(list,task(dir,file)) end
      if lfs.attributes(dir..file,'mode') == 'directory' then
        local list2 = walk(dir..file,pattern,task)
        if list2 then
          for _,v in pairs(list2) do table.insert(list,v) end
        end
      end
    end
  end
  if #list > 0 then return list else return nil end
end

-----------------------------------------------------------------------------
-- Copy files.
-- Recursively walk directory structure and copy all files matching pattern.
-- Existing files will be overwritten.
-- Uses Lua pattern matching.
-- @param   srcdir      source directory
-- @param   destdir     destination directory
-- @param   pattern     filename matcher pattern as a regex
-- @return              list of copied files
-----------------------------------------------------------------------------
local function copy(srcdir,destdir,pattern)
  srcdir = string.match(srcdir,'.*/$') or (srcdir..'/')
  destdir = string.match(destdir,'.*/$') or (destdir..'/')
  return walk(srcdir,pattern,
    function(founddir,foundfile)
      if lfs.attributes(founddir..foundfile,'mode') == 'directory' then return nil end
      local src = assert(io.open(founddir..foundfile,'rb'))
      local dir = destdir..string.match(founddir,srcdir..'(.*)')
      lfs.mkdir(dir)
      local dest = assert(io.open(dir..foundfile,'wb'))
      dest:write(src:read('*a'))
      src:close()
      dest:close()
      return founddir..foundfile
    end)
end

-----------------------------------------------------------------------------
-- Exported functions.
-----------------------------------------------------------------------------
M.accept = accept
M.reject = reject
return M

