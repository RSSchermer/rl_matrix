part of rl_matrix;

/// Matrix data structure.
///
/// This implements an immutable matrix data structure, meaning that all
/// operations will return a new [Matrix] instance, rather than update the
/// current [Matrix] instance.
class Matrix {
  /// This [Matrix]'s column dimension (number of columns).
  final int columnDimension;

  /// The values in this [Matrix], row-packed.
  ///
  /// The values that make up this matrix in row-packed format, meaning that
  /// for a [Matrix] with a column dimension of 5, the first 5 values make up
  /// the first row, the second 5 values make up the second row, etc.
  final Float32List _values;

  /// Memoized column packed values.
  UnmodifiableListView<double> _valuesColumnPacked;

  /// Memoized LU-decomposition.
  PivotingLUDecomposition _luDecompostion;

  /// Memoized QR-decomposition.
  ReducedQRDecomposition _qrDecomposition;

  /// Memoized inverse matrix.
  Matrix _inverse;

  /// Creates a [Matrix] from the given [rowLists].
  ///
  /// The [rowList] is a list of lists, where each list contains the values for
  /// a single row. The [Matrix]'s row dimension will be the number of row
  /// value lists. The [Matrix]'s column dimension will be the length of the
  /// lists of row values.
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     1.0 2.0 3.0
  ///     //     4.0 5.0 6.0
  ///     //
  ///     var matrix = new Matrix([
  ///       [1.0, 2.0, 3.0],
  ///       [4.0, 5.0, 6.0]
  ///     ]);
  ///
  /// Throws an [ArgumentError] if the length of each row value list is not
  /// equal.
  ///
  /// Throws an [ArgumentError] if the length of [rowLists] is `0`.
  factory Matrix(List<List<double>> rowLists) {
    if (rowLists.length == 0) {
      throw new ArgumentError('At least one rowList must be supplied, the '
          'length of rowLists must not be 0.');
    }

    final columnDimension = rowLists.first.length;
    final rowDimension = rowLists.length;
    final values = new Float32List(columnDimension * rowDimension);

    for (var i = 0; i < rowDimension; i++) {
      final row = rowLists[i];
      final m = i * columnDimension;

      if (row.length != columnDimension) {
        throw new ArgumentError('The length of row $i (${row.length}) does not '
            'match the length of the prior row(s) ($columnDimension). All rows '
            'must be of equal length.');
      }

      for (var j = 0; j < columnDimension; j++) {
        values[m + j] = row[j];
      }
    }

    return new Matrix._internal(values, columnDimension);
  }

  /// Creates a [Matrix] from the in the given [list], with the specified
  /// [columnDimension].
  ///
  /// The [rowDimension] will be inferred from the [list]'s length. The [list]'s
  /// length must be a multiple of the [columnDimension].
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     1.0 2.0 3.0
  ///     //     4.0 5.0 6.0
  ///     //
  ///     var matrix = new Matrix.fromList([
  ///       1.0, 2.0, 3.0,
  ///       4.0, 5.0, 6.0
  ///     ], 3);
  ///
  /// Throws [ArgumentError] if the [list]'s length is not a multiple of the
  /// [columnDimension].
  Matrix.fromList(List<double> list, this.columnDimension)
      : _values = new Float32List.fromList(list) {
    if (list.length.remainder(columnDimension) != 0) {
      throw new ArgumentError(
          'The length of the given list (${list.length}) must be a multiple '
          'of the specified columnDimension (${columnDimension}).');
    }
  }

  /// Creates a constant matrix of the given [value] with the specified
  /// [rowDimension] and [columnDimension].
  ///
  /// Creates a new [Matrix] where every position is set to [value].
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     1.0 1.0 1.0 1.0
  ///     //     1.0 1.0 1.0 1.0
  ///     //     1.0 1.0 1.0 1.0
  ///     //
  ///     var matrix = new Matrix.constant(1.0, 3, 4);
  ///
  Matrix.constant(double value, int rowDimension, int columnDimension)
      : columnDimension = columnDimension,
        _values = new Float32List(rowDimension * columnDimension)
          ..fillRange(0, rowDimension * columnDimension, value);

