= Typst example
A list:
#let left = (2, "{{type}}", 5)
#let right = (3, 2, 6)
#left.zip(right).map(
  ((a,b)) => a * b
)

The name is: {{name}}
