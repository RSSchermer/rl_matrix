part of rl_matrix;

/// Generic superclass for matrices and vectors.
///
/// This implements an immutable matrix data structure, meaning that all
/// operations will return a new matrix instance, rather than update the current
/// matrix instance.
///
/// This abstract base class exists to facilitate easy definition of matrix
/// types with specific matrix dimensions (e.g. Vec3, Mat4, etc.). Such subtypes
/// can override operations with more efficient dimension-specific algorithms.
///
/// This class takes 2 type parameters: the extending class' type (a self-bound)
/// and the extending class' transpose type. Also, two abstract methods will
/// need to be defined:
///
/// - `withValues`: needs to return a new matrix of the same type and with the
///   same dimensions, with the given values.
/// - `transposeWithValues`: needs to return a new matrix of the matrix's
///   transpose type, with transposed dimensions, with the given values.
///
/// The following example implements a column vector:
///
///     class ColumnVector extends GenericMatrix<ColumnVector, RowVector> {
///       ColumnVector(List<double> values) : super.fromList(values, 1);
///
///       ColumnVector.fromFloat32List(Float32List values)
///           : super.fromFloat32List(values, 1);
///
///       ColumnVector withValues(Float32List newValues) =>
///         new ColumnVector.fromFloat32List(newValues);
///
///       RowVector transposeWithValues(Float32List newValues) =>
///         new RowVector.fromFloat32List(newValues);
///     }
///
abstract class GenericMatrix<Self extends GenericMatrix<Self, Transpose>,
    Transpose extends GenericMatrix> {
  /// This matrix's column dimension (number of columns)
  final int columnDimension;

  /// The values in this matrix, row-packed.
  ///
  /// The values that make up this matrix in row-packed format, meaning that
  /// for a matrix with a column dimension of 5, the first 5 values make up
  /// the first row, the second 5 values make up the second row, etc.
  final Float32List _values;

  /// Memoized column packed values.
  UnmodifiableListView<double> _valuesColumnPacked;

  /// Memoized LU-decomposition.
  PivotingLUDecomposition _luDecompostion;

  /// Memoized QR-decomposition.
  ReducedQRDecomposition _qrDecomposition;

  /// Memoized inverse matrix.
  Transpose _inverse;

  /// Creates a matrix from the in the given [list], with the specified
  /// [columnDimension].
  ///
  /// The row dimension will be inferred from the list's length. The list's
  /// length must be a multiple of the [columnDimension].
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     1.0 2.0 3.0
  ///     //     4.0 5.0 6.0
  ///     //
  ///     var matrix = new Matrix.fromList([1.0, 2.0, 3.0,
  ///                                       4.0, 5.0, 6.0], 3);
  ///
  /// Throws [ArgumentError] if the list's length is not a multiple of the
  /// [columnDimension].
  GenericMatrix.fromList(List<double> list, this.columnDimension)
      : _values = new Float32List.fromList(list) {
    if (list.length % columnDimension != 0) {
      throw new ArgumentError(
          'The length of the given list (${list.length}) must be a multiple '
          'of the specified columnDimension (${columnDimension}).');
    }
  }

  /// Creates a matrix from the given [Float32List], with the specified
  /// [columnDimension].
  ///
  /// The row dimension will be inferred from the list's length. The list's
  /// length must be a multiple of the [columnDimension].
  ///
  /// Throws [ArgumentError] if the value list's length is not a multiple of the
  /// column dimension.
  GenericMatrix.fromFloat32List(Float32List values, this.columnDimension)
      : _values = values {
    if (values.length % columnDimension != 0) {
      throw new ArgumentError(
          'The length of the given values list (${values.length}) must be a '
          'multiple of the specified columnDimension (${columnDimension}).');
    }
  }

  /// Creates a constant matrix of the given [value] with the specified
  /// [rowDimension] and [columnDimension].
  ///
  /// Creates a new matrix where every position is set to the given [value].
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     1.0 1.0 1.0
  ///     //     1.0 1.0 1.0
  ///     //     1.0 1.0 1.0
  ///     //
  ///     var matrix = new Matrix.constant(1.0, 3, 3)
  ///
  GenericMatrix.constant(double value, int rowDimension, int columnDimension)
      : columnDimension = columnDimension,
        _values = new Float32List(rowDimension * columnDimension)
          ..fillRange(0, rowDimension * columnDimension, value);

  /// Creates a matrix of only zeros with the specified [rowDimension] and
  /// [columnDimension].
  ///
  /// Creates a new matrix where every position is set to `0.0`.
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     0.0 0.0 0.0 0.0
  ///     //     0.0 0.0 0.0 0.0
  ///     //     0.0 0.0 0.0 0.0
  ///     //
  ///     var matrix = new Matrix.zero(3, 4)
  ///
  GenericMatrix.zero(int rowDimension, int columnDimension)
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
  ///     var matrix = new Matrix.identity(4)
  ///
  GenericMatrix.identity(int size)
      : columnDimension = size,
        _values = _identityValues(size);

  /// Creates a new instance of equal dimensions, with the given [values].
  ///
  /// Returns a new matrix instance with the same number of rows and columns as
  /// this current matrix, but with different values.
  ///
  /// The values are used in row-packed order, meaning that the first 5 values
  /// will fill the first row, the second 5 values will fill the second row,
  /// etc.
  Self withValues(Float32List values);

  /// Creates a new instance of this matrix's transpose type of transposed
  /// dimensions, with the given [values].
  ///
  /// Returns a new instance of the matrix's transpose type with a column
  /// dimension equal to this current matrix's row dimension, and a row
  /// dimension equal to this current matrix's column dimension. The new
  /// instance will be filled with the given [values].
  ///
  /// The values are used in row-packed order, meaning that the first 5 values
  /// will fill the first row, the second 5 values will fill the second row,
  /// etc.
  Transpose transposeWithValues(Float32List values);

  /// The transpose of the matrix.
  Transpose get transpose =>
      transposeWithValues(new Float32List.fromList(valuesColumnPacked));

  /// The row dimension of this matrix (number of rows).
  int get rowDimension => _values.length ~/ columnDimension;

  /// Returns whether or not the matrix is square ([rowDimension] is equal to
  /// [columnDimension]).
  bool get isSquare => rowDimension == columnDimension;

  /// Returns the value at the given coordinates.
  ///
  /// Returns the values at the given coordinates, where the first coordinate
  /// identifies the row and the second coordinate identifies the column. Row
  /// and column indices start at 0, so (0, 0) identifies the top left value in
  /// the matrix.
  double valueAt(int row, int column) =>
      _values[row * columnDimension + column];

  /// Returns the values in this matrix, column-packed.
  ///
  /// The values that make up this matrix in column-packed format, meaning that
  /// for a matrix with a [rowDimension] of 5, the first 5 values will
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

  /// Returns the values in this matrix, row-packed.
  ///
  /// The values that make up this matrix in row-packed format, meaning that
  /// for a matrix with a [columnDimension] of 5, the first 5 values will
  /// correspond to the first row, the second 5 values will correspond to the
  /// second row, etc.
  Iterable<double> get valuesRowPacked => new UnmodifiableListView(_values);

  /// Alias for `valuesRowPacked`
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
  /// Throws an [ArgumentError] if the [rowEnd] index is not greater than the
  /// [rowStart] index.
  ///
  /// Throws an [ArgumentError] if the [colEnd] index is not greater than the
  /// [colStart] index.
  GenericMatrix subMatrix(int rowStart, int rowEnd, int colStart, int colEnd) {
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
      for (var j = colStart; j < colEnd; j++) {
        subMatrixVals[(i - rowStart) * cols + (j - colStart)] = valueAt(i, j);
      }
    }

    return new Matrix(subMatrixVals, cols);
  }

  /// Returns a list containing the values in the row at the given [index].
  ///
  /// Rows are zero-indexed, meaning 0 will return the first row.
  ///
  /// Throws a [RangeError] if the [index] is out of bounds (smaller than 0 or
  /// greater than the [rowDimension] of the matrix).
  List<double> rowAt(int index) {
    if (index >= rowDimension) {
      throw new RangeError.range(index, 0, rowDimension);
    }

    return _values.sublist(
        index * columnDimension, (index + 1) * columnDimension);
  }

  /// Computes the entrywise sum matrix of this matrix and another matrix.
  ///
  /// Computes the entrywise sum matrix `C` of this matrix `A` with another
  /// matrix [B]: `A + B = C`, where each value `C_ij` at coordinates (i, j) in
  /// matrix `C`, is equal to `A_ij + B_ij`.
  ///
  /// Throws an [ArgumentError] if the matrix dimensions don't match.
  Self entrywiseSum(GenericMatrix B) {
    _assertEqualDimensions(B);

    final length = _values.length;
    final summedValues = new Float32List(length);

    for (var i = 0; i < length; i++) {
      summedValues[i] = _values[i] + B._values[i];
    }

    return withValues(summedValues);
  }

  /// Computes the entrywise difference matrix of this matrix and another
  /// matrix.
  ///
  /// Computes the entrywise difference matrix `C` of this matrix `A` with
  /// another matrix [B]: `A - B = C`, where each value `C_ij` at coordinates
  /// (i, j) in matrix `C`, is equal to `A_ij - B_ij`.
  ///
  /// Throws an [ArgumentError] if the matrix dimensions don't match.
  Self entrywiseDifference(GenericMatrix B) {
    _assertEqualDimensions(B);

    final length = _values.length;
    final differenceValues = new Float32List(length);

    for (var i = 0; i < length; i++) {
      differenceValues[i] = _values[i] - B._values[i];
    }

    return withValues(differenceValues);
  }

  /// Computes the entrywise product of this matrix and another matrix.
  ///
  /// Computes the entrywise (Hadamard) product `C` of this matrix `A` with
  /// another matrix [B]. Each value `C_ij` at coordinates (i, j) in matrix `C`,
  /// is equal to `A_ij * B_ij`.
  ///
  /// Throws an [ArgumentError] if the matrix dimensions don't match.
  Self entrywiseProduct(GenericMatrix B) {
    _assertEqualDimensions(B);

    final length = _values.length;
    final productValues = new Float32List(length);

    for (var i = 0; i < length; i++) {
      productValues[i] = _values[i] * B._values[i];
    }

    return withValues(productValues);
  }

  /// Multiply this matrix with a scalar value.
  ///
  /// Computes a new matrix `B` of this matrix `A` multiplied with a scalar `s`:
  /// `A * s = B`, where each value `B_ij` at coordinates (i, j) in matrix `B`,
  /// is equal to `A_ij * s`.
  Self scalarProduct(num s) {
    final length = _values.length;
    final multipliedValues = new Float32List(length);

    for (var i = 0; i < length; i++) {
      multipliedValues[i] = _values[i] * s;
    }

    return withValues(multipliedValues);
  }

  /// Divide this matrix by a scalar value.
  ///
  /// Computes a new matrix `B` of this matrix `A` divided by a scalar s:
  /// `A / s = B`, where each value `B_ij` at coordinates (i, j) in matrix `B`,
  /// is equal to `A_ij / s`.
  Self scalarDivision(num s) {
    final length = _values.length;
    final multipliedValues = new Float32List(length);

    for (var i = 0; i < length; i++) {
      multipliedValues[i] = _values[i] / s;
    }

    return withValues(multipliedValues);
  }

  /// Computes the matrix product of this matrix with another matrix.
  ///
  /// Computes the product matrix `C`, the matrix product of the matrix `A` with
  /// another matrix `B`: `AB = C`. The column dimension of `A` must match the
  /// row dimension of `B`.
  ///
  /// Throws an [ArgumentError] if matrix `A`'s [columnDimension] does not equal
  /// matrix `B`'s [rowDimension].
  GenericMatrix matrixProduct(GenericMatrix B) {
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

    return new Matrix(productValues, B.columnDimension);
  }

  /// The LU-decomposition for this matrix (with partial pivoting).
  PivotingLUDecomposition get luDecomposition {
    if (_luDecompostion != null) {
      return _luDecompostion;
    }

    _luDecompostion = new PivotingLUDecomposition(this);

    return _luDecompostion;
  }

  /// The QR-decomposition for this matrix.
  ReducedQRDecomposition get qrDecomposition {
    if (_qrDecomposition != null) {
      return _qrDecomposition;
    }

    _qrDecomposition = new ReducedQRDecomposition(this);

    return _qrDecomposition;
  }

  /// Whether or not this matrix is non-singular (invertible).
  bool get isNonSingular {
    if (isSquare) {
      return luDecomposition.isNonsingular;
    } else {
      return false;
    }
  }

  /// This matrix's determinant.
  ///
  /// Throws an [UnsupportedError] if the matrix is not square.
  double get determinant => luDecomposition.determinant;

  /// Solves `AX = B` for X, where `A` is this matrix and [B] the given matrix.
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
  GenericMatrix solve(GenericMatrix B) {
    if (columnDimension > rowDimension) {
      throw new UnsupportedError('Matrix has more columns than rows.');
    }

    if (isSquare) {
      return luDecomposition.solve(B);
    } else {
      return qrDecomposition.solve(B);
    }
  }

  /// Solves `XA = B` for X, where `A` is this matrix and [B] the given matrix.
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
  GenericMatrix solveTranspose(GenericMatrix B) {
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
  Transpose get inverse {
    if (_inverse != null) {
      return _inverse;
    }

    final values =
        luDecomposition.solve(new Matrix.identity(rowDimension)).values;

    _inverse = transposeWithValues(new Float32List.fromList(values));

    return _inverse;
  }

  /// Computes the entrywise sum matrix of this matrix and another matrix.
  ///
  /// Computes the entrywise sum matrix `C` of this matrix `A` with another
  /// matrix [B]: `A + B = C`, where each value `C_ij` at coordinates (i, j) in
  /// matrix `C`, is equal to `A_ij + B_ij`.
  ///
  /// Throws an [ArgumentError] if the matrix dimensions don't match.
  Self operator +(GenericMatrix B) => entrywiseSum(B);

  /// Computes the entrywise difference matrix of this matrix and another
  /// matrix.
  ///
  /// Computes the entrywise difference matrix `C` of this matrix `A` with
  /// another matrix [B]: `A - B = C`, where each value `C_ij` at coordinates
  /// (i, j) in matrix `C`, is equal to `A_ij - B_ij`.
  ///
  /// Throws an [ArgumentError] if the matrix dimensions don't match.
  Self operator -(GenericMatrix B) => entrywiseDifference(B);

  /// Returns the scalar product for numerical values and the matrix product
  /// for matrix values.
  operator *(a) {
    if (a is num) {
      return scalarProduct(a);
    } else if (a is GenericMatrix) {
      return matrixProduct(a);
    } else {
      throw new ArgumentError('Expected num or GenericMatrix.');
    }
  }

  /// Checks if this matrix is equal to another.
  ///
  /// Two matrices are equal if they have equal dimensions and equal values.
  /// Does not check if the types of the matrices are equal.
  bool operator ==(GenericMatrix matrix) =>
      columnDimension == matrix.columnDimension &&
          _iterableEquals(values, matrix.values);

  int get hashCode =>
      hash3(columnDimension, rowDimension, hashObjects(_values));

  _assertEqualDimensions(GenericMatrix m) {
    if (m.columnDimension != columnDimension ||
        m.rowDimension != rowDimension) {
      throw new ArgumentError(
          'The dimenions of the matrices must match (the row dimenions must be '
          'equal and the column dimenions must be equal).');
    }
  }
}

