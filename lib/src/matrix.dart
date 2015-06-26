part of matrix;

/// Generic subclass for matrices and vectors.
///
/// Generic implementation for matrix operations. This implements an immutable
/// matrix data structure, meaning that all operations will return a new matrix.
///
/// This takes two type parameters: the self type and the type of the transpose.
/// This is to facilitate easy definition of subtypes for specific matrix
/// dimensions (e.g. Vec3, Mat4x4, etc.), either for more efficient dimension
/// specific operation overrides, or to be able to use Dart's type system to
/// constrain matrix types in function signatures to matrices of specific
/// dimensions.
abstract class GenericMatrix<Self extends GenericMatrix<Self, Transpose>, Transpose extends GenericMatrix> {

  /// The matrix's column dimension (number of columns)
  final int columnDimension;

  /// The values in the matrix, row-packed.
  ///
  /// The values that make up this matrix in row-packed format, meaning that
  /// for a matrix with a column dimension of 5, the first 5 values make up
  /// the first row, the second 5 values make up the second row, etc.
  final UnmodifiableListView<num> _values;

  /// Memoization of column packed values.
  UnmodifiableListView<num> _valuesColumnPacked;

  /// Memoization of inverse matrix.
  Self _inverse;

  /// Creates a matrix from the given list with the given column dimension.
  ///
  /// Creates a matrix from the given list with the given column dimension. the
  /// row dimension will be inferred from the list length. The list length must
  /// be a multiple of the column dimension
  GenericMatrix.fromList(List<num> values, this.columnDimension)
      : _values = new UnmodifiableListView(values) {
    if (values.length % columnDimension != 0) {
      throw new ArgumentError('The length of the values list (${values.length}) must be a multiple of the columnDimension (${columnDimension}) specified.');
    }
  }

  /// Creates a constant matrix of the specified value with the specified
  /// dimensions.
  GenericMatrix.constant(num value, int rowDimension, int columnDimension)
      : columnDimension = columnDimension,
        _values =  new UnmodifiableListView(new List.filled(columnDimension * rowDimension, value));

  /// Creates a matrix of only zeros with the specified dimensions
  GenericMatrix.zero(int rowDimension, int columnDimension)
      : this.constant(0, rowDimension, columnDimension);

  /// Creates an identity matrix of the given size.
  ///
  /// Creates an square identity matrix (ones on the diagonal, zeros elsewhere)
  /// of the specified size.
  GenericMatrix.identity(int size)
      : columnDimension = size,
        _values = new UnmodifiableListView(_identityValues(size));

  /// Creates a new instance of this matrix type of equal dimensions.
  ///
  /// Creates a new instance of this matrix type of equal dimensions, optionally
  /// with a new set of values populating the matrix.
  Self copy([List<num> newValues]);

  /// The transpose of the matrix.
  Transpose get transpose;

  /// The row dimension of the matrix (number of rows).
  int get rowDimension => _values.length ~/ columnDimension;

  /// Returns whether or not the matrix is square (row dimension equal to column
  /// dimension).
  bool get isSquare => rowDimension == columnDimension;

  /// Returns the value at the given coordinates.
  ///
  /// Returns the values at the given coordinates, where the first coordinate
  /// specifies the row and the second coordinate specifies the column. Row and
  /// column indices start at 1, so (1, 1) identifies the top left value in the
  /// matrix.
  num valueAt(int row, int column) =>
    _values[(row - 1) * columnDimension + column - 1];

