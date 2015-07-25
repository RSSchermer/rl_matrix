part of matrix;

/// Generic subclass for matrices and vectors.
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
/// and the extending class' tranpose type. Also, two abstract methods will need
/// to be defined:
///
/// - `withValues`: needs to return a new matrix of the same type and with the
///   same dimensions, with the given values.
/// - `transposeWithValues`: needs to return a new matrix of the matrix's
///   transpose type, with transposed dimensions, with the given values.
///
/// The following example implements a column vector:
///
///     class ColumnVector extends GenericMatrix<ColumnVector, RowVector> {
///       ColumnVector(List<num> values) : super.fromList(values, 1);
///
///       ColumnVector withValues(List<num> newValues) =>
///         new ColumnVector(newValues);
///
///       RowVector transposeWithValues(List<num> newValues) =>
///         new RowVector(newValues);
///     }
///
abstract class GenericMatrix<Self extends GenericMatrix<Self, Transpose>, Transpose extends GenericMatrix> {

  /// The matrix's column dimension (number of columns)
  final int columnDimension;

  /// The values in the matrix, row-packed.
  ///
  /// The values that make up this matrix in row-packed format, meaning that
  /// for a matrix with a column dimension of 5, the first 5 values make up
  /// the first row, the second 5 values make up the second row, etc.
  final UnmodifiableListView<num> _values;

  /// Memoized column packed values.
  UnmodifiableListView<num> _valuesColumnPacked;

  /// Memoized LU-decomposition.
  PivotingLUDecomposition _luDecompostion;

  /// Memoized QR-decomposition.
  ReducedQRDecomposition _qrDecomposition;

  /// Memoized inverse matrix.
  Transpose _inverse;

  /// Memoized left inverse matrix.
  Transpose _leftInverse;

  /// Memoized right inverse matrix.
  Transpose _rightInverse;

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
  ///     // 1 2 3
  ///     // 4 5 6
  ///     var matrix = new Matrix.fromList([1, 2, 3,
  ///                                       4, 5, 6], 3);
  ///
  GenericMatrix.fromList(List<num> values, this.columnDimension)
      : _values = new UnmodifiableListView(values) {
    if (values.length % columnDimension != 0) {
      throw new ArgumentError('The length of the values list (${values.length}) must be a multiple of the columnDimension (${columnDimension}) specified.');
    }
  }

  /// Creates a constant matrix of the specified value with the specified
  /// dimensions.
  ///
  ///     // Instantiates the following matrix:
  ///     // 1 1 1
  ///     // 1 1 1
  ///     // 1 1 1
  ///     var matrix = new Matrix.constant(1, 3, 3)
  ///
  GenericMatrix.constant(num value, int rowDimension, int columnDimension)
      : columnDimension = columnDimension,
        _values =  new UnmodifiableListView(new List.filled(columnDimension * rowDimension, value));

  /// Creates a matrix of only zeros with the specified dimensions.
  ///
  ///     // Instantiates the following matrix:
  ///     // 0 0 0 0
  ///     // 0 0 0 0
  ///     // 0 0 0 0
  ///     var matrix = new Matrix.zero(3, 4)
  ///
  GenericMatrix.zero(int rowDimension, int columnDimension)
      : this.constant(0, rowDimension, columnDimension);

  /// Creates an identity matrix of the given size.
  ///
  /// Creates an square identity matrix (ones on the diagonal, zeros elsewhere)
  /// of the specified size.
  ///
  ///     // Instantiates the following matrix:
  ///     // 1 0 0 0
  ///     // 0 1 0 0
  ///     // 0 0 1 0
  ///     // 0 0 0 1
  ///     var matrix = new Matrix.identity(4)
  ///
  GenericMatrix.identity(int size)
      : columnDimension = size,
        _values = new UnmodifiableListView(_identityValues(size));

  /// Creates a new instance of this matrix type of equal dimensions, with the
  /// given values.
  Self withValues(List<num> newValues);

  /// Creates a new instance of this matrix's transpose type of transposed
  /// dimensions, with the given values.
  Transpose transposeWithValues(List<num> newValues);

  /// The transpose of the matrix.
  Transpose get transpose => transposeWithValues(valuesColumnPacked);

  /// The row dimension of the matrix (number of rows).
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
  num valueAt(int row, int column) =>
    _values[row * columnDimension + column];

  /// Returns the values in the matrix, column-packed.
  ///
  /// The values that make up this matrix in column-packed format, meaning that
  /// for a matrix with a row dimension of 5, the first 5 values make up the
  /// first column, the second 5 values make up the second column, etc.
  Iterable<num> get valuesColumnPacked {
    if (_valuesColumnPacked != null) {
      return _valuesColumnPacked;
    }

    var values = new List();
        
    for (var column = 0; column < columnDimension; column++) {
      for (var row = 0; row < rowDimension; row++) {
        values.add(valueAt(row, column));
      }
    }

    _valuesColumnPacked = new UnmodifiableListView(values);

    return _valuesColumnPacked;
  }