/// Matrix data structure.
///
/// This implements an immutable matrix data structure, meaning that all
/// operations will return a new matrix instance, rather than update the current
/// matrix instance.
class Matrix extends GenericMatrix<Matrix, Matrix> {
  /// Creates a matrix from the given list of [values], with the specified
  /// [columnDimension].
  ///
  /// Creates a matrix from the given list with the specified [columnDimension].
  /// the row dimension will be inferred from the list's length. The list's
  /// length must be a multiple of the [columnDimension].
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     1.0 2.0 3.0
  ///     //     4.0 5.0 6.0
  ///     //
  ///     var matrix = new Matrix([1.0, 2.0, 3.0,
  ///                              4.0, 5.0, 6.0], 3);
  ///
  /// Throws [ArgumentError] if the list's length is not a multiple of the
  /// [columnDimension].
  Matrix(List<double> values, columnDimension)
      : super.fromList(values, columnDimension);

  /// Creates a matrix from the in the given [list], with the specified
  /// [columnDimension].
  ///
  /// The row dimension will be inferred from the list's length. The list's
  /// length must be a multiple of the [columnDimension].
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     1.0 2.0 3.0
  ///     //     4.0 5.0 6.0
  ///     //
  ///     var matrix = new Matrix.fromList([1.0, 2.0, 3.0,
  ///                                       4.0, 5.0, 6.0], 3);
  ///
  /// Throws [ArgumentError] if the list's length is not a multiple of the
  /// [columnDimension].
  Matrix.fromList(List<double> values, columnDimension)
      : super.fromList(values, columnDimension);

