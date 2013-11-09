module MotionModelResource
  module DateParser
    def self.parseDate(arg)
      date_formatter = NSDateFormatter.alloc.init
      date_formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
      date = date_formatter.dateFromString arg

      return nil if date.blank?

      date.description
    end
  end
end