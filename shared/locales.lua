Locales = Locales or {}

function _U(key, vars)
  local lang = (Config and Config.Locale) or 'en'
  local t = (Locales[lang] and Locales[lang][key]) or (Locales['en'] and Locales['en'][key]) or key

  if vars then
    for k, v in pairs(vars) do
      t = t:gsub('{' .. k .. '}', tostring(v))
    end
  end
  return t
end