  /// Creates a matrix from the given [Float32List], with the specified
  /// [columnDimension].
  ///
  /// The row dimension will be inferred from the list's length. The list's
  /// length must be a multiple of the [columnDimension].
  ///
  /// Throws [ArgumentError] if the value list's length is not a multiple of the
  /// column dimension.
  Matrix.fromFloat32List(Float32List values, columnDimension)
      : super.fromFloat32List(values, columnDimension);

  /// Creates a constant matrix of the given [value] with the specified
  /// [rowDimension] and [columnDimension].
  ///
  /// Creates a new matrix where every position is set to the given [value].
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     1.0 1.0 1.0
  ///     //     1.0 1.0 1.0
  ///     //     1.0 1.0 1.0
  ///     //
  ///     var matrix = new Matrix.constant(1.0, 3, 3)
  ///
  Matrix.constant(double value, int rowDimension, int columnDimension)
      : super.constant(value, rowDimension, columnDimension);

  /// Creates a matrix of only zeros with the specified [rowDimension] and
  /// [columnDimension].
  ///
  /// Creates a new matrix where every position is set to `0.0`.
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     0.0 0.0 0.0 0.0
  ///     //     0.0 0.0 0.0 0.0
  ///     //     0.0 0.0 0.0 0.0
  ///     //
  ///     var matrix = new Matrix.zero(3, 4)
  ///
  Matrix.zero(int rowDimension, int columnDimension)
      : super.zero(rowDimension, columnDimension);

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
  ///     var matrix = new Matrix.identity(4)
  ///
  Matrix.identity(int size) : super.identity(size);

  Matrix withValues(Float32List newValues) =>
      new Matrix.fromFloat32List(newValues, columnDimension);

  Matrix transposeWithValues(Float32List newValues) =>
      new Matrix.fromFloat32List(newValues, rowDimension);

  /// Returns a list containing the values in the specified row.
  ///
  /// Rows are zero-indexed, meaning 0 will return the first row.
  ///
  /// Throws [RangeError] if there is no row for the given row index.
  List<double> operator [](int row) => rowAt(row);
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
