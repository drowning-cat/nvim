;; extends

(function_definition
  parameters: (_)
  (_)+ @function.inner)

(function_declaration
  parameters: (_)
  (_)+ @function.inner)

((while_statement
  condition: (_) @block.inner) @block.outer)

((for_statement
  clause: (_) @block.inner) @block.outer)

((binary_expression
  left: (binary_expression)) @ternary.outer)
(binary_expression
  left: (binary_expression left: (_) @ternary.inner))
(binary_expression
  left: (binary_expression right: (_) @ternary.inner))
(binary_expression
  left: (binary_expression) right: (_) @ternary.inner)