  /// Creates a zero matrix with the specified [rowDimension] and
  /// [columnDimension].
  ///
  /// Creates a new [Matrix] where every position is set to `0.0`.
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     0.0 0.0 0.0 0.0
  ///     //     0.0 0.0 0.0 0.0
  ///     //     0.0 0.0 0.0 0.0
  ///     //
  ///     var matrix = new Matrix.zero(3, 4);
  ///
  Matrix.zero(int rowDimension, int columnDimension)
      : columnDimension = columnDimension,
        _values = new Float32List(rowDimension * columnDimension);

  /// Creates an identity matrix of the given [size].
  ///
  /// Creates a square identity matrix (ones on the diagonal, zeros elsewhere)
  /// of the specified [size].
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     1.0 0.0 0.0 0.0
  ///     //     0.0 1.0 0.0 0.0
  ///     //     0.0 0.0 1.0 0.0
  ///     //     0.0 0.0 0.0 1.0
  ///     //
  ///     var matrix = new Matrix.identity(4);
  ///
  Matrix.identity(int size)
      : columnDimension = size,
        _values = _identityValues(size);

  Matrix._internal(this._values, this.columnDimension);

  /// The transpose of this [Matrix].
  Matrix get transpose => new Matrix._internal(
      new Float32List.fromList(valuesColumnPacked), rowDimension);

  /// The row dimension of this [Matrix] (number of rows).
  int get rowDimension => _values.length ~/ columnDimension;

  /// Returns whether or not this [Matrix] is square ([rowDimension] is equal to
  /// [columnDimension]).
  bool get isSquare => rowDimension == columnDimension;

  /// Returns the value at the given coordinates.
  ///
  /// Returns the values at the given coordinates, where the [row] coordinate
  /// identifies the row and the [column] coordinate identifies the column. Row
  /// and column indices start at 0, so (0, 0) identifies the top left value in
  /// the matrix.
  double valueAt(int row, int column) =>
      _values[row * columnDimension + column];

  /// Returns the values in this matrix in column-packed order.
  ///
  /// The values that make up this matrix in column-packed format, meaning that
  /// for a [Matrix] with a [rowDimension] of 5, the first 5 values will
  /// correspond to the first column, the second 5 values will correspond to the
  /// second column, etc.
  Iterable<double> get valuesColumnPacked {
    if (_valuesColumnPacked != null) {
      return _valuesColumnPacked;
    }

    final rows = rowDimension;
    final values = new Float32List(_values.length);

    for (var column = 0; column < columnDimension; column++) {
      final m = column * rows;

      for (var row = 0; row < rowDimension; row++) {
        values[m + row] = _values[row * columnDimension + column];
      }
    }

    _valuesColumnPacked = new UnmodifiableListView(values);

    return _valuesColumnPacked;
  }

  /// Returns the values in this matrix in row-packed order.
  ///
  /// The values that make up this matrix in row-packed format, meaning that
  /// for a [Matrix] with a [columnDimension] of 5, the first 5 values will
  /// correspond to the first row, the second 5 values will correspond to the
  /// second row, etc.
  Iterable<double> get valuesRowPacked => new UnmodifiableListView(_values);

  /// Alias for [valuesRowPacked].
  Iterable<double> get values => new UnmodifiableListView(_values);

