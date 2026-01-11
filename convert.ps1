docker run --rm -i -v "$(pwd):/data" `
    -e name=Andrey -e type=Markdown -e "inline=print('Me')" `
    pandoc/minimal:3.8 input.md input.typ --from=reader-env-vars.lua --output output.md
