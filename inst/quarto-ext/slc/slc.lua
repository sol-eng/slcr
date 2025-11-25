function Meta(meta)
  -- Read the shared HTML resource file
  local directory = quarto.project and quarto.project.directory or "."
  local resource_path = directory .. "/_extensions/slc/slc-resources.html"

  local handle = io.open(resource_path, "r")
  if not handle then
    -- Fallback: try to find it in the R package installation
    -- This is a simplified approach - in practice you'd need to locate the R package
    return meta
  end

  local resources = handle:read("*a")
  handle:close()

  quarto.doc.include_text("in-header", resources)
  return meta
end

return {
  { Meta = Meta }
}
