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
        for (var i = 0; i < lookupTable.subTableCount; i++) {
          final int pairSetStart = lookupTableStart +
              lookupTable.subtableOffsets[i];
          reader.seek(pairSetStart);
          var posFormat = reader.readUnsignedShort();
          if (posFormat == 1) {
            var pairPosFormat1 = _parsePairPosFormat1(reader);
            // TODO make sure valueFormat1 == 4 and valueFormat2 == 0
            if (pairPosFormat1.valueFormat1 == 4 && pairPosFormat1.valueFormat2 == 0) {
              for (var j = 0; j < pairPosFormat1.pairSetCount; j++) {
                reader.seek(pairSetStart + pairPosFormat1.pairSetOffsets[j]);
                pairPosFormat1.pairSets[j] = _parsePairSet(reader);
              }
              reader.seek(pairSetStart + pairPosFormat1.coverageOffset);
              final coverageFormat = reader.readUnsignedShort();
              if (coverageFormat == 1) {
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
              }
            }
          } else if (posFormat == 2) {
            var pairPosFormat = _parsePairPosFormat2(reader);
            for (var i = 0; i <
                pairPosFormat.class1Count * pairPosFormat.class2Count; i++) {
//              var xAdvance = reader.readUnsignedShort();
//              var secondGlyph = String.fromCharCode(
//                  font.cmap.glyphToCharIndexMap[reader
//                      .readUnsignedShort()]);
              var valueRecord1 = reader.readSignedShort();
//              print('xAdvance $valueRecord1');
            }
            reader.seek(pairSetStart + pairPosFormat.classDef1Offset);
            var classFormat = reader.readUnsignedShort();
            if (classFormat == 1) {
              var startGlyphID = reader.readUnsignedShort();
              var glyphCount = reader.readUnsignedShort();
              print(
                  'classFormat $classFormat startGlyphID $startGlyphID glyphCount $glyphCount');
            } else if (classFormat == 2) {
              var classRangeCount = reader.readUnsignedShort();
              print(
                  'classFormat $classFormat classRangeCount $classRangeCount');
            }
            reader.seek(pairSetStart + pairPosFormat.classDef2Offset);
            var class2Format = reader.readUnsignedShort();
            if (class2Format == 1) {
              var startGlyphID = reader.readUnsignedShort();
              var glyphCount = reader.readUnsignedShort();
              print(
                  'ClassDefFormat$class2Format startGlyphID $startGlyphID glyphCount $glyphCount');
            } else if (class2Format == 2) {
              var classRangeCount = reader.readUnsignedShort();
              print(
                  'ClassDefFormat$class2Format classRangeCount $classRangeCount');
              for (var i = 0; i < classRangeCount; i++) {
                var startGlyphID = reader.readUnsignedShort();
                int startStr = font.cmap.glyphToCharIndexMap[startGlyphID] ?? 0;
                var endGlyphID = reader.readUnsignedShort();
                int endStr = font.cmap.glyphToCharIndexMap[endGlyphID] ?? 0;
                var classDef = reader.readUnsignedShort();
                print('start $startGlyphID ${font.getStringFromGlyph(
                    startGlyphID)}'
                    ' end $endGlyphID ${font.getStringFromGlyph(
                    endGlyphID)} class $classDef');
              }
            }
          }
        }
      }
    }
    kernings.forEach((key, value) {
      print('$key $value');

    });
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
        'PosFormat1 coverageOffset ${pairPosFormat.coverageOffset}'
            ' vF1 ${pairPosFormat.valueFormat1} vF2 ${pairPosFormat
            .valueFormat2}'
            ' classDef1Offset ${pairPosFormat.classDef1Offset}'
            ' classDef2Offset ${pairPosFormat.classDef2Offset}'
            ' class1Count ${pairPosFormat.class1Count}'
            ' class2Count ${pairPosFormat.class2Count}');
    return pairPosFormat;
  }

  _PairSet _parsePairSet(StreamReader reader) {
    final pairSet = new _PairSet();
    pairSet.pairValueCount = reader.readUnsignedShort();
    pairSet.pairValueRecords =
    new List<_PairValueRecord>(pairSet.pairValueCount);

    print(
        'pairValueCount ${pairSet
            .pairValueCount}'); // secondGlyph $secondGlyph vR1 $valueRecord1 vR2 $valueRecord2');
//    if (pairPosFormat1.valueFormat1 == 4) {
    for (var k = 0; k < pairSet.pairValueCount; k++) {
      pairSet.pairValueRecords[k] = _parsePairValueRecord(reader);
    }
//    }
    return pairSet;
  }

  _PairValueRecord _parsePairValueRecord(StreamReader reader) {
    final pairValueRecord = new _PairValueRecord();
    pairValueRecord.secondGlyph = reader.readUnsignedShort();
    var secondGlyph = font.getStringFromGlyph(pairValueRecord.secondGlyph);
    pairValueRecord.valueRecord1 = new _ValueRecord()
      ..xAdvance = reader.readSignedShort();
    // Note: we only consider valueRecord1 so far
//    pairValueRecord.valueRecord2 = pairPosFormat1.valueFormat2 != 0 ? reader.readSignedShort() : 0;
    print('secondGlyph $secondGlyph vR1 ${pairValueRecord.valueRecord1
        .xAdvance}');
    return pairValueRecord;
  }

  _CoverageFormat1 _parseCoverageFormat1(StreamReader reader) {
    final coverageFormat = new _CoverageFormat1();
    coverageFormat.glyphCount = reader.readUnsignedShort();
    coverageFormat.glyphArray = new List<int>(coverageFormat.glyphCount);
    for (var k = 0; k < coverageFormat.glyphCount; k++) {
      coverageFormat.glyphArray[k] = reader.readUnsignedShort();
      var glyphCode = font.getStringFromGlyph(coverageFormat.glyphArray[k]);
      print('glyphID ${coverageFormat.glyphArray[k]} char $glyphCode');
    }
    return coverageFormat;
  }

  void _registerKerning(int leftGlyphId, int rightGlyphId, int value) {
    int leftKeyCode = font.cmap.glyphToCharIndexMap[leftGlyphId];
    int rightKeyCode = font.cmap.glyphToCharIndexMap[rightGlyphId];
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
}

class _ClassRangeRecord {
  int startGlyphID; // First glyph ID in the range
  int endGlyphID; // Last glyph ID in the range
  int classDef; // Applied to all glpyhs in the range
}

