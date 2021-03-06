/// Immutable implementation for matrices of real numbers in Dart, based on
/// Java's [JAMA package](http://math.nist.gov/javanumerics/jama/).
///
/// Defines a [Matrix] class which can be used for expressing matrices of
/// arbitrary dimensions.
///
/// Also provides a [GenericMatrix] class, which can be extended to define
/// custom classes for specific matrix dimensions.
library rl_matrix_64;

import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

part 'src/rl_matrix_64/matrix.dart';
part 'src/rl_matrix_64/pivoting_lu_decomposition.dart';
part 'src/rl_matrix_64/reduced_qr_decomposition.dart';
