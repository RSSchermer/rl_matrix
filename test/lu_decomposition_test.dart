import 'package:unittest/unittest.dart';
import 'package:rl-matrix/matrix.dart';

void main() {
  group('LUDecomposition', () {
    group('isNonsingular', () {
      group('2x2', () {
        group('non-singular', () {
          test('[0, 1, 1, 0]', () {
            var LU = new LUDecomposition(new Matrix([0, 1, 1, 0], 2));

            expect(LU.isNonsingular, isTrue);
          });

          test('[0, 1, 1, 1]', () {
            var LU = new LUDecomposition(new Matrix([0, 1, 1, 1], 2));

            expect(LU.isNonsingular, isTrue);
          });

          test('[1, 0, 0, 1]', () {
            var LU = new LUDecomposition(new Matrix([1, 0, 0, 1], 2));

            expect(LU.isNonsingular, isTrue);
          });

          test('[1, 0, 1, 1]', () {
            var LU = new LUDecomposition(new Matrix([1, 0, 1, 1], 2));

            expect(LU.isNonsingular, isTrue);
          });

          test('[1, 1, 1, 0]', () {
            var LU = new LUDecomposition(new Matrix([1, 1, 1, 0], 2));

            expect(LU.isNonsingular, isTrue);
          });

          test('[1, 1, 0, 1]', () {
            var LU = new LUDecomposition(new Matrix([1, 1, 0, 1], 2));

            expect(LU.isNonsingular, isTrue);
          });
        });

        group('singular', () {
          test('[0, 0, 0, 0]', () {
            var LU = new LUDecomposition(new Matrix([0, 0, 0, 0], 2));

            expect(LU.isNonsingular, isFalse);
          });

          test('[0, 0, 0, 1]', () {
            var LU = new LUDecomposition(new Matrix([0, 0, 0, 1], 2));

            expect(LU.isNonsingular, isFalse);
          });

          test('[0, 0, 1, 0]', () {
            var LU = new LUDecomposition(new Matrix([0, 0, 1, 0], 2));

            expect(LU.isNonsingular, isFalse);
          });

          test('[0, 1, 0, 0]', () {
            var LU = new LUDecomposition(new Matrix([0, 1, 0, 0], 2));

            expect(LU.isNonsingular, isFalse);
          });

          test('[1, 0, 0, 0]', () {
            var LU = new LUDecomposition(new Matrix([1, 0, 0, 0], 2));

            expect(LU.isNonsingular, isFalse);
          });

          test('[1, 1, 0, 0]', () {
            var LU = new LUDecomposition(new Matrix([1, 1, 0, 0], 2));

            expect(LU.isNonsingular, isFalse);
          });

          test('[1, 0, 1, 0]', () {
            var LU = new LUDecomposition(new Matrix([1, 0, 1, 0], 2));

            expect(LU.isNonsingular, isFalse);
          });

          test('[0, 1, 0, 1]', () {
            var LU = new LUDecomposition(new Matrix([0, 1, 0, 1], 2));

            expect(LU.isNonsingular, isFalse);
          });

          test('[0, 0, 1, 1]', () {
            var LU = new LUDecomposition(new Matrix([0, 0, 1, 1], 2));

            expect(LU.isNonsingular, isFalse);
          });

          test('[1, 1, 1, 1]', () {
            var LU = new LUDecomposition(new Matrix([1, 1, 1, 1], 2));

            expect(LU.isNonsingular, isFalse);
          });
        });
      });
    });

    group('lower * upper factor matrix product', () {
      test('2x2 [4, 3, 6, 3]', () {
        var LU = new LUDecomposition(new Matrix([4, 3, 6, 3], 2));
        var product = LU.lowerFactor * LU.upperFactor;

        expect(product.values, equals([4, 3, 6, 3]));
      });

      test('3x3 [1, 2, 4, 3, 8, 14, 2, 6, 13]', () {
        var LU = new LUDecomposition(new Matrix([1, 2, 4, 3, 8, 14, 2, 6, 13], 3));
        var product = LU.lowerFactor * LU.upperFactor;

        expect(product.values, equals([1, 2, 4, 3, 8, 14, 2, 6, 13]));
      });
    });

    group('lowerFactor', () {
      test('2x2 [4, 3, 6, 3]', (){
        var LU = new LUDecomposition(new Matrix([4, 3, 6, 3], 2));

        expect(LU.lowerFactor.values, equals([1, 0, 1.5, 1]));
      });

      test('3x3 [1, 2, 4, 3, 8, 14, 2, 6, 13]', () {
        var LU = new LUDecomposition(new Matrix([1, 2, 4, 3, 8, 14, 2, 6, 13], 3));

        expect(LU.lowerFactor.values, equals([1, 0, 0, 3, 1, 0, 2, 1, 1]));
      });
    });

    group('upperFactor', () {
      test('2x2 [4, 3, 6, 3]', (){
        var LU = new LUDecomposition(new Matrix([4, 3, 6, 3], 2));

        expect(LU.upperFactor.values, equals([4, 3, 0, -1.5]));
      });

      test('3x3 [1, 2, 4, 3, 8, 14, 2, 6, 13]', () {
        var LU = new LUDecomposition(new Matrix([1, 2, 4, 3, 8, 14, 2, 6, 13], 3));

        expect(LU.upperFactor.values, equals([1, 2, 4, 0, 2, 2, 0, 0, 3]));
      });
    });

    group('determinant', () {
      test('2x2 [3, 8, 4, 6]', () {
        var LU = new LUDecomposition(new Matrix([3, 8, 4, 6], 2));

        expect(LU.determinant, equals(-14));
      });

      test('3x3 [6, 1, 1, 4, -2, 5, 2, 8, 7]', () {
        var LU = new LUDecomposition(new Matrix([6, 1, 1, 4, -2, 5, 2, 8, 7], 3));

        expect(LU.determinant, equals(-306));
      });
    });
  });
}
