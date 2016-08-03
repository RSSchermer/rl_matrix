part of rl_matrix;

/// The reduced QR-decomposition of a [Matrix].
///
/// Decomposes an M x N [Matrix] `A`, with `M >= N`, into an M x N orthogonal
/// [Matrix] `Q` and an N x N upper rectangular [Matrix] `R`, such that
/// `A = QR`.
///
/// The primary use of the reduced QR-decomposition is in the least squares
/// solution of non-square systems of simultaneous linear equations. This will
/// fail if the [Matrix] is rank deficient.
class ReducedQRDecomposition {
  /// The source [Matrix].
  ///
  /// The [Matrix] for which this is the [ReducedQRDecomposition].
  final Matrix matrix;

  /// QR decomposition values.
  Float32List _QR;

  /// The values on the diagonal of the upper rectangular factor.
  Float32List _Rdiag;

  /// The decomposed [Matrix]'s row dimension.
  num _rows;

  /// The decomposed [Matrix]'s column dimension.
  num _cols;

  /// Memoized Householder matrix.
  Matrix _householderMatrix;

  /// Memoized upper triangular factor.
  Matrix _upperTriangularFactor;

  /// Memoized orthogonal factor.
  Matrix _orthogonalFactor;

  /// Creates a new [ReducedQRDecomposition] for the [matrix].
  ReducedQRDecomposition(Matrix matrix)
      : matrix = matrix,
        _QR = new Float32List.fromList(matrix._values),
        _rows = matrix.rowDimension,
        _cols = matrix.columnDimension,
        _Rdiag = new Float32List(matrix.columnDimension) {
    // Main loop.
    for (var k = 0; k < _cols; k++) {
      final m = k * _cols;

      // Compute 2-norm of k-th column
      var nrm = 0.0;

      for (var i = k; i < _rows; i++) {
        nrm = sqrt(pow(nrm, 2) + pow(_QR[i * _cols + k], 2));
      }

      if (nrm != 0.0) {
        // Form k-th Householder vector.
        if (_QR[m + k] < 0) {
          nrm = -nrm;
        }

        for (var i = k; i < _rows; i++) {
          _QR[i * _cols + k] /= nrm;
        }

        _QR[m + k] += 1.0;

        // Apply transformation to remaining columns.
        for (var j = k + 1; j < _cols; j++) {
          var s = 0;

          for (var i = k; i < _rows; i++) {
            var n = i * _cols;

            s += _QR[n + k] * _QR[n + j];
          }

          s = -s / _QR[m + k];

          for (var i = k; i < _rows; i++) {
            final n = i * _cols;

            _QR[n + j] += s * _QR[n + k];
          }
        }
      }

      _Rdiag[k] = -nrm;
    }
  }

  /// Whether or not the decomposed [Matrix] is full rank.
  bool get isFullRank {
    for (var j = 0; j < _cols; j++) {
      if (_Rdiag[j].abs() < 0.00001) {
        return false;
      }
    }

    return true;
  }

  /// This [ReducedQRDecomposition]'s Householder matrix.
  ///
  /// Lower trapezoidal [Matrix] whose columns define the reflections.
  Matrix get householderMatrix {
    if (_householderMatrix != null) {
      return _householderMatrix;
    }

    final values = new Float32List(_rows * _cols);
    var counter = 0;

    for (var i = 0; i < _rows; i++) {
      final m = i * _cols;

      for (var j = 0; j < _cols; j++) {
        if (i >= j) {
          values[counter] = _QR[m + j];
        } else {
          values[counter] = 0.0;
        }

        counter++;
      }
    }

    _householderMatrix = new Matrix._internal(values, _cols);

    return _householderMatrix;
  }

  /// This [ReducedQRDecomposition]'s upper triangular factor R.
  Matrix get upperTriangularFactor {
    if (_upperTriangularFactor != null) {
      return _upperTriangularFactor;
    }

    final values = new Float32List(_cols * _cols);
    var counter = 0;

    for (var i = 0; i < _cols; i++) {
      final m = i * _cols;

      for (var j = 0; j < _cols; j++) {
        if (i < j) {
          values[counter] = _QR[m + j];
        } else if (i == j) {
          values[counter] = _Rdiag[i];
        } else {
          values[counter] = 0.0;
        }

        counter++;
      }
    }

    _upperTriangularFactor = new Matrix._internal(values, _cols);

    return _upperTriangularFactor;
  }

  /// This [ReducedQRDecomposition]'s orthogonal factor Q.
  Matrix get orthogonalFactor {
    if (_orthogonalFactor != null) {
      return _orthogonalFactor;
    }

    final values = new Float32List(_rows * _cols);

    for (var i = 0; i < _rows * _cols; i++) {
      values[i] = 0.0;
    }

    for (var k = _cols - 1; k >= 0; k--) {
      final m = k * _cols;

      for (var i = 0; i < _rows; i++) {
        values[i * _cols + k] = 0.0;
      }

      if (k < _rows) {
        values[k * _cols + k] = 1.0;
      }

      for (var j = k; j < _cols; j++) {
        if (k < _rows && _QR[m + k] != 0.0) {
          var s = 0.0;

          for (var i = k; i < _rows; i++) {
            final n = i * _cols;

            s += _QR[n + k] * values[n + j];
          }

          s = -s / _QR[m + k];

          for (var i = k; i < _rows; i++) {
            final n = i * _cols;

            values[n + j] += s * _QR[n + k];
          }
        }
      }
    }

    _orthogonalFactor = new Matrix._internal(values, _cols);

    return _orthogonalFactor;
  }

  /// Solves `AX=B` for `X`, where `A` is the decomposed [Matrix] and [B] the
  /// given [Matrix].
  ///
  /// Throws an [ArgumentError] if the row dimensions of `A` and [B] do not
  /// match.
  ///
  /// Throws an [UnsupportedError] if `A` is rank deficient (not full rank).
  Matrix solve(Matrix B) {
    if (B.rowDimension != _rows) {
      throw new ArgumentError('Matrix row dimensions must agree.');
    }

    if (!isFullRank) {
      throw new UnsupportedError('Matrix is rank deficient.');
    }

    // Copy right hand side
    final xCols = B.columnDimension;
    final xVals = new Float32List.fromList(B.values);

    // Compute Y = transpose(Q)*B
    for (var k = 0; k < _cols; k++) {
      final m = k * _cols;

      for (var j = 0; j < xCols; j++) {
        var s = 0;

        for (var i = k; i < _rows; i++) {
          final n = i * _cols;

          s += _QR[n + k] * xVals[n + j];
        }

        s = -s / _QR[m + k];

        for (var i = k; i < _rows; i++) {
          final n = i * _cols;

          xVals[n + j] += s * _QR[n + k];
        }
      }
    }

    // Solve R*X = Y;
    for (var k = _cols - 1; k >= 0; k--) {
      final m = k * _cols;

      for (var j = 0; j < xCols; j++) {
        xVals[m + j] /= _Rdiag[k];
      }

      for (var i = 0; i < k; i++) {
        final n = i * _cols;

        for (var j = 0; j < xCols; j++) {
          xVals[n + j] -= xVals[m + j] * _QR[n + k];
        }
      }
    }

    return new Matrix._internal(xVals, xCols).subMatrix(0, _cols, 0, xCols);
  }
}