  /// Returns the values in the matrix, row-packed.
  ///
  /// The values that make up this matrix and column-packed format, meaning that
  /// for a matrix with a column dimension of 5, the first 5 values make up the
  /// first row, the second 5 values make up the second row, etc.
  Iterable<num> get valuesRowPacked => _values;

  /// Alias for `valuesRowPacked`
  Iterable<num> get values => _values;

  /// Returns a new sub-matrix.
  ///
  /// Takes 4 arguments: the starting row's index, the ending row's index, the
  /// starting column's index and the ending column's index. Indexes start at
  /// zero. The resulting sub-matrix will be the sub-section of the matrix
  /// delineated by these indices. The given indices are inclusive, meaning that
  /// a starting row index of 0 will include the first row in the sub-matrix.
  ///
  /// Throws an [ArgumentError] if the starting row index is greater than the
  /// ending row index, or the starting column index is greater than the
  /// ending column index.
  GenericMatrix subMatrix(int rowStart, int rowEnd, int colStart, int colEnd) {
    if (rowStart > rowEnd) {
      throw new ArgumentError("Ending row index may not be bigger than starting row index.");
    }

    if (colStart > colEnd) {
      throw new ArgumentError("Ending column index may not be bigger than starting column index.");
    }

    var subMatrixVals = new List();

    for (var i = rowStart; i <= rowEnd; i++) {
      for (var j = colStart; j <= colEnd; j++) {
        subMatrixVals.add(valueAt(i, j));
      }
    }

    return new Matrix(subMatrixVals, colEnd - colStart + 1);
  }

  /// Computes the entrywise sum matrix with another matrix.
  ///
  /// Computes the entrywise sum matrix `C` of the matrix `A` with another
  /// matrix `B`: `A + B = C`, where each value `C_ij` at coordinates (i, j) in
  /// matrix `C`, is equal to `A_ij + B_ij`.
  Self entrywiseSum(GenericMatrix B) {
    _assertEqualDimensions(B);
    
    var summedValues = new List();
    
    for (var i = 0; i < _values.length; i++) {
      summedValues.add(_values[i] + B._values[i]);
    }
    
    return withValues(summedValues);
  }

  /// Computes the entrywise difference matrix with another matrix.
  ///
  /// Computes the entrywise difference matrix `C` of the matrix `A` with
  /// another matrix `B`: `A - B = C`, where each value `C_ij` at coordinates
  /// (i, j) in matrix `C`, is equal to `A_ij - B_ij`.
  Self entrywiseDifference(GenericMatrix B) {
    _assertEqualDimensions(B);
    
    var differenceValues = new List();
    
    for (var i = 0; i < _values.length; i++) {
      differenceValues.add(_values[i] - B._values[i]);
    }

    return withValues(differenceValues);
  }

  /// Computes the entrywise product of the matrix with another matrix.
  ///
  /// Computes the entrywise (Hadamard) product `C` of the matrix `A` with
  /// another matrix `B`. Each value `C_ij` at coordinates (i, j) in matrix `C`,
  /// is equal to `A_ij * B_ij`.
  Self entrywiseProduct(GenericMatrix B) {
    _assertEqualDimensions(B);

    var productValues = new List();

    for (var i = 0; i < _values.length; i++) {
      productValues.add(_values[i] * B._values[i]);
    }

    return withValues(productValues);
  }

  /// Multiply the matrix with a scalar value.
  ///
  /// Computes a new matrix `B` of this matrix `A` multiplied with a scalar `s`:
  /// `A * s = B`, where each value `B_ij` at coordinates (i, j) in matrix `B`,
  /// is equal to `A_ij * s`.
  Self scalarProduct(num s) {
    var multipliedValues = new List.from(_values).map((v) => s * v);

    return withValues(multipliedValues.toList());
  }

  /// Divide the matrix by a scalar value.
  ///
  /// Computes a new matrix `B` of this matrix `A` divided by a scalar s:
  /// `A / s = B`, where each value `B_ij` at coordinates (i, j) in matrix `B`,
  /// is equal to `A_ij / s`.
  Self scalarDivision(num s) {
    var dividedValues = new List.from(_values).map((v) => s / v);

    return withValues(dividedValues.toList());
  }

  /// Computes the matrix product of the matrix with another matrix.
  ///
  /// Computes the product matrix `C`, the matrix product of the matrix `A` with
  /// another matrix `B`: `AB = C`. The column dimension of `A` must match the
  /// row dimension of `B`.
  GenericMatrix matrixProduct(GenericMatrix B) {
    if (columnDimension != B.rowDimension) {
      throw new ArgumentError("Matrix inner dimensions must agree.");
    }

    var productValues = new List();
    var bColumnPacked = B.valuesColumnPacked;
    var bCols = B.columnDimension;

    for (var row = 0; row < rowDimension; row++) {
      for (var col = 0; col < bCols; col++) {
        var sum = 0;

        for (var j = 0; j < columnDimension; j++) {
          sum += _values[row * columnDimension + j] * bColumnPacked[col * columnDimension + j];
        }

        productValues.add(sum);
      }
    }

    return new Matrix(productValues, B.columnDimension);
  }

