

module JekyllMultilang

  class Translate < Liquid::Tag
    include JekyllMultilang::Utilities
    include JekyllMultilang::Core

    def initialize(tag_name, passed_arguments, tokens)
      super
      arguments, options = split_arguments(passed_arguments)
      options = TagParser.new.parse(options)
      Jekyll.logger.debug(log_topic, "init arguments: " + arguments.inspect)
      Jekyll.logger.debug(log_topic, "init lang_key: " + @lang_key.inspect)
      Jekyll.logger.debug(log_topic, "options: " + options.inspect)
      @lang_key = arguments[0]
      @lang = options.lang
    end

    def render(context)
      # Parse the language key.
      lang_key = get_page_variable(@lang_key, context)
      lang_key = render_variable(lang_key, context)
      
      # Use the page language if not specified.
      if @lang.nil?
        lang = context['page']['lang']
      else
        lang = @lang
      end

      translation = MLCore.parsed_translation[lang].access(lang_key) if lang_key.is_a?(String)
      Jekyll.logger.debug(log_topic, "lang: " + lang + "; lang_key: " + lang_key + "; translation: " + translation.inspect)

      if translation.nil? or translation.empty?
        translation = MLCore.parsed_translation[MLCore.default_lang].access(lang_key) || '???'
        Jekyll.logger.error(log_topic, "Missing i18n key: #{lang}: #{lang_key}. Tried to use the translation of the default language.")
      end
      
      translation
    end
    
  end

end



Liquid::Template.register_tag('translate', JekyllMultilang::Translate)
