import 'package:test/test.dart';
import 'package:rl_matrix/rl_matrix.dart';
import 'helpers.dart';

void main() {
  group('Matrix', () {
    group('constructors', () {
      test('strict value list length checking', () {
        expect(() => new Matrix([1, 2], 3), throwsArgumentError);
        expect(() => new Matrix([1, 2, 3, 4], 3), throwsArgumentError);
      });

      test('constant matrix', () {
        var m = new Matrix.constant(6, 3, 2);
        var e = [6, 6, 6,
                 6, 6, 6];

        expect(m.values, equals(e));
      });

      test('zero matrix', () {
        var m = new Matrix.zero(3, 3);
        var e = [0, 0, 0,
                 0, 0, 0,
                 0, 0, 0];

        expect(m.values, equals(e));
      });

      test('identity matrix', () {
        var m = new Matrix.identity(3);
        var e = [1, 0, 0,
                 0, 1, 0,
                 0, 0, 1];

        expect(m.values, equals(e));
      });
    });

    group('rowDimension', () {
      test('1 x 3', () {
        var m = new Matrix([1, 2, 3], 3);

        expect(m.rowDimension, equals(1));
      });
    });

    group('isSquare', () {
      test('2 x 3', () {
        var m = new Matrix.constant(1, 2, 3);

        expect(m.isSquare, isFalse);
      });

      test('3 x 3', () {
        var m = new Matrix.constant(1, 3, 3);

        expect(m.isSquare, isTrue);
      });
    });

    test('values', () {
      var m = new Matrix([0, 1, 2,
                          3, 4, 5], 3);

      expect(m.values, equals([0, 1, 2, 3, 4, 5]));
    });

    group('valueAt', () {
      var m = new Matrix([0, 1, 2,
                          3, 4, 5], 3);

      test('(0, 0)', () {
        expect(m.valueAt(0, 0), equals(0));
      });

      test('(0, 2)', () {
        expect(m.valueAt(0, 2), equals(2));
      });

      test('(1, 0)', () {
        expect(m.valueAt(1, 0), equals(3));
      });

      test('(1, 2)', () {
        expect(m.valueAt(1, 2), equals(5));
      });
    });

    test('valuesColumnPacked', () {
      var m = new Matrix([1, 2, 3,
                          1, 2, 3,
                          1, 2, 3], 3);

      expect(m.valuesColumnPacked, equals([1, 1, 1, 2, 2, 2, 3, 3, 3]));
    });

    test('valuesRowPacked', () {
      var m = new Matrix([1, 2, 3,
                          1, 2, 3,
                          1, 2, 3], 3);

      expect(m.valuesRowPacked, equals([1, 2, 3, 1, 2, 3, 1, 2, 3]));
    });

    group('subMatrix', () {
      test('throws and error when the starting row index is greater than the ending row index', () {
        var m = new Matrix([1, 2, 3,
                            1, 2, 3,
                            1, 2, 3], 3);

        expect(() => m.subMatrix(1, 0, 0, 2), throwsArgumentError);
      });

      test('throws and error when the starting column index is greater than the ending column index', () {
        var m = new Matrix([1, 2, 3,
                            1, 2, 3,
                            1, 2, 3], 3);

        expect(() => m.subMatrix(0, 2, 1, 0), throwsArgumentError);
      });

      group('returns a new matrix', () {
        var m = new Matrix([1, 2, 3,
                            4, 5, 6,
                            7, 8, 9], 3);
        var subMatrix = m.subMatrix(1, 2, 1, 2);

        test('with the expected values', () {
          expect(subMatrix.values, equals([5, 6, 8, 9]));
        });

        test('with the expected column dimensions', () {
          expect(subMatrix.columnDimension, equals(2));
        });
      });
    });

    group('entrywiseSum', () {
      test('differing dimensions', () {
        var m1 = new Matrix([0, 1, 2,
                             3, 4, 5,
                             6, 7, 8], 3);
        var m2 = new Matrix([8, 7, 6,
                             5, 4, 3], 3);

        expect(() => m1.entrywiseSum(m2), throwsArgumentError);
      });

      test('valid dimensions', () {
        var m1 = new Matrix([0, 1, 2,
                             3, 4, 5,
                             6, 7, 8], 3);
        var m2 = new Matrix([8, 7, 6,
                             5, 4, 3,
                             2, 1, 0], 3);
        var e = [8, 8, 8,
                 8, 8, 8,
                 8, 8, 8];

        expect(m1.entrywiseSum(m2).values, equals(e));
      });
    });

    group('entrywiseDifference', () {
      test('differing dimensions', () {
        var m1 = new Matrix([0, 1, 2,
                             3, 4, 5,
                             6, 7, 8], 3);
        var m2 = new Matrix([8, 7, 6,
                             5, 4, 3], 3);

        expect(() => m1.entrywiseDifference(m2), throwsArgumentError);
      });

      test('valid dimensions', () {
        var m1 = new Matrix([0, 1, 2,
                             3, 4, 5,
                             6, 7, 8], 3);
        var m2 = new Matrix([0, 1, 2,
                             3, 4, 5,
                             6, 7, 8], 3);
        var e = [0, 0, 0,
                 0, 0, 0,
                 0, 0, 0];

        expect(m1.entrywiseDifference(m2).values, equals(e));
      });
    });

    test('scalarProduct', () {
      var m = new Matrix([1, 1, 1,
                          1, 1, 1,
                          1, 1, 1], 3);
      var e = [3, 3, 3,
               3, 3, 3,
               3, 3, 3];

      expect(m.scalarProduct(3).values, equals(e));
    });

    group('matrixProduct', () {
      test('matrix dimensions are not in agreement', () {
        var m1 = new Matrix([1, 2, 3,
                             4, 5, 6], 3);
        var m2 = new Matrix([1, 2, 3,
                             4, 5, 6], 3);

        expect(() => m1.matrixProduct(m2), throwsArgumentError);
      });

      test('identity matrix', () {
        var m1 = new Matrix([1, 2, 3,
                             4, 5, 6], 3);
        var m2 = new Matrix.identity(3);
        var e = [1, 2, 3,
                 4, 5, 6];

        expect(m1.matrixProduct(m2).columnDimension, equals(3));
        expect(m1.matrixProduct(m2).values, equals(e));
      });

      test('valid dimensions', () {
        var m1 = new Matrix([ 2,  1,
                              0, -1,
                             -2,  3,
                             -1,  0], 2);
        var m2 = new Matrix([ 1, 0, 3,
                             -2, 1, 5], 3);
        var e = [ 0,  1, 11,
                  2, -1, -5,
                 -8,  3,  9,
                 -1,  0, -3];

        expect(m1.matrixProduct(m2).columnDimension, equals(3));
        expect(m1.matrixProduct(m2).values, equals(e));
      });
    });

    test('transpose', () {
      var m = new Matrix([0, 1, 2,
                          3, 4, 5], 3);
      var e = [0, 3,
               1, 4,
               2, 5];

      expect(m.transpose.columnDimension, equals(2));
      expect(m.transpose.values, equals(e));
    });

    group('solve', () {
      test('throws error if row dimensions do not match', () {
        var sourceMatrix = new Matrix([ 2,  1,
                                        0, -1,
                                       -2,  3,
                                       -1,  0], 2);
        var targetMatrix = new Matrix([ 0,  1, 11,
                                        2, -1, -5,
                                       -8,  3,  9], 3);

        expect(() => sourceMatrix.solve(targetMatrix), throwsArgumentError);
      });

      test('throws error if the matrix is square and singular', () {
        var sourceMatrix = new Matrix([0, 0,
                                       0, 1], 2);
        var targetMatrix = new Matrix([0,  1, 11,
                                       2, -1, -5], 3);

        expect(() => sourceMatrix.solve(targetMatrix), throwsUnsupportedError);
      });

      test('throws error if the matrix has more columns than rows', () {
        var sourceMatrix = new Matrix([1, 2, 3,
                                       4, 5, 6], 3);
        var targetMatrix = new Matrix([0,  1, 11,
                                       2, -1, -5], 3);

        expect(() => sourceMatrix.solve(targetMatrix), throwsUnsupportedError);
      });

      test('verify solution X for `AX = A` is identity', () {
        var matrix = new Matrix([6,  1, 1,
                                 4, -2, 5,
                                 2,  8, 7], 3);
        var solution = matrix.solve(matrix);

        expect(solution.values, pairWiseDifferenceLessThan(new Matrix.identity(3).values, 0.0000000001));
        expect(solution.columnDimension, equals(3));
      });

      test('verify `AX = B`, for the solution X and matrix A:\n   3 2\n  -6 6\n And matrix B:\n  7\n  6', () {
        var sourceMatrix = new Matrix([ 3, 2,
                                       -6, 6], 2);
        var targetMatrix = new Matrix([7,
                                       6], 1);
        var solution = sourceMatrix.solve(targetMatrix);
        var product = sourceMatrix * solution;

        expect(product.values, pairWiseDifferenceLessThan(targetMatrix.values, 0.0000000001));
      });

      test('verify `AX = B`, for the solution X and matrix A:\n  6 3 0\n  2 5 1\n  9 8 6\n And matrix B:\n   60 45\n   49 43\n  141 92', () {
        var sourceMatrix = new Matrix([6, 3, 0,
                                       2, 5, 1,
                                       9, 8, 6], 3);
        var targetMatrix = new Matrix([ 60, 45,
                                        49, 43,
                                       141, 92], 2);
        var solution = sourceMatrix.solve(targetMatrix);
        var product = sourceMatrix * solution;

        expect(product.values, pairWiseDifferenceLessThan(targetMatrix.values, 0.0000000001));
      });

      test('verify `AX = B`, for the solution X and matrix A:\n  4 0\n  0 2\n  1 6\n And matrix B:\n  92 40\n  18  8\n  59 26', () {
        var sourceMatrix = new Matrix([4, 8,
                                       0, 2,
                                       1, 6], 2);
        var targetMatrix = new Matrix([92, 40,
                                       18,  8,
                                       59, 26], 2);
        var solution = sourceMatrix.solve(targetMatrix);
        var product = sourceMatrix * solution;

        expect(product.values, pairWiseDifferenceLessThan(targetMatrix.values, 0.0000000001));
      });
    });

    group('solveTranspose', () {
      test('throws error when the matrix has more rows than columns', () {
        var sourceMatrix = new Matrix([4, 8,
                                       0, 2,
                                       1, 6], 2);
        var targetMatrix = new Matrix([92, 40,
                                       18,  8,
                                       59, 26], 2);

        expect(() => sourceMatrix.solveTranspose(targetMatrix), throwsUnsupportedError);
      });

      test('verify `XA = B`, for the solution X and matrix A:\n  6 3 0\n  2 5 1\n  9 8 6\n And matrix B:\n  60 45 141\n  49 43  92', () {
        var sourceMatrix = new Matrix([6, 3, 0,
                                       2, 5, 1,
                                       9, 8, 6], 3);
        var targetMatrix = new Matrix([60, 45, 141,
                                       49, 43,  92], 3);
        var solution = sourceMatrix.solveTranspose(targetMatrix);
        var product = solution * sourceMatrix;

        expect(product.values, pairWiseDifferenceLessThan(targetMatrix.values, 0.0000000001));
      });
    });

    group('inverse', () {
      test('throws an error if the matrix is not square', () {
        var matrix = new Matrix([1, 2, 3,
                                 4, 5, 6], 3);

        expect(() => matrix.inverse, throwsUnsupportedError);
      });

      test('throws an error if the matrix is square and singular', () {
        var matrix = new Matrix([0, 0,
                                 0, 0], 2);

        expect(() => matrix.inverse, throwsUnsupportedError);
      });

      group('returns the inverse for a non-singular square matrix', () {
        var matrix = new Matrix([2, 0, 0,
                                 1, 0, 2,
                                 4, 2, 4], 3);
        var inverse = matrix.inverse;

        test('with the right column dimension', () {
          expect(inverse.columnDimension, equals(3));
        });

        test('with the right values', () {
          expect(inverse.values, equals([0.5, 0, 0, -0.5, -1, 0.5, -0.25, 0.5, 0]));
        });
      });
    });

    group('+ operator', () {
      test('differing dimensions', () {
        var m1 = new Matrix([0, 1, 2,
                             3, 4, 5,
                             6, 7, 8], 3);
        var m2 = new Matrix([8, 7, 6,
                             5, 4, 3], 3);

        expect(() => m1 + m2, throwsArgumentError);
      });

      test('valid dimensions', () {
        var m1 = new Matrix([0, 1, 2,
                             3, 4, 5,
                             6, 7, 8], 3);
        var m2 = new Matrix([8, 7, 6,
                             5, 4, 3,
                             2, 1, 0], 3);
        var e = [8, 8, 8,
                 8, 8, 8,
                 8, 8, 8];

        expect((m1 + m2).values, equals(e));
      });
    });

    group('- operator', () {
      test('differing dimensions', () {
        var m1 = new Matrix([0, 1, 2,
                             3, 4, 5,
                             6, 7, 8], 3);
        var m2 = new Matrix([8, 7, 6,
                             5, 4, 3], 3);

        expect(() => m1 - m2, throwsArgumentError);
      });

      test('valid dimensions', () {
        var m1 = new Matrix([0, 1, 2,
                             3, 4, 5,
                             6, 7, 8], 3);
        var m2 = new Matrix([0, 1, 2,
                             3, 4, 5,
                             6, 7, 8], 3);
        var e = [0, 0, 0,
                 0, 0, 0,
                 0, 0, 0];

        expect((m1 - m2).values, equals(e));
      });
    });

    group('* operator', () {
      test('with a num value', () {
        var m = new Matrix([1, 1, 1,
                            1, 1, 1,
                            1, 1, 1], 3);
        var e = [3, 3, 3,
                 3, 3, 3,
                 3, 3, 3];

        expect((m * 3).values, equals(e));
      });

      group('with a matrix value', () {
        test('matrix dimensions are not in agreement', () {
          var m1 = new Matrix([1, 2, 3,
                               4, 5, 6], 3);
          var m2 = new Matrix([1, 2, 3,
                               4, 5, 6], 3);

          expect(() => m1 * m2, throwsArgumentError);
        });

        test('valid dimensions', () {
          var m1 = new Matrix([ 2,  1,
                                0, -1,
                               -2,  3,
                               -1,  0], 2);
          var m2 = new Matrix([ 1, 0, 3,
                               -2, 1, 5], 3);
          var e = [ 0,  1, 11,
                    2, -1, -5,
                   -8,  3,  9,
                   -1,  0, -3];

          expect((m1 * m2).columnDimension, equals(3));
          expect((m1 * m2).values, equals(e));
        });
      });
    });
  });
}
