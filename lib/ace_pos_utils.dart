// ignore_for_file: unnecessary_this

library ace_pos_print;

import 'dart:convert';

import 'package:ace_pos_utils/commands.dart';

enum PosAlign { left, center, right }

class PosPaperSize {
  const PosPaperSize._internal(this.value);
  final int value;
  static const mm58 = PosPaperSize._internal(1);
  static const mm80 = PosPaperSize._internal(2);

  int get width => value == PosPaperSize.mm58.value ? 372 : 558;
}

class PosColumn {
  String text;
  double weight;
  PosSize size;
  PosAlign align;

  PosColumn({
    required this.text,
    this.weight = .33,
    this.size = const PosSize(),
    this.align = PosAlign.left,
  });
}

enum PosFont { fontA, fontB }

class PosSize {
  final bool bold;
  final int width;
  final int height;
  const PosSize({this.bold = false, this.width = 1, this.height = 1});
}

class AcePosPrint {
  final PosPaperSize _paperSize;
  PosFont? _font;

  AcePosPrint(this._paperSize, [this._font = PosFont.fontA]);

  List<int> printCustom(
    String message, {
    PosSize size = const PosSize(),
    PosAlign align = PosAlign.left,
    String? charset,
  }) {
    List<int> bytes = [];
    bytes += _setSize(size);
    bytes += _setAlign(align);
    if (charset != null) {
      bytes += _setFont();
      bytes += Encoding.getByName(charset)?.encode(message) ?? [];
    } else {
      bytes += _setFont();
      bytes += latin1.encode(message);
    }
    bytes += feed();
    return bytes;
  }

  List<int> printLeftRight(String left, String right, {PosSize size = const PosSize(), String? charset}) {
    List<int> bytes = [];
    bytes += _setSize(size);
    bytes += cAlignLeft.codeUnits;
    int width = _charsPerLine(size) ~/ 2;

    String line = left.trimToWidth(width).padRight(width) + right.trimToWidth(width).padLeft(width);

    if (charset != null) {
      bytes += _setFont();
      bytes += Encoding.getByName(charset)?.encode(line) ?? [];
    } else {
      bytes += _setFont();
      bytes += latin1.encode(line);
    }
    bytes += feed();
    return bytes;
  }

  List<int> print3Column(PosColumn col1, PosColumn col2, PosColumn col3, {String? charset}) {
    List<int> bytes = [];

    bytes += cAlignCenter.codeUnits;

    int lineCharacters = _charsPerLine();

    int col1Width = (lineCharacters * col1.weight).toInt() ~/ col1.size.width;
    bytes += _setSize(col1.size);
    final text1 = _setTextAlign(col1.text.trimToWidth(col1Width), col1.align, col1Width);
    if (charset != null) {
      bytes += _setFont();
      bytes += Encoding.getByName(charset)?.encode(text1) ?? [];
    } else {
      bytes += _setFont();
      bytes += latin1.encode(text1);
    }

    int col2Width = (lineCharacters * col2.weight).toInt() ~/ col2.size.width;
    bytes += _setSize(col2.size);
    final line2 = _setTextAlign(col2.text.trimToWidth(col2Width), col2.align, col2Width);

    if (charset != null) {
      bytes += _setFont();
      bytes += Encoding.getByName(charset)?.encode(line2) ?? [];
    } else {
      bytes += _setFont();
      bytes += latin1.encode(line2);
    }

    int col3Width = (lineCharacters * col3.weight).toInt() ~/ col3.size.width;
    bytes += _setSize(col3.size);
    final line3 = _setTextAlign(col3.text.trimToWidth(col3Width), col3.align, col3Width);

    if (charset != null) {
      bytes += _setFont();
      bytes += Encoding.getByName(charset)?.encode(line3) ?? [];
    } else {
      bytes += _setFont();
      bytes += latin1.encode(line3);
    }
    bytes += feed();
    return bytes;
  }

