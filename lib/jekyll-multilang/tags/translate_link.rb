module JekyllMultilang

  class TranslateLink < Liquid::Tag

    def initialize(tag_name, arguments, tokens)
      super
      @arguments = arguments
    end

    def render(context)
      @arguments
    end
  end

end

Liquid::Template.register_tag('translate_link', JekyllMultilang::TranslateLink)
