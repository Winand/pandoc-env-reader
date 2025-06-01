# Substitute environment variables in Markdown
A custom Markdown reader for _pandoc_, which allows to replace `{{...}}` template
values inside a source document with values from environment variables.

The reader should be specified in `--from` argument:
```powershell
docker run --rm -i -v "$(pwd):/data" `
    -e name=Andrey -e type=Markdown -e "inline=print('Me')" `
    pandoc/minimal:3.7 input.md --from=reader-env-vars.lua --output output.docx
```

It also support some of Bash paramenter expansion features:
- default value: `{{UNSET:-default val}}`
- if defined: `{{defined:+value}}`
- substring: `{{name:3:5}}`
- length, prefix/suffix removal, substring replacement,
upper/lower case conversion (see also _input.md_)
