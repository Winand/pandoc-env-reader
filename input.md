# Hello, {{name}}
This is a test {{type}} file.

It allows to substitute variables in `inline code like this: {{inline}}`
and in code blocks:
```python
print("Hello, {{name}}")
```

Unknown variables are marked with "!!": {{unknown}}

It also supports some of the Bash features:

- Default value: UNSET is '{{UNSET:-default val}}'
- Remove first 3 characters: {{name:3}}
- Value if a variable is defined: name is {{name:+defined}}
- Length of a value: name is {{#name}} characters long
- Remove suffix: {{name%rey}}, remove prefix: {{name#And}}
- Upper case: {{inline^}} (first letter), {{inline^^}} (all)
- Lower case: {{name,}} (first letter), {{name,,}} (all)
- Replace substring: {{inline/'/"}} (first), {{inline//'/"}} (all)
- Recursive resolution of variables: {{type:{{#name}}}}, {{UNSET:-{{name/y/w}}}}
