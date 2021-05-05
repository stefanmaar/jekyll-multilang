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
        attr_accessor :parsed_translation

        # The default configuration.
        attr_accessor :defaults
      end

      self.config = Hash.new
      self.parsed_translation = Hash.new
      
      self.defaults = {
        # The languages of the site (e.g. ['de', 'en']).
        'languages' => [],

        # The default language (e.g. 'de').
        # If no default language is given, the first language in languages
        # is used.
        'default_language' => nil,
      }
      
    end
  end
end
