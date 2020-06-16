namespace :parsing do
  task get_category_links: :environment do
    site_url = "https://polletkani.ru/products"
    doc = Nokogiri::HTML(RestClient::Request.execute(:url => site_url, :method => :get, :verify_ssl => false))
    categories_links = doc.css('.catalog-menu .catalog-menu__item  a').map { |category| category['href']}.uniq
    categories_links.each do |category_link|
      Rake::Task['parsing:get_pagination'].invoke(category_link)
      Rake::Task['parsing:get_pagination'].reenable
    end
  end

  task :get_pagination, [:category_link] => :environment do |_t, args|
    category_link = args[:category_link]
    category_url = "https://polletkani.ru#{category_link}"
    doc_category = Nokogiri::HTML(RestClient::Request.execute(:url => category_url, :method => :get, :verify_ssl => false))
    count_pages = doc_category.css('.pagination__item')

    Rake::Task['parsing:get_product_links'].invoke(category_url)
    Rake::Task['parsing:get_product_links'].reenable

    if count_pages.size != 0
      (2..count_pages.size).each do |page|
        category_url = "https://polletkani.ru#{category_link}?page=#{page}"
        Rake::Task['parsing:get_product_links'].invoke(category_url)
        Rake::Task['parsing:get_product_links'].reenable
      end
    end
  end

  task :get_product_links, [:category_url] => :environment do |_t, args|
    category_url = args[:category_url]
    doc_category = Nokogiri::HTML(RestClient::Request.execute(:url => category_url, :method => :get, :verify_ssl => false))
    products_url_in_category = doc_category.css('.product-item__content a').map { |category| category['href']}.uniq

    Rake::Task['parsing:get_product'].invoke(products_url_in_category)
    Rake::Task['parsing:get_product'].reenable
  end

  task :get_product, [:products_url_in_category] => :environment do |_t, args|
    args[:products_url_in_category].each do |product_link|
      doc_product = Nokogiri::HTML(RestClient::Request.execute(:url => product_link, :method => :get, :verify_ssl => false))
      @tov = Tov.new
      @tov.fid = product_link.split('/').last
      @tov.link = product_link
      @tov.title = doc_product.css('h1').text
      @tov.desc = doc_product.css('.product__desc').inner_html
      @tov.price = doc_product.css('.product-price').first.text.strip
      @tov.pict = doc_product.css('.fancy-img').map { |image| "http:#{image['href']}" }.uniq.join(' ')
      # p1 =
      # p2 =
      @tov.p3 = "НОВИНКА" if doc_product.css('.markers').present?
      @tov.p4 = "Каталог/#{doc_product.css('.bread-crumbs__text')[1].text}"
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
        p "создан товар #{@tov.fid}"
      else
        p "!!!!ОШИБКА!!!!! товара #{@tov.fid}"
      end
    end
    p Tov.count
  end
end

