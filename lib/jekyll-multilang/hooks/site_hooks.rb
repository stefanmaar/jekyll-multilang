Jekyll::Hooks.register :site, :after_init do |site|
  # Initialize the plugin.
  include JekyllMultilang::Utilities
  include JekyllMultilang::Core

  Jekyll.logger.info "JekyllMultilang:", "Initializing."

  # Update missing configuration with plugin defaults.
  defaults = MLCore.defaults.dup
  Jekyll.logger.info(log_topic, "defaults: " + defaults.inspect)
  MLCore.config = defaults.merge(site.config['multilang'] || {})
  Jekyll.logger.info(log_topic, "updated config: " + MLCore.config.inspect)

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
    Jekyll.logger.info(log_topic, "parsed_translations: " + MLCore.parsed_translation.inspect)
  end
  
end


Jekyll::Hooks.register :site, :post_read do |site|
  # Initialize the plugin.
  include JekyllMultilang::Utilities
  include JekyllMultilang::Core

  Jekyll.logger.info(log_topic, "Site post rendering.")

  namespace = Hash.new

  # Customize the pages.
  site.pages.each do |page|
    Jekyll.logger.info(log_topic, "local variables: " + page.instance_variables.inspect)
    #Jekyll.logger.info(log_topic, "page: " + page.data.inspect)
    #Jekyll.logger.info(log_topic, "dir: " + page.dir)
    #Jekyll.logger.info(log_topic, "url: " + page.url)
    #Jekyll.logger.info(log_topic, "lang: " + page.data['lang'].inspect)

    # Extract the namespace information.
    if page.data.has_key? 'namespace'
      lang = page.data['lang']
      if namespace.has_key? page.data['namespace']
        namespace[page.data['namespace']][lang] = {'permalink' => page.data['permalink']}
      else
        namespace[page.data['namespace']] = {lang => {'permalink' => page.data['permalink']}}
      end
    end

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
      page.data['permalink'] = '/' + page.data['lang'] + page.data['permalink']
    end

    Jekyll.logger.info(log_topic, "permalink: " + page.permalink.inspect)
    Jekyll.logger.info(log_topic, "url after permalink: " + page.url)

  end
  
  Jekyll.logger.info(log_topic, "namespace: " + namespace.inspect)
  site.data['namespace'] = namespace
  
  site.posts.docs.each do |post|
    # Set the permalink of the post.
    #post.data['permalink'] = '/deutsch/' + post.data['slug'] + '/'

    Jekyll.logger.info(log_topic, "post: " + post.inspect)
    Jekyll.logger.info(log_topic, "local variables: " + post.instance_variables.inspect)
    Jekyll.logger.info(log_topic, "post.data: " + post.data.inspect)
    Jekyll.logger.info(log_topic, "permalink: " + post.permalink.inspect)
    Jekyll.logger.info(log_topic, "url: " + post.url)
  end

  # Created a hash of posts grouped by their language.
  site.data['ml_posts'] = Hash.new
  MLCore.config['languages'].each do |lang|
    site.data['ml_posts'][lang] = site.posts.docs.select {|post| post.data['lang'] == lang}
  end
  Jekyll.logger.info(log_topic, "ml_posts: " + site.data['ml_posts'].inspect)
  
end
