part of rl_matrix;

/// Generic superclass for matrices and vectors.
///
/// Generic implementation for matrix operations. This implements an immutable
/// matrix data structure, meaning that all operations will return a new matrix.
///
/// This class exists to facilitate easy definition of subtypes for specific
/// matrix dimensions (e.g. Vec3, Mat4, etc.), either for more efficient
/// dimension specific operation overrides, or to be able to use Dart's type
/// system to constrain matrix types in function signatures to specific
/// dimensions.
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

  /// Creates a matrix from the given list with the given column dimension.
  ///
  /// Creates a matrix from the given list with the given column dimension. The
  /// row dimension will be inferred from the list length. The list length must
  /// be a multiple of the column dimension.
  ///
  /// Throws [ArgumentError] if the value list's length is not a multiple of the
  /// column dimension.
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     1.0 2.0 3.0
  ///     //     4.0 5.0 6.0
  ///     //
  ///     var matrix = new Matrix.fromList([1.0, 2.0, 3.0,
  ///                                       4.0, 5.0, 6.0], 3);
  ///
  GenericMatrix.fromList(List<double> values, this.columnDimension)
      : _values = new Float32List.fromList(values) {
    if (values.length % columnDimension != 0) {
      throw new ArgumentError(
          'The length of the given values list (${values.length}) must be a '
          'multiple of the specified columnDimension (${columnDimension}).');
    }
  }

  /// Creates a matrix from the given typed float32 list, with the given
  /// column dimension.
  ///
  /// Creates a matrix from the given typed float32 list, with the given column
  /// dimension. The row dimension will be inferred from the list length. The
  /// list length must be a multiple of the column dimension.
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

  /// Creates a constant matrix of the specified value with the specified
  /// dimensions.
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

  /// Creates a matrix of only zeros with the specified dimensions.
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

  /// Creates an identity matrix of the given size.
  ///
  /// Creates an square identity matrix (ones on the diagonal, zeros elsewhere)
  /// of the specified size.
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

  /// Creates a new instance of this matrix type of equal dimensions, with the
  /// given values.
  Self withValues(Float32List newValues);

  /// Creates a new instance of this matrix's transpose type of transposed
  /// dimensions, with the given values.
  Transpose transposeWithValues(Float32List newValues);

  /// The transpose of the matrix.
  Transpose get transpose =>
      transposeWithValues(new Float32List.fromList(valuesColumnPacked));

  /// The row dimension of this matrix (number of rows).
  int get rowDimension => _values.length ~/ columnDimension;

  /// Returns whether or not the matrix is square (row dimension equal to column
  /// dimension).
  bool get isSquare => rowDimension == columnDimension;

  /// Returns the value at the given coordinates.
  ///
  /// Returns the values at the given coordinates, where the first coordinate
  /// specifies the row and the second coordinate specifies the column. Row and
  /// column indices start at 0, so (0, 0) identifies the top left value in the
  /// matrix.
  double valueAt(int row, int column) =>
      _values[row * columnDimension + column];

  /// Returns the values in this matrix, column-packed.
  ///
  /// The values that make up this matrix in column-packed format, meaning that
  /// for a matrix with a row dimension of 5, the first 5 values make up the
  /// first column, the second 5 values make up the second column, etc.
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
  /// The values that make up this matrix and column-packed format, meaning that
  /// for a matrix with a column dimension of 5, the first 5 values make up the
  /// first row, the second 5 values make up the second row, etc.
  Iterable<double> get valuesRowPacked => new UnmodifiableListView(_values);

  /// Alias for `valuesRowPacked`
  Iterable<double> get values => new UnmodifiableListView(_values);

  /// Returns a new sub-matrix.
  ///
  /// Takes 4 arguments: the starting row's index, the ending row's index, the
  /// starting column's index and the ending column's index. Indexes start at
  /// zero. The resulting sub-matrix will be the sub-section of the matrix
  /// delineated by these indices. The indices are inclusive, meaning that a
  /// starting row index of 0 will include the first row in the sub-matrix and
  /// an ending row index of 3 will include the fourth row in the sub-matrix.
  ///
  /// Throws an [ArgumentError] if the starting row index is greater than the
  /// ending row index, or the starting column index is greater than the
  /// ending column index.
  GenericMatrix subMatrix(int rowStart, int rowEnd, int colStart, int colEnd) {
    if (rowStart > rowEnd) {
      throw new ArgumentError(
          'Ending row index may not be bigger than starting row index.');
    }

    if (colStart > colEnd) {
      throw new ArgumentError(
          'Ending column index may not be bigger than starting column index.');
    }

    final rows = (rowEnd - rowStart) + 1;
    final cols = (colEnd - colStart) + 1;
    final subMatrixVals = new Float32List(rows * cols);

    for (var i = rowStart; i <= rowEnd; i++) {
      for (var j = colStart; j <= colEnd; j++) {
        subMatrixVals[(i - rowStart) * cols + (j - colStart)] = valueAt(i, j);
      }
    }

    return new Matrix(subMatrixVals, cols);
  }

  /// Returns a list containing the values in the specified row.
  ///
  /// Rows are zero-indexed, meaning 0 will return the first row.
  ///
  /// Throws [RangeError] if there is no row for the given row index.
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
  /// matrix `B`: `A + B = C`, where each value `C_ij` at coordinates (i, j) in
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
  /// another matrix `B`: `A - B = C`, where each value `C_ij` at coordinates
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
  /// another matrix `B`. Each value `C_ij` at coordinates (i, j) in matrix `C`,
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
  /// Throws an [ArgumentError] if matrix `A`'s column dimension does not equal
  /// matrix `B`'s row dimension.
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
  /// Throws an [UnsupportedError] if the decomposed matrix is not square.
  double get determinant => luDecomposition.determinant;

  /// Solves `AX = B` for X, where A is this matrix and B the given matrix.
  ///
  /// Returns the solution if A is square, or the least squares solution
  /// otherwise.
  ///
  /// Throws an [ArgumentError] if the row dimensions of A and B do not match.
  /// Throws an [UnsupportedError] if A is square and singular.
  /// Throws an [UnsupportedError] if A has more columns than rows.
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

  /// Solves `XA = B` for X, where A is this matrix and B the given matrix.
  ///
  /// Solves `X * A = B` for X using `A' * X' = B'`. Returns the solution if A
  /// is square, or the least squares solution otherwise.
  ///
  /// Throws an [ArgumentError] if the column dimensions of A and B do not
  /// match.
  /// Throws an [UnsupportedError] if A is square and singular.
  /// Throws an [UnsupportedError] if A has more rows than columns.
  GenericMatrix solveTranspose(GenericMatrix B) {
    if (rowDimension > columnDimension) {
      throw new UnsupportedError('Matrix has more rows than columns.');
    }

    return transpose.solve(B.transpose).transpose;
  }

  /// This matrix's inverse if this matrix is non-singular.
  ///
  /// Throws an [UnsupportedError] if the matrix is not square.
  /// Throws an [UnsupportedError] if the matrix is square and singular.
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
  /// Computes the entrywise sum matrix `C` of the matrix `A` with another
  /// matrix `B`: `A + B = C`, where each value `C_ij` at coordinates (i, j) in
  /// matrix `C`, is equal to `A_ij + B_ij`.
  ///
  /// Throws an [ArgumentError] if the matrix dimensions don't match.
  Self operator +(GenericMatrix B) => entrywiseSum(B);

  /// Computes the entrywise difference matrix of this matrix and another
  /// matrix.
  ///
  /// Computes the entrywise difference matrix `C` of the matrix `A` with
  /// another matrix `B`: `A - B = C`, where each value `C_ij` at coordinates
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
  /// Equality for matrices is defined as equal dimensions and equal values. It
  /// does not check matrix type.
  bool operator ==(GenericMatrix matrix) =>
      columnDimension == matrix.columnDimension &&
          _iterableEquals(values, matrix.values);

  int get hashCode =>
      hash3(columnDimension, rowDimension, hashObjects(_values));

  _assertEqualDimensions(GenericMatrix m) {
    if (m.columnDimension != columnDimension ||
        m.rowDimension != rowDimension) {
      throw new ArgumentError(
          'Can only compute an entrywise sum of matrices of equal dimensions.');
    }
  }
}

