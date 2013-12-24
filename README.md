lua-resty-info
==============

This module for OpenResty displays all sorts of information about currently running installation of Nginx and Lua.
It is not unlike the phpinfo() function found in PHP.

Here is a [sample output](http://www.kembox.com/lua-resty-info.html).

How to use
----------

Add this to your nginx configuration

```
location /info {
    content_by_lua '
      local info = require 'resty.info'
      info()';
}
```

Then, just call url **/info** on your server and see useful information.
