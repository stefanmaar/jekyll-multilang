module JekyllMultilang

  class TranslateLink < Liquid::Tag
    include JekyllMultilang::Utilities
    include JekyllMultilang::Core

    def initialize(tag_name, passed_arguments, tokens)
      super
      arguments, options = split_arguments(passed_arguments)
      options = TagParser.new.parse(options)
      @namespace = arguments[0]
      @lang = options.lang

      Jekyll.logger.debug(log_topic, "init arguments: " + arguments.inspect)
      Jekyll.logger.debug(log_topic, "init options: " + options.inspect)
      Jekyll.logger.debug(log_topic, "init lang: " + @lang.inspect)
    end

    def render(context)
      Jekyll.logger.debug(log_topic, "Translating Link")
      
      # Parse the namespace.
      namespace = get_page_variable(@namespace, context)
      namespace = render_variable(namespace, context)

      # Get the page title.
      page_url = context['page']['url']

      # Get site spcecific data.
      site = context.registers[:site]
      site_namespace = site.data['namespace']
      Jekyll.logger.debug(log_topic, "site_namespace: " + site_namespace.inspect)

      # Get the default language.
      default_lang ||= MLCore.default_lang

      # Use the page language if not specified.
      if @lang.nil?
        lang = context['page']['lang']
      else
        lang = default_lang
      end

      # Get the permalink for the requested namespace and language.
      default_permalink = site_namespace.dig(namespace, default_lang, 'permalink') || context['page']['permalink'] || context['page']['url']
      permalink = site_namespace.dig(namespace, lang, 'permalink')
      if permalink.nil?
        Jekyll.logger.warn(log_topic, "TranslateLink - Page #{page_url}. No namespace for #{namespace} and language #{lang}. Using a fallback link....")
        Jekyll.logger.debug(log_topic, "site namespace: " + site_namespace[namespace].inspect)
        permalink = default_permalink
      end
      
      url = site.baseurl + permalink
      Jekyll.logger.debug(log_topic, "translated url: " + url.inspect)
      url
    end
  end

end

Liquid::Template.register_tag('translate_link', JekyllMultilang::TranslateLink)
