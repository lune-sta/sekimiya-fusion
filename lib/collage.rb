require 'pp'
require 'rmagick'
require 'chunky_png'
require 'AnimeFace'

require_relative './otaku_generator'

class Collage


  def initialize(otaku_gen, img, faces)
    @otaku_gen = otaku_gen
    @img = img  # ChunkyPNG::Image
    @faces = faces

  end


  def fusion(scale: 2.2)
    new_img = Marshal.load(Marshal.dump(@img))

    @faces.each_with_index do |face, i|
      otaku = @otaku_gen.get_new_otaku(left_eye_color: mp_to_rgb(face['eyes']['left']['colors'][0]),
                                right_eye_color: mp_to_rgb(face['eyes']['right']['colors'][0]),
                                hair_color: mp_to_rgb(face['hair_color']),
                                skin_color: mp_to_rgb(face['skin_color']),
                                size: (face['face']['width'] * scale).to_i)

      face_center = {:x=> face['face']['x'] + face['face']['width']/2,
                     :y=> face['face']['y'] + face['face']['height']/2}

      otaku_face_area = {:x=> face_center[:x] - otaku.width/2,
                         :y=> face_center[:y] - otaku.height/2 - otaku.height/8,
                         :width=> otaku.width,
                         :height=> otaku.height}

      otaku.flip_vertically! if facing_left?(face)

      (0...otaku.width).each do |y|
        (0...otaku.height).each do |x|
          next if corner_noise?(otaku, x, y) ## すみっこの白いギザギザ対策
          new_img.compose_pixel(otaku_face_area[:x] + x, otaku_face_area[:y] + y, otaku.get_pixel(x, y))
        end
      end
    end

    new_img
  end


  def corner_noise?(img, x, y)
    rgb = rgb(img.get_pixel(x, y))
    return false unless close_white?(rgb)

    axys = [{:x=>1, :y=>0}, {:x=>-1, :y=>0}, {:x=>0, :y=>1},{:x=>1, :y=>-1}]
    flag = false ## 隣に透過ピクセルがあるか？
    axys.each do |axy|
      a = ChunkyPNG::Color.a(img.get_pixel(x+axy[:x], y+axy[:y]))
      if a == 0
        flag = true
        break
      end
    end

    flag
  end


  def close_white?(rgb)
    ## 白に近いか？
    rgb[:r] + rgb[:g] + rgb[:b] > 500
  end


  def facing_left?(face)
    ## 左を向いているか？
    center = face['face']['x'] + face['face']['width']/2
    face['nose']['x'] < center
  end


  def rgb(i)
    {:r => ChunkyPNG::Color.r(i),
    :g => ChunkyPNG::Color.g(i),
    :b => ChunkyPNG::Color.b(i)}
  end


  def mp_to_rgb(magick_pixel)
    arr = magick_pixel.to_s.split(', ').map{|a| a.split('=')[1]}
    {:r=> arr[0].to_i,
    :g=> arr[1].to_i,
    :b=> arr[2].to_i}
  end
end
