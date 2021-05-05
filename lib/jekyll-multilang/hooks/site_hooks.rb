Jekyll::Hooks.register :site, :after_init do |site|
  # Initialize the plugin.
  include JekyllMultilang::Utilities
  include JekyllMultilang::Core

  Jekyll.logger.info "JekyllMultilang:", "Initializing."

  # Update missing configuration with plugin defaults.
  MLCore.config = site.config['multilang']
  MLCore.default_lang = MLCore.config['languages'][0]

  # Set the scope of the language folders.

  # Load the translation files.
  languages = site.config['multilang']['languages']
  languages.each do |lang|
    Jekyll.logger.info(log_topic, "Loading translation from file #{site.source}/_i18n/#{lang}.yml")
    MLCore.parsed_translation[lang] = YAML.load_file("#{site.source}/_i18n/#{lang}.yml")
    Jekyll.logger.info(log_topic, "parsed_translations: " + MLCore.parsed_translation.inspect)
  end
  
end
