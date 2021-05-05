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

      #Jekyll.logger.info(log_topic, "+++++++++++++++++++++++++++++++++++++++++++")
      #Jekyll.logger.info(log_topic, "init arguments: " + arguments.inspect)
      #Jekyll.logger.info(log_topic, "init options: " + options.inspect)
      #Jekyll.logger.info(log_topic, "init lang: " + @lang.inspect)
    end

    def render(context)
      Jekyll.logger.info(log_topic, "###########################################")
      Jekyll.logger.info(log_topic, "Translating Link")
      # Parse the namespace.
      namespace = get_page_variable(@namespace, context)
      namespace = render_variable(namespace, context)

      # Use the page language if not specified.
      if @lang.nil?
        lang = context['page']['lang']
      else
        lang = @lang
      end
      
      site = context.registers[:site]
      site_namespace = site.data['namespace']
      Jekyll.logger.info(log_topic, "site_namespace: " + site_namespace.inspect)
      default_lang ||= MLCore.default_lang

      Jekyll.logger.info(log_topic, "lang: " + lang.inspect)
      Jekyll.logger.info(log_topic, "namespace: " + namespace.inspect)

      
      if site_namespace.has_key? namespace
        default_permalink = site_namespace[namespace][default_lang]['permalink'] || context['page']['permalink']
        permalink = site_namespace[namespace][lang]['permalink'] || default_permalink
      else
        Jekyll.logger.warn(log_topic, "No site namespace available for #{namespace}. Using a fallback link....")
        permalink = context['page']['permalink'] || context['page']['url']
      end

      url = site.baseurl + "/#{lang}" + permalink
      Jekyll.logger.info(log_topic, "translated url: " + url.inspect)
      url
    end
  end

end

Liquid::Template.register_tag('translate_link', JekyllMultilang::TranslateLink)
