part of rolab_matrix_algebra;

abstract class Vector extends Matrix {
  Vector(int columns, List<num> numberList) :
    super(columns, numberList);
  
  int get dimension;
}