  /// Returns a new sub-matrix.
  ///
  /// Takes 4 arguments: the starting row's index ([rowStart]), the ending
  /// row's index ([rowEnd]), the starting column's index ([colStart]) and the
  /// ending column's index ([colEnd]). Indices start at zero. The resulting
  /// sub-matrix will be the sub-section of the matrix delineated by these
  /// indices. The [rowStart] and [colStart] indices are inclusive. The [rowEnd]
  /// and [colEnd] indices are exclusive.
  ///
  /// Example:
  ///
  ///     // Given this matrix:
  ///     //
  ///     //    0.0 1.0 2.0 3.0
  ///     //    0.1 1.1 2.1 3.1
  ///     //    0.2 1.2 2.2 3.2
  ///     //    0.3 1.3 2.3 3.3
  ///     //
  ///
  ///     matrix.subMatrix(1, 3, 1, 3)
  ///
  ///     // Results in:
  ///     //
  ///     //    1.1 2.1
  ///     //    1.2 2.2
  ///     //
  ///
  /// Throws an [ArgumentError] if the [rowEnd] index is not greater than the
  /// [rowStart] index.
  ///
  /// Throws an [ArgumentError] if the [colEnd] index is not greater than the
  /// [colStart] index.
  Matrix subMatrix(int rowStart, int rowEnd, int colStart, int colEnd) {
    if (rowEnd <= rowStart) {
      throw new ArgumentError(
          'The rowEnd index must be greater than the rowStart index.');
    }

    if (colEnd <= colStart) {
      throw new ArgumentError(
          'The colEnd index must be greater than the colStart index.');
    }

    final rows = (rowEnd - rowStart);
    final cols = (colEnd - colStart);
    final subMatrixVals = new Float32List(rows * cols);

    for (var i = rowStart; i < rowEnd; i++) {
      final m = (i - rowStart) * cols;

      for (var j = colStart; j < colEnd; j++) {
        subMatrixVals[m + j - colStart] = valueAt(i, j);
      }
    }

    return new Matrix._internal(subMatrixVals, cols);
  }

  /// Returns a list containing the values in the row at the [index].
  ///
  /// Rows are zero-indexed, meaning 0 will return the first row.
  ///
  /// Throws a [RangeError] if the [index] is out of bounds (`index < 0` or
  /// `index >= rowDimension`).
  List<double> rowAt(int index) {
    if (index >= rowDimension) {
      throw new RangeError.range(index, 0, rowDimension);
    }

    return _values.sublist(
        index * columnDimension, (index + 1) * columnDimension);
  }

  /// Computes the entrywise sum matrix of this [Matrix] and another [Matrix].
  ///
  /// Computes the entrywise sum matrix `C` of this matrix `A` with another
  /// matrix [B]: `A + B = C`, where each value `C_ij` at coordinates (i, j) in
  /// matrix `C`, is equal to `A_ij + B_ij`.
  ///
  /// Throws an [ArgumentError] if the matrix dimensions don't match.
  Matrix entrywiseSum(Matrix B) {
    _assertEqualDimensions(B);

    final length = _values.length;
    final summedValues = new Float32List(length);

    for (var i = 0; i < length; i++) {
      summedValues[i] = _values[i] + B._values[i];
    }

    return new Matrix._internal(summedValues, columnDimension);
  }

  /// Computes the entrywise difference matrix of this [Matrix] and another
  /// [Matrix].
  ///
  /// Computes the entrywise difference matrix `C` of this matrix `A` with
  /// another matrix [B]: `A - B = C`, where each value `C_ij` at coordinates
  /// (i, j) in matrix `C`, is equal to `A_ij - B_ij`.
  ///
  /// Throws an [ArgumentError] if the matrix dimensions don't match.
  Matrix entrywiseDifference(Matrix B) {
    _assertEqualDimensions(B);

    final length = _values.length;
    final differenceValues = new Float32List(length);

    for (var i = 0; i < length; i++) {
      differenceValues[i] = _values[i] - B._values[i];
    }

    return new Matrix._internal(differenceValues, columnDimension);
  }

  /// Computes the entrywise product of this [Matrix] and another [Matrix].
  ///
  /// Computes the entrywise (Hadamard) product `C` of this matrix `A` with
  /// another matrix [B]. Each value `C_ij` at coordinates (i, j) in matrix `C`,
  /// is equal to `A_ij * B_ij`.
  ///
  /// Throws an [ArgumentError] if the matrix dimensions don't match.
  Matrix entrywiseProduct(Matrix B) {
    _assertEqualDimensions(B);

    final length = _values.length;
    final productValues = new Float32List(length);

    for (var i = 0; i < length; i++) {
      productValues[i] = _values[i] * B._values[i];
    }

    return new Matrix._internal(productValues, columnDimension);
  }

