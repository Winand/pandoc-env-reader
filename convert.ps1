docker run --rm -i -v "$(pwd):/data" `
    -e name=Andrey -e type=Markdown -e "inline=print('Me')" `
    pandoc/minimal:3.7 input.md --from=reader-env-vars.lua --output output.md
