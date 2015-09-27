/// Provides an immutable implementation for matrices of real numbers in Dart,
/// based on Java's [JAMA package](http://math.nist.gov/javanumerics/jama/).
///
/// Defines a [Matrix] class which can be used for expressing matrices of
/// arbitrary dimensions.
///
/// Also provides a [GenericMatrix] class, which can be extended to define
/// custom classes for specific matrix dimensions.
library rl_matrix;

import 'package:collection/equality.dart';
import 'package:collection/wrappers.dart';
import 'dart:math';
import 'dart:typed_data';

part 'src/matrix.dart';
part 'src/pivoting_lu_decomposition.dart';
part 'src/reduced_qr_decomposition.dart';
