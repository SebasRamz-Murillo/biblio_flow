// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:string_scanner/src/charcode.dart';
import 'package:string_scanner/string_scanner.dart';
import 'package:test/test.dart';

void main() {
  late LineScanner scanner;
  setUp(() {
    scanner = LineScanner('foo\nbar\r\nbaz');
  });

  test('begins with line and column 0', () {
    expect(scanner.line, equals(0));
    expect(scanner.column, equals(0));
  });

  group('scan()', () {
    test('consuming no newlines increases the column but not the line', () {
      scanner.scan('foo');
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(3));
    });

    test('consuming a newline resets the column and increases the line', () {
      scanner.expect('foo\nba');
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(2));
    });

    test('consuming multiple newlines resets the column and increases the line',
        () {
      scanner.expect('foo\nbar\r\nb');
      expect(scanner.line, equals(2));
      expect(scanner.column, equals(1));
    });

    test("consuming halfway through a CR LF doesn't count as a line", () {
      scanner.expect('foo\nbar\r');
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(4));

      scanner.expect('\nb');
      expect(scanner.line, equals(2));
      expect(scanner.column, equals(1));
    });
  });

  group('readChar()', () {
    test('on a non-newline character increases the column but not the line',
        () {
      scanner.readChar();
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(1));
    });

    test('consuming a newline resets the column and increases the line', () {
      scanner.expect('foo');
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(3));

      scanner.readChar();
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(0));
    });

    test("consuming halfway through a CR LF doesn't count as a line", () {
      scanner.expect('foo\nbar');
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(3));

      scanner.readChar();
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(4));

      scanner.readChar();
      expect(scanner.line, equals(2));
      expect(scanner.column, equals(0));
    });
  });

  group('readCodePoint()', () {
    test('on a non-newline character increases the column but not the line',
        () {
      scanner.readCodePoint();
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(1));
    });

    test('consuming a newline resets the column and increases the line', () {
      scanner.expect('foo');
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(3));

      scanner.readCodePoint();
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(0));
    });

    test("consuming halfway through a CR LF doesn't count as a line", () {
      scanner.expect('foo\nbar');
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(3));

      scanner.readCodePoint();
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(4));

      scanner.readCodePoint();
      expect(scanner.line, equals(2));
      expect(scanner.column, equals(0));
    });
  });

  group('scanChar()', () {
    test('on a non-newline character increases the column but not the line',
        () {
      scanner.scanChar($f);
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(1));
    });

    test('consuming a newline resets the column and increases the line', () {
      scanner.expect('foo');
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(3));

      scanner.scanChar($lf);
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(0));
    });

    test("consuming halfway through a CR LF doesn't count as a line", () {
      scanner.expect('foo\nbar');
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(3));

      scanner.scanChar($cr);
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(4));

      scanner.scanChar($lf);
      expect(scanner.line, equals(2));
      expect(scanner.column, equals(0));
    });
  });

  group('before a surrogate pair', () {
    final codePoint = '\uD83D\uDC6D'.runes.first;
    const highSurrogate = 0xD83D;

    late LineScanner scanner;
    setUp(() {
      scanner = LineScanner('foo: \uD83D\uDC6D');
      expect(scanner.scan('foo: '), isTrue);
    });

    test('readChar returns the high surrogate and moves into the pair', () {
      expect(scanner.readChar(), equals(highSurrogate));
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(6));
      expect(scanner.position, equals(6));
    });

    test('readCodePoint returns the code unit and moves past the pair', () {
      expect(scanner.readCodePoint(), equals(codePoint));
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(7));
      expect(scanner.position, equals(7));
    });

    test('scanChar with the high surrogate moves into the pair', () {
      expect(scanner.scanChar(highSurrogate), isTrue);
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(6));
      expect(scanner.position, equals(6));
    });

    test('scanChar with the code point moves past the pair', () {
      expect(scanner.scanChar(codePoint), isTrue);
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(7));
      expect(scanner.position, equals(7));
    });

    test('expectChar with the high surrogate moves into the pair', () {
      scanner.expectChar(highSurrogate);
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(6));
      expect(scanner.position, equals(6));
    });

    test('expectChar with the code point moves past the pair', () {
      scanner.expectChar(codePoint);
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(7));
      expect(scanner.position, equals(7));
    });
  });

  group('position=', () {
    test('forward through newlines sets the line and column', () {
      scanner.position = 10; // "foo\nbar\r\nb"
      expect(scanner.line, equals(2));
      expect(scanner.column, equals(1));
    });

    test('forward through no newlines sets the column', () {
      scanner.position = 2; // "fo"
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(2));
    });

    test('backward through newlines sets the line and column', () {
      scanner.scan('foo\nbar\r\nbaz');
      scanner.position = 2; // "fo"
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(2));
    });

    test('backward through no newlines sets the column', () {
      scanner.scan('foo\nbar\r\nbaz');
      scanner.position = 10; // "foo\nbar\r\nb"
      expect(scanner.line, equals(2));
      expect(scanner.column, equals(1));
    });

    test("forward halfway through a CR LF doesn't count as a line", () {
      scanner.position = 8; // "foo\nbar\r"
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(4));
    });
  });

  test('state= restores the line, column, and position', () {
    scanner.scan('foo\nb');
    final state = scanner.state;

    scanner.scan('ar\nba');
    scanner.state = state;
    expect(scanner.rest, equals('ar\r\nbaz'));
    expect(scanner.line, equals(1));
    expect(scanner.column, equals(1));
  });

  test('state= rejects a foreign state', () {
    scanner.scan('foo\nb');

    expect(() => LineScanner(scanner.string).state = scanner.state,
        throwsArgumentError);
  });
}
