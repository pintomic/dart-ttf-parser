part of ttf_parser;

class TtfTableOS2 implements TtfTable {

  int sTypoAscender;
  int sTypoDescender;
  int sxHeight;
  int sCapHeight;

  TtfTableOS2();

  void parseData(StreamReader reader) {
    int majorVersion = reader.readUnsignedShort();
    if (majorVersion > 1) {
      int xAvgCharWidth = reader.readSignedShort();
      int usWeightClass = reader.readUnsignedShort();
      int usWidthClass = reader.readUnsignedShort();
      int fsType = reader.readUnsignedShort();
      int ySubscriptXSize = reader.readSignedShort();
      int ySubscriptYSize = reader.readSignedShort();
      int ySubscriptXOffset = reader.readSignedShort();
      int ySubscriptYOffset = reader.readSignedShort();
      int ySuperscriptXSize = reader.readSignedShort();
      int ySuperscriptYSize = reader.readSignedShort();
      int ySuperscriptXOffset = reader.readSignedShort();
      int ySuperscriptYOffset = reader.readSignedShort();
      int yStrikeoutSize = reader.readSignedShort();
      int yStrikeoutPosition = reader.readSignedShort();
      int sFamilyClass = reader.readSignedShort();
      List<int> panose10 = reader.readBytes(10);
      int ulUnicodeRange1 = reader.readUnsignedInt();
      int ulUnicodeRange2 = reader.readUnsignedInt();
      int ulUnicodeRange3 = reader.readUnsignedInt();
      int ulUnicodeRange4 = reader.readUnsignedInt();
      int achVendID = reader.readUnsignedInt();
      int fsSelection = reader.readUnsignedShort();
      int usFirstCharIndex = reader.readUnsignedShort();
      int usLastCharIndex = reader.readUnsignedShort();
      sTypoAscender = reader.readSignedShort();
      sTypoDescender = reader.readSignedShort();
      int sTypoLineGap = reader.readSignedShort();

      int usWinAscent = reader.readUnsignedShort();
      int usWinDescent = reader.readUnsignedShort();
      int ulCodePageRange1 = reader.readUnsignedInt();
      int ulCodePageRange2 = reader.readUnsignedInt();
      sxHeight = reader.readSignedShort();
      sCapHeight = reader.readSignedShort();
//uint16	usDefaultChar
//uint16	usBreakChar
//uint16	usMaxContext
      print(
          'OS/2 $majorVersion typoAscent $sTypoAscender usWinAscent $usWinAscent usWinDescent $usWinDescent xAvgCharWidth $xAvgCharWidth xHeight $sxHeight capHeight $sCapHeight');
    }
  }
}

