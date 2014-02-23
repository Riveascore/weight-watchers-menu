CONFIG = YAML.load_file(File.dirname(__FILE__) + "/config.yml")[ENV['RACK_ENV'] || "development"]

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://localhost/app_development")

Dir[File.dirname(__FILE__) + '/models/*.rb'].each { |model| require model }

require './helpers'
# Home
set :bind, '192.168.1.142'
class App < Sinatra::Base
  # If you run into issues with click-jacking (like with Facebook
  # Canvas apps), or with CSRF issues, you may want to disable
  # sinatra-contrib's default protection:
  #
  # disable :protection

  set :root, File.dirname(__FILE__)
  set :sprockets, (Sprockets::Environment.new(root) { |env| env.logger = Logger.new(STDOUT) })
  set :assets_path, File.join(root, 'assets')
  set :environments, %w{development staging production}

  # If you're writing a Facebook application which requires AJAX requests
  # (such as submitting a form, or downloading JSON data), you're going to want to
  # uncomment the following block:
  #
  # before do
  #   headers["P3P"] = 'CP="IDC DSP COR CURa ADMa OUR IND PHY ONL COM STA"'
  # end

  configure do
    sprockets.append_path File.join(root, 'assets', 'stylesheets')
    sprockets.append_path File.join(root, 'assets', 'javascripts')
  end

  configure :development do
    register Sinatra::Reloader
  end

  helpers Sinatra::AssetHelpers

  get "/" do
    @finalRecipeObjects = []

    coreURL = "http://www.food.com/recipe-finder/all/weight-watchers"
    page = Nokogiri::HTML(open(coreURL))

    pagesList = page.css('.rz-pagi a[href^="?pn="]')
    numberOfPages = pagesList[pagesList.length-2].text.to_i

    (1..numberOfPages).each do |num|

      currentPage = coreURL + "?pn=" + num.to_s
      currentNoko = Nokogiri::HTML(open(currentPage))
      recipeItems = currentNoko.css('.pod.sr-recipe-item .sr-recipe-item-e a')

      recipeItems.each do |recipeItem|
        picture = recipeItem.search("img").attribute("src").content

        # if contains fdc-default, don't use...
        if !picture.include?("fdc-default")
          linkToRecipe = recipeItem.attribute("href")
          @finalRecipeObjects << { 
            :href => linkToRecipe.content, 
            :src => picture.sub(/thumbs/, "large")
          }
        end
      end
    end

    # Shuffle array:
    @finalRecipeObjects.shuffle!
    haml :index
  end
end

DataMapper.finalize