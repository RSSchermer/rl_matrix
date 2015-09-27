import 'package:test/test.dart';
import 'package:rl_matrix/rl_matrix.dart';
import 'helpers.dart';

void main() {
  group('Matrix', () {
    group('constructors', () {
      test('strict value list length checking', () {
        expect(() => new Matrix([1.0, 2.0], 3), throwsArgumentError);
        expect(() => new Matrix([1.0, 2.0, 3.0, 4.0], 3), throwsArgumentError);
      });

      test('constant matrix', () {
        var m = new Matrix.constant(6.0, 3, 2);
        var e = [6.0, 6.0, 6.0,
                 6.0, 6.0, 6.0];

        expect(m.values.toList(), equals(e));
      });

      test('zero matrix', () {
        var m = new Matrix.zero(3, 3);
        var e = [0.0, 0.0, 0.0,
                 0.0, 0.0, 0.0,
                 0.0, 0.0, 0.0];

        expect(m.values.toList(), equals(e));
      });

      test('identity matrix', () {
        var m = new Matrix.identity(3);
        var e = [1.0, 0.0, 0.0,
                 0.0, 1.0, 0.0,
                 0.0, 0.0, 1.0];

        expect(m.values.toList(), equals(e));
      });
    });

    group('rowDimension', () {
      test('1 x 3', () {
        var m = new Matrix([1.0, 2.0, 3.0], 3);

        expect(m.rowDimension, equals(1));
      });
    });

    group('isSquare', () {
      test('2 x 3', () {
        var m = new Matrix.constant(1.0, 2, 3);

        expect(m.isSquare, isFalse);
      });

      test('3 x 3', () {
        var m = new Matrix.constant(1.0, 3, 3);

        expect(m.isSquare, isTrue);
      });
    });

    test('values', () {
      var m = new Matrix([0.0, 1.0, 2.0,
                          3.0, 4.0, 5.0], 3);

      expect(m.values.toList(), equals([0.0, 1.0, 2.0, 3.0, 4.0, 5.0]));
    });

    group('valueAt', () {
      var m = new Matrix([0.0, 1.0, 2.0,
                          3.0, 4.0, 5.0], 3);

      test('(0, 0)', () {
        expect(m.valueAt(0, 0), equals(0.0));
      });

      test('(0, 2)', () {
        expect(m.valueAt(0, 2), equals(2.0));
      });

      test('(1, 0)', () {
        expect(m.valueAt(1, 0), equals(3.0));
      });

      test('(1, 2)', () {
        expect(m.valueAt(1, 2), equals(5.0));
      });
    });

    test('valuesColumnPacked', () {
      var m = new Matrix([1.0, 2.0, 3.0,
                          1.0, 2.0, 3.0,
                          1.0, 2.0, 3.0], 3);

      expect(m.valuesColumnPacked.toList(), equals([1.0, 1.0, 1.0, 2.0, 2.0, 2.0, 3.0, 3.0, 3.0]));
    });

    test('valuesRowPacked', () {
      var m = new Matrix([1.0, 2.0, 3.0,
                          1.0, 2.0, 3.0,
                          1.0, 2.0, 3.0], 3);

      expect(m.valuesRowPacked.toList(), equals([1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0]));
    });

    group('subMatrix', () {
      test('throws and error when the starting row index is greater than the ending row index', () {
        var m = new Matrix([1.0, 2.0, 3.0,
                            1.0, 2.0, 3.0,
                            1.0, 2.0, 3.0], 3);

        expect(() => m.subMatrix(1, 0, 0, 2), throwsArgumentError);
      });

      test('throws and error when the starting column index is greater than the ending column index', () {
        var m = new Matrix([1.0, 2.0, 3.0,
                            1.0, 2.0, 3.0,
                            1.0, 2.0, 3.0], 3);

        expect(() => m.subMatrix(0, 2, 1, 0), throwsArgumentError);
      });

      group('returns a new matrix', () {
        var m = new Matrix([1.0, 2.0, 3.0,
                            4.0, 5.0, 6.0,
                            7.0, 8.0, 9.0], 3);
        var subMatrix = m.subMatrix(1, 2, 1, 2);

        test('with the expected values', () {
          expect(subMatrix.values.toList(), equals([5.0, 6.0, 8.0, 9.0]));
        });

        test('with the expected column dimensions', () {
          expect(subMatrix.columnDimension, equals(2));
        });
      });
    });

    group('rowAt', () {
      test('throws an error when trying to access an out of bounds row', () {
        var matrix = new Matrix([1.0, 2.0, 3.0,
                                 4.0, 5.0, 6.0,
                                 7.0, 8.0, 9.0], 3);

        expect(() => matrix.rowAt(3), throwsRangeError);
      });

      test('returns the correct row', () {
        var matrix = new Matrix([1.0, 2.0, 3.0,
                                 4.0, 5.0, 6.0,
                                 7.0, 8.0, 9.0], 3);

        expect(matrix.rowAt(1), equals([4.0, 5.0, 6.0]));
      });
    });

    group('entrywiseSum', () {
      test('differing dimensions', () {
        var m1 = new Matrix([0.0, 1.0, 2.0,
                             3.0, 4.0, 5.0,
                             6.0, 7.0, 8.0], 3);
        var m2 = new Matrix([8.0, 7.0, 6.0,
                             5.0, 4.0, 3.0], 3);

        expect(() => m1.entrywiseSum(m2), throwsArgumentError);
      });

      test('valid dimensions', () {
        var m1 = new Matrix([0.0, 1.0, 2.0,
                             3.0, 4.0, 5.0,
                             6.0, 7.0, 8.0], 3);
        var m2 = new Matrix([8.0, 7.0, 6.0,
                             5.0, 4.0, 3.0,
                             2.0, 1.0, 0.0], 3);
        var e = [8.0, 8.0, 8.0,
                 8.0, 8.0, 8.0,
                 8.0, 8.0, 8.0];

        expect(m1.entrywiseSum(m2).values.toList(), equals(e));
      });
    });

    group('entrywiseDifference', () {
      test('differing dimensions', () {
        var m1 = new Matrix([0.0, 1.0, 2.0,
                             3.0, 4.0, 5.0,
                             6.0, 7.0, 8.0], 3);
        var m2 = new Matrix([8.0, 7.0, 6.0,
                             5.0, 4.0, 3.0], 3);

        expect(() => m1.entrywiseDifference(m2), throwsArgumentError);
      });

      test('valid dimensions', () {
        var m1 = new Matrix([0.0, 1.0, 2.0,
                             3.0, 4.0, 5.0,
                             6.0, 7.0, 8.0], 3);
        var m2 = new Matrix([0.0, 1.0, 2.0,
                             3.0, 4.0, 5.0,
                             6.0, 7.0, 8.0], 3);
        var e = [0.0, 0.0, 0.0,
                 0.0, 0.0, 0.0,
                 0.0, 0.0, 0.0];

        expect(m1.entrywiseDifference(m2).values.toList(), equals(e));
      });
    });

    test('scalarProduct', () {
      var m = new Matrix([1.0, 1.0, 1.0,
                          1.0, 1.0, 1.0,
                          1.0, 1.0, 1.0], 3);
      var e = [3.0, 3.0, 3.0,
               3.0, 3.0, 3.0,
               3.0, 3.0, 3.0];

      expect(m.scalarProduct(3).values.toList(), equals(e));
    });

    group('matrixProduct', () {
      test('matrix dimensions are not in agreement', () {
        var m1 = new Matrix([1.0, 2.0, 3.0,
                             4.0, 5.0, 6.0], 3);
        var m2 = new Matrix([1.0, 2.0, 3.0,
                             4.0, 5.0, 6.0], 3);

        expect(() => m1.matrixProduct(m2), throwsArgumentError);
      });

      test('identity matrix', () {
        var m1 = new Matrix([1.0, 2.0, 3.0,
                             4.0, 5.0, 6.0], 3);
        var m2 = new Matrix.identity(3);
        var e = [1.0, 2.0, 3.0,
                 4.0, 5.0, 6.0];

        expect(m1.matrixProduct(m2).columnDimension, equals(3));
        expect(m1.matrixProduct(m2).values.toList(), equals(e));
      });

      test('valid dimensions', () {
        var m1 = new Matrix([ 2.0,  1.0,
                              0.0, -1.0,
                             -2.0,  3.0,
                             -1.0,  0.0], 2);
        var m2 = new Matrix([ 1.0, 0.0, 3.0,
                             -2.0, 1.0, 5.0], 3);
        var e = [ 0.0,  1.0, 11.0,
                  2.0, -1.0, -5.0,
                 -8.0,  3.0,  9.0,
                 -1.0,  0.0, -3.0];

        expect(m1.matrixProduct(m2).columnDimension, equals(3));
        expect(m1.matrixProduct(m2).values.toList(), equals(e));
      });
    });

    test('transpose', () {
      var m = new Matrix([0.0, 1.0, 2.0,
                          3.0, 4.0, 5.0], 3);
      var e = [0.0, 3.0,
               1.0, 4.0,
               2.0, 5.0];

      expect(m.transpose.columnDimension, equals(2));
      expect(m.transpose.values.toList(), equals(e));
    });

    group('solve', () {
      test('throws error if row dimensions do not match', () {
        var sourceMatrix = new Matrix([ 2.0,  1.0,
                                        0.0, -1.0,
                                       -2.0,  3.0,
                                       -1.0,  0.0], 2);
        var targetMatrix = new Matrix([ 0.0,  1.0, 11.0,
                                        2.0, -1.0, -5.0,
                                       -8.0,  3.0,  9.0], 3);

        expect(() => sourceMatrix.solve(targetMatrix), throwsArgumentError);
      });

      test('throws error if the matrix is square and singular', () {
        var sourceMatrix = new Matrix([0.0, 0.0,
                                       0.0, 1.0], 2);
        var targetMatrix = new Matrix([0.0,  1.0, 11.0,
                                       2.0, -1.0, -5.0], 3);

        expect(() => sourceMatrix.solve(targetMatrix), throwsUnsupportedError);
      });

      test('throws error if the matrix has more columns than rows', () {
        var sourceMatrix = new Matrix([1.0, 2.0, 3.0,
                                       4.0, 5.0, 6.0], 3);
        var targetMatrix = new Matrix([0.0,  1.0, 11.0,
                                       2.0, -1.0, -5.0], 3);

        expect(() => sourceMatrix.solve(targetMatrix), throwsUnsupportedError);
      });

      test('verify solution X for `AX = A` is identity', () {
        var matrix = new Matrix([6.0,  1.0, 1.0,
                                 4.0, -2.0, 5.0,
                                 2.0,  8.0, 7.0], 3);
        var solution = matrix.solve(matrix);

        expect(solution.values, pairWiseDifferenceLessThan(new Matrix.identity(3).values.toList(), 0.00001));
        expect(solution.columnDimension, equals(3));
      });

      test('verify `AX = B`, for the solution X and matrix A:\n   3 2\n  -6 6\n And matrix B:\n  7\n  6', () {
        var sourceMatrix = new Matrix([ 3.0, 2.0,
                                       -6.0, 6.0], 2);
        var targetMatrix = new Matrix([7.0,
                                       6.0], 1);
        var solution = sourceMatrix.solve(targetMatrix);
        var product = sourceMatrix * solution;

        expect(product.values, pairWiseDifferenceLessThan(targetMatrix.values.toList(), 0.00001));
      });

      test('verify `AX = B`, for the solution X and matrix A:\n  6 3 0\n  2 5 1\n  9 8 6\n And matrix B:\n   60 45\n   49 43\n  141 92', () {
        var sourceMatrix = new Matrix([6.0, 3.0, 0.0,
                                       2.0, 5.0, 1.0,
                                       9.0, 8.0, 6.0], 3);
        var targetMatrix = new Matrix([ 60.0, 45.0,
                                        49.0, 43.0,
                                       141.0, 92.0], 2);
        var solution = sourceMatrix.solve(targetMatrix);
        var product = sourceMatrix * solution;

        expect(product.values, pairWiseDifferenceLessThan(targetMatrix.values.toList(), 0.00001));
      });

      test('verify `AX = B`, for the solution X and matrix A:\n  4 0\n  0 2\n  1 6\n And matrix B:\n  92 40\n  18  8\n  59 26', () {
        var sourceMatrix = new Matrix([4.0, 8.0,
                                       0.0, 2.0,
                                       1.0, 6.0], 2);
        var targetMatrix = new Matrix([92.0, 40.0,
                                       18.0,  8.0,
                                       59.0, 26.0], 2);
        var solution = sourceMatrix.solve(targetMatrix);
        var product = sourceMatrix * solution;

        expect(product.values, pairWiseDifferenceLessThan(targetMatrix.values.toList(), 0.00001));
      });
    });

    group('solveTranspose', () {
      test('throws error when the matrix has more rows than columns', () {
        var sourceMatrix = new Matrix([4.0, 8.0,
                                       0.0, 2.0,
                                       1.0, 6.0], 2);
        var targetMatrix = new Matrix([92.0, 40.0,
                                       18.0,  8.0,
                                       59.0, 26.0], 2);

        expect(() => sourceMatrix.solveTranspose(targetMatrix), throwsUnsupportedError);
      });

      test('verify `XA = B`, for the solution X and matrix A:\n  6 3 0\n  2 5 1\n  9 8 6\n And matrix B:\n  60 45 141\n  49 43  92', () {
        var sourceMatrix = new Matrix([6.0, 3.0, 0.0,
                                       2.0, 5.0, 1.0,
                                       9.0, 8.0, 6.0], 3);
        var targetMatrix = new Matrix([60.0, 45.0, 141.0,
                                       49.0, 43.0,  92.0], 3);
        var solution = sourceMatrix.solveTranspose(targetMatrix);
        var product = solution * sourceMatrix;

        expect(product.values, pairWiseDifferenceLessThan(targetMatrix.values.toList(), 0.00001));
      });
    });

    group('inverse', () {
      test('throws an error if the matrix is not square', () {
        var matrix = new Matrix([1.0, 2.0, 3.0,
                                 4.0, 5.0, 6.0], 3);

        expect(() => matrix.inverse, throwsUnsupportedError);
      });

      test('throws an error if the matrix is square and singular', () {
        var matrix = new Matrix([0.0, 0.0,
                                 0.0, 0.0], 2);

        expect(() => matrix.inverse, throwsUnsupportedError);
      });

      group('returns the inverse for a non-singular square matrix', () {
        var matrix = new Matrix([2.0, 0.0, 0.0,
                                 1.0, 0.0, 2.0,
                                 4.0, 2.0, 4.0], 3);
        var inverse = matrix.inverse;

        test('with the right column dimension', () {
          expect(inverse.columnDimension, equals(3));
        });

        test('with the right values', () {
          expect(inverse.values.toList(), equals([0.5, 0.0, 0.0, -0.5, -1.0, 0.5, -0.25, 0.5, 0.0]));
        });
      });
    });

    group('+ operator', () {
      test('differing dimensions', () {
        var m1 = new Matrix([0.0, 1.0, 2.0,
                             3.0, 4.0, 5.0,
                             6.0, 7.0, 8.0], 3);
        var m2 = new Matrix([8.0, 7.0, 6.0,
                             5.0, 4.0, 3.0], 3);

        expect(() => m1 + m2, throwsArgumentError);
      });

      test('valid dimensions', () {
        var m1 = new Matrix([0.0, 1.0, 2.0,
                             3.0, 4.0, 5.0,
                             6.0, 7.0, 8.0], 3);
        var m2 = new Matrix([8.0, 7.0, 6.0,
                             5.0, 4.0, 3.0,
                             2.0, 1.0, 0.0], 3);
        var e = [8.0, 8.0, 8.0,
                 8.0, 8.0, 8.0,
                 8.0, 8.0, 8.0];

        expect((m1 + m2).values.toList(), equals(e));
      });
    });

    group('- operator', () {
      test('differing dimensions', () {
        var m1 = new Matrix([0.0, 1.0, 2.0,
                             3.0, 4.0, 5.0,
                             6.0, 7.0, 8.0], 3);
        var m2 = new Matrix([8.0, 7.0, 6.0,
                             5.0, 4.0, 3.0], 3);

        expect(() => m1 - m2, throwsArgumentError);
      });

      test('valid dimensions', () {
        var m1 = new Matrix([0.0, 1.0, 2.0,
                             3.0, 4.0, 5.0,
                             6.0, 7.0, 8.0], 3);
        var m2 = new Matrix([0.0, 1.0, 2.0,
                             3.0, 4.0, 5.0,
                             6.0, 7.0, 8.0], 3);
        var e = [0.0, 0.0, 0.0,
                 0.0, 0.0, 0.0,
                 0.0, 0.0, 0.0];

        expect((m1 - m2).values.toList(), equals(e));
      });
    });

    group('* operator', () {
      test('with a num value', () {
        var m = new Matrix([1.0, 1.0, 1.0,
                            1.0, 1.0, 1.0,
                            1.0, 1.0, 1.0], 3);
        var e = [3.0, 3.0, 3.0,
                 3.0, 3.0, 3.0,
                 3.0, 3.0, 3.0];

        expect((m * 3).values.toList(), equals(e));
      });

      group('with a matrix value', () {
        test('matrix dimensions are not in agreement', () {
          var m1 = new Matrix([1.0, 2.0, 3.0,
                               4.0, 5.0, 6.0], 3);
          var m2 = new Matrix([1.0, 2.0, 3.0,
                               4.0, 5.0, 6.0], 3);

          expect(() => m1 * m2, throwsArgumentError);
        });

        test('valid dimensions', () {
          var m1 = new Matrix([ 2.0,  1.0,
                                0.0, -1.0,
                               -2.0,  3.0,
                               -1.0,  0.0], 2);
          var m2 = new Matrix([ 1.0, 0.0, 3.0,
                               -2.0, 1.0, 5.0], 3);
          var e = [ 0.0,  1.0, 11.0,
                    2.0, -1.0, -5.0,
                   -8.0,  3.0,  9.0,
                   -1.0,  0.0, -3.0];

          expect((m1 * m2).columnDimension, equals(3));
          expect((m1 * m2).values, equals(e));
        });
      });
    });

    group('[] operator', () {
      test('throws an error when trying to access an out of bounds row', () {
        var matrix = new Matrix([1.0, 2.0, 3.0,
                                 4.0, 5.0, 6.0,
                                 7.0, 8.0, 9.0], 3);

        expect(() => matrix[3], throwsRangeError);
      });

      test('returns the correct row', () {
        var matrix = new Matrix([1.0, 2.0, 3.0,
                                 4.0, 5.0, 6.0,
                                 7.0, 8.0, 9.0], 3);

        expect(matrix[1], equals([4.0, 5.0, 6.0]));
      });

      test('allows chaining with another [] operator to return a specific value', () {
        var matrix = new Matrix([1.0, 2.0, 3.0,
                                 4.0, 5.0, 6.0,
                                 7.0, 8.0, 9.0], 3);

        expect(matrix[1][2], equals(6.0));
      });
    });

    group('== operator', () {
      test('returns false for matrices of differing dimensions', () {
        var matrix1 = new Matrix([1.0, 2.0, 3.0,
                                  4.0, 5.0, 6.0], 3);
        var matrix2 = new Matrix([1.0, 2.0,
                                  3.0, 4.0,
                                  5.0, 6.0], 2);

        expect(matrix1 == matrix2, equals(false));
      });

      test('returns false for matrices of equal dimensions with different values', () {
        var matrix1 = new Matrix([1.0, 2.0, 3.0,
                                  4.0, 5.0, 6.0], 3);
        var matrix2 = new Matrix([1.0, 2.0, 3.0,
                                  4.0, 5.0, 7.0], 3);

        expect(matrix1 == matrix2, equals(false));
      });

      test('returns true for matrices of equal dimensions with the same values', () {
        var matrix1 = new Matrix([1.0, 2.0, 3.0,
                                  4.0, 5.0, 6.0], 3);
        var matrix2 = new Matrix([1.0, 2.0, 3.0,
                                  4.0, 5.0, 6.0], 3);

        expect(matrix1 == matrix2, equals(true));
      });
    });
  });
}