  /// Multiply this matrix with a scalar value.
  ///
  /// Computes a new matrix `B` of this matrix `A` multiplied with a scalar `s`:
  /// `A * s = B`, where each value `B_ij` at coordinates (i, j) in matrix `B`,
  /// is equal to `A_ij * s`.
  Matrix scalarProduct(num s) {
    final length = _values.length;
    final multipliedValues = new Float32List(length);

    for (var i = 0; i < length; i++) {
      multipliedValues[i] = _values[i] * s;
    }

    return new Matrix._internal(multipliedValues, columnDimension);
  }

  /// Divide this [Matrix] by a scalar value.
  ///
  /// Computes a new matrix `B` of this matrix `A` divided by a scalar s:
  /// `A / s = B`, where each value `B_ij` at coordinates (i, j) in matrix `B`,
  /// is equal to `A_ij / s`.
  Matrix scalarDivision(num s) {
    final length = _values.length;
    final multipliedValues = new Float32List(length);

    for (var i = 0; i < length; i++) {
      multipliedValues[i] = _values[i] / s;
    }

    return new Matrix._internal(multipliedValues, columnDimension);
  }

  /// Computes the matrix product of this [Matrix] with another [Matrix].
  ///
  /// Computes the product matrix `C`, the matrix product of the matrix `A` with
  /// another matrix `B`: `AB = C`. The column dimension of `A` must match the
  /// row dimension of `B`.
  ///
  /// Throws an [ArgumentError] if matrix `A`'s [columnDimension] does not equal
  /// matrix `B`'s [rowDimension].
  Matrix matrixProduct(Matrix B) {
    if (columnDimension != B.rowDimension) {
      throw new ArgumentError('Matrix inner dimensions must agree.');
    }

    final rows = rowDimension;
    final bCols = B.columnDimension;
    final productValues = new Float32List(rows * bCols);
    var counter = 0;

    for (var row = 0; row < rows; row++) {
      final m = row * columnDimension;

      for (var col = 0; col < bCols; col++) {
        var sum = 0.0;

        for (var j = 0; j < columnDimension; j++) {
          sum += _values[m + j] * B._values[j * bCols + col];
        }

        productValues[counter] = sum;
        counter++;
      }
    }

    return new Matrix._internal(productValues, B.columnDimension);
  }

  /// The LU-decomposition for this [Matrix] (with partial pivoting).
  PivotingLUDecomposition get luDecomposition {
    if (_luDecompostion != null) {
      return _luDecompostion;
    }

    _luDecompostion = new PivotingLUDecomposition(this);

    return _luDecompostion;
  }

  /// The QR-decomposition for this [Matrix].
  ReducedQRDecomposition get qrDecomposition {
    if (_qrDecomposition != null) {
      return _qrDecomposition;
    }

    _qrDecomposition = new ReducedQRDecomposition(this);

    return _qrDecomposition;
  }

  /// Whether or not this [Matrix] is non-singular (invertible).
  bool get isNonSingular {
    if (isSquare) {
      return luDecomposition.isNonsingular;
    } else {
      return false;
    }
  }

  /// This [Matrix]'s determinant.
  ///
  /// Throws an [UnsupportedError] if the matrix is not square.
  double get determinant => luDecomposition.determinant;

  /// Solves `AX = B` for X, where `A` is this [Matrix] and [B] the given
  /// [Matrix].
  ///
  /// Returns the solution if `A` is square, or the least squares solution
  /// otherwise.
  ///
  /// Throws an [ArgumentError] if the row dimensions of `A` and [B] do not
  /// match.
  ///
  /// Throws an [UnsupportedError] if `A` is square and singular.
  ///
  /// Throws an [UnsupportedError] if `A` has more columns than rows.
  Matrix solve(Matrix B) {
    if (columnDimension > rowDimension) {
      throw new UnsupportedError('Matrix has more columns than rows.');
    }

    if (isSquare) {
      return luDecomposition.solve(B);
    } else {
      return qrDecomposition.solve(B);
    }
  }

