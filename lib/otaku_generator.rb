require 'chunky_png'
require_relative './image'

class OtakuGenerator < Image

  def initialize(img: ChunkyPNG::Image.from_file('./miya.png'))
    @img = img ## オタク画像

    @left_eye_pixels = get_fill_pixels(@img, 160, 245)
    @right_eye_pixels = get_fill_pixels(@img, 303, 252)

    @hair_pixels = get_close_color_pixels(@img, 233, 82)
    @hair_bright_pixiels = get_close_color_pixels(@img, 96, 102)
    @hair_dark_pixels = get_close_color_pixels(@img, 198, 133)

    @skin_pixels = get_close_color_pixels(@img, 225, 290)
    @skin_dark_pixels = get_close_color_pixels(@img, 135, 333)

  end


  def get_new_otaku(left_eye_color:, right_eye_color:, hair_color:, skin_color:, size:)
    ## 新しいオタクを返す

    new_otaku = Marshal.load(Marshal.dump(@img))

    unless left_eye_color && right_eye_color && hair_color && skin_color
      raise('Required argument lacking.')
    end

    new_otaku = change_color(new_otaku, @left_eye_pixels, left_eye_color)
    new_otaku = change_color(new_otaku, @right_eye_pixels, right_eye_color)
    new_otaku = change_color(new_otaku, @hair_pixels, hair_color)
    new_otaku = change_color(new_otaku, @hair_bright_pixiels, adjust_color(hair_color, 20))
    new_otaku = change_color(new_otaku, @hair_dark_pixels, adjust_color(hair_color, -20))
    new_otaku = change_color(new_otaku, @skin_pixels, skin_color)
    new_otaku = change_color(new_otaku, @skin_dark_pixels, adjust_color(skin_color, -20))

    new_otaku = new_otaku.resample_bilinear(size, size)

    back_ground_pixels = get_close_color_pixels(new_otaku, 0, 0, range:10)
    new_otaku = transparent(new_otaku, back_ground_pixels)

    new_otaku
  end
  
end
