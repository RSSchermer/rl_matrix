part of rolab_matrix_algebra;

class MatrixAlgebraException implements Exception {
  String _message;
  
  MatrixAlgebraException([this._message]);
  
  String toString() => "MatrixAlgebraException: ${_message}";
}
