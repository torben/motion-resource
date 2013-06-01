module MotionResource
  class WrapperNotDefinedError < Exception; end

  module ApiWrapper
    def self.included(base)
      base.extend(PublicClassMethods)
    end

    module PublicClassMethods
      def lastUpdate
        order(:updatedAt).first.try(:updatedAt)
      end

      # ActiveResource
      def fetch(site, params = {}, &block)
        raise MotionResource::WrapperNotDefinedError.new "Wrapper is not defined!" unless self.respond_to?(:wrapper)
        BW::HTTP.get(site, params) do |response|
          models = []
          if response.ok? && response.body.present?
            json = BW::JSON.parse(response.body.to_str)
            models = updateModels(json)
          end

          block.call(models) if block.present? && block.respond_to?(:call)
        end
      end

      def updateModels(json)
        if json.is_a?(Array)
          models = []
          for jsonPart in json
            model = buildModel(jsonPart)
            if model.present?
              model.save
              models << model
            end
          end
          return models
        else
          model = buildModel(json)
          if model.present?
            model.save
            return model
          end
        end
      end

      def buildModel(json)
        classname = name.downcase

        model = where("id").eq(json["id"]).first
        if model.present?
          if model.wrap(json)
            model.lastSyncAt = Time.now if model.respond_to?(:lastSyncAt)
            return model
          end
        else
          newModel = self.new
          return newModel if newModel.wrap(json)
        end

        return nil
      end
    end

    def save(options = {}, &block)
      if block.present?
        NSException.raise("URL is not defined for #{self.class.name}!", format: "error") unless self.class.respond_to?(:url)

        action = if new_record?
          "create"
        elsif self.id.present?
          "update"
        else
          NSException.raise("Action ist not implemented for #{self.class.name}!", format: "error")
        end

        model = self

        model.id = nil if model.id.present? && action == "create"

        hash = buildHashFromModel(self.class.name.downcase, self)
        hash.merge!(options[:params]) if options[:params].present?

        requestBlock = Proc.new do |response|
          if response.ok? && response.body.present?
            json = BW::JSON.parse(response.body.to_str)

            model.wrap(json)
            model.lastSyncAt = Time.now if model.respond_to?(:lastSyncAt)
            model.save
          else
            model = nil
          end

          block.call(model) if block.present? && block.respond_to?(:call)
        end

        case action
        when "create"
          BW::HTTP.post(self.class.url, {payload: hash}, &requestBlock)
        when "update"
          BW::HTTP.put("#{self.class.url}/#{model.id}", {payload: hash}, &requestBlock)
        end
      else
        super
      end
    end

    def buildHashFromModel(mainKey, model)
      hash = {
        mainKey => {}
      }
      hash[mainKey] = {}

      model.attributes.each do |key, attribute|
        if model.class.has_many_columns.keys.include?(key)
          newKey = attribute.first.class.name.pluralize.downcase
          hash[mainKey][newKey] = []
          for a in attribute
            hash[mainKey][newKey].push(buildHashFromModel(newKey, a)[newKey])
          end
        elsif attribute.respond_to?(:attributes)
          newKey = attribute.class.name.downcase
          h = buildHashFromModel(newKey, attribute)
          hash[mainKey][newKey] = h[newKey] if h.has_key?(newKey)
        else
          model.class.wrapper[:fields].each do |wrapperKey, wrapperValue|
            hash[mainKey][wrapperKey] = attribute if wrapperValue == key
          end
        end
      end

      return hash
    end

    def fetch(site, params, &block)
      NSException.raise("Wrapper is not defined!", format: "error") unless self.class.respond_to?"wrapper"
      model = self
      BW::HTTP.get(site, params) do |response|
        if response.ok? && response.body.present?
          json = BW::JSON.parse(response.body.to_str)
          model.wrap(json)
          model.lastSyncAt = Time.now if model.respond_to?(:lastSyncAt)

          model.save
        end

        block.call if block.present? && block.respond_to?(:call)
      end
    end

    def wrap(modelJson)
      return unless self.class.respond_to? "wrapper"

      self.class.wrapper[:fields].each do |online, local|
        if modelJson.respond_to?("key?") && modelJson.key?("#{online}")
          self.send("#{local}=", modelJson[online])
        end
      end

      if self.class.wrapper[:relations].present?
        self.class.wrapper[:relations].each do |relation|
          if modelJson.respond_to?("key?") && modelJson.key?("#{relation}") && modelJson["#{relation}"].present?
            klass = Object.const_get(relation.to_s.singularize.camelize)
            newRelation = klass.updateModels(modelJson["#{relation}"])
            self.send("#{relation}=", newRelation) rescue NoMethodError # not correct implemented in MotionModel
          end
        end
      end

      true
    end
  end
end