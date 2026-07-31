; extends

(function_definition
  parameters: (_)
  (_)+ @function.inner)

(function_declaration
  parameters: (_)
  (_)+ @function.inner)

(while_statement
  condition: (_) @block.inner) @block.outer

(for_statement
  clause: (_) @block.inner) @block.outer

(variable_list
  name: (_) @parameter.inner)

(expression_list
  value: (_) @parameter.inner)

(variable_list
  name: (_) @parameter.outer
  "," @parameter.outer)

(expression_list
  value: (_) @parameter.outer
  "," @parameter.outer)

(binary_expression
  left: (binary_expression)) @ternary.outer

(binary_expression
  left: (binary_expression
    left: (_) @ternary.inner))

(binary_expression
  left: (binary_expression
    right: (_) @ternary.inner))

(binary_expression
  left: (binary_expression)
  right: (_) @ternary.inner)
