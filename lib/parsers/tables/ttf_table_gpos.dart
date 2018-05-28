part of ttf_parser;

/**
 * OpenType Layout common table formats
 * https://docs.microsoft.com/en-us/typography/opentype/spec/chapter2
 */
class TtfTableGpos implements TtfTable {
  int majorVersion;
  int minorVersion;
  int scriptListOffset;
  int featureListOffset;
  int lookupListOffset;
  Map<int, Map<int, int>> kernings = new Map<int, Map<int, int>>();
  TtfFont font;

  TtfTableGpos(this.font);

  void parseData(StreamReader reader) {
    int currentPosition = reader.currentPosition;
    print('currentPosition $currentPosition');
    majorVersion = reader.readUnsignedShort();
    minorVersion = reader.readUnsignedShort();
    scriptListOffset = reader.readUnsignedShort();
    featureListOffset = reader.readUnsignedShort();
    lookupListOffset = reader.readUnsignedShort();

    print(
        'GPOS $majorVersion.$minorVersion $scriptListOffset $featureListOffset $lookupListOffset');
    reader.seek(currentPosition + lookupListOffset);

    var lookupTableList = _parseLookupListTable(reader);
    print('lookUpTableOffsets ${lookupTableList.lookupTableOffsets}');
    for (var i = 0; i < lookupTableList.lookUpCount; i++) {
      final int lookupTableStart = currentPosition + lookupListOffset +
          lookupTableList.lookupTableOffsets[i];
      reader.seek(lookupTableStart);
      var lookupTable = _parseLookupTable(reader);

      print(
          'type at $i type ${lookupTable.lookupType} flag ${lookupTable
              .lookupFlag} subTableCount ${lookupTable.subTableCount}');
      if (lookupTable.lookupType == 2) {
        for (var lookupTableIndex = 0; lookupTableIndex <
            lookupTable.subTableCount; lookupTableIndex++) {
          final int subtableStart = lookupTableStart +
              lookupTable.subtableOffsets[lookupTableIndex];
          reader.seek(subtableStart);
          var posFormat = reader.readUnsignedShort();
          print('PosFormat $posFormat');
          if (posFormat == 1) {
            _evaluatePosFormat1(reader, subtableStart);
          } else if (posFormat == 2) { // PairPosFormat 2
            var pairPosFormat = _parsePairPosFormat2(reader);
            reader.seek(subtableStart + pairPosFormat.classDef1Offset);
            var classDef1Format = reader.readUnsignedShort();
            _ClassDefFormat2 classDef1;
            if (classDef1Format == 1) {
              var classDef1Format1 = _parseClassDefFormat1(reader);
              print(
                  'ClassDef1Format $classDef1Format startGlyphID ${classDef1Format1
                      .startGlyphID} glyphCount ${classDef1Format1
                      .glyphCount}');
            } else if (classDef1Format == 2) {
              classDef1 = _parseClassDefFormat2(reader);
              print(
                  'ClassDef1Format $classDef1Format classRangeCount ${classDef1
                      .classRangeCount}');
            }
            reader.seek(subtableStart + pairPosFormat.classDef2Offset);
            var classDef2Format = reader.readUnsignedShort();
            _ClassDefFormat2 classDef2;
            if (classDef2Format == 1) {
              var classDef2Format1 = _parseClassDefFormat1(reader);
              print(
                  'ClassDef2Format $classDef2Format startGlyphID ${classDef2Format1
                      .startGlyphID} glyphCount ${classDef2Format1
                      .glyphCount}');
            } else if (classDef2Format == 2) {
              classDef2 = _parseClassDefFormat2(reader);
              print(
                  'ClassDef2Format $classDef2Format classRangeCount ${classDef2
                      .classRangeCount}');
            }
            if (classDef1Format == 2 && classDef2Format == 2) {
              for (var i = 0; i < classDef1.classRangeCount; i++) {
                _ClassRangeRecord record1 = classDef1.classRangeRecords[i];
                for (var j = 0; j < classDef2.classRangeCount; j++) {
                  _ClassRangeRecord record2 = classDef2.classRangeRecords[j];
                  final int xAdvance = pairPosFormat.classRecords[record1.classDef][record2
                      .classDef];
                  if (xAdvance != 0) {
//                  print('class1Def.class ${record1
//                      .classDef} class2Def.class ${record2
//                      .classDef} advance $xAdvance');
                    for (var k = record1.startGlyphID; k <= record1.endGlyphID;
                    k++) {
                      for (var l = record2.startGlyphID; l <=
                          record2.endGlyphID; l++) {
                        _registerKerning(k, l, xAdvance);
                      }
                    }
                  }
                }
              }
            }

            reader.seek(subtableStart + pairPosFormat.coverageOffset);
            final coverageFormat = reader.readUnsignedShort();
            if (coverageFormat == 1) {
              final coverageTable = _parseCoverageFormat1(reader);
              print('CoverageFormat 1 count ${coverageTable
                  .glyphCount} ${coverageTable.glyphArray}');
              for (var i = 0; i < coverageTable.glyphCount; i++) {
                final bool isCovered = classDef1.covered.contains(
                    coverageTable.glyphArray[i]);
//                print('cover ${font.getStringFromGlyph(
//                    coverageTable.glyphArray[i])} ${isCovered}');
                if (!isCovered) {
                  for (var j = 0; j < classDef2.classRangeCount; j++) {
                    _ClassRangeRecord record2 = classDef2.classRangeRecords[j];
                    final int xAdvance = pairPosFormat.classRecords[0][record2
                        .classDef];
                    if (xAdvance != 0) {
//                      print('class1Def.class ${0} class2Def.class ${record2
//                          .classDef} advance $xAdvance');
                      for (var l = record2.startGlyphID; l <=
                          record2.endGlyphID; l++) {
                        _registerKerning(
                            coverageTable.glyphArray[i], l, xAdvance);
                      }
                    }
                  }
                }
              }
            } else if (coverageFormat == 2) {
              // TODO
              print('CoverageFormat 2');
              final coverageTable = _parseCoverageFormat2(reader);
              for (var i = 0; i < coverageTable.rangeCount; i++) {
                final _RangeRecord record = coverageTable.rangeRecords[i];
                for (var j = record.startGlyphID; j <= record.endGlyphID; j++) {
                  if (!classDef1.covered.contains(j)) {
                    for (var k = 0; k < classDef2.classRangeCount; k++) {
                      _ClassRangeRecord record2 = classDef2
                          .classRangeRecords[k];
                      final int xAdvance = pairPosFormat.classRecords[0][record2
                          .classDef];
                      if (xAdvance != 0) {
//                        print('class1Def.class ${0} class2Def.class ${record2
//                            .classDef} advance $xAdvance');
                        for (var l = record2.startGlyphID; l <=
                            record2.endGlyphID; l++) {
                          _registerKerning(j, l, xAdvance);
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    kernings.forEach((key, value) {
      print('$key $value');
    });
    print('-----------------------DONE----------------------------');
  }

  _evaluatePosFormat1(StreamReader reader, int subtableStart) {
    var pairPosFormat1 = _parsePairPosFormat1(reader);
    print('PosFormat1 vF1 ${pairPosFormat1
        .valueFormat1} vF2 ${pairPosFormat1.valueFormat2} pairSets ${pairPosFormat1.pairSetCount}');
    if (pairPosFormat1.valueFormat1 == 4 &&
        pairPosFormat1.valueFormat2 == 0) {
      for (var j = 0; j < pairPosFormat1.pairSetCount; j++) {
        reader.seek(subtableStart + pairPosFormat1.pairSetOffsets[j]);
        pairPosFormat1.pairSets[j] = _parsePairSet(reader);
      }
      reader.seek(subtableStart + pairPosFormat1.coverageOffset);
      final coverageFormat = reader.readUnsignedShort();
      if (coverageFormat == 1) {
        print('PosFormat1 + CoverageFormat1');
        final coverageTable = _parseCoverageFormat1(reader);
        for (var i = 0; i < coverageTable.glyphCount; i++) {
          final leftGlyphId = coverageTable.glyphArray[i];
          for (var j = 0; j < pairPosFormat1.pairSets[i].pairValueCount;
          j++) {
            var record = pairPosFormat1.pairSets[i].pairValueRecords[j];
            _registerKerning(leftGlyphId, record.secondGlyph,
                record.valueRecord1.xAdvance);
          }
        }
      } else if (coverageFormat == 2) {
        print('PosFormat1 + CoverageFormat2');
        var coverageFormat2 = _parseCoverageFormat2(reader);
        print('coverageFormat2 rangeCount ${coverageFormat2.rangeCount}');
        for (var i = 0; i < coverageFormat2.rangeCount; i++) {
          final _RangeRecord record = coverageFormat2.rangeRecords[i];
          print('rangeRecrod ${record.startCoverageIndex} ${record.startGlyphID} ${record.endGlyphID}');
          for (var j = 0; j <= record.endGlyphID - record.startGlyphID; j++) {
            var leftGlyphId = record.startCoverageIndex + record.startGlyphID;
            for (var k = 0; k < pairPosFormat1.pairSets[record.startCoverageIndex + j].pairValueCount;
            k++) {
              var pvr = pairPosFormat1.pairSets[record.startCoverageIndex + j].pairValueRecords[k];
              _registerKerning(leftGlyphId, pvr.secondGlyph,
                  pvr.valueRecord1.xAdvance);
            }
          }
        }
      }
    }
  }

  _LookupListTable _parseLookupListTable(StreamReader reader) {
    final lookupListTable = new _LookupListTable();
    lookupListTable.lookUpCount = reader.readUnsignedShort();
    print('lookupCount ${lookupListTable.lookUpCount}');
    lookupListTable.lookupTableOffsets =
    new List<int>(lookupListTable.lookUpCount);
    for (var i = 0; i < lookupListTable.lookUpCount; i++) {
      lookupListTable.lookupTableOffsets[i] = (reader.readUnsignedShort());
    }
    return lookupListTable;
  }

  _LookupTable _parseLookupTable(StreamReader reader) {
    final lookupTable = new _LookupTable();
    lookupTable.lookupType = reader
        .readUnsignedShort(); // Lookup Type 2: Pair Adjustment Positioning Subtable
    lookupTable.lookupFlag = reader.readUnsignedShort();
    lookupTable.subTableCount = reader.readUnsignedShort();
    lookupTable.subtableOffsets = new List<int>(lookupTable.subTableCount);
    for (var i = 0; i < lookupTable.subTableCount; i++) {
      lookupTable.subtableOffsets[i] = reader.readUnsignedShort();
    }
    return lookupTable;
  }

  _PairPosFormat1 _parsePairPosFormat1(StreamReader reader) {
    final pairPosFormat = new _PairPosFormat1();
    pairPosFormat.coverageOffset = reader.readUnsignedShort();
    pairPosFormat.valueFormat1 = reader.readUnsignedShort();
    pairPosFormat.valueFormat2 = reader.readUnsignedShort();
    pairPosFormat.pairSetCount = reader.readUnsignedShort();
    pairPosFormat.pairSetOffsets = new List<int>(pairPosFormat.pairSetCount);
    pairPosFormat.pairSets = new List<_PairSet>(pairPosFormat.pairSetCount);
    print(
        'PosFormat1 coverageOffset ${pairPosFormat.coverageOffset} '
            'vF1 ${pairPosFormat.valueFormat1} '
            'vF2 ${pairPosFormat.valueFormat2} '
            'pairSetCount ${pairPosFormat.pairSetCount}');
    // valueFormat1 == 4 X_ADVANCE int16
    for (var j = 0; j < pairPosFormat.pairSetCount; j++) {
      pairPosFormat.pairSetOffsets[j] = reader.readUnsignedShort();
    }
    return pairPosFormat;
  }

  _PairPosFormat2 _parsePairPosFormat2(StreamReader reader) {
    final pairPosFormat = new _PairPosFormat2();
    pairPosFormat.coverageOffset = reader.readUnsignedShort();
    pairPosFormat.valueFormat1 = reader.readUnsignedShort();
    pairPosFormat.valueFormat2 = reader.readUnsignedShort();
    pairPosFormat.classDef1Offset = reader.readUnsignedShort();
    pairPosFormat.classDef2Offset = reader.readUnsignedShort();
    pairPosFormat.class1Count = reader.readUnsignedShort();
    pairPosFormat.class2Count = reader.readUnsignedShort();
    print(
        'PosFormat2 coverageOffset ${pairPosFormat.coverageOffset}'
            ' vF1 ${pairPosFormat.valueFormat1} vF2 ${pairPosFormat
            .valueFormat2}'
            ' classDef1Offset ${pairPosFormat.classDef1Offset}'
            ' classDef2Offset ${pairPosFormat.classDef2Offset}'
            ' class1Count ${pairPosFormat.class1Count}'
            ' class2Count ${pairPosFormat.class2Count}');
    pairPosFormat.classRecords = new List.generate(
        pairPosFormat.class1Count, (_) =>
    new List<int>(
        pairPosFormat.class2Count));
    for (var i = 0; i < pairPosFormat.class1Count; i++) {
      var start = i * pairPosFormat.class2Count;
      for (var j = 0; j < pairPosFormat.class2Count; j++) {
        var valueRecord1 = reader.readSignedShort();
        pairPosFormat.classRecords[i][j] = valueRecord1;
//                print('$j xAdvance $valueRecord1');
      }
    }
    return pairPosFormat;
  }

  _PairSet _parsePairSet(StreamReader reader) {
    final pairSet = new _PairSet();
    pairSet.pairValueCount = reader.readUnsignedShort();
    pairSet.pairValueRecords =
    new List<_PairValueRecord>(pairSet.pairValueCount);

//    print('pairValueCount ${pairSet.pairValueCount}'); // secondGlyph $secondGlyph vR1 $valueRecord1 vR2 $valueRecord2');
    for (var k = 0; k < pairSet.pairValueCount; k++) {
      pairSet.pairValueRecords[k] = _parsePairValueRecord(reader);
    }
    return pairSet;
  }

  _PairValueRecord _parsePairValueRecord(StreamReader reader) {
    final pairValueRecord = new _PairValueRecord();
    pairValueRecord.secondGlyph = reader.readUnsignedShort();
    var secondGlyph = font.getStringFromGlyph(pairValueRecord.secondGlyph);
    pairValueRecord.valueRecord1 = new _ValueRecord()
      ..xAdvance = reader.readSignedShort();
    // Note: we only consider valueRecord1 so far
//    print('secondGlyph $secondGlyph vR1 ${pairValueRecord.valueRecord1
//        .xAdvance}');
    return pairValueRecord;
  }

  _CoverageFormat1 _parseCoverageFormat1(StreamReader reader) {
    final coverageFormat = new _CoverageFormat1();
    coverageFormat.glyphCount = reader.readUnsignedShort();
    coverageFormat.glyphArray = new List<int>(coverageFormat.glyphCount);
    for (var k = 0; k < coverageFormat.glyphCount; k++) {
      coverageFormat.glyphArray[k] = reader.readUnsignedShort();
      var glyphCode = font.getStringFromGlyph(coverageFormat.glyphArray[k]);
//      print('glyphID ${coverageFormat.glyphArray[k]} char $glyphCode');
    }
    return coverageFormat;
  }

  _CoverageFormat2 _parseCoverageFormat2(StreamReader reader) {
    final coverageFormat = new _CoverageFormat2();
    coverageFormat.rangeCount = reader.readUnsignedShort();
    coverageFormat.rangeRecords =
    new List<_RangeRecord>(coverageFormat.rangeCount);
    print('CoverageFormat2 rangeCount ${coverageFormat.rangeCount}');
    for (var i = 0; i < coverageFormat.rangeCount; i++) {
      coverageFormat.rangeRecords[i] = _parseRangeRecord(reader);
    }
    return coverageFormat;
  }

  _RangeRecord _parseRangeRecord(StreamReader reader) {
    var rangeRecord = new _RangeRecord();
    rangeRecord.startGlyphID = reader.readUnsignedShort();
    rangeRecord.endGlyphID = reader.readUnsignedShort();
    rangeRecord.startCoverageIndex = reader.readUnsignedShort();
//    print('RR ${rangeRecord.startGlyphID} ${rangeRecord.endGlyphID} ${rangeRecord.startCoverageIndex}');
    return rangeRecord;
  }

  _ClassDefFormat1 _parseClassDefFormat1(StreamReader reader) {
    final _ClassDefFormat1 classFormat = new _ClassDefFormat1();
    classFormat.startGlyphID = reader.readUnsignedShort();
    classFormat.glyphCount = reader.readUnsignedShort();
    // TODO parse classValueArray
    return classFormat;
  }

  _ClassDefFormat2 _parseClassDefFormat2(StreamReader reader) {
    final _ClassDefFormat2 classDefFormat = new _ClassDefFormat2();
    classDefFormat.classRangeCount = reader.readUnsignedShort();
    classDefFormat.classRangeRecords =
    new List<_ClassRangeRecord>(classDefFormat.classRangeCount);
    for (var i = 0; i < classDefFormat.classRangeCount; i++) {
      final _ClassRangeRecord record = _parseClassRangeRecord(reader);
      classDefFormat.classRangeRecords[i] = record;
      for (var j = record.startGlyphID; j <= record.endGlyphID; j++) {
        classDefFormat.covered.add(j);
      }
    }
    return classDefFormat;
  }

  _ClassRangeRecord _parseClassRangeRecord(StreamReader reader) {
    var rangeRecord = new _ClassRangeRecord();
    rangeRecord.startGlyphID = reader.readUnsignedShort();
    rangeRecord.endGlyphID = reader.readUnsignedShort();
    rangeRecord.classDef = reader.readUnsignedShort();
//    print('CRR ${font.getStringFromGlyph(rangeRecord.startGlyphID)} ${font.cmap
//        .glyphToCharIndexMap[rangeRecord.startGlyphID]} ${font
//        .getStringFromGlyph(rangeRecord.endGlyphID)} ${rangeRecord.classDef}');
    return rangeRecord;
  }

  void _registerKerning(int leftGlyphId, int rightGlyphId, int value) {
    int leftKeyCode = font.cmap.glyphToCharIndexMap[leftGlyphId];
    int rightKeyCode = font.cmap.glyphToCharIndexMap[rightGlyphId];
    if (leftKeyCode == null || rightKeyCode == null) {
      return;
    }
//    String left = font.getStringFromGlyph(leftGlyphId);
//    String right = font.getStringFromGlyph(rightGlyphId);
//    print('kerning $leftKeyCode $left $rightKeyCode $right $value');
    if (!kernings.containsKey(leftKeyCode)) {
      kernings[leftKeyCode] = new Map<int, int>();
    }
    kernings[leftKeyCode][rightKeyCode] = value;
  }
}


class _LookupListTable {
  int lookUpCount;
  List<int> lookupTableOffsets;
}

class _LookupTable {
  int lookupType;
  int lookupFlag;
  int subTableCount;
  List<int> subtableOffsets;
}

class _PairPosFormat1 {
  int coverageOffset; // Offset to Coverage table, from beginning of PairPos subtable.
  int valueFormat1; // Defines the types of data in valueRecord1 — for the first glyph in the pair (may be zero).
  int valueFormat2; // Defines the types of data in valueRecord2 — for the second glyph in the pair (may be zero).
  int pairSetCount; // Number of PairSet tables
  List<
      int> pairSetOffsets; // Array of offsets to PairSet tables. Offsets are from beginning of PairPos subtable, ordered by Coverage Index.
  List<_PairSet> pairSets;
}

class _PairPosFormat2 {
  int coverageOffset; // Offset to Coverage table, from beginning of PairPos subtable.
  int valueFormat1; // ValueRecord definition — for the first glyph of the pair (may be zero).
  int valueFormat2; // ValueRecord definition — for the second glyph of the pair (may be zero).
  int classDef1Offset; // Offset to ClassDef table, from beginning of PairPos subtable — for the first glyph of the pair.
  int classDef2Offset; // Offset to ClassDef table, from beginning of PairPos subtable — for the second glyph of the pair.
  int class1Count; // Number of classes in classDef1 table — includes Class 0.
  int class2Count; // Number of classes in classDef2 table — includes Class 0.
  List<List<int>> classRecords;
  List<
      _Class1Record> class1Records; //  class1Records[class1Count]	Array of Class1 records, ordered by classes in classDef1.
}

class _Class1Record {
  List<
      _Class2Record> class2Records; // Array of Class2 records, ordered by classes in classDef2.
}

class _Class2Record {
  _ValueRecord valueRecord1; // Positioning for first glyph — empty if valueFormat1 = 0.
  _ValueRecord valueRecord2; // Positioning for second glyph — empty if valueFormat2 = 0.
}

class _PairSet {
  int pairValueCount;
  List<_PairValueRecord> pairValueRecords;
}

class _PairValueRecord {
  int secondGlyph;
  _ValueRecord valueRecord1;
  _ValueRecord valueRecord2;
}

class _ValueRecord {
  int xAdvance;
// way more optional values
}

class _CoverageFormat1 {
  int glyphCount; // Number of glyphs in the glyph array
  List<int> glyphArray; // Array of glyph IDs - in numerical order
}

class _CoverageFormat2 {
  int rangeCount; // Number of RangeRecords
  List<
      _RangeRecord> rangeRecords; // Array of glyph ranges - ordered by startGlyphID.
}

class _RangeRecord {
  int startGlyphID; // First glyph ID in the range
  int endGlyphID; // Last glyph ID in the range
  int startCoverageIndex; // Coverage index of first glyph ID in range
}

// https://docs.microsoft.com/en-us/typography/opentype/spec/chapter2#classDefTbl
class _ClassDefFormat1 {
  int startGlyphID; // First glyph ID of the classValueArray
  int glyphCount; // Size of the classValueArray
  List<int> classValueArray; // Array of Class Values - one per glyph ID
}

class _ClassDefFormat2 {
  int classRangeCount; // Number of ClassRangeRecords
  List<
      _ClassRangeRecord> classRangeRecords; // Array of ClassRangeRecords - ordered by startGlyphID
  Set<int> covered = new Set<int>();
}

class _ClassRangeRecord {
  int startGlyphID; // First glyph ID in the range
  int endGlyphID; // Last glyph ID in the range
  int classDef; // Applied to all glpyhs in the range
}

