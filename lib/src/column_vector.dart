part of rolab_matrix_algebra;

class ColumnVector extends Vector {
  ColumnVector(List<num> numberList) :
    super(numberList.length, numberList);
  
  int get dimension => rows;
  
  RowVector get transpose {
    return new RowVector(_values);
  }
}
