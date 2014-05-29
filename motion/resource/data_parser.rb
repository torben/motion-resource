module MotionModelResource
  module DateParser
    def parseDate(arg)
      return nil if arg
      additional_parsestring = arg.include?(".") ? ".SSS" : ""
      date_formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss#{additional_parsestring}ZZZZ"
      date = date_formatter.dateFromString arg

      return nil if date.blank?

      "#{date.description}"
    end
    
    def date_formatter
      @date_formatter ||= NSDateFormatter.new
    end
  end
end