  List<int> row(List<PosColumn> cols, {String? charset}) {
    List<int> bytes = [];
    bool showPrintNewLine = false;
    List<PosColumn> newCols = [];
    for (var col in cols) {
      bytes += cAlignCenter.codeUnits;

      int lineCharacters = _charsPerLine();

      int colWidth = (lineCharacters * col.weight).toInt() ~/ col.size.width;
      bytes += _setSize(col.size);
      final text = _setTextAlign(col.text.trimToWidth(colWidth), col.align, colWidth);
      if (col.text.length > colWidth) {
        showPrintNewLine = true;
        newCols.add(PosColumn(
            text: text.substring(colWidth, col.text.length), size: col.size, align: col.align, weight: col.weight));
      }else{
        newCols.add(PosColumn(text: " ", size: col.size, align: col.align, weight: col.weight));
      }
      if (charset != null) {
        bytes += _setFont();
        bytes += Encoding.getByName(charset)?.encode(text) ?? [];
      } else {
        bytes += _setFont();
        bytes += latin1.encode(text);
      }
      bytes += feed();
    }
    if (showPrintNewLine) {
      bytes += row(newCols, charset: charset);
    }
    return bytes;
  }

  List<int> selectCodeTable(int tableId) {
    List<int> bytes = [];
    bytes += List.from(cCodeTable.codeUnits)..add(tableId);
    return bytes;
  }

  List<int> feed([int lines = 1]) {
    return List.from(cFeedN.codeUnits)..add(lines);
  }

  List<int> hr([ch = '-']) {
    List<int> bytes = [];
    for (int i = 0; i < _charsPerLine(); i++) {
      bytes += _setFont();
      bytes.addAll(latin1.encode(ch));
    }
    bytes += feed();
    return bytes;
  }

  List<int> paperCut() {
    return cCutPart.codeUnits;
  }

  List<int> _setFont() {
    if (this._font == PosFont.fontA) {
      return cFontA.codeUnits;
    } else {
      return cFontB.codeUnits;
    }
  }

  List<int> _setSize(PosSize size) {
    List<int> bytes = [];
    if (size.bold) {
      bytes += cBoldOn.codeUnits;
    } else {
      bytes += cBoldOff.codeUnits;
    }
    return bytes += List.from(cSizeGSn.codeUnits)..add(16 * (size.width - 1) + (size.height - 1));
  }

  String _setTextAlign(String text, PosAlign align, int width) {
    switch (align) {
      case PosAlign.left:
        return text.padRight(width);
      case PosAlign.center:
        return text.center(width);
      case PosAlign.right:
        return text.padLeft(width);
    }
  }

  List<int> _setAlign(PosAlign align) {
    switch (align) {
      case PosAlign.left:
        return cAlignLeft.codeUnits;
      case PosAlign.center:
        return cAlignCenter.codeUnits;
      case PosAlign.right:
        return cAlignRight.codeUnits;
    }
  }

  void setGlobalFont(PosFont font) {
    this._font = font;
  }

  int _charsPerLine([PosSize size = const PosSize()]) {
    int perLine = 0;
    if (_paperSize == PosPaperSize.mm58) {
      perLine = (_font == null || _font == PosFont.fontA) ? 32 : 42;
    } else {
      perLine = (_font == null || _font == PosFont.fontA) ? 48 : 64;
    }
    return perLine ~/ size.width;
  }
}

extension StringExt on String {
  String center(int width) {
    var str = this;
    if (this.length > width) str = this.substring(0, width);
    var len = str.length;
    var left = str.substring(0, len ~/ 2);
    var right = str.substring(len ~/ 2, len);

    var leftPadded = left.padLeft(width ~/ 2);
    var rightPadded = right.padRight(width ~/ 2);
    return leftPadded + rightPadded;
  }

  String trimToWidth(int width) {
    if (length > width) {
      return substring(0, width);
    } else {
      return this;
    }
  }
}