  /// Solves `XA = B` for X, where `A` is this [Matrix] and [B] the given
  /// [Matrix].
  ///
  /// Solves `X * A = B` for X using `A' * X' = B'`. Returns the solution if `A`
  /// is square, or the least squares solution otherwise.
  ///
  /// Throws an [ArgumentError] if the column dimensions of `A` and [B] do not
  /// match.
  ///
  /// Throws an [UnsupportedError] if `A` is square and singular.
  ///
  /// Throws an [UnsupportedError] if `A` has more rows than columns.
  Matrix solveTranspose(Matrix B) {
    if (rowDimension > columnDimension) {
      throw new UnsupportedError('Matrix has more rows than columns.');
    }

    return transpose.solve(B.transpose).transpose;
  }

  /// This matrix's inverse.
  ///
  /// Throws an [UnsupportedError] if the matrix is not square.
  ///
  /// Throws an [UnsupportedError] if the matrix is singular (not invertible).
  Matrix get inverse {
    if (_inverse != null) {
      return _inverse;
    }

    final values =
        luDecomposition.solve(new Matrix.identity(rowDimension)).values;

    _inverse =
        new Matrix._internal(new Float32List.fromList(values), rowDimension);

    return _inverse;
  }

  /// Computes the entrywise sum matrix of this [Matrix] and another [Matrix].
  ///
  /// Computes the entrywise sum matrix `C` of this matrix `A` with another
  /// matrix [B]: `A + B = C`, where each value `C_ij` at coordinates (i, j) in
  /// matrix `C`, is equal to `A_ij + B_ij`.
  ///
  /// Throws an [ArgumentError] if the matrix dimensions don't match.
  Matrix operator +(Matrix B) => entrywiseSum(B);

  /// Computes the entrywise difference matrix of this [Matrix] and another
  /// [Matrix].
  ///
  /// Computes the entrywise difference matrix `C` of this matrix `A` with
  /// another matrix [B]: `A - B = C`, where each value `C_ij` at coordinates
  /// (i, j) in matrix `C`, is equal to `A_ij - B_ij`.
  ///
  /// Throws an [ArgumentError] if the matrix dimensions don't match.
  Matrix operator -(Matrix B) => entrywiseDifference(B);

  /// Returns the scalar product for numerical values and the matrix product
  /// for [Matrix] values.
  operator *(a) {
    if (a is num) {
      return scalarProduct(a);
    } else if (a is Matrix) {
      return matrixProduct(a);
    } else {
      throw new ArgumentError('Expected num or Matrix.');
    }
  }

  /// Returns whether this [Matrix] is equal to another [Matrix].
  ///
  /// Two matrices are equal if they have equal dimensions and equal values.
  /// Does not check if the types of the matrices are equal.
  bool operator ==(Matrix matrix) =>
      identical(this, matrix) ||
      columnDimension == matrix.columnDimension &&
          _iterableEquals(values, matrix.values);

  int get hashCode =>
      hash3(columnDimension, rowDimension, hashObjects(_values));

  _assertEqualDimensions(Matrix m) {
    if (m.columnDimension != columnDimension ||
        m.rowDimension != rowDimension) {
      throw new ArgumentError(
          'The dimenions of the matrices must match (the row dimenions must be '
          'equal and the column dimenions must be equal).');
    }
  }
}

_identityValues(int size) {
  final values = new Float32List(size * size);
  var counter = 0;

  for (var i = 0; i < size; i++) {
    for (var j = 0; j < size; j++) {
      if (i == j) {
        values[counter] = 1.0;
      } else {
        values[counter] = 0.0;
      }

      counter++;
    }
  }

  return values;
}

Function _iterableEquals = const ListEquality().equals;
