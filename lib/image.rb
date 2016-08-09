class Image

  protected

  def in_area?(img, x, y)
    ## 座標が画像の範囲内か？
     x <= img.width-1 && y <= img.height-1
  end


  def get_fill_pixels(img, x, y, range: 20000)
    ## 与えられた座標を始点として、塗りつぶし対象になる座標のリストを返す
    ## rangeは許容度(テキトー)

    flag = Array.new(img.height){ Array.new(img.width, false) }
    base_color = rgb(img.get_pixel(x, y))
    axys = [{:x=>1, :y=>0},
            {:x=>-1, :y=>0},
            {:x=>0, :y=>1},
            {:x=>1, :y=>-1}]

    que = []
    res = []
    que << {:x=>x, :y=>y}
    flag[y][x] = true

    loop do
      break if que.size == 0
      pi = que.shift
      res << pi

      axys.each do |axy|
        next_pi = {:x=>pi[:x]+axy[:x], :y=>pi[:y]+axy[:y]}
        if !flag[next_pi[:y]][next_pi[:x]] && in_area?(img, next_pi[:x], next_pi[:y]) &&
          close_color?(base_color, rgb(img.get_pixel(next_pi[:x], next_pi[:y])), range)

          que << next_pi
          flag[next_pi[:y]][next_pi[:x]] = true
        end
      end
    end

    res
  end


  def get_close_color_pixels(img, x, y, range: 200)
    ## 与えられた座標と色が近い座標のリストを返す
    ## 画像全体と対象とする。 rangeは許容度(テキトー)

    base_color = rgb(img.get_pixel(x, y))
    res = []

    img.width.times do |x|
      img.height.times do |y|
        pi = {:x=>x, :y=>y}
        if close_color?(base_color, rgb(img.get_pixel(x, y)), range)
          res << pi
        end
      end
    end

    res
  end


  def in_area?(img, x, y)
    ## 座標が画像の範囲内か？
     x <= img.width-1 && y <= img.height-1
  end


  def close_color?(rgb1, rgb2, range)
    ## 2つの色が十分に近いか？
    score = (rgb1[:r]-rgb2[:r])**2 + (rgb1[:g]-rgb2[:g])**2 + (rgb1[:b]-rgb2[:b])**2
    score < range ? true : false
  end


  def close_white?(rgb)
    ## 白に近いか？
    rgb[:r] + rgb[:g] + rgb[:b] > 500
  end


  def adjust_color(rgb, i)
    ## 雑に色を調節する iが0より小さいと暗く、大きいと明るくなる
    res = {}
    rgb.each do |k, v|
      v += i
      v = 255 if v > 255
      v = 0 if v < 0
      res[k] = v
    end
    res
  end


  def change_color(img, pixels, rgb)
    pixels.each do |pi|
      img.set_pixel(pi[:x], pi[:y], rgb_to_int(rgb))
    end
    img
  end


  def transparent(img, pixels)
    pixels.each do |pi|
      img.set_pixel(pi[:x], pi[:y], ChunkyPNG::Color.rgba(255, 255, 255, 0))
    end
    img
  end


  def rgb(i)
    {:r => ChunkyPNG::Color.r(i),
    :g => ChunkyPNG::Color.g(i),
    :b => ChunkyPNG::Color.b(i)}
  end


  def rgb_to_int(rgb)
    ChunkyPNG::Color.rgb(rgb[:r], rgb[:g], rgb[:b])
  end


  def mp_to_rgb(magick_pixel)
    arr = magick_pixel.to_s.split(', ').map{|a| a.split('=')[1]}
    {:r=> arr[0].to_i,
    :g=> arr[1].to_i,
    :b=> arr[2].to_i}
  end

end