/// Matrix data structure.
///
/// Immutable matrix implementation without dimension specific optimisations or
/// dimension restrictions.
///
///     // Instantiates the following matrix:
///     //
///     //     1.0 2.0 3.0
///     //     4.0 5.0 6.0
///     //
///     var matrix = new Matrix([1.0, 2.0, 3.0,
///                              4.0, 5.0, 6.0], 3);
///
class Matrix extends GenericMatrix<Matrix, Matrix> {
  /// Creates a matrix from the given list with the given column dimension.
  ///
  /// Creates a matrix from the given list with the given column dimension. the
  /// row dimension will be inferred from the list length. The list length must
  /// be a multiple of the column dimension.
  ///
  /// Throws [ArgumentError] if the value list's length is not a multiple of the
  /// column dimension.
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     1.0 2.0 3.0
  ///     //     4.0 5.0 6.0
  ///     //
  ///     var matrix = new Matrix([1.0, 2.0, 3.0,
  ///                              4.0, 5.0, 6.0], 3);
  ///
  Matrix(List<double> values, columnDimension)
      : super.fromList(values, columnDimension);

  /// Creates a matrix from the given list with the given column dimension.
  ///
  /// Creates a matrix from the given list with the given column dimension. The
  /// row dimension will be inferred from the list length. The list length must
  /// be a multiple of the column dimension.
  ///
  /// Throws [ArgumentError] if the value list's length is not a multiple of the
  /// column dimension.
  ///
  ///     // Instantiates the following matrix:
  ///     //
  ///     //     1.0 2.0 3.0
  ///     //     4.0 5.0 6.0
  ///     //
  ///     var matrix = new Matrix.fromList([1.0, 2.0, 3.0,
  ///                                       4.0, 5.0, 6.0], 3);
  ///
  Matrix.fromList(List<double> values, columnDimension)
      : super.fromList(values, columnDimension);

  /// Creates a matrix from the given typed float32 list, with the given
  /// column dimension.
  ///
  /// Creates a matrix from the given typed float32 list, with the given column
  /// dimension. The row dimension will be inferred from the list length. The
  /// list length must be a multiple of the column dimension.
  ///
  /// Throws [ArgumentError] if the value list's length is not a multiple of the
  /// column dimension.
  Matrix.fromFloat32List(Float32List values, columnDimension)
      : super.fromFloat32List(values, columnDimension);

  /// Creates a constant matrix of the specified value with the specified
  /// dimensions.
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

  /// Creates a matrix of only zeros with the specified dimensions.
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

  /// Creates an identity matrix of the given size.
  ///
  /// Creates an square identity matrix (ones on the diagonal, zeros elsewhere)
  /// of the specified size.
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
