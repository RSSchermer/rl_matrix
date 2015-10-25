import 'package:test/test.dart';
import 'package:rl_matrix/rl_matrix.dart';
import 'helpers.dart';

void main() {
  group('QR decomposition', () {
    group('isFullRank', () {
      test('is true for full rank square matrix:\n  1 0 2\n  2 1 0\n  3 2 1', () {
        var matrix = new Matrix([1.0, 0.0, 2.0,
                                 2.0, 1.0, 0.0,
                                 3.0, 2.0, 1.0], 3);
        var QR = new ReducedQRDecomposition(matrix);

        expect(QR.isFullRank, equals(true));
      });

      test('is true for full rank tall matrix:\n   2  5 3\n   4  6 6\n  11  3 2\n   4 -7 9', () {
        var matrix = new Matrix([ 2.0,  5.0, 3.0,
                                  4.0,  6.0, 6.0,
                                 11.0,  3.0, 2.0,
                                  4.0, -7.0, 9.0], 3);
        var QR = new ReducedQRDecomposition(matrix);

        expect(QR.isFullRank, equals(true));
      });

      test('is false for rank deficient square matrix:\n  1 0 1\n  2 1 3\n  3 2 5', () {
        // Rank deficient because: Column3 = Column1 + Column2
        var matrix = new Matrix([1.0, 0.0, 1.0,
                                 2.0, 1.0, 3.0,
                                 3.0, 2.0, 5.0], 3);
        var QR = new ReducedQRDecomposition(matrix);

        expect(QR.isFullRank, equals(false));
      });

      test('is false for rank deficient tall matrix:\n  1 2 \n  2 4\n  3 6', () {
        // Rank deficient because: Column2 = Column1 * 2
        var matrix = new Matrix([1.0, 2.0,
                                 2.0, 4.0,
                                 3.0, 6.0], 2);
        var QR = new ReducedQRDecomposition(matrix);

        expect(QR.isFullRank, equals(false));
      });

      test('is false for short matrices (with more columns than rows)', () {
        var matrix = new Matrix([1.0, 0.0, 2.0,
                                 2.0, 1.0, 0.0], 3);
        var QR = new ReducedQRDecomposition(matrix);

        expect(QR.isFullRank, equals(false));
      });
    });

    group('upperTriangularFactor', () {
      test('has only zeros below the diagonal', () {
        var matrix = new Matrix([ 2.0,  5.0, 3.0,
                                  4.0,  6.0, 6.0,
                                 11.0,  3.0, 2.0,
                                  4.0, -7.0, 9.0], 3);
        var QL = new ReducedQRDecomposition(matrix);
        var upperTriangularFactor = QL.upperTriangularFactor;

        for (var i = 0; i < upperTriangularFactor.rowDimension; i++) {
          for (var j = 0; j < upperTriangularFactor.columnDimension; j++) {
            if (j < i) {
              expect(upperTriangularFactor.valueAt(i, j), equals(0.0));
            }
          }
        }
      });
    });

    group('verify `sourceMatrix = orthogonalFactor * upperTriangularFactor`', () {
      test('for tall matrix:\n   2  5 3\n   4  6 6\n  11  3 2\n   4 -7 9', () {
        var sourceMatrix = new Matrix([ 2.0,  5.0, 3.0,
                                        4.0,  6.0, 6.0,
                                       11.0,  3.0, 2.0,
                                        4.0, -7.0, 9.0], 3);
        var QR = new ReducedQRDecomposition(sourceMatrix);
        var product = QR.orthogonalFactor * QR.upperTriangularFactor;

        expect(product.values, pairWiseDifferenceLessThan(sourceMatrix.values, 0.00001));
      });
    });

    group('solve', () {
      test('throws error when row dimensions do not agree', () {
        var sourceMatrix = new Matrix([ 2.0,  1.0,
                                        0.0, -1.0,
                                       -2.0,  3.0,
                                       -1.0,  0.0], 2);
        var targetMatrix = new Matrix([ 0.0,  1.0, 11.0,
                                        2.0, -1.0, -5.0,
                                       -8.0,  3.0,  9.0], 3);
        var sourceQR = new ReducedQRDecomposition(sourceMatrix);

        expect(() => sourceQR.solve(targetMatrix), throwsArgumentError);
      });

      test('throws error when the matrix is rank deficient', () {
        var sourceMatrix = new Matrix([1.0, 2.0,
                                       2.0, 4.0,
                                       3.0, 6.0], 2);
        var targetMatrix = new Matrix([0.0,  1.0,
                                       2.0, -1.0,
                                       8.0, 11.0], 2);
        var sourceQR = new ReducedQRDecomposition(sourceMatrix);

        expect(() => sourceQR.solve(targetMatrix), throwsUnsupportedError);
      });

      test('verify solution X for `AX = A` is identity', () {
        var matrix = new Matrix([6.0,  1.0,
                                 4.0, -2.0,
                                 2.0,  8.0], 2);
        var QR = new ReducedQRDecomposition(matrix);
        var solution = QR.solve(matrix);

        expect(solution.values, pairWiseDifferenceLessThan(new Matrix.identity(2).values.toList(), 0.00001));
        expect(solution.columnDimension, equals(2));
      });

      test('verify `AX = B`, for the solution X and matrix A:\n  4 0\n  0 2\n  1 6\n And matrix B:\n  92 40\n  18  8\n  59 26', () {
        var sourceMatrix = new Matrix([4.0, 8.0,
                                       0.0, 2.0,
                                       1.0, 6.0], 2);
        var targetMatrix = new Matrix([92.0, 40.0,
                                       18.0,  8.0,
                                       59.0, 26.0], 2);
        var sourceQR = new ReducedQRDecomposition(sourceMatrix);
        var solution = sourceQR.solve(targetMatrix);
        var product = sourceMatrix * solution;

        expect(product.values, pairWiseDifferenceLessThan(targetMatrix.values, 0.00001));
      });
    });
  });
}
