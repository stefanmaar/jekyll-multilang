

module JekyllMultilang

  class Translate < Liquid::Tag
    include JekyllMultilang::Utilities
    include JekyllMultilang::Core

    def initialize(tag_name, passed_arguments, tokens)
      super
      #@config = multilang_config
      arguments, options = split_arguments(passed_arguments)
      options = TagParser.new.parse(options)
      Jekyll.logger.info(log_topic, "init arguments: " + arguments.inspect)
      Jekyll.logger.info(log_topic, "init lang_key: " + @lang_key.inspect)
      #Jekyll.logger.info(log_topic, "options: " + options.inspect)
      @lang_key = arguments[0].dup
      @lang = options.lang
      Jekyll.logger.info(log_topic, "init lang_key: " + @lang_key.inspect)
    end

    def render(context)
      Jekyll.logger.info(log_topic, "processing page: " + context['page']['title'])
      Jekyll.logger.info(log_topic, "lang_key: " + @lang_key.inspect)
      Jekyll.logger.info(log_topic, "context_lang_key: " + "#{context[@lang_key.strip]}")

      # Parse the language key.
      lang_key = get_page_variable(@lang_key, context)
      lang_key = render_variable(lang_key, context)
      
      lang ||= MLCore.default_lang

      translation = MLCore.parsed_translation[lang].access(lang_key) if lang_key.is_a?(String)
      Jekyll.logger.info(log_topic, "translation: " + translation.inspect)

      if translation.nil? or translation.empty?
        translation = MLCore.parsed_translation[lang].access(lang_key) || '???'
        Jekyll.logger.error(log_topic, "Missing i18n key: #{lang}: #{lang_key}. Tried to use the translation of the default language.")
      end
      
      translation
    end
    
  end

end



Liquid::Template.register_tag('translate', JekyllMultilang::Translate)
