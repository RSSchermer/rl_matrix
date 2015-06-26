part of matrix;

class LUDecomposition<M extends GenericMatrix> {
  final M matrix;

  List<num> _LU;

  num _pivotSign = 1;

  List<num> _piv;

  num _rows;
  num _cols;

  M _lowerFactor;
  M _upperFactor;

  num _determinant;

  LUDecomposition(M matrix)
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

  /*
  LUDecomposition(M matrix)
      : matrix = matrix,
        _LU = matrix.values.toList(),
        _rows = matrix.rowDimension,
        _cols = matrix.columnDimension,
        _piv = new List.generate(matrix.rowDimension, (i) => i) {

    // Outer loop.
    for (var j = 0; j < _cols; j++) {

      // Apply previous transformations.
      for (var i = 0; i < _rows; i++) {
        var kmax = min(i, j);
        var s = 0;

        // Most of the time is spent in the following dot product.
        for (var k = 0; k < kmax; k++) {
          s += _LU[i * _cols + k] * _LU[k * _cols + j];
        }

        _LU[i * _cols + j] -= s;
      }

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
        }
      }
    }
  }
  */

  bool get isNonsingular {
    for (var j = 0; j < _cols; j++) {
      if (_LU[j * _cols + j] == 0)
        return false;
    }

    return true;
  }

  M get lowerFactor {
    if (_lowerFactor != null) return _lowerFactor;

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

    _lowerFactor = matrix.copy(values);

    return _lowerFactor;
  }

  M get upperFactor {
    if (_upperFactor != null) return _upperFactor;

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

    _upperFactor = matrix.copy(values);

    return _upperFactor;
  }

  Matrix get pivot => new Matrix(_piv, 1);

  num get determinant {
    if (_determinant != null) return _determinant;
    if (_rows != _cols) throw new UnsupportedError("Matrix must be square.");

    _determinant = _pivotSign;

    for (int j = 0; j < _cols; j++) {
      _determinant *= _LU[j * _cols + j];
    }

    return _determinant;
  }

  GenericMatrix solve (GenericMatrix B) {
    if (B.rowDimension != _m) {
      throw new ArgumentError("Matrix row dimensions must agree.");
    }

    if (!isNonsingular) {
      throw new UnsupportedError("Matrix is singular.");
    }

    // Copy right hand side with pivoting
    var vals = B.values.toList();
    var nx = B.columnDimension;
    var X = new List();

    _piv.forEach((row) {
      for (var i = 0; i < nx; i++) {
        X.add(vals[row * nx + i]);
      }
    });

    // Solve L*Y = B(piv,:)
    for (var k = 0; k < _n; k++) {
      for (var i = k + 1; i < _n; i++) {
        for (var j = 0; j < nx; j++) {
          X[i * nx + j] -= X[k * nx + j] * _LU[i * _m + k];
        }
      }
    }

    // Solve U*X = Y;
    for (var k = _n - 1; k >= 0; k--) {
      for (var j = 0; j < nx; j++) {
        X[k * nx + j] /= _LU[k * _m + k];
      }

      for (var i = 0; i < k; i++) {
        for (var j = 0; j < nx; j++) {
          X[i * nx + j] -= X[k * nx + j] * _LU[i * _m + k];
        }
      }
    }

    return new Matrix(X, nx);
  }
}