  /// Returns the values in the matrix, column-packed.
  ///
  /// The values that make up this matrix in column-packed format, meaning that
  /// for a matrix with a row dimension of 5, the first 5 values make up the
  /// first column, the second 5 values make up the second column, etc.
  Iterable<num> get valuesColumnPacked {
    if (_valuesColumnPacked != null) return _valuesColumnPacked;

    var values = new List<num>();
        
    for (var column = 1; column <= columnDimension; column++) {
      for (var row = 1; row <= rowDimension; row++) {
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

  /// Computes the entrywise sum matrix with another matrix.
  ///
  /// Computes the entrywise sum matrix `C` of the matrix `A` with another
  /// matrix `B`: `A + B = C`, where each value `C_ij` at coordinates (i, j) in
  /// matrix `C`, is equal to `A_ij + B_ij`.
  Self entrywiseSum(GenericMatrix m) {
    _assertEqualDimensions(m);
    
    var summedValues = new List<num>();
    
    for (var i = 0; i < _values.length; i++) {
      summedValues.add(_values[i] + m._values[i]);
    }
    
    return copy(summedValues);
  }

  /// Computes the entrywise difference matrix with another matrix.
  ///
  /// Computes the entrywise difference matrix `C` of the matrix `A` with
  /// another matrix `B`: `A - B = C`, where each value `C_ij` at coordinates
  /// (i, j) in matrix `C`, is equal to `A_ij - B_ij`.
  Self entrywiseDifference(GenericMatrix m) {
    _assertEqualDimensions(m);
    
    var differenceValues = new List<num>();
    
    for (var i = 0; i < _values.length; i++) {
      differenceValues.add(_values[i] - m._values[i]);
    }

    return copy(differenceValues);
  }

  /// Multiply the matrix with a scalar value.
  ///
  /// Computes a new matrix `B` of this matrix `A` multiplied with a scalar `s`:
  /// `A * s = B`, where each value `B_ij` at coordinates (i, j) in matrix `B`,
  /// is equal to `A_ij * s`.
  Self scalarProduct(num s) {
    var multipliedValues = new List.from(_values).map((v) => s * v);

    return copy(multipliedValues.toList());
  }

  /// Computes the matrix product of the matrix with another matrix.
  ///
  /// Computes the product matrix `C`, the matrix product of the matrix `A` with
  /// another matrix `B`: `AB = C`. The column dimension of `A` must match the
  /// row dimension of `B`.
  GenericMatrix matrixProduct(GenericMatrix m) {
    if (columnDimension != m.rowDimension) {
      throw new ArgumentError("Matrix inner dimensions must agree.");
    }

    var productValues = new List<num>();
    var mColumnPacked = m.valuesColumnPacked;
    var mCols = m.columnDimension;
    var sum;

    for (var row = 0; row < rowDimension; row++) {
      for (var col = 0; col < mCols; col++) {
        sum = 0;

        for (var j = 0; j < columnDimension; j++) {
          sum += _values[row * columnDimension + j] * mColumnPacked[col * columnDimension + j];
        }

        productValues.add(sum);
      }
    }

    return new Matrix(productValues, m.columnDimension);
  }

  /// Computes the Hadamard product of the matrix with another matrix.
  ///
  /// Computes the Hadamard product, or entrywise product, `C` of the matrix `A`
  /// with another matrix `B`. Each value `C_ij` at coordinates (i, j) in matrix
  /// `C`, is equal to `A_ij * B_ij`.
  Self hadamardProduct(GenericMatrix m) {
    _assertEqualDimensions(m);

    var productValues = new List<num>();

    for (var i = 0; i < _values.length; i++) {
      productValues.add(_values[i] * m._values[i]);
    }

    return copy(productValues);
  }

  /// Divide the matrix by a scalar value.
  ///
  /// Computes a new matrix `B` of this matrix `A` divided by a scalar s:
  /// `A / s = B`, where each value `B_ij` at coordinates (i, j) in matrix `B`,
  /// is equal to `A_ij / s`.
  Self scalarDivision(num s) {
    var dividedValues = new List.from(_values).map((v) => s / v);

    return copy(dividedValues.toList());
  }

  /// Returns the inverse matrix of the matrix.
  Self get inverse {
    if (_inverse != null) return _inverse;

    var numberList;
    
    return copy(numberList);
  }

  /// Computes the entrywise sum matrix with another matrix.
  ///
  /// Computes the entrywise sum matrix `C` of the matrix `A` with another
  /// matrix `B`: `A + B = C`, where each value `C_ij` at coordinates (i, j) in
  /// matrix `C`, is equal to `A_ij + B_ij`.
  Self operator +(GenericMatrix m) => entrywiseSum(m);

  /// Computes the entrywise difference matrix with another matrix.
  ///
  /// Computes the entrywise difference matrix `C` of the matrix `A` with
  /// another matrix `B`: `A - B = C`, where each value `C_ij` at coordinates
  /// (i, j) in matrix `C`, is equal to `A_ij - B_ij`.
  Self operator -(GenericMatrix m) => entrywiseDifference(m);

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
class Matrix extends GenericMatrix<Matrix, Matrix> {
  Matrix(List<num> values, columnDimension)
      : super.fromList(values, columnDimension);

  Matrix.fromList(List<num> values, columnDimension)
      : super.fromList(values, columnDimension);

  Matrix.constant(num value, int rowDimension, int columnDimension)
      : super.constant(value, rowDimension, columnDimension);

  Matrix.zero(int rowDimension, int columnDimension)
      : super.zero(rowDimension, columnDimension);

  Matrix.identity(int size) : super.identity(size);

  Matrix copy([List<num> newValues]) =>
    new Matrix(newValues != null ? newValues : _values, columnDimension);

  Matrix get transpose =>
    new Matrix(valuesColumnPacked, rowDimension);
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
