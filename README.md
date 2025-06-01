# Substitute environment variables in Markdown
A custom Markdown reader for _pandoc_, which allows to replace `{{...}}` template
strings inside a source document with values from environment variables.

The reader should be specified in `--from` argument:
```powershell
docker run --rm -i -v "$(pwd):/data" `
    -e name=Andrey -e type=Markdown -e "inline=print('Me')" `
    pandoc/minimal:3.7 input.md --from=reader-env-vars.lua --output output.docx
```

It also supports a subset of the Bash parameter expansion features:
- default value: `{{UNSET:-default val}}`
- if defined: `{{defined:+value}}`
- substring: `{{name:3:5}}`
- substring replacement: `{{string//%d/*}}` (supports Lua patterns)
- length, prefix/suffix removal, upper/lower case conversion (see also _input.md_)
