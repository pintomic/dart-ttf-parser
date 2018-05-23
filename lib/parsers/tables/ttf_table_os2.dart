part of ttf_parser;

class TtfTableOS2 implements TtfTable {

  TtfTableOS2();

  void parseData(StreamReader reader) {
    int majorVersion = reader.readUnsignedShort();
    int xAvgCharWidth = reader.readUnsignedShort();

    print('OS/2 $majorVersion $xAvgCharWidth');
  }
}
