-- Function to read and write memory
function rwmem(Address, SizeOrBuffer)
  assert(Address ~= nil, "[rwmem]: error, provided address is null.")
  local _rw = {}

  if type(SizeOrBuffer) == "number" then
    local result = ""
    for i = 1, SizeOrBuffer do
      _rw[i] = {
        address = Address - 1 + i,
        flags = gg.TYPE_BYTE
      }
    end

    -- Attempt to read values from memory
    local values = gg.getValues(_rw)
    for _, value in ipairs(values) do
      if value.value == 0 and limit == true then
        return result
      end
      result = result .. string.format("%02X", value.value & 255)
    end

    return result
  end

  local Byte = {}
  SizeOrBuffer:gsub("..", function(x)
    Byte[#Byte + 1] = x
    _rw[#Byte] = {
      address = Address - 1 + #Byte,
      flags = gg.TYPE_BYTE,
      value = x .. "h"
    }
  end)

  gg.setValues(_rw)
end

-- Function to decode hexadecimal to string
function hexdecode(hex)
  return (hex:gsub("%x%x", function(digits)
    return string.char(tonumber(digits, 16))
  end))
end

-- Function to clean and filter non-printable characters
function cleanText(str)
  return (str:gsub("[\0-\31\127]", ""))
end

-- Manually format JSON with indentation
function formatJsonManually(jsonText)
  local indent = 0
  local formatted = ""
  local inString = false
  local prevChar = ""

  for i = 1, #jsonText do
    local currentChar = jsonText:sub(i, i)

    if currentChar == '"' and prevChar ~= "\\" then
      inString = not inString
    end

    if inString then
      formatted = formatted .. currentChar
    else
      if currentChar == "{" or currentChar == "[" then
        formatted = formatted .. currentChar .. "\n"
        indent = indent + 1
        formatted = formatted .. string.rep("  ", indent)
      elseif currentChar == "}" or currentChar == "]" then
        formatted = formatted .. "\n"
        indent = indent - 1
        formatted = formatted .. string.rep("  ", indent) .. currentChar
      elseif currentChar == "," then
        formatted = formatted .. currentChar .. "\n"
        formatted = formatted .. string.rep("  ", indent)
      else
        formatted = formatted .. currentChar
      end
    end

    prevChar = currentChar
  end

  return formatted
end

-- Save data to a file
function save(data)
  local file = io.open("/sdcard/decrypt.txt", "w")
  file:write(data)
  file:close()
end

-- Main function that controls the decryption process
function DarkTunnel()
  limit = true
  gg.clearResults()
  gg.setVisible(true)
  gg.setRanges(gg.REGION_JAVA_HEAP | gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS | gg.REGION_JAVA | gg.REGION_C_HEAP | gg.REGION_C_DATA)

  -- Function to search and save specific data
  local function searchAndSave(searchText)
    gg.searchNumber(searchText, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, 0, -1, 0)
    local result = gg.getResults(1)

    if #result > 0 then
      if limit == false then
        result[1].address = result[1].address - 8192
      end
      local readedMem = rwmem(result[1].address, 10000)
      save(hexdecode(readedMem))
      return true
    end

    return false
  end

  -- List of tests with specific byte patterns
  local tests = {
    'h 7B 22 69 6E 62 6F 75 6E 64 73 22 3A 5B 7B 22 6C 69 73 74 65 6E 22 3A 22 31 32 37 2E 30 2E 30 2E 31 22 2C',
    'h 7B 22 69 6E 62 6F 75 6E 64 73 22 3A 5B 7B 22 6C 69 73 74 65 6E 22 3A 22 31 32 37 2E 30 2E 30 2E 31 22 2C',
    'h 7B 22 69 6E 62 6F 75 6E 64 73 22 3A 5B 7B 22 6C 69 73 74 65 6E 22 3A 22 31 32 37 2E 30 2E 30 2E 31 22',
    'h 3a 56 65 72 73 69 6f 6e 43 6f 64 65',
  }

  -- Attempt to search and save one of the tests
  local addressFound = false

  for _, searchText in ipairs(tests) do
    if searchAndSave(searchText) then
      addressFound = true
      break
    end
  end

  -- If no address is found, show an alert and exit
  if not addressFound then
    gg.alert("Decryption failed. Re-import the file and run the script.")
    os.exit()
  end

  -- Read the decrypted data from the file
  local file = io.open("/sdcard/decrypt.txt", "r")
  local dark = file:read("*all")
  file:close()

  -- Clean the text (remove non-printable characters)
  dark = cleanText(dark)

  -- If it's JSON-like data, format it manually
  if dark:sub(1, 1) == "{" or dark:sub(1, 1) == "[" then
    dark = formatJsonManually(dark)
  end

  -- Prepare the header
  local header = [[
╭────────────────────────╮
║ ╠═► ᗪᗩᖇK TᑌᑎᑎEᒪ ᐯ2ᖇᗩY
║ ╠═► SNIFF BY: Altaf Raja
║ ╠═► Code By: gh0st_h4ck3r
╰────────────────────────╯
]]

  -- Prepare the footer with the updated name
  local footer = [[
╭────────────────────────╮
║ ╠═► GROUP : t.me/gh0st_h4ck3r
╰────────────────────────╯
]]

  -- Wrap the JSON data with the "Json" markers
  local jsonWrapped = "```Json\n" .. dark .. "\n```"

  -- Combine header, JSON wrapped data, and footer
  local message = header .. "\n\n" .. jsonWrapped .. "\n\n" .. footer

  -- Save the combined message to the file
  save(message)

  -- Copy text including header, formatted JSON, and footer
  gg.alert(message, 'Copy and exit')
  gg.copyText(message, false)

  -- Save the message to the file
  save(message)

  -- Hide GameGuardian interface
  gg.setVisible(false)
end

-- Call the DarkTunnel function to execute the script
DarkTunnel()