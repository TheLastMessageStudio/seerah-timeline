class Pos {
  const Pos(this.c, this.r);
  final int c;
  final int r;

  int dist(Pos o) => (c - o.c).abs() + (r - o.r).abs();
  List<Pos> get neighbors =>
      [Pos(c + 1, r), Pos(c - 1, r), Pos(c, r + 1), Pos(c, r - 1)];

  /// Chess-like label, e.g. column 0 row 0 -> "A1".
  String get label {
    String l(int n) => String.fromCharCode(65 + n);
    return '${c < 26 ? l(c) : 'A${l(c - 26)}'}${r + 1}';
  }

  @override
  bool operator ==(Object other) =>
      other is Pos && other.c == c && other.r == r;

  @override
  int get hashCode => Object.hash(c, r);

  @override
  String toString() => label;
}

