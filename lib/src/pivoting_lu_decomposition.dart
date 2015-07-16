part of matrix;

/// The lower-upper factor decomposition of a matrix, with partial pivoting.
///
/// Lower-upper factor decomposition with partial pivoting of an M x N matrix A,
/// results in 3 matrices:
///
/// - L: the lower factor matrix. An M x N matrix with all zero's above the
///   diagonal.
/// - U: the upper factor matrix. An N x N matrix with all zero's below the
///   diagonal.
/// - P: the pivot matrix. An M x M permutation matrix.
///
/// Such that `PA = LU`.
///
/// The primary use of the lower-upper decomposition is in the solution of
/// square systems of simultaneous linear equations. This will fail if the
/// matrix is non-singular. Pivoting reduces the impact of rounding errors.
class PivotingLUDecomposition {

  /// The source matrix.
  ///
  /// The matrix for which this is the LU decomposition.
  final GenericMatrix matrix;

  /// LU decomposition values.
  List<num> _LU;

  /// The pivot vector.
  ///
  /// Used to keep track of where to place 1's in the pivot matrix.
  ///
  /// Each row in the pivot matrix consists of zero's and one 1. The values
  /// in the pivot vector track in which column to place the one (zero indexed).
  /// A pivot vector of `(0, 2, 3, 1)` thus corresponds to the following pivot
  /// matrix:
  ///
  ///   1 0 0 0
  ///   0 0 1 0
  ///   0 0 0 1
  ///   0 1 0 0
  ///
  List<num> _piv;

  /// The pivot sign.
  num _pivotSign = 1;

  /// The decomposed matrix's row dimension.
  num _rows;

  /// The decomposed matrix's column dimension
  num _cols;

  /// Memoized lower factor.
  GenericMatrix _lowerFactor;

  /// Memoized upper factor.
  GenericMatrix _upperFactor;

  /// Memoized pivot matrix.
  GenericMatrix _pivotMatrix;

  /// Memoized determinant.
  num _determinant;

  /// Creates a new lower-upper factor decomposition for the given matrix.
  PivotingLUDecomposition(GenericMatrix matrix)
      : matrix = matrix,
        _LU = matrix.valuesRowPacked.toList(),
        _rows = matrix.rowDimension,
        _cols = matrix.columnDimension,
        _piv = new List.generate(matrix.rowDimension, (i) => i) {

    // Outer loop.
    for (var j = 0; j < _cols; j++) {

      // Find pivot
      var p = j;

      for (var i = j + 1; i < _rows; i++) {
        if (_LU[i * _cols + j].abs() > _LU[p * _cols + j].abs()) {
          p = i;
        }
      }

      // Exchange pivot if necessary
      if (p != j) {
        for (var k = 0; k < _cols; k++) {
          var t = _LU[p * _cols + k];
          _LU[p * _cols + k] = _LU[j * _cols + k];
          _LU[j * _cols + k] = t;
        }

        var k = _piv[p];
        _piv[p] = _piv[j];
        _piv[j] = k;

        _pivotSign = -_pivotSign;
      }

      // Compute multipliers.
      if (j < _rows && _LU[j * _cols + j] != 0) {
        for (var i = j + 1; i < _rows; i++) {
          _LU[i * _cols + j] /= _LU[j * _cols + j];

          for (var k = j + 1; k < _cols; k++) {
            _LU[i * _cols + k] -= _LU[i * _cols + j] * _LU[j * _cols + k];
          }
        }
      }
    }
  }

  /// Whether is not the decomposed matrix is non-singular.
  ///
  /// A non-singular matrix has an inverse and a non-zero determinant.
  ///
  /// Throws an [UnsupportedError] if the decomposed matrix is not square.
  bool get isNonsingular {
    if (!matrix.isSquare) {
      throw new UnsupportedError("Matrix is not square.");
    }

    for (var j = 0; j < _cols; j++) {
      if (_LU[j * _cols + j] == 0)
        return false;
    }

    return true;
  }

