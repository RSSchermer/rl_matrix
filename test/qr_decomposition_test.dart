import 'package:test/test.dart';
import 'package:rl-matrix/matrix.dart';
import 'helpers.dart';

void main() {
  group('QR decomposition', () {
    group('isFullRank', () {
      test('is true for full rank matrix:\n  1 0 2\n  2 1 0\n  3 2 1', () {
        var matrix = new Matrix([1, 0, 2,
                                 2, 1, 0,
                                 3, 2, 1], 3);
        var QR = new QRDecomposition(matrix);

        expect(QR.isFullRank, equals(true));
      });

      test('is false for rank deficient matrix:\n  1 2 3\n  2 4 6', () {
        var matrix = new Matrix([1, 2, 3,
                                 2, 4, 6], 3);
        var QR = new QRDecomposition(matrix);

        expect(QR.isFullRank, equals(false));
      });
    });

    group('verify `sourceMatrix = orthogonalFactor * upperTriangularFactor`', () {
      test('for matrix:\n   2  5 3\n   4  6 6\n  11  3 2\n   4 -7 9', () {
        var sourceMatrix = new Matrix([ 2,  5, 3,
                                        4,  6, 6,
                                       11,  3, 2,
                                        4, -7, 9], 3);
        var QR = new QRDecomposition(sourceMatrix);
        var product = QR.orthogonalFactor * QR.upperTriangularFactor;

        expect(product.values, pairWiseDifferenceLessThan(sourceMatrix.values, 0.0000000001));
      });

      test('for matrix:\n   2  5 3  4\n   4  6 6 -7\n  11  3 2  9', () {
        var sourceMatrix = new Matrix([ 2,  5, 3,  4,
                                        4,  6, 6, -7,
                                       11,  3, 2,  9], 4);
        var QR = new QRDecomposition(sourceMatrix);
        var product = QR.orthogonalFactor * QR.upperTriangularFactor;

        expect(product.values, pairWiseDifferenceLessThan(sourceMatrix.values, 0.0000000001));
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
        var sourceQR = new QRDecomposition(sourceMatrix);

        expect(() => sourceQR.solve(targetMatrix), throwsArgumentError);
      });

      test('throws error when the matrix is rank deficient', () {
        var sourceMatrix = new Matrix([1, 2, 3,
                                       2, 4, 6], 3);
        var targetMatrix = new Matrix([ 0,  1, 11,
                                        2, -1, -5], 3);
        var sourceQR = new QRDecomposition(sourceMatrix);

        expect(() => sourceQR.solve(targetMatrix), throwsUnsupportedError);
      });

      test('verify solution X for `AX = A` is identity', () {
        var matrix = new Matrix([6,  1,
                                 4, -2,
                                 2,  8], 2);
        var QR = new QRDecomposition(matrix);
        var solution = QR.solve(matrix);

        expect(solution.values, pairWiseDifferenceLessThan(new Matrix.identity(2).values, 0.0000000001));
        expect(solution.columnDimension, equals(2));
      });

      test('verify `AX = B`, for the solution X and matrix A:\n  4 0\n  0 2\n  1 6\n And matrix B:\n  92 40\n  18  8\n  59 26', () {
        var sourceMatrix = new Matrix([4, 8,
                                       0, 2,
                                       1, 6], 2);
        var targetMatrix = new Matrix([92, 40,
                                       18,  8,
                                       59, 26], 2);
        var sourceQR = new QRDecomposition(sourceMatrix);
        var solution = sourceQR.solve(targetMatrix);
        var product = sourceMatrix * solution;

        expect(product.values, pairWiseDifferenceLessThan(targetMatrix.values, 0.0000000001));
      });
    });
  });
}
