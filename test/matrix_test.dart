import 'package:test/test.dart';
import 'package:rl-matrix/matrix.dart';

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
