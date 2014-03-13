part of rolab_matrix_algebra;

class MatrixDefinitionException implements Exception {
  String _message;
  
  MatrixDefinitionException([this._message]);
  
  String toString() => "MatrixDefinitionException: ${_message}";
}
