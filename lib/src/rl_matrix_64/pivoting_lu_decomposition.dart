part of rl_matrix_64;

/// The lower-upper factor decomposition of a [Matrix], with partial pivoting.
///
/// Lower-upper factor decomposition with partial pivoting of an M x N matrix
/// `A`, results in 3 matrices:
///
/// - `L`: the lower factor matrix. An M x N [Matrix] with all zero's above the
///   diagonal.
/// - `U`: the upper factor matrix. An N x N [Matrix] with all zero's below the
///   diagonal.
/// - `P`: the pivot matrix. An M x M permutation [Matrix].
///
/// Such that `PA = LU`.
///
/// The primary use of the lower-upper decomposition is in the solution of
/// square systems of simultaneous linear equations. This will fail if the
/// [Matrix] is non-singular. Pivoting reduces the impact of rounding errors.
class PivotingLUDecomposition {
  /// The source [Matrix].
  ///
  /// The [Matrix] for which this is the [PivotingLUDecomposition].
  final Matrix matrix;

  /// LU decomposition values.
  Float64List _LU;

  /// The pivot vector.
  ///
  /// Used to keep track of where to place 1's in the pivot matrix.
  ///
  /// Each row in the pivot matrix consists of zero's and one 1. The values
  /// in the pivot vector track in which column to place the one (zero indexed).
  /// A pivot vector of `(0, 2, 3, 1)` thus corresponds to the following pivot
  /// matrix:
  ///
  ///     1 0 0 0
  ///     0 0 1 0
  ///     0 0 0 1
  ///     0 1 0 0
  ///
  List<int> _piv;

  /// The pivot sign.
  num _pivotSign = 1;

  /// The decomposed [Matrix]'s row dimension.
  int _rows;

  /// The decomposed [Matrix]'s column dimension.
  int _cols;

  /// Memoized lower factor.
  Matrix _lowerFactor;

  /// Memoized upper factor.
  Matrix _upperFactor;

  /// Memoized pivot matrix.
  Matrix _pivotMatrix;

  /// Memoized determinant.
  double _determinant;

  /// Creates a new [PivotingLUDecomposition] for the [matrix].
  PivotingLUDecomposition(Matrix matrix)
      : matrix = matrix,
        _LU = new Float64List.fromList(matrix.values.toList()),
        _rows = matrix.rowDimension,
        _cols = matrix.columnDimension,
        _piv = new List<int>.generate(matrix.rowDimension, (i) => i) {
    // Outer loop.
    for (var j = 0; j < _cols; j++) {
      final m = j * _cols;

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
          final n = p * _cols;

          final t = _LU[n + k];
          _LU[n + k] = _LU[m + k];
          _LU[m + k] = t;
        }

        final k = _piv[p];
        _piv[p] = _piv[j];
        _piv[j] = k;

        _pivotSign = -_pivotSign;
      }

