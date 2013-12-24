-- General information about OpenResty installation
-- Copyright (C) 2013 Bertrand Mansion (golgote), Mamasam
-- License MIT

local M = {
	_VERSION = '0.1'
}

local function htmlspecialchars(str)
	local html = {
		["<"] = "&lt;",
		[">"] = "&gt;",
		["&"] = "&amp;",
	}
	return string.gsub(tostring(str), "[<>&]", function(char)
		return html[char] or char
	end)
end

local function dump2html(value, field)
	local html

	local function isemptytable(t)
		return next(t) == nil
	end

	local function basicSerialize(o)
		local so = tostring(o)
		if not o then
			return "nil"
		elseif type(o) == "function" then
			local info = debug.getinfo(o, "S")
			-- info.name is nil because o is not a calling level
			if info.what == "C" then
				return "C function"
			else
				-- the information is defined through lines
				return string.format("%s", so .. ", defined in (" ..
					info.linedefined .. "-" .. info.lastlinedefined ..
				")" .. info.source)
			end
		elseif type(o) == "number" then
			return so
		elseif type(o) == "boolean" then
			return so
		else
			return htmlspecialchars(so)
		end
	end

	local function addtohtml(value, field, saved)
		local value = value
		saved = saved or {}
		html[#html+1] = '<tr><td class="left">' .. field .. '</td>'
		if type(value) ~= "table" then
			html[#html+1] = '<td>' .. basicSerialize(value) .. '</td></tr>'
		else
			if saved[value] then
				html[#html+1] = '<td>' .. saved[value] .. ' (self reference)' .. '</td></tr>'

			else
				saved[value] = field
				if isemptytable(value) then
					html[#html+1] = '<td>{ }</td>'
				else
					html[#html+1] = '<td style="padding:0">'
					html[#html+1] = '<table>'
					for k, v in pairs(value) do
						k = basicSerialize(k)
						addtohtml(v, k, saved)
					end
					html[#html+1] = '</table>'
					html[#html+1] = '</td>'
				end
				html[#html+1] = '</tr>'
			end
		end
	end

	if type(value) ~= "table" then
		return '<tr><td class="left">' .. field .. '</td><td>' .. basicSerialize(value) .. '</td></tr>'
	end

	html = {}
	addtohtml(value, field)
	return table.concat(html, "\n")
end

local function package_info()
	local ngx = ngx
	local modules = {}
	local packages = {}
	for id, content in pairs(package.loaded) do
		packages[id] = content
	end
	packages["ngx"] = ngx

	for id, content in pairs(packages) do
		if id ~= 'package' and id ~= 'preload' and id ~= '_G' and type(content) == 'table' then
			modules[id] = {}
			local functions = {}
			local meta = {}
			for its_id, its_c in pairs(content) do
				if type(its_c) == 'string' or type(its_c) == 'number' then
					meta[its_id] = tostring(its_c)
				elseif type(its_c) == 'function' then
					functions[#functions+1] = its_id
				end
			end
			modules[id]["meta"] = meta
			table.sort(functions)
			modules[id]["functions"] = functions
		end
	end

	local html = {}
	-- sorted list of modules
	local sorted = {}
	for n in pairs(modules) do table.insert(sorted, n) end
	table.sort(sorted)
	for _,id in ipairs(sorted) do
		local values = modules[id]
		html[#html+1] = '<table cellspacing="0" align="center"><tr><th colspan="2">'.. id ..'</th></tr>'
		if values["meta"] then
			-- sort properties
			local meta = values['meta']
			sorted = {}
			for n in pairs(meta) do table.insert(sorted, n) end
			table.sort(sorted)
			for i,n in ipairs(sorted) do
				html[#html+1] = '<tr class="meta"><td class="left">' .. n .. '</td><td>' .. meta[n] .. '</td></tr>'
			end
		end
		-- functions
		if values["functions"] and #values["functions"] > 0 then
			html[#html+1] = '<tr><td colspan="2" class="functions"><span class="function">' .. table.concat(values["functions"], '</span> <span class="function">') .. '</span></td></tr>'
		end
		html[#html+1] = '</table>'
	end
	return table.concat(html, "\n")
end

local function server_configuration()
	local ngx = ngx
	local html = {'<table cellspacing="0" align="center"><tr><th>Directive</th><th>Value</th></tr>'}
	html[#html+1] = '<tr><td class="left">Nginx version</td><td>' .. htmlspecialchars(tostring(ngx.config.nginx_version)) .. '</td></tr>'
	html[#html+1] = '<tr><td class="left">Nginx Lua version</td><td>' .. htmlspecialchars(tostring(ngx.config.ngx_lua_version)) .. '</td></tr>'
	html[#html+1] = '<tr><td class="left">Lua version</td><td>' .. htmlspecialchars(tostring(_VERSION)) .. '</td></tr>'

	local paths

	-- package.path
	paths = {}
	for token in string.gmatch(package.path, "[^;]+") do
		paths[#paths+1] = htmlspecialchars(token)
	end
	html[#html+1] = '<tr><td class="left">package.path</td><td>' .. table.concat(paths, "<br>") .. '</td></tr>'

	-- package.cpath
	paths = {}
	for token in string.gmatch(package.cpath, "[^;]+") do
		paths[#paths+1] = htmlspecialchars(token)
	end
	html[#html+1] = '<tr><td class="left">package.cpath</td><td>' .. table.concat(paths, "<br>") .. '</td></tr>'

	html[#html+1] = '</table>'
	return table.concat(html, "\n")
end

local function server_info()
	local ngx = ngx
	-- from http://wiki.nginx.org/NginxHttpCoreModule#.24arg_PARAMETER
	local vars = {
		"args",
		"body_bytes_sent",
		"content_length",
		"content_type",
		"cookie_test", -- cookie_COOKIE
		"document_root",
		"document_uri",
		"headers_in",
		"headers_out",
		"host",
		"hostname",
		"http_user_agent", -- http_HEADER
		"http_referer", -- http_HEADER
		"is_args",
		"limit_rate",
		"nginx_version",
		"query_string",
		"remote_addr",
		"remote_port",
		"remote_user",
		"request_filename",
		"request_body",
		"request_body_file",
		"request_completion",
		"request_method",
		"request_uri",
		"scheme",
		"server_addr",
		"server_name",
		"server_port",
		"server_protocol",
		"uri",
	}
	local html = {'<table cellspacing="0" align="center"><tr><th>Variable</th><th>Value</th></tr>'}
	for i,v in ipairs(vars) do
		if ngx.var[v] then
			html[#html+1] = '<tr><td class="left">ngx.var.' .. v .. '</td><td>' .. htmlspecialchars(tostring(ngx.var[v])) .. '</td></tr>'
		end
	end
	html[#html+1] = '<tr><td class="left">ngx.header_sent</td><td>' .. htmlspecialchars(tostring(ngx.header_sent)) .. '</td></tr>'
	html[#html+1] = '<tr><td class="left">ngx.status</td><td>' .. htmlspecialchars(tostring(ngx.status)) .. '</td></tr>'
	html[#html+1] = '<tr><td class="left">ngx.is_subrequest</td><td>' .. htmlspecialchars(tostring(ngx.is_subrequest)) .. '</td></tr>'
	html[#html+1] = dump2html(ngx.ctx, 'ngx.ctx')

	html[#html+1] = '</table>'
	return table.concat(html, "\n")
end

local function server_functions()
	local html = {}
	local result = {}
	local ngx = ngx

	result['ngx.req.get_headers()'] = ngx.req.get_headers()
	result['ngx.req.get_uri_args()'] = ngx.req.get_uri_args()
	result['ngx.today()'] = ngx.today()
	result['ngx.time()'] = ngx.time()
	result['ngx.now()'] = ngx.now()
	result['ngx.localtime()'] = ngx.localtime()
	result['ngx.utctime()'] = ngx.utctime()
	result['ngx.get_phase()'] = ngx.get_phase()

	local html = {'<table cellspacing="0" align="center"><tr><th>Function</th><th>Result</th></tr>'}
	for id, content in pairs(result) do
		html[#html+1] = dump2html(content, id)
	end
	html[#html+1] = '</table>'
	return table.concat(html, "\n")
end

M.info = function()
	local template = [[<html><head><title>Lua resty info</title>
	<style>
	body, td, th {font:12px Arial, sans-serif;}
	table {width:90%%;border-right:1px solid #69D2E7;margin-bottom:10px;border-collapse:collapse;}
	tr.meta {background-color:#e3fbff}
	td {border-left:1px solid #69D2E7;border-bottom:1px solid #69D2E7;padding:4px;vertical-align:top;}
	td.left {background-color:#caf2f8;font-weight:bold;width:33%%;}
	table table {width:100%%;border:0;margin:0;}
	table table td {border:0;}
	table table tr {border-top:1px solid #69D2E7;}
	table table tr:first-child {border:0;}
	th {background-color:#69D2E7;color:white;text-align:left;padding:4px;font-weight:bold;}
	h1 {font-weight:bold;font-size:1.6em;text-align:center;color:#444}
	h2 {font-weight:bold;font-size:1.4em;text-align:center;color:#444}
	.functions {line-height:2.2em}
	span.function {padding:4px 8px;background-color:#E0E4CC;border-radius:3px}
	</style>
	</head><body>
	<h1>Nginx OpenResty version %s</h1>
	<h2>Server configuration</h2>
	%s
	<h2>Modules</h2>
	%s
	<h2>Server variables</h2>
	%s
	<h2>Resty functions</h2>
	%s
	</body></html>]]

	local html = string.format(template, ngx.var.nginx_version, server_configuration(), package_info(), server_info(), server_functions())
	ngx.header.content_type = 'text/html'
	ngx.print(html)
end

local mt = {}
mt.__call = function(...)
	 return M.info(...)
end
setmetatable(M, mt)

return M
