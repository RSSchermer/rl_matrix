# RL-matrix

Provides an immutable implementation for matrices of real numbers in Dart, based 
on Java's [JAMA package](http://math.nist.gov/javanumerics/jama/). 

[![Build Status](https://travis-ci.org/RSSchermer/rl_matrix.svg?branch=master)](https://travis-ci.org/RSSchermer/rl_matrix)

## Usage

Example:

```dart
var matrix = new Matrix([1, 2, 3,
                         4, 5, 6], 3);
var transpose = matrix.transpose;
var product = matrix * transpose;
```

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
  ColumnVector(List<num> values) : super.fromList(values, 1);

  ColumnVector withValues(List<num> newValues) =>
    new ColumnVector(newValues);

  RowVector transposeWithValues(List<num> newValues) =>
    new RowVector(newValues);
}
```
