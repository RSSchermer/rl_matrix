# RL-matrix

Provides an immutable implementation for matrices of real numbers in Dart, based 
on Java's [JAMA package](http://math.nist.gov/javanumerics/jama/). 

[![Build Status](https://travis-ci.org/RSSchermer/rl_matrix.svg?branch=master)](https://travis-ci.org/RSSchermer/rl_matrix)

## Usage

Example:

```dart
// Instantiates the following matrix:
//
// 1.0 2.0 3.0
// 4.0 5.0 6.0
//
var matrix = new Matrix([1.0, 2.0, 3.0,
                         4.0, 5.0, 6.0], 3);

var transpose = matrix.transpose;
var product = matrix * transpose;
```

Matrix instantiation currently takes 2 arguments: the first argument is a row
major list of values and the second argument is the matrix's column dimension.
Matrices need to be instantiated with double values, using integer values will
result in an error.

For a complete overview of the operations available, have a look at the 
[API documentation](http://www.dartdocs.org/documentation/rl_matrix/latest/index.html#rl_matrix).

## Dimension specific matrix classes

You may want to create a custom matrix class, either to be able to leverage
Dart's type checker to enforce specific matrix dimensions, or to override 
certain algorithms with more effective dimension specific implementations.
The abstract `GenericMatrix` class can be extended for this purpose. The 
`GenericMatrix` class takes 2 type parameters: the extending class' type 
(a self-bound) and the extending class' transpose type. Also, two abstract 
methods will need to be defined:

- `withValues`: needs to return a new matrix of the same type and with the same 
  dimensions, with the given values.
- `transposeWithValues`: needs to return a new matrix of the matrix's transpose 
  type, with transposed dimensions, with the given values.

The following example implements a column vector:

```dart
class ColumnVector extends GenericMatrix<ColumnVector, RowVector> {
  ColumnVector(List<double> values) : super.fromList(values, 1);
  
  ColumnVector.fromFloat32List(Float32List values)
      : super.fromFloat32List(values, 1);

  ColumnVector withValues(Float32List newValues) =>
    new ColumnVector.fromFloat32List(newValues);

  RowVector transposeWithValues(Float32List newValues) =>
    new RowVector.fromFloat32List(newValues);
}
```
