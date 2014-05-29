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
      def fetch(site = nil, params = {}, &block)
        raise MotionModelResource::WrapperNotDefinedError.new "Wrapper is not defined!" unless self.respond_to?(:wrapper)
        raise MotionModelResource::URLNotDefinedError.new "Resource URL ist not defined! (#{name}.url)" if site.blank? && self.try(:url).blank?

        site = self.url if site.blank?

        BW::HTTP.get(site, params) do |response|
          models = []
          if response.ok? && response.body.present?
            begin
              json = BW::JSON.parse(response.body.to_str)
              models = update_models(json)
            rescue BW::JSON::ParserError
            end
          end

          block.call(models) if block.present? && block.respond_to?(:call)
        end
      end

      # Parses given JSON object and saves the founded models.
      # Returns an array with models, or the founded model
      def update_models(json)
        if json.is_a?(Array)
          model_ids = []
          for json_part in json
            model = save_model_with(json_part)
            model_ids << "#{model.id}".to_i if model.present?
          end
          where(:id).in model_ids
        else
          model = save_model_with(json)
          return nil if model.blank?

          find("#{model.id}".to_i)
        end
      end

      # Builds a model for given JSON object. Returns a new or presend model.
      def build_model_with(json)
        return nil if json.is_a?(Array)

        model = where("id").eq(json["id"]).first || self.new        
        model.wrap(json)
      end

      # Builds and update/create a model for given JSON object. Returns a new or presend model.
      def save_model_with(json)
        return nil if json.is_a?(Array)

        model = build_model_with(json)
        model.try :save
        model
      end
    end

    # Instance methods

    # When called, the lastSyncAt Column will be set with Time.now (if present)
    def touch_sync
      self.lastSyncAt = Time.now if self.respond_to?(:lastSyncAt=)
    end

    # Saves the current model. Calls super when block is not given.
    # If block is given, the url method will be needed to call the remote server.
    # The answer of the server will be parsed and stored.
    # If the record is a new one, a POST request will be fired, otherwise a PUT call comes to the server.
    def save(options = {}, &block)
      if block.present?
        save_remote(options, &block)
      else
        super
      end
    end
    
    def save_remote(options, &block)
      raise MotionModelResource::URLNotDefinedError.new "URL is not defined for #{self.class.name}!" unless self.class.respond_to?(:url)

      self.id = nil if self.id.present? && save_action == :create

      params = build_hash_from_model(self.class.name.underscore, self)
      params.merge!(options[:params]) if options[:params].present?

      model = self

      save_remote_call(params) do |response|
        if response.ok? && response.body.present?
          begin
            json = BW::JSON.parse(response.body.to_str)

            model.wrap json
            model.save
            model.touch_sync
          rescue BW::JSON::ParserError
            model = nil
          end
        else
          model = nil
        end

        block.call(model, json) if block.present? && block.respond_to?(:call)
      end
    end

    def destroy(options = {}, &block)
      if block.present?
        destroy_remote(options, &block)
      else
        super
      end
    end
    
    # Destroys a remote model
    # UNTESTED # TODO write a test
    def destroy_remote(options = {}, &block)
      raise MotionModelResource::URLNotDefinedError.new "URL is not defined for #{self.class.name}!" unless self.class.respond_to?(:url)
      
      model = self

      BW::HTTP.delete(save_url, {payload: options[:params]}) do |response|
        if response.ok? || options[:force] == true
          model.delete
        end

        block.call if block.present? && block.respond_to?(:call)
      end
    end
    
    # Takes no care of the server response.
    # UNTESTED # TODO write a test
    def destroy!(options = {}, &block)
      options.merge!(force: true)

      destroy_remote(options, &block)
    end
    alias_method :destroy_remote!, :destroy!

    # Returns a hash with given model
    def build_hash_from_model(main_key, model)
      hash = {
        main_key => {}
      }
      hash[main_key] = {}

      model.attributes.each do |key, attribute|
        if model.class.has_many_columns.keys.include?(key)
          new_key = attribute.first.class.name.pluralize.underscore
          hash[main_key][new_key] = []
          for a in attribute
            hash[main_key][new_key].push(build_hash_from_model(new_key, a)[new_key])
          end
        elsif attribute.respond_to?(:attributes)
          new_key = attribute.class.name.underscore
          h = attribute.build_hash_from_model(new_key, attribute)
          hash[main_key][new_key] = h[new_key] if h.has_key?(new_key)
        else
          model.class.wrapper[:fields].each do |wrapper_key, wrapper_value|
            hash[main_key][wrapper_key] = attribute if wrapper_value == key
          end
        end
      end

      hash
    end

    # Loads the given URL and parse the JSON for a model.
    # If the model is present, the model will updates.
    # If block given, the block will called, when the the model is saved. The model will be passed as an argument to the block.
    def fetch(site = nil, params = {}, &block)
      raise MotionModelResource::URLNotDefinedError.new "Resource URL ist not defined! (#{self.class.name}.url)" if site.blank? && self.class.try(:url).blank?
      raise MotionModelResource::WrapperNotDefinedError.new "Wrapper is not defined!" unless self.class.respond_to?(:wrapper)

      site = "#{self.class.url}/#{id}" if site.blank?

      model = self
      BW::HTTP.get(site, params) do |response|
        if response.ok? && response.body.present?
          begin
            json = BW::JSON.parse(response.body.to_str)
            model.wrap(json)

            model.save
          rescue BW::JSON::ParserError
            model = nil
          end
        else
          model = nil
        end

        block.call model if block.present? && block.respond_to?(:call)
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
          value = parse_value(local, model_json["#{online}"])
          self.send("#{local}=", value)
        end
      end

      if self.class.wrapper[:relations].present?
        self.class.wrapper[:relations].each do |relation|
          if model_json.respond_to?("key?") && model_json.key?("#{relation}") && model_json["#{relation}"].present?
            klass_name = column(relation.to_s).instance_variable_get("@options").try(:[], :joined_class_name) || relation.to_s.singularize.camelize

            klass = Object.const_get(klass_name)

            new_relation = klass.update_models(model_json["#{relation}"])
            self.send("#{relation}=", new_relation) rescue NoMethodError # not correct implemented in MotionModel
          end
        end
      end

      self
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

    private

    # Returns the action for save
    def save_action
      if new_record?
        :create
      elsif self.id.present?
        :update
      else
        raise MotionModelResource::ActionNotImplemented.new "Action ist not implemented for #{self.class.name}!"
      end
    end

    # Returns the URL for the resource
    def save_url
      raise MotionModelResource::URLNotDefinedError.new "URL is not defined for #{self.class.name}!" unless self.class.respond_to?(:url)

      case save_action
      when :create then self.try(:url) || self.class.url
      when :update then self.try(:url) || "#{self.class.url}/#{id}"
      end
    end

    # Calls a request to the remote server with the given params.
    def save_remote_call(params, &request_block)
      case save_action
      when :create
        BW::HTTP.post(save_url, {payload: params}, &request_block)
      when :update
        BW::HTTP.put(save_url, {payload: params}, &request_block)
      end
    end
  end
end