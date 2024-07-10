# luasocket-playground

## Building

### With `mise` and `luarocks`

1. Install [mise](https://mise.jdx.dev/)
2. Run `mise install`
   1. This will install `lua` and `luarocks` scoped to this dir; it shouldn't use your system's `luarocks` or `lua` if they're present
3. Run `luarocks build`

### Manually with `luarocks`

`require`s are written assuming that the `package.path` of the environment matches what the [asdf-lua](https://github.com/Stratus3D/asdf-lua) plugin would do, as that's what `mise` uses to manage Lua versions. The paths are prepended by the values in the `.env` file for the directory.

You'll also need to install [luarocks](https://luarocks.org/#quick-start) at a version that supports rockspec format 3.0.

1. Install `lua`
2. Install `luarocks`
3. Run `luarocks build`
4. Configure your package path (either via `LUA_PATH` or some other mechanism to set `package.path`) to start with the values in the `.env` and end with the path to your `luarocks` installation.
5. Configure your package cpath (either via `LUA_CPATH` or some other mechanism to set `package.cpath`) to be able to find native libs from your luarocks install, since `luasocket` has C code.

## Running the examples

Every file in the `src` folder is a standalone script. From the root dir, use `lua src/<script_name>` to execute them.

### Script arguments

All of the example scripts can take the following arguments, with default fallbacks:

- `-h`|`--host <string>`|`--host=<string>`: the hostname to use for connections. Defaults to `"127.0.0.1"`.
- `-p`|`--port <string>`|`--port=<string>`: the port to use for connections. Defaults to `"9999"`. Use `'*'` in single quotes for random port selection.
- `-l`|`--log <string>`|`--log=<string>`: the log level. Defaults to `'info'`.

See [./lib/parsearg.lua](./lib/parsearg.lua) for argument parsing details.
