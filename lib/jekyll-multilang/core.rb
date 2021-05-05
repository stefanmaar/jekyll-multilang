module JekyllMultilang 
  module Core
    # The MLBase module holds global data
    # used by the plugin.
    # The data is initialized in the Jekyll after_init hook.
    module MLCore
      class << self
        # The plugin configuration.
        attr_accessor :config

        # The default language.
        attr_accessor :default_lang
        
        # The translation data read from the yaml files.
        attr_accessor :parsed_translation;
      end

      self.config = Hash.new
      self.parsed_translation = Hash.new
    end
  end
end
