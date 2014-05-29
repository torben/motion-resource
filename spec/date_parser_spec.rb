describe '#date_parser' do
  describe '#parseValue' do
    it 'should parse a date in the right format for MotionModel' do
      time_string = "2013-11-03T16:59:35+01:00"

      MotionModelResource::DateParser.parse_date(time_string).should.equal("2013-11-03 15:59:35 +0000")
    end

    it 'should return nil, when giving a wrong time' do
      time_string = "2342"
      time_string2 = "2013-21-03T16:59:35+01:00"

      MotionModelResource::DateParser.parse_date(time_string).should.equal nil
      MotionModelResource::DateParser.parse_date(time_string2).should.equal nil
    end
  end
end