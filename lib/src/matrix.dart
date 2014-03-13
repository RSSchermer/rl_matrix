part of rolab_matrix_algebra;

class Matrix {
  final int columns;
  
  List<num> _values;
  
  Matrix(this.columns, this._values) {
    if (_values.length % columns != 0) {
      throw new MatrixDefinitionException(
        'The number of values (${_values.length}) must be a multiple of ' +
        'the number of columns (${columns}) specified.'
      );
    }
  }
  
  Matrix.zero(this.columns, int rows) {
    _values = new List<num>.filled(columns * rows, 0);
  }
  
  Matrix.identity(int size) : columns = size {
    var currentRow = 0, currentColumn = 0;
        
    while (currentRow < size) {
      while (currentColumn < size) {
        if (currentRow == currentColumn) {
          _values.add(1);
        } else {
          _values.add(0);
        }
        
        currentColumn++;
      }
      
      currentRow = 0;
      currentColumn++;
    }
  }
  
  int get rows => _values.length ~/ columns;
  
  bool get isSquare => rows == columns;
  
  UnmodifiableListView<num> get values => new UnmodifiableListView(_values);
  
  num valueAt(int row, int column) {
    return _values[row * columns + column];
  }
  
  UnmodifiableListView<num> getValuesColumnPacked() {
    List<num> values;
        
    for (var column = 0; column < columns; column++) {
      for (var row = 0; row < rows; row++) {
        values.add(valueAt(row, column));
      }
    }
    
    return new UnmodifiableListView(values);
  }
  
  RowVector getRowAsVector(int row) {
    return new RowVector(
        _values.getRange(row * columns, (row + 1) * columns - 1));
  }
  
  ColumnVector getColumnAsVector(int column) {
    List<num> values;
    
    for (var row = 0; row < rows; row++) {
      values.add(valueAt(row, column));
    }
    
    return new ColumnVector(values);
  }
  
  Matrix entrywiseSum(Matrix m) {
    if (m.columns != columns || m.rows != rows) {
      throw new MatrixAlgebraException('Can only compute an entrywise sum of ' +
          'matrices of equal dimensions.');
    }
    
    List<num> summedValues;
    
    for (var i = 0; i <= values.length; i++) {
      summedValues.add(values[i] + m.values[i]);
    }
    
    return new Matrix(columns, summedValues);
  }
  
  Matrix entrywiseDifference(Matrix m) {
    if (m.columns != columns || m.rows != rows) {
      throw new MatrixAlgebraException('Can only compute an entrywise ' +
          'difference of matrices of equal dimensions.');
    }
    
    List<num> differenceValues;
    
    for (var i = 0; i <= values.length; i++) {
      differenceValues.add(values[i] - m.values[i]);
    }
    
    return new Matrix(columns, differenceValues);
  }
  
  Matrix scalarProduct(num s) {
    List<num> multipliedValues = new List.from(values).map((v) => s * v);
    
    return new Matrix(columns, multipliedValues);
  }
  
  Matrix matrixProduct(Matrix m) {
    
  }
    
  Matrix computeTranspose() => new Matrix(rows, getValuesColumnPacked());
    
  Matrix computeInverse() {
    List<num> numberList;
    
    return new Matrix(columns, numberList);
  }
}
