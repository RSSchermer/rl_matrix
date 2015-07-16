part of matrix;

class QRDecomposition {

  /// The source matrix.
  ///
  /// The matrix for which this is the QR decomposition.
  final GenericMatrix matrix;

  /// QR decomposition values.
  List<num> _QR;

  List<num> _Rdiag = new List();

  /// The decomposed matrix's row dimension.
  num _rows;

  /// The decomposed matrix's column dimension
  num _cols;

  GenericMatrix _householderMatrix;

  GenericMatrix _upperTriangularFactor;

  GenericMatrix _orthogonalFactor;

  QRDecomposition(GenericMatrix matrix)
      : matrix = matrix,
        _QR = matrix.valuesRowPacked.toList(),
        _rows = matrix.rowDimension,
        _cols = matrix.columnDimension {

    // Main loop.
    for (var k = 0; k < _cols; k++) {

      // Compute 2-norm of k-th column
      var nrm = 0;

      for (var i = k; i < _rows; i++) {
        nrm = sqrt(pow(nrm, 2) + pow(_QR[i * _cols + k], 2));
      }

      if (nrm != 0) {

        // Form k-th Householder vector.
        if (_QR[k * _cols + k] < 0) {
          nrm = -nrm;
        }

        for (var i = k; i < _rows; i++) {
          _QR[i * _cols + k] /= nrm;
        }

        _QR[k * _cols + k] += 1.0;

        // Apply transformation to remaining columns.
        for (var j = k + 1; j < _cols; j++) {
          var s = 0;

          for (var i = k; i < _rows; i++) {
            s += _QR[i * _cols + k] * _QR[i * _cols + j];
          }

          s = -s / _QR[k * _cols + k];

          for (var i = k; i < _rows; i++) {
            _QR[i * _cols + j] += s * _QR[i * _cols + k];
          }
        }
      }

      _Rdiag.add(-nrm);
    }
  }

  bool get isFullRank {
    for (var j = 0; j < _cols; j++) {
      if (_Rdiag[j] == 0) {
        return false;
      }
    }

    return true;
  }

  GenericMatrix get householderMatrix {
    if(_householderMatrix != null) return _householderMatrix;

    var values = new List();

    for (var i = 0; i < _rows; i++) {
      for (var j = 0; j < _cols; j++) {
        if (i >= j) {
          values.add(_QR[i * _cols + j]);
        } else {
          values.add(0);
        }
      }
    }

    _householderMatrix = new Matrix(values, _cols);

    return _householderMatrix;
  }

  GenericMatrix get upperTriangularFactor {
    if(_upperTriangularFactor != null) return _upperTriangularFactor;

    var values = new List();

    for (var i = 0; i < _cols; i++) {
      for (var j = 0; j < _cols; j++) {
        if (i < j) {
          values.add(_QR[i * _cols + j]);
        } else if (i == j) {
          values.add(_Rdiag[i]);
        } else {
          values.add(0);
        }
      }
    }

    _upperTriangularFactor = new Matrix(values, _cols);

    return _upperTriangularFactor;
  }

  GenericMatrix get orthogonalFactor {
    if(_orthogonalFactor != null) return _orthogonalFactor;

    var values = new List.filled(_rows * _cols, 0);

    for (var k = _cols - 1; k >= 0; k--) {
      for (var i = 0; i < _rows; i++) {
        values[i * _cols + k] = 0;
      }

      if (k < _rows) {
        values[k * _cols + k] = 1;
      }

      for (var j = k; j < _cols; j++) {
        if (k < _rows && _QR[k * _cols + k] != 0) {
          var s = 0;

          for (var i = k; i < _rows; i++) {
            s += _QR[i * _cols + k] * values[i * _cols + j];
          }

          s = -s / _QR[k * _cols + k];

          for (var i = k; i < _rows; i++) {
            values[i * _cols + j] += s * _QR[i * _cols + k];
          }
        }
      }
    }

    _orthogonalFactor = new Matrix(values, _cols);

    return _orthogonalFactor;
  }

  GenericMatrix solve(GenericMatrix B) {
    if (B.rowDimension != _rows) {
      throw new ArgumentError('Matrix row dimensions must agree.');
    }

    if (!isFullRank) {
      throw new UnsupportedError('Matrix is rank deficient.');
    }

    // Copy right hand side
    var xCols = B.columnDimension;
    var xVals = new List.from(B.values);

    // Compute Y = transpose(Q)*B
    for (var k = 0; k < _cols; k++) {
      for (var j = 0; j < xCols; j++) {
        var s = 0;

        for (var i = k; i < _rows; i++) {
          s += _QR[i * _cols + k] * xVals[i * _cols + j];
        }

        s = -s / _QR[k * _cols + k];

        for (var i = k; i < _rows; i++) {
          xVals[i * _cols + j] += s * _QR[i * _cols + k];
        }
      }
    }

    // Solve R*X = Y;
    for (var k = _cols - 1; k >= 0; k--) {
      for (var j = 0; j < xCols; j++) {
        xVals[k * _cols + j] /= _Rdiag[k];
      }

      for (var i = 0; i < k; i++) {
        for (var j = 0; j < xCols; j++) {
          xVals[i * _cols + j] -= xVals[k* _cols + j] * _QR[i * _cols + k];
        }
      }
    }

    return (new Matrix(xVals, xCols).subMatrix(0, _cols - 1, 0, xCols - 1));
  }
}