import 'dart:math';

import 'pdf_page_graphics.dart';

class PdfMatrix {
  const PdfMatrix(this.a, this.b, this.c, this.d, this.e, this.f);

  const PdfMatrix.identity() : this(1, 0, 0, 1, 0, 0);

  const PdfMatrix.translation(double x, double y) : this(1, 0, 0, 1, x, y);

  final double a;
  final double b;
  final double c;
  final double d;
  final double e;
  final double f;

  PdfMatrix then(PdfMatrix outer) => PdfMatrix(
    a * outer.a + b * outer.c,
    a * outer.b + b * outer.d,
    c * outer.a + d * outer.c,
    c * outer.b + d * outer.d,
    e * outer.a + f * outer.c + outer.e,
    e * outer.b + f * outer.d + outer.f,
  );

  PdfPoint transform(double x, double y) =>
      PdfPoint(a * x + c * y + e, b * x + d * y + f);

  double get horizontalScale => sqrt(a * a + b * b);

  double get averageScale => sqrt((a * d - b * c).abs());
}
