lua-resty-info
==============

This module for OpenResty displays all sorts of information about currently running installation of Nginx and Lua.
It is not unlike the phpinfo() function found in PHP.

Here is a [sample output](http://www.kembox.com/lua-resty-info.html).

How to use
----------

This module must be installed in your lua package.path, possibly under the resty/ directory, for example in /usr/local/openresty/lualib/resty/info.lua, but that depends on your installation.

Then, just add this to your nginx configuration :

```
location /info {
    content_by_lua '
      local info = require "resty.info"
      info()';
}
```

Then, just call url **/info** on your server and see useful information.

It is probably not complete, so please fork and send me pull requests.

Copyright and license
=====================

Copyright (c) 2013 Bertrand Mansion, Mamasam

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
