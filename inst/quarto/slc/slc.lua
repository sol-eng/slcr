local function ensureSlcFilter()
  return {
    CodeBlock = function(el)
      if el.attr.classes[1] == "slc" then
        return el
      end
      return el
    end
  }
end

return {
  {
    Filter = ensureSlcFilter,
    name = "slc"
  }
}