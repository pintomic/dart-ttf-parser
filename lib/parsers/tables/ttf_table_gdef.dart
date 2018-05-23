part of ttf_parser;

class TtfTableGdef implements TtfTable {
  int majorVersion;
  int minorVersion;
  int glyphClassDefOffset;
  int attachListOffset;
  int ligCaretListOffset;
  int markAttachClassDefOffset;
  TtfFont font;

  TtfTableGdef(this.font);

  void parseData(StreamReader reader) {
    majorVersion = reader.readUnsignedShort();
    minorVersion = reader.readUnsignedShort();
    glyphClassDefOffset = reader.readUnsignedShort();
    attachListOffset = reader.readUnsignedShort();
    ligCaretListOffset = reader.readUnsignedShort();
    markAttachClassDefOffset = reader.readUnsignedShort();

    print('GDEF $majorVersion $minorVersion $glyphClassDefOffset $attachListOffset $ligCaretListOffset $markAttachClassDefOffset');
//    reader.seek(lookupListOffset);
//    print('lookupCount ${reader.readUnsignedShort()}');
//    for (var i = 0; i < nTables; i++) {
//      _parseSubTable(reader);
//    }
  }
}