  /// The LU-decomposition for the matrix (with partial pivoting).
  PivotingLUDecomposition get luDecomposition {
    if (_luDecompostion != null) {
      return _luDecompostion;
    }

    _luDecompostion = new PivotingLUDecomposition(this);

    return _luDecompostion;
  }

  /// The QR-decomposition for the matrix.
  ReducedQRDecomposition get qrDecomposition {
    if (_qrDecomposition != null) {
      return _qrDecomposition;
    }

    _qrDecomposition = new ReducedQRDecomposition(this);

    return _qrDecomposition;
  }

  /// Whether or not the matrix is non-singular (invertible).
  bool get isNonSingular {
    if (isSquare) {
      return luDecomposition.isNonsingular;
    } else {
      return false;
    }
  }

  /// The matrix's determinant.
  ///
  /// Throws an [UnsupportedError] if the decomposed matrix is not square.
  num get determinant => luDecomposition.determinant;

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

  /// The matrix's inverse if the matrix is non-singular.
  ///
  /// Throws an [UnsupportedError] if the matrix is not square.
  /// Throws an [UnsupportedError] if the matrix is square and singular.
  Transpose get inverse {
    if (_inverse != null) {
      return _inverse;
    }

    var values = luDecomposition.solve(new Matrix.identity(rowDimension)).values;

    _inverse = transposeWithValues(values);
    
    return _inverse;
  }

  /// Computes the entrywise sum matrix with another matrix.
  ///
  /// Computes the entrywise sum matrix `C` of the matrix `A` with another
  /// matrix `B`: `A + B = C`, where each value `C_ij` at coordinates (i, j) in
  /// matrix `C`, is equal to `A_ij + B_ij`.
  Self operator +(GenericMatrix B) => entrywiseSum(B);

  /// Computes the entrywise difference matrix with another matrix.
  ///
  /// Computes the entrywise difference matrix `C` of the matrix `A` with
  /// another matrix `B`: `A - B = C`, where each value `C_ij` at coordinates
  /// (i, j) in matrix `C`, is equal to `A_ij - B_ij`.
  Self operator -(GenericMatrix B) => entrywiseDifference(B);

  /// Returns the scalar product for numerical values and the matrix product
  /// for matrix values.
  operator *(a) {
    if (a is num) {
      return scalarProduct(a);
    } else if (a is GenericMatrix) {
      return matrixProduct(a);
    } else {
      throw new ArgumentError("Expected num or GenericMatrix");
    }
  }

  _assertEqualDimensions(GenericMatrix m) {
    if (m.columnDimension != columnDimension || m.rowDimension != rowDimension) {
      throw new ArgumentError('Can only compute an entrywise sum of matrices of equal dimensions.');
    }
  }
}

/// Matrix data structure.
///
/// Immutable matrix implementation without dimension specific optimisations or
/// dimension restrictions.
///
///     var matrix = new Matrix([1, 2, 3,
///                              4, 5, 6], 3);
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
  ///     // 1 2 3
  ///     // 4 5 6
  ///     var matrix = new Matrix.fromList([1, 2, 3,
  ///                                       4, 5, 6], 3);
  ///
  Matrix(List<num> values, columnDimension)
      : super.fromList(values, columnDimension);

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
  ///     // 1 2 3
  ///     // 4 5 6
  ///     var matrix = new Matrix.fromList([1, 2, 3,
  ///                                       4, 5, 6], 3);
  ///
  Matrix.fromList(List<num> values, columnDimension)
      : super.fromList(values, columnDimension);

  /// Creates a constant matrix of the specified value with the specified
  /// dimensions.
  ///
  ///     // Instantiates the following matrix:
  ///     // 1 1 1
  ///     // 1 1 1
  ///     // 1 1 1
  ///     var matrix = new Matrix.constant(1, 3, 3)
  ///
  Matrix.constant(num value, int rowDimension, int columnDimension)
      : super.constant(value, rowDimension, columnDimension);

  /// Creates a matrix of only zeros with the specified dimensions.
  ///
  ///     // Instantiates the following matrix:
  ///     // 0 0 0 0
  ///     // 0 0 0 0
  ///     // 0 0 0 0
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
  ///     // 1 0 0 0
  ///     // 0 1 0 0
  ///     // 0 0 1 0
  ///     // 0 0 0 1
  ///     var matrix = new Matrix.identity(4)
  ///
  Matrix.identity(int size) : super.identity(size);

  Matrix withValues(List<num> newValues) =>
    new Matrix(newValues, columnDimension);

  Matrix transposeWithValues(List<num> newValues) =>
    new Matrix(newValues, rowDimension);
}

_identityValues(int size) {
  var values = new List();
  var currentRow = 0, currentColumn = 0;

  while (currentRow < size) {
    while (currentColumn < size) {
      if (currentRow == currentColumn) {
        values.add(1);
      } else {
        values.add(0);
      }

      currentColumn++;
    }

    currentColumn = 0;
    currentRow++;
  }

  return values;
}
