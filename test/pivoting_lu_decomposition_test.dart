import 'package:test/test.dart';
import 'package:rl-matrix/matrix.dart';
import 'helpers.dart';

void main() {
  group('Lower-upper factor decomposition with pivoting:', () {
    group('isNonsingular', () {
      test('throws an error is the matrix is not square', () {
        var matrix = new Matrix([6,  1,
                                 4, -2,
                                 2,  8], 2);
        var LU = new PivotingLUDecomposition(matrix);

        expect(() => LU.isNonsingular, throwsUnsupportedError);
      });

      group('is true for non-singular matrix:', () {
        test('\n  0 1\n  1 0', () {
          var matrix = new Matrix([0, 1,
                                   1, 0], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isTrue);
        });

        test('\n  0 1\n  1 1', () {
          var matrix = new Matrix([0, 1,
                                   1, 1], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isTrue);
        });

        test('\n  1 0\n  0 1', () {
          var matrix = new Matrix([1, 0,
                                   0, 1], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isTrue);
        });

        test('\n  1 0\n  1 1', () {
          var matrix = new Matrix([1, 0,
                                   1, 1], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isTrue);
        });

        test('\n  1 1\n  1 0', () {
          var matrix = new Matrix([1, 1,
                                   1, 0], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isTrue);
        });

        test('\n  1 1\n  0 1', () {
          var matrix = new Matrix([1, 1,
                                   0, 1], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isTrue);
        });
      });

      group('is false for singular matrix:', () {
        test('\n  0 0\n  0 0', () {
          var matrix = new Matrix([0, 0,
                                   0, 0], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isFalse);
        });

        test('\n  0 0\n  0 1', () {
          var matrix = new Matrix([0, 0,
                                   0, 1], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isFalse);
        });

        test('\n  0 0\n  1 0', () {
          var matrix = new Matrix([0, 0,
                                   1, 0], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isFalse);
        });

        test('\n  0 1\n  0 0', () {
          var matrix = new Matrix([0, 1,
                                   0, 0], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isFalse);
        });

        test('\n  1 0\n  0 0', () {
          var matrix = new Matrix([1, 0,
                                   0, 0], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isFalse);
        });

        test('\n  1 1\n  0 0', () {
          var matrix = new Matrix([1, 1,
                                   0, 0], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isFalse);
        });

        test('\n  1 0\n  1 0', () {
          var matrix = new Matrix([1, 0,
                                   1, 0], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isFalse);
        });

        test('\n  0 1\n  0 1', () {
          var matrix = new Matrix([0, 1,
                                   0, 1], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isFalse);
        });

        test('\n  0 0\n  1 1', () {
          var matrix = new Matrix([0, 0,
                                   1, 1], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isFalse);
        });

        test('\n  1 1\n  1 1', () {
          var matrix = new Matrix([1, 1,
                                   1, 1], 2);
          var LU = new PivotingLUDecomposition(matrix);

          expect(LU.isNonsingular, isFalse);
        });
      });
    });

    group('verify `pivotMatrix * sourceMatrix = lowerFactor * upperFactor`', () {
      test('for matrix:\n  4 3\n  6 3', () {
        var sourceMatrix = new Matrix([4, 3,
                                       6, 3], 2);
        var LU = new PivotingLUDecomposition(sourceMatrix);
        var pivotedSource = LU.pivotMatrix * sourceMatrix;
        var product = LU.lowerFactor * LU.upperFactor;

        expect(product.values, pairWiseDifferenceLessThan(pivotedSource.values, 0.0000000001));
      });

      test('for matrix:\n  1 2  4\n  3 8 14\n  2 6 13', () {
        var sourceMatrix = new Matrix([1, 2,  4,
                                       3, 8, 14,
                                       2, 6, 13], 3);
        var LU = new PivotingLUDecomposition(sourceMatrix);
        var pivotedSource = LU.pivotMatrix * sourceMatrix;
        var product = LU.lowerFactor * LU.upperFactor;

        expect(product.values, pairWiseDifferenceLessThan(pivotedSource.values, 0.0000000001));
      });

      test('for matrix:\n   2  5 3  5\n   4  6 6  3\n  11  3 2 -2\n   4 -7 9  3', () {
        var sourceMatrix = new Matrix([ 2,  5, 3,  5,
                                        4,  6, 6,  3,
                                       11,  3, 2, -2,
                                        4, -7, 9,  3], 4);
        var LU = new PivotingLUDecomposition(sourceMatrix);
        var pivotedSource = LU.pivotMatrix * sourceMatrix;
        var product = LU.lowerFactor * LU.upperFactor;

        expect(product.values, pairWiseDifferenceLessThan(pivotedSource.values, 0.0000000001));
      });
    });

    group('determinant', () {
      test('throws an error is the matrix is not square', () {
        var matrix = new Matrix([6,  1,
                                 4, -2,
                                 2,  8], 2);
        var LU = new PivotingLUDecomposition(matrix);

        expect(() => LU.determinant, throwsUnsupportedError);
      });

      test('is -14 for matrix:\n  3 8\n  4 6', () {
        var matrix = new Matrix([3, 8,
                                 4, 6], 2);
        var LU = new PivotingLUDecomposition(matrix);

        expect((LU.determinant + 14).abs(), lessThan(0.0000000001));
      });

      test('is -306 for matrix:\n  6  1 1\n  4 -2 5\n  2  8 7', () {
        var matrix = new Matrix([6,  1, 1,
                                 4, -2, 5,
                                 2,  8, 7], 3);
        var LU = new PivotingLUDecomposition(matrix);

        expect((LU.determinant + 306).abs(), lessThan(0.0000000001));
      });

      test('is 2960 for matrix:\n   2  5 3  5\n   4  6 6  3\n  11  3 2 -2\n   4 -7 9  3', () {
        var matrix = new Matrix([ 2,  5, 3,  5,
                                  4,  6, 6,  3,
                                 11,  3, 2, -2,
                                  4, -7, 9,  3], 4);
        var LU = new PivotingLUDecomposition(matrix);

        expect((LU.determinant - 2960).abs(), lessThan(0.0000000001));
      });
    });

    group('solve', () {
      test('throws error when row dimensions do not agree', () {
        var sourceMatrix = new Matrix([ 2,  1,
                                        0, -1,
                                       -2,  3,
                                       -1,  0], 2);
        var targetMatrix = new Matrix([ 0,  1, 11,
                                        2, -1, -5,
                                       -8,  3,  9], 3);
        var sourceLU = new PivotingLUDecomposition(sourceMatrix);

        expect(() => sourceLU.solve(targetMatrix), throwsArgumentError);
      });

      test('throws error when the matrix is singular', () {
        var sourceMatrix = new Matrix([0, 0,
                                       0, 1], 2);
        var targetMatrix = new Matrix([ 0,  1, 11,
                                        2, -1, -5], 3);
        var sourceLU = new PivotingLUDecomposition(sourceMatrix);

        expect(() => sourceLU.solve(targetMatrix), throwsUnsupportedError);
      });

      test('throws error when the matrix is not square', () {
        var sourceMatrix = new Matrix([ 2,  1,
                                        0, -1,
                                       -2,  3,
                                       -1,  0], 2);
        var targetMatrix = new Matrix([ 0,  1, 11,
                                        2, -1, -5,
                                       -8,  3,  9,
                                       -1,  0, -3], 3);
        var sourceLU = new PivotingLUDecomposition(sourceMatrix);

        expect(() => sourceLU.solve(targetMatrix), throwsUnsupportedError);
      });

      test('verify solution X for `AX = A` is identity', () {
        var matrix = new Matrix([6,  1, 1,
                                 4, -2, 5,
                                 2,  8, 7], 3);
        var LU = new PivotingLUDecomposition(matrix);
        var solution = LU.solve(matrix);

        expect(solution.values, equals(new Matrix.identity(3).values));
        expect(solution.columnDimension, equals(3));
      });

      test('verify `AX = B`, for the solution X and matrix A:\n   3 2\n  -6 6\n And matrix B:\n  7\n  6', () {
        var sourceMatrix = new Matrix([ 3, 2,
                                       -6, 6], 2);
        var targetMatrix = new Matrix([7,
                                       6], 1);
        var sourceLU = new PivotingLUDecomposition(sourceMatrix);
        var solution = sourceLU.solve(targetMatrix);
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

        var sourceLU = new PivotingLUDecomposition(sourceMatrix);
        var solution = sourceLU.solve(targetMatrix);
        var product = sourceMatrix * solution;

        expect(product.values, pairWiseDifferenceLessThan(targetMatrix.values, 0.0000000001));
      });
    });
  });
}
