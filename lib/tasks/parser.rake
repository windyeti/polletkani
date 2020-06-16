namespace :product do
  task start: :environment do
    get_links_categories
  end

  def get_links_categories(url = '', category_path_name = [])
    category_url = url.empty? ? "https://polletkani.ru/products" : url
    doc = Nokogiri::HTML(RestClient::Request.execute(:url => category_url, :method => :get, :verify_ssl => false))

    # определяем категорию по крошкам, на стартовой их нет
    # передаем массив категорий до создания объекта товара
    doc_category_name = doc.css('.bread-crumbs__item_active')
    if doc_category_name.present?
      category_path_name.push( doc_category_name.text )
    else
      category_path_name.push( "Каталог" )
    end

    categories_urls = doc.css('.catalog__list .category-item a').map { |node_category| "https://polletkani.ru#{node_category['href']}"}.uniq

    # проверяем наличие вложенных категорий
    # если есть ---> recursive parsing:start
    if categories_urls.present?
      categories_urls.each do |category_url|
        get_links_categories(category_url, category_path_name)
      end
    end

    # определяем есть ли пагинация в этой категории
    count_pagination_pages = doc.css('.pagination__item')
    if !count_pagination_pages.empty?
      # тут надо определить первую страницу в пагинации, если она есть
      (1..count_pagination_pages.size).each do |number|
        # в нашем случае первая страница идет без параметра ?page=1 Надо смотреть как сделано
        pagination_category_url = number == 1 ?
                         category_url : "#{category_url}?page=#{number}"
        Rake::Task['product:get_product_links'].invoke(pagination_category_url, category_path_name)
        Rake::Task['product:get_product_links'].reenable
      end
    else
      Rake::Task['product:get_product_links'].invoke(category_url, category_path_name)
      Rake::Task['product:get_product_links'].reenable
    end
  end


  task :get_product_links, [:category_url, :category_path_name] => :environment do |_t, args|
    category_url = args[:category_url]
    category_path_name = args[:category_path_name]

    doc_category = Nokogiri::HTML(RestClient::Request.execute(:url => category_url, :method => :get, :verify_ssl => false))
    products_urls_in_category = doc_category.css('.product-item__content a').map { |category| category['href']}.uniq

    Rake::Task['product:get_product'].invoke(products_urls_in_category, category_path_name)
    Rake::Task['product:get_product'].reenable
  end

  task :get_product, [:products_urls_in_category, :category_path_name] => :environment do |_t, args|
    category_path_name = args[:category_path_name]
    args[:products_urls_in_category].each do |product_link|
      doc_product = Nokogiri::HTML(RestClient::Request.execute(:url => product_link, :method => :get, :verify_ssl => false))

      # по уникальному ключу ищем в базе уже созданный товар,
      # если он есть, то апдейтим дополняя 'Категория/Категория_1 ## Категория/Категория_2'
      # При импорте товар будет во всех указанных категориях
      fid = product_link.split('/').last
      @tov = Tov.find_by_fid(fid)

      if @tov
        tov_category_path_name = @tov.p4
        @tov.update(p4: "#{tov_category_path_name} ## #{category_path_name.join('/')}")
      else
        @tov = Tov.new
        @tov.fid = product_link.split('/').last
        @tov.link = product_link
        @tov.title = doc_product.css('h1').text
        @tov.desc = doc_product.at_css('.product__desc').inner_html if doc_product.at_css('.product__desc')
        @tov.price = doc_product.css('.product-price').first.text.strip.gsub(' руб.', '')
        @tov.pict = doc_product.css('.fancy-img').map { |image| "http:#{image['href']}" }.uniq.join(' ')
        # p1 =
        # p2 =
        @tov.p3 = "НОВИНКА" if doc_product.css('.markers').present?
        @tov.p4 = category_path_name.join('/')
        # @tov.p4 = "Каталог/#{doc_product.css('.bread-crumbs__text')[1].text}"
        # linkins =
        @tov.cat = 'Каталог'
        @tov.cat1 = doc_product.css('.bread-crumbs__text')[1].text
        # oldprice
        # insid
        @tov.mtitle = doc_product.css('title').text
        # mdesc
        @tov.mkeyw = doc_product.at_css('meta[name="keywords"]')['content']
        # sku
        # check
        # sdesc
        # cat2
        # cat3
        # label
        if @tov.save
          p "создан товар #{@tov.fid} -- всего: #{Tov.count}"
        else
          p "!!!!ОШИБКА!!!!! товара #{@tov.fid}"
        end
      end
    end
    p "Total: #{Tov.count}"
  end
end
