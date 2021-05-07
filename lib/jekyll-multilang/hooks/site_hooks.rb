Jekyll::Hooks.register :site, :after_init do |site|
  # Initialize the plugin.
  include JekyllMultilang::Utilities
  include JekyllMultilang::Core

  Jekyll.logger.info "JekyllMultilang:", "Starting the :site:after_init hook."

  # Update missing configuration with plugin defaults.
  defaults = MLCore.defaults.dup
  Jekyll.logger.debug(log_topic, "defaults: " + defaults.inspect)
  MLCore.config = defaults.merge(site.config['multilang'] || {})
  Jekyll.logger.debug(log_topic, "updated config: " + MLCore.config.inspect)

  # Check for site languages.
  if MLCore.config['languages'].empty?
    Jekyll.logger.error(log_topic, "No site languages defined. Please set 'languages' parameter in the Jekyll configuration file (_config.yml). Can't continue.")
    exit
  end

  # Set the default language.
  if MLCore.config['default_language'].nil?
    Jekyll.logger.warn(log_topic, "No default language specified, using the first site language.")
    MLCore.default_lang = MLCore.config['languages'][0]
  else
    if MLCore.config['languages'].include? MLCore.config['default_language']
      MLCore.default_lang = MLCore.config['default_language']
    else
      Jekyll.logger.warn(log_topic, "The specified default language #{MLCore.config['default_language']} is not in the specified site languages #{MLCore.config['languages']}. Using the first site langauge as the default language.")
      MLCore.default_lang = MLCore.config['languages'][0]
    end
  end

  # Set language specific configuration and load the translation data.
  languages = site.config['multilang']['languages']
  languages.each do |lang|
    # Inject the page language using the site defaults.
    site.config['defaults'].append({"scope"=>{"path"=>lang}, "values"=>{"lang"=>lang}})
    
    # Load the translation files.
    Jekyll.logger.info(log_topic, "Loading translation from file #{site.source}/_i18n/#{lang}.yml")
    MLCore.parsed_translation[lang] = YAML.load_file("#{site.source}/_i18n/#{lang}.yml")
    Jekyll.logger.debug(log_topic, "parsed_translations: " + MLCore.parsed_translation.inspect)
  end
  
end


Jekyll::Hooks.register :site, :post_read do |site|
  # Initialize the plugin.
  include JekyllMultilang::Utilities
  include JekyllMultilang::Core

  Jekyll.logger.info(log_topic, "Starting the :site:post_read hook.")

  namespace = Hash.new

  # Customize the pages.
  Jekyll.logger.info(log_topic, "Customizing the pages.")
  site.pages.each do |page|
    Jekyll.logger.debug(log_topic, "title: #{page.data['title']}")

    # Get the page language.
    lang = page.data['lang']

    Jekyll.logger.debug(log_topic, "lang: #{lang}")
                        
   
    # Set the permalink of the page. This is used by the page when creating the
    # page url.
    # !! Don't call the page.url method before setting the permalink. This will
    # initialize the page.url instance variable and return this variable on every
    # successive call to page.url. Setting the permalink won't alter the url anylonger.
    #
    # TODO: This is a potential point of error if some other plugin or method calls the
    # page.url methode before this point. Try to find a better solution.
    #
    if !page.data['lang'].nil?
      # Create the post permalink and url including the language directory.
      ml_permalink = Jekyll::URL.new(
        :template => page.template,
        :placeholders => page.url_placeholders,
        :permalink => page.data['permalink']
      ).to_s
      # Without a specified permalink, the page permalink ist built using the path
      # and the basename including the language directory.
      # Remove the language from the permalink.
      if ml_permalink.start_with? ("/#{lang}")
        ml_permalink = ml_permalink.sub("/#{lang}", "") 
      end

      # Set the page permalink data.
      page.data['ml_permalink'] = ml_permalink
      lang_permalink = "/#{lang}" + ml_permalink
      if lang == MLCore.default_lang
        page.data['permalink'] = ml_permalink
      else
        page.data['permalink'] = lang_permalink
      end      
    end

    # Extract the namespace information.
    if page.data.has_key? 'namespace'
      if namespace.has_key? page.data['namespace']
        namespace[page.data['namespace']][lang] = {'permalink' => page.data['permalink']}
      else
        namespace[page.data['namespace']] = {lang => {'permalink' => page.data['permalink']}}
      end
    end

    Jekyll.logger.info(log_topic, "ml_permalink: " + page.data['ml_permalink'].inspect)
    Jekyll.logger.info(log_topic, "permalink: " + page.permalink.inspect)
    Jekyll.logger.info(log_topic, "url after permalink: " + page.url)

  end

  # Customize the collections.
  Jekyll.logger.debug(log_topic, "collections: " + site.collections.inspect)
  site.collections.each do |col_name, col|
    Jekyll.logger.info(log_topic, "Customizing the collection #{col_name}.")

    col.docs.each do |doc|
      # Get the document language.
      lang = doc.data['lang']
      
      # Remove the language from the categories.
      doc.data['categories'].delete(lang)

      if col_name == 'posts'
        # Add the post date to the given namespace to make sure, that it is unique.
        post_date_slug = doc.data['date'].strftime("%Y%m%d")
        post_namespace = doc.data['namespace'] || doc.data['slug']
        doc.data['namespace'] = col_name + '_' + post_date_slug + '_' + post_namespace
      else
        doc.data['namespace'] = col_name + '_' + post_namespace
      end

      # Create the post permalink and url including the language directory.
      ml_permalink = Jekyll::URL.new(
        :template => doc.url_template,
        :placeholders => doc.url_placeholders
      ).to_s
      doc.data['ml_permalink'] = ml_permalink
      lang_permalink = "/#{lang}" + ml_permalink
      if lang == MLCore.default_lang
        doc.data['permalink'] = ml_permalink
      else
        doc.data['permalink'] = lang_permalink
      end

      # Save the post namespace data in the namespace hash.
      if namespace.has_key? doc.data['namespace']
        namespace[doc.data['namespace']][lang] = {'permalink' => doc.data['permalink']}
      else
        namespace[doc.data['namespace']] = {lang => {'permalink' => doc.data['permalink']}}
      end

      Jekyll.logger.debug(log_topic, "doc: " + doc.inspect)
      Jekyll.logger.debug(log_topic, "local variables: " + doc.instance_variables.inspect)
      Jekyll.logger.debug(log_topic, "doc.data: " + doc.data.inspect)
      Jekyll.logger.debug(log_topic, "permalink: " + doc.permalink.inspect)
      Jekyll.logger.debug(log_topic, "url: " + doc.url)
    end
  end

  # Save the namespace in the site data hash.
  Jekyll.logger.debug(log_topic, "namespace: " + namespace.inspect)
  site.data['namespace'] = namespace

  # Created a hash of documents grouped by their language.
  site.data['ml_posts'] = Hash.new
  site.data['ml_pages'] = Hash.new
  MLCore.config['languages'].each do |lang|
    site.data['ml_posts'][lang] = site.posts.docs.select {|post| post.data['lang'] == lang}
    site.data['ml_posts'][lang] = site.data['ml_posts'][lang].sort_by {|post| post.date}.reverse
    site.data['ml_pages'][lang] = site.pages.select {|page| page.data['lang'] == lang}
  end
end
