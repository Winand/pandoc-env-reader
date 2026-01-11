# Substitute environment variables in input document templates
A custom reader for _pandoc_, which allows to replace `{{...}}` template
strings inside source documents with values from environment variables.

The reader should be specified in `--from` argument:
```powershell
docker run --rm -i -v "$(pwd):/data" `
    -e name=Andrey -e type=Markdown -e "inline=print('Me')" `
    pandoc/minimal:3.8 input.md --from=reader-env-vars.lua --output output.docx
```

It supports combining multiple input files. File format is determined by the extension of each input file.

Common input format can be specified via reader extension: `--from=reader-env-vars.lua+markdown`.
Default format for data read from _stdin_ is Markdown.

The reader also supports a subset of the Bash parameter expansion features:
- default value: `{{UNSET:-default val}}`
- if defined: `{{defined:+value}}`
- substring: `{{name:3:5}}`
- substring replacement: `{{string//%d/*}}` (supports Lua patterns)
- array indexing: `{{array[1]}}`
- length, prefix/suffix removal, upper/lower case conversion (see also _input.md_)