  /// The decomposition's lower factor.
  ///
  /// A matrix with all zero's above the diagonal.
  GenericMatrix get lowerFactor {
    if (_lowerFactor != null) {
      return _lowerFactor;
    }

    var values = new List();

    for (var i = 0; i < _rows; i++) {
      for (var j = 0; j < _cols; j++) {
        if (i > j) {
          values.add(_LU[i * _cols + j]);
        } else if (i == j) {
          values.add(1);
        } else {
          values.add(0);
        }
      }
    }

    _lowerFactor = new Matrix(values, _cols);

    return _lowerFactor;
  }

  /// The decomposition's upper factor.
  ///
  /// A matrix with all zero's below the diagonal.
  GenericMatrix get upperFactor {
    if (_upperFactor != null) {
      return _upperFactor;
    }

    var values = new List();

    for (var i = 0; i < _cols; i++) {
      for (int j = 0; j < _cols; j++) {
        if (i <= j) {
          values.add(_LU[i * _cols + j]);
        } else {
          values.add(0);
        }
      }
    }

    _upperFactor = new Matrix(values, _cols);

    return _upperFactor;
  }

  /// The decomposition's pivot matrix.
  ///
  /// A permutation matrix.
  GenericMatrix get pivotMatrix {
    if (_pivotMatrix != null) {
      return _pivotMatrix;
    }

    var values = new List();

    for (var i = 0; i < _rows; i++) {
      for (var j = 0; j < _rows; j++) {
        if (j == _piv[i]) {
          values.add(1);
        } else {
          values.add(0);
        }
      }
    }

    _pivotMatrix = new Matrix(values, _rows);

    return _pivotMatrix;
  }

  /// The decomposed matrix's determinant.
  ///
  /// Throws an [UnsupportedError] if the decomposed matrix is not square.
  num get determinant {
    if (!matrix.isSquare) {
      throw new UnsupportedError('Matrix must be square.');
    }

    if (_determinant != null) {
      return _determinant;
    }

    _determinant = _pivotSign;

    for (int j = 0; j < _cols; j++) {
      _determinant *= _LU[j * _cols + j];
    }

    return _determinant;
  }

  /// Solves `AX=B` for X, where A is the decomposed matrix and B the given
  /// matrix.
  ///
  /// Throws an [ArgumentError] if the row dimensions of A and B do not match.
  /// Throws an [UnsupportedError] if A is singular.
  /// Throws an [UnsupportedError] if A is not square.
  GenericMatrix solve (GenericMatrix B) {
    if (B.rowDimension != _rows) {
      throw new ArgumentError('Matrix row dimensions must agree.');
    }

    if (!isNonsingular) {
      throw new UnsupportedError('Matrix is singular.');
    }

    // Copy right hand side with pivoting
    var bVals = B.values.toList();
    var xVals = new List();
    var xCols = B.columnDimension;

    _piv.forEach((row) {
      for (var i = 0; i < xCols; i++) {
        xVals.add(bVals[row * xCols + i]);
      }
    });

    // Solve L*Y = B(piv,:)
    for (var k = 0; k < _cols; k++) {
      for (var i = k + 1; i < _cols; i++) {
        for (var j = 0; j < xCols; j++) {
          xVals[i * xCols + j] -= xVals[k * xCols + j] * _LU[i * _cols + k];
        }
      }
    }

    // Solve U*X = Y;
    for (var k = _cols - 1; k >= 0; k--) {
      for (var j = 0; j < xCols; j++) {
        xVals[k * xCols + j] /= _LU[k * _cols + k];
      }

      for (var i = 0; i < k; i++) {
        for (var j = 0; j < xCols; j++) {
          xVals[i * xCols + j] -= xVals[k * xCols + j] * _LU[i * _cols + k];
        }
      }
    }

    return new Matrix(xVals, xCols);
  }
}
