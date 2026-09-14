# Substitute environment variables in input document templates
A custom reader for _pandoc_, which allows to replace `{{...}}` template
strings inside source documents with values from environment variables.

The reader should be specified in `--from` argument:
```powershell
docker run --rm -i -v "$(pwd):/data" `
    -e name=Andrey -e type=Markdown -e "inline=print('Me')" `
    pandoc/minimal:3.8 input.md input.typ --from=reader-env-vars.lua --output output.docx
```

It supports combining multiple input files. File format is determined by the extension of each input file.

Common input format can be specified via reader extension: `--from=reader-env-vars.lua+markdown`.
Default format for data read from _stdin_ is Markdown.

The reader also supports a subset of the Bash parameter expansion features and additional features:
- default value: `{{UNSET:-default val}}`
- if defined: `{{defined:+value}}`
- simple conditionals (eq, ne, gt, ge, le, lt): `{{name="John":+value}}`, `{{name!=name2:+value}}`
- substring: `{{name:3:5}}`
- substring replacement: `{{string//%d/*}}` (supports Lua patterns)
- array indexing: `{{array[1]}}`, `{{array[-2]}}`
- length, prefix/suffix removal, upper/lower case conversion (see also _input.md_)
