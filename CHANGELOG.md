# RL-matrix Change Log

## 0.1.0

Adds a brackets `[]` operator to matrices. This allows you to get the value at
a specific position in the matrix:

```dart
var matrix = new Matrix([1, 2, 3,
                         4, 5, 6], 3);
                         
print(matrix[1][2]); // 6
```

Rows and columns are zero indexed, so `[0][0]` is the top left value.

Also adds a custom equality `==` operator, which will find 2 matrices to be
equal if their dimensions are equal and they contain the same values.

```dart
var matrix1 = new Matrix([1, 2, 3,
                          4, 5, 6], 3);
var matrix2 = new Matrix([1, 2, 3,
                          4, 5, 6], 3);
                          
print(matrix1 == matrix2); // true
```

It does not check the matrix object types, so an instance of a custom subclass 
of `GenericMatrix` may still be equal to an instance of `Matrix` if the
dimensions and values match.
