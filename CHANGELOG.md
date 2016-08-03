# RL-matrix Change Log

## 0.6.0

- BREAKING: removes `GenericMatrix`class. This felt like a really 
  over-engineered solution and required some leakiness with regards to the
  immutability. The core of this library is now much less complex. If you were
  using `GenericMatrix`, please open an issue.
- BREAKING: removes `Matrix.withValues`. Was only necessary to support the
  `GenericMatrix` construct.
- BREAKING: removes `Matrix.withValuesTranspose`. Was only necessary to support 
  the `GenericMatrix` construct.
- BREAKING: removes `fromFloat32List` constructor. Use `fromList` instead.
- BREAKING: removes `[]` operator from matrix class. Use `Matrix.rowAt` instead.
- BREAKING: replaces `Matrix`'s default constructor. The default constructor now
  takes a list of lists:
  
  ```dart
  var matrix = new Matrix([
    [1.0, 2.0, 3.0],
    [4.0, 5.0, 6.0],
    [7.0, 8.0, 9.0]
  ]);
  ```
  
  Each list represents a row in the matrix. All row lists must of of equal 
  length.

  The `Matrix` class' default constructor behaved identically to the `fromList` 
  constructor. The simplest way to fix existing code that used the default
  constructor is to run a "replace all" for `new Matrix(` with 
  `new Matrix.fromList(`.

This release includes some sweeping breaking changes. However, I feel these
changes address most of the issues I had with the library in its prior state.

## 0.5.0

Changes the `rowEnd` and `colEnd` indices for `subMatrix` from being inclusive
to being exclusive. This matches conventions in the Dart standard library.

This means that the `rowEnd` and `colEnd` indices need to be incremented by
one, e.g.:

```dart
matrix.subMatrix(0, 2, 0, 2);
```

Becomes:

```dart
matrix.subMatrix(0, 3, 0, 3);
```

## 0.4.0

Adds auto-generated implementation using `Float64List` for better precision.

## 0.3.0

BC break: as of this version, the matrix implementation uses a `Float32List` for 
value memory. This should constitute a significant performance boost, but also
means that matrices now need to be instantiated with `double` values and can
no longer be instantiated with `int` values:

```dart
var matrix = new Matrix([1, 2, 3,
                         4, 5, 6], 3);

// Needs to be replaced with:

var matrix = new Matrix([1.0, 2.0, 3.0,
                         4.0, 5.0, 6.0], 3);
```

## 0.2.0

BC break: the brackets operator `[]` implementation was removed from 
`GenericMatrix` and added to `Matrix`. It's now up to a subclass of 
`GenericMatrix` whether or not to implement the `[]` operator and to decide
what the return type should be:

```dart
class ColumnVector extends GenericMatrix<ColumnVector, RowVector> {
  ...

  num operator [](int index) => valueAt(index, 0);
}
```

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
