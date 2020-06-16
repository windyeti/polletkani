require 'csv'

class Tov < ApplicationRecord
  def self.csv_param
    puts "Файл tov инсалес c параметрами на лету"
    file = "#{Rails.public_path}"+'/tov.csv'
    check = File.file?(file)
    if check.present?
      File.delete(file)
    end
    file_ins = "#{Rails.public_path}"+'/ins_tov.csv'
    check = File.file?(file_ins)
    if check.present?
      File.delete(file_ins)
    end

    #создаём файл со статичными данными
    @tovs = Tov.order(:id)#.limit(10) #where('title like ?', '%Bellelli B-bip%')
    file = "#{Rails.root}/public/tov.csv"
    CSV.open(file, 'w') do |writer|
      headers = [
        'fid', 'Артикул', 'Название товара', 'Краткое описание', 'Полное описание', 'Цена продажи', 'Изображения',
        'Свойство: Цвет', 'Параметр: OLDLINK', 'Подкатегория 1', 'Подкатегория 2', 'Подкатегория 3', 'Подкатегория 4',
        'Тег title', 'Мета-тег description','Мета-тег keywords'
      ]

      writer << headers
      @tovs.each do |pr|
        if pr.title != nil
          # 			puts pr.id
          fid = pr.fid
          title = pr.title.split(',')[0]
          sku = pr.sku
          image = pr.pict
          price = pr.price
          link = pr.link
# 				qt = pr.qt
          sdesc = pr.sdesc
          desc = pr.desc
          cat = pr.cat
          cat1 = pr.cat1
          cat2 = pr.cat2
          cat3 = pr.cat3
          mtitle = pr.mtitle
          mdesc = pr.mdesc
          mkeyw = pr.mkeyw
          p4 = pr.p4
          writer << [fid, sku, title, sdesc, desc, price, image, p4, link, cat, cat1, cat2, cat3, mtitle, mdesc, mkeyw ]
        end
      end
    end #CSV.open

    #параметры в таблице записаны в виде - "Состояние: новый --- Вид: квадратный --- Объём: 3л --- Радиус: 10м"
    # дополняем header файла названиями параметров

    vparamHeader = []
    p = @tovs.select(:p1)
    p.each do |p|
      if p.p1 != nil
        p.p1.split('---').each do |pa|
          vparamHeader << pa.split(':')[0].strip if pa != nil
        end
      end
    end
    addHeaders = vparamHeader.uniq

    # Load the original CSV file
    # rows = CSV.read(file, headers: true).map(&:to_hash)

    rows = CSV.read(file, headers: true).collect do |row|
      row.to_hash
    end

    # !!!! есть такое ощущение, что здесь надо один раз составить массив новых заголовков с Параметрами
    # !!!! а затем один раз создать s = CSV.generate ==> добавить новый полный заголовки и все данные values = row.values
    # Original CSV column headers
    column_names = rows.first.keys
    # Array of the new column headers
    addHeaders.each do |addH|
      additional_column_names = ['Параметр: '+addH]
      # Append new column name(s)
      column_names += additional_column_names
      s = CSV.generate do |csv|
        csv << column_names
        rows.each do |row|
          # Original CSV values
          values = row.values
          # Array of the new column(s) of data to be appended to row
          # 				additional_values_for_row = ['1']
          # 				values += additional_values_for_row
          csv << values
        end
      end
      File.open(file, 'w') { |file| file.write(s) }
    end
    # Overwrite csv file

    # заполняем параметры по каждому товару в файле
    new_file = "#{Rails.public_path}"+'/ins_tov.csv'
    CSV.open(new_file, "w") do |csv_out|
      rows = CSV.read(file, headers: true).collect do |row|
        row.to_hash
      end
      column_names = rows.first.keys
      csv_out << column_names
      CSV.foreach(file, headers: true ) do |row|
        fid = row[0]
        vel = Tov.find_by_fid(fid)
        if vel != nil
# 				puts vel.id
          if vel.p1.present? # Вид записи должен быть типа - "Длина рамы: 20 --- Ширина рамы: 30"
            vel.p1.split('---').each do |vp|
              key = 'Параметр: '+vp.split(':')[0].strip
              value = vp.split(':')[1].remove('.') if vp.split(':')[1] !=nil
              row[key] = value
            end
          end
        end
        csv_out << row
      end
    end
    # 	VeloolimpMailer.insales.deliver_now
    puts "Finish Файл tov инсалес с параметрами на лету"

    current_process = "создаём файл csv_param"
    CaseMailer.notifier_process(current_process).deliver_now
  end
end
