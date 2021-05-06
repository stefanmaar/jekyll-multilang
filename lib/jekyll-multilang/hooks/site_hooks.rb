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
    Jekyll.logger.debug(log_topic, "local variables: " + page.instance_variables.inspect)
    lang = page.data['lang']
   
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
      page.data['ml_permalink'] = page.data['permalink']
      unless lang == MLCore.default_lang
        page.data['permalink'] = "/#{lang}" + page.data['permalink']
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

    Jekyll.logger.debug(log_topic, "permalink: " + page.permalink.inspect)
    Jekyll.logger.debug(log_topic, "url after permalink: " + page.url)

  end

  # Customize the posts.
  Jekyll.logger.info(log_topic, "Customizing the posts.")
  site.posts.docs.each do |post|
    # Get the post language.
    lang = post.data['lang']
    
    # Remove the language from the categories.
    post.data['categories'].delete(post.data['lang'])
    
    # Add the post date to the given namespace to make sure, that it is unique.
    post_date_slug = post.data['date'].strftime("%Y%m%d")
    post_namespace = post.data['namespace'] || post.data['slug']
    post.data['namespace'] = post_date_slug + '_' + post_namespace

    # Create the post permalink and url including the language directory.
    ml_permalink = Jekyll::URL.new(
      :template => post.url_template,
      :placeholders => post.url_placeholders
    ).to_s
    post.data['ml_permalink'] = ml_permalink
    lang_permalink = "/#{lang}" + ml_permalink
    if lang == MLCore.default_lang
      post.data['permalink'] = ml_permalink
    else
      post.data['permalink'] = lang_permalink
    end

    # Save the post namespace data in the namespace hash.
    if namespace.has_key? post.data['namespace']
      namespace[post.data['namespace']][lang] = {'permalink' => post.data['permalink']}
    else
      namespace[post.data['namespace']] = {lang => {'permalink' => post.data['permalink']}}
    end

    Jekyll.logger.debug(log_topic, "post: " + post.inspect)
    Jekyll.logger.debug(log_topic, "local variables: " + post.instance_variables.inspect)
    Jekyll.logger.debug(log_topic, "post.data: " + post.data.inspect)
    Jekyll.logger.debug(log_topic, "permalink: " + post.permalink.inspect)
    Jekyll.logger.debug(log_topic, "url: " + post.url)
  end

  # Save the namespace in the site data hash.
  Jekyll.logger.debug(log_topic, "namespace: " + namespace.inspect)
  site.data['namespace'] = namespace

  # Created a hash of posts grouped by their language.
  site.data['ml_posts'] = Hash.new
  MLCore.config['languages'].each do |lang|
    site.data['ml_posts'][lang] = site.posts.docs.select {|post| post.data['lang'] == lang}
  end
end
