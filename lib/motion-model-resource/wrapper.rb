module MotionModelResource
  class WrapperNotDefinedError < Exception; end
  class URLNotDefinedError < Exception; end
  class ActionNotImplemented < Exception; end

  module ApiWrapper
    def self.included(base)
      base.extend(PublicClassMethods)
    end

    module PublicClassMethods
      # Returns the last updated at or nil value of Model
      def last_update
        return unless columns.include? :updated_at
        order{|one, two| two.updated_at <=> one.updated_at}.first.try(:updated_at)
      end

      # Loads the given URL and parse the JSON for new models.
      # If the models are present, the model will update.
      # If block given, the block will called, when the the models are saved. The model/s will be passed as an argument to the block.
      def fetch(site, params = {}, &block)
        raise MotionModelResource::WrapperNotDefinedError.new "Wrapper is not defined!" unless self.respond_to?(:wrapper)

        BW::HTTP.get(site, params) do |response|
          models = []
          if response.ok? && response.body.present?
            json = BW::JSON.parse(response.body.to_str)
            models = update_models(json)
          end

          block.call(models) if block.present? && block.respond_to?(:call)
        end
      end

      # Parses given JSON object and saves the founded models.
      # Returns an array with models, or the founded model
      def update_models(json)
        if json.is_a?(Array)
          models = []
          for json_part in json
            model = build_model(json_part)
            if model.present?
              model.save
              models << model
            end
          end
          return models
        else
          model = build_model(json)
          model.save if model.present?

          return model
        end
      end

      # Builds a model for given JSON object. Returns a new or presend model.
      def build_model(json)
        classname = name.downcase

        model = where("id").eq(json["id"]).first
        if model.present?
          if model.wrap(json)
            return model
          end
        else
          new_model = self.new
          return new_model if new_model.wrap(json)
        end

        nil
      end
    end

    # Instance methods

    # Saves the current model. Calls super when block is not given.
    # If block is given, the url method will be needed to call the remote server.
    # The answer of the server will be parsed and stored.
    # If the record is a new one, a POST request will be fired, otherwise a PUT call comes to the server.
    def save(options = {}, &block)
      if block.present?
        raise MotionModelResource::URLNotDefinedError.new "URL is not defined for #{self.class.name}!" unless self.class.respond_to?(:url)

        action = if new_record?
          "create"
        elsif self.id.present?
          "update"
        else
          raise MotionModelResource::ActionNotImplemented.new "Action ist not implemented for #{self.class.name}!"
        end

        model = self

        model.id = nil if model.id.present? && action == "create"

        hash = build_hash_from_model(self.class.name.downcase, self)
        hash.merge!(options[:params]) if options[:params].present?

        request_block = Proc.new do |response|
          model = nil
          if response.ok? && response.body.present?
            json = BW::JSON.parse(response.body.to_str)

            model.wrap(json)
            model.save
          end

          block.call(model) if block.present? && block.respond_to?(:call)
        end

        case action
        when "create"
          BW::HTTP.post(self.class.url, {payload: hash}, &request_block)
        when "update"
          BW::HTTP.put("#{self.class.url}/#{model.id}", {payload: hash}, &request_block)
        end
      else
        super
      end
    end

    def touch_sync
      self.lastSyncAt = Time.now if self.respond_to?(:lastSyncAt=)
    end

    # Returns a hash with given model
    def build_hash_from_model(main_key, model)
      hash = {
        main_key => {}
      }
      hash[main_key] = {}

      model.attributes.each do |key, attribute|
        if model.class.has_many_columns.keys.include?(key)
          new_key = attribute.first.class.name.pluralize.downcase
          hash[main_key][new_key] = []
          for a in attribute
            hash[main_key][new_key].push(build_hash_from_model(new_key, a)[new_key])
          end
        elsif attribute.respond_to?(:attributes)
          new_key = attribute.class.name.downcase
          h = build_hash_from_model(new_key, attribute)
          hash[main_key][new_key] = h[new_key] if h.has_key?(new_key)
        else
          model.class.wrapper[:fields].each do |wrapper_key, wrapper_value|
            hash[main_key][wrapper_key] = attribute if wrapper_value == key
          end
        end
      end

      return hash
    end

    # Loads the given URL and parse the JSON for a model.
    # If the model is present, the model will updates.
    # If block given, the block will called, when the the model is saved. The model will be passed as an argument to the block.
    def fetch(site, params, &block)
      raise MotionModelResource::WrapperNotDefinedError.new "Wrapper is not defined!" unless self.class.respond_to?(:wrapper)
      model = self
      BW::HTTP.get(site, params) do |response|
        if response.ok? && response.body.present?
          json = BW::JSON.parse(response.body.to_str)
          model.wrap(json)

          model.save
        end

        block.call if block.present? && block.respond_to?(:call)
      end
    end

    # Wraps the current model with the given JSON.
    # All the fields found in JSON and self.wrapper will be parsed.
    # Returns true, when no error exists
    def wrap(model_json)
      return unless self.class.respond_to?(:wrapper)

      touch_sync

      self.class.wrapper[:fields].each do |online, local|
        if model_json.respond_to?("key?") && model_json.key?("#{online}")
          value = parse_value(local, model_json[online])
          self.send("#{local}=", value)
        end
      end

      if self.class.wrapper[:relations].present?
        self.class.wrapper[:relations].each do |relation|
          if model_json.respond_to?("key?") && model_json.key?("#{relation}") && model_json["#{relation}"].present?
            klass = Object.const_get(relation.to_s.singularize.camelize)
            new_relation = klass.update_models(model_json["#{relation}"])
            self.send("#{relation}=", new_relation) rescue NoMethodError # not correct implemented in MotionModel
          end
        end
      end

      true
    end

    # Parses given value for key in the right format for MotionModel.
    # Currently only Date/Time support needed
    def parse_value(key, value)
      case self.column_type(key.to_sym)
      when :date, :time then MotionModelResource::DateParser.parse_date value
      else value
      end
    end
  end
end