      // Compute multipliers.
      if (j < _rows && _LU[m + j] != 0.0) {
        for (var i = j + 1; i < _rows; i++) {
          final n = i * _cols;

          _LU[n + j] /= _LU[m + j];

          for (var k = j + 1; k < _cols; k++) {
            _LU[n + k] -= _LU[n + j] * _LU[m + k];
          }
        }
      }
    }
  }

  /// Whether is not the decomposed [Matrix] is non-singular.
  ///
  /// A non-singular [Matrix] has an inverse and a non-zero determinant.
  ///
  /// Throws an [UnsupportedError] if the decomposed [Matrix] is not square.
  bool get isNonsingular {
    if (!matrix.isSquare) {
      throw new UnsupportedError('Matrix is not square.');
    }

    for (var j = 0; j < _cols; j++) {
      if (_LU[j * _cols + j] == 0.0) return false;
    }

    return true;
  }

  /// This [PivotingLUDecomposition]'s lower factor.
  ///
  /// A [Matrix] with all zero's above the diagonal.
  Matrix get lowerFactor {
    if (_lowerFactor != null) {
      return _lowerFactor;
    }

    final values = new Float64List(_rows * _cols);
    var counter = 0;

    for (var i = 0; i < _rows; i++) {
      final m = i * _cols;

      for (var j = 0; j < _cols; j++) {
        if (i > j) {
          values[counter] = _LU[m + j];
        } else if (i == j) {
          values[counter] = 1.0;
        } else {
          values[counter] = 0.0;
        }

        counter++;
      }
    }

    _lowerFactor = new Matrix._internal(values, _cols);

    return _lowerFactor;
  }

  /// This [PivotingLUDecomposition]'s upper factor.
  ///
  /// A [Matrix] with all zero's below the diagonal.
  Matrix get upperFactor {
    if (_upperFactor != null) {
      return _upperFactor;
    }

    final values = new Float64List(_cols * _cols);
    var counter = 0;

    for (var i = 0; i < _cols; i++) {
      final m = i * _cols;

      for (int j = 0; j < _cols; j++) {
        if (i <= j) {
          values[counter] = _LU[m + j];
        } else {
          values[counter] = 0.0;
        }

        counter++;
      }
    }

    _upperFactor = new Matrix._internal(values, _cols);

    return _upperFactor;
  }

  /// This [PivotingLUDecomposition]'s pivot matrix.
  ///
  /// A permutation matrix.
  Matrix get pivotMatrix {
    if (_pivotMatrix != null) {
      return _pivotMatrix;
    }

    final values = new Float64List(_rows * _rows);
    var counter = 0;

    for (var i = 0; i < _rows; i++) {
      for (var j = 0; j < _rows; j++) {
        if (j == _piv[i]) {
          values[counter] = 1.0;
        } else {
          values[counter] = 0.0;
        }

        counter++;
      }
    }

    _pivotMatrix = new Matrix._internal(values, _rows);

    return _pivotMatrix;
  }

  /// The decomposed [Matrix]'s determinant.
  ///
  /// Throws an [UnsupportedError] if the decomposed [Matrix] is not square.
  double get determinant {
    if (!matrix.isSquare) {
      throw new UnsupportedError('Matrix must be square.');
    }

    if (_determinant != null) {
      return _determinant;
    }

    _determinant = _pivotSign.toDouble();

    for (int j = 0; j < _cols; j++) {
      _determinant *= _LU[j * _cols + j];
    }

    return _determinant;
  }

  /// Solves `AX=B` for X, where `A` is the decomposed [Matrix] and [B] the
  /// given [Matrix].
  ///
  /// Throws an [ArgumentError] if the row dimensions of `A` and [B] do not
  /// match.
  ///
  /// Throws an [UnsupportedError] if `A` is not square.
  ///
  /// Throws an [UnsupportedError] if `A` is singular (not invertible).
  Matrix solve(Matrix B) {
    if (B.rowDimension != _rows) {
      throw new ArgumentError('Matrix row dimensions must agree.');
    }

    if (!isNonsingular) {
      throw new UnsupportedError('Matrix is singular.');
    }

    final bVals = B.values.toList();
    final xCols = B.columnDimension;
    final xVals = new Float64List(_cols * xCols);

    // Copy right hand side with pivoting
    var counter = 0;

    for (var row in _piv) {
      final m = row * xCols;

      for (var i = 0; i < xCols; i++) {
        xVals[counter] = bVals[m + i];
        counter++;
      }
    }

    // Solve L*Y = B(piv,:)
    for (var k = 0; k < _cols; k++) {
      final m = k * xCols;

      for (var i = k + 1; i < _cols; i++) {
        final n = i * xCols;
        final o = i * _cols;

        for (var j = 0; j < xCols; j++) {
          xVals[n + j] -= xVals[m + j] * _LU[o + k];
        }
      }
    }

    // Solve U*X = Y;
    for (var k = _cols - 1; k >= 0; k--) {
      final m = k * xCols;
      final n = k * _cols;

      for (var j = 0; j < xCols; j++) {
        xVals[m + j] /= _LU[n + k];
      }

      for (var i = 0; i < k; i++) {
        final o = i * xCols;
        final p = i * _cols;

        for (var j = 0; j < xCols; j++) {
          xVals[o + j] -= xVals[m + j] * _LU[p + k];
        }
      }
    }

    return new Matrix._internal(xVals, xCols);
  }
}
