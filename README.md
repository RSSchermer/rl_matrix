# RL-matrix

Provides an immutable implementation for matrices of real numbers in Dart, based 
on Java's [JAMA package](http://math.nist.gov/javanumerics/jama/). 

[![Build Status](https://travis-ci.org/RSSchermer/rl_matrix.svg?branch=master)](https://travis-ci.org/RSSchermer/rl_matrix)

## Usage

Example:

```dart
// Instantiates the following matrix:
//
//     1.0 2.0 3.0
//     4.0 5.0 6.0
//
var matrix = new Matrix([
  [1.0, 2.0, 3.0],
  [4.0, 5.0, 6.0]
]);

var transpose = matrix.transpose;
var product = matrix * transpose;
```

For a complete overview of the operations available, have a look at the 
[API documentation for the Matrix class](https://www.dartdocs.org/documentation/rl_matrix/latest/rl_matrix/Matrix-class.html).
