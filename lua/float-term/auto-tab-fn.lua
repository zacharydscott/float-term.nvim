local M = {}

-- this is a bit cheecky and for
-- values preater than 39 a threhld
-- would be required

function M:roman_numerals()

  local rn = {
    {
      val = 10,
      char = 'X'
    },
    {
      val = 5,
      char = 'V'
    },
    {
      val = 1,
      char = 'I'
    }
  }

  local function fn(len)
    local numeral = ''
    local last_char = nil
    while len ~= 0 do
      if len > 0 then
        for _,v in pairs(rn) do
          if len >= v.val - 1 then
            numeral = numeral..(last_char or '')
            last_char = v.char
            len = len - v.val
            break
          end
        end
      else
        numeral = numeral..'I'..last_char
        last_char = nil
        len = len + 1
      end
    end
    if last_char then
      numeral = numeral..last_char
    end
    return numeral
  end
  return fn
end

return M
