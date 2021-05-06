require 'optparse'


module JekyllMultilang

  module Utilities
    TagOptions = Struct.new(:lang)

    @@log_topic = 'JekyllMultiLang:'

    def split_arguments(arg_string)
      #Jekyll.logger.info "JekyllMultilang:", "arg_string: " + arg_string
      tokens = arg_string.strip.split(/\s+/)
      arguments = tokens.take_while { |a| !a.start_with?('-') }
      options = (tokens - arguments)

      [arguments, options]
    end
    

    def log_topic
      return @@log_topic
    end

    
    def get_multilang_config(context)
      return context.registers[:site].config['multilang']
    end


    # Get page variables from the context using a variable string.
    def get_page_variable(var, context)
      if "#{context[var]}" != ""
        rendered = "#{context[var]}"
      else
        rendered = var
      end
      
      rendered
    end


    # Render a variable.
    def render_variable(var, context)
      Liquid::Template.parse(var).render(context)
    end

    
    class TagParser

      def parse(options)
        parsed_options = TagOptions.new

        opt_parser = OptionParser.new do |opts|
          opts.on("-l", "--lang LANG") do |lang|
            parsed_options.lang = lang
          end
        end

        opt_parser.parse!(options)

        return parsed_options
      end
    end
  end
end
 


# Extend the Hash with an access method accepting
# point separated strings.
class Hash
  
  def access(path)
    value = self
    
    path.to_s.split('.').each do |p|
      if p.to_i.to_s == p
        value = value[p.to_i]
      else
        value = value[p].nil? ? value[p.to_sym] : value[p]
      end
      break if value.nil?
    end
    
    value
  end
end
