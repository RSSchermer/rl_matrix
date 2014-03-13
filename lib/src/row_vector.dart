part of rolab_matrix_algebra;

class RowVector extends Vector {
  RowVector(List<num> numberList) :
    super(1, numberList);
  
  int get dimension => columns;
  
  ColumnVector get transpose {
    return new ColumnVector(_values);
  }
}
