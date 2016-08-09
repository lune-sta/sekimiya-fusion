#* utf-8
require 'yaml'
require 'twitter'
require 'rmagick'
require 'chunky_png'
require 'AnimeFace'
require 'tempfile'
require 'open-uri'
require_relative './lib/otaku_generator'
require_relative './lib/collage'

class SekimiyaFusion

  def initialize(config)
    @config = config

    @twitter_rest_api = Twitter::REST::Client.new do |o|
      o.consumer_key        = config['twitter']['consumer_key']
      o.consumer_secret     = config['twitter']['consumer_secret']
      o.access_token        = config['twitter']['access_token']
      o.access_token_secret = config['twitter']['access_token_secret']
    end

    @twitter_stream_api = Twitter::Streaming::Client.new do |o|
      o.consumer_key        = config['twitter']['consumer_key']
      o.consumer_secret     = config['twitter']['consumer_secret']
      o.access_token        = config['twitter']['access_token']
      o.access_token_secret = config['twitter']['access_token_secret']
    end

    @retry_count = 0

    @otaku_gen = OtakuGenerator.new(img: ChunkyPNG::Image.from_file('./miya.png'))
  end

  def run
    begin
      log('started')
      twitter_stream_loop
    rescue => e
      puts e

      if @retry_count >= 5
        log('exit')
        exit
      end

      sleep 10
      log('retry')
      retry
    end
  end

  private

  def twitter_stream_loop
    @twitter_stream_api.user do |o|

      next unless o.is_a?(Twitter::Tweet)
      next unless o.text =~ /^#{@config['twitter']['screen_name']}\s/
      log("screen_name = '#{o.user.screen_name}', text = '#{o.text}'")

      ## 添付がついてなければ無視
      urls = o.media.map{ |photo| photo.media_url.to_s }
      next if urls.size == 0

      res = []

      urls.each do |url|
        suffix = url.split('.')[-1]
        img_temp = Tempfile.create(['sf', '.' + suffix])

        open(img_temp.path, 'wb') do |output|
          open(url) do |data|
            output.write(data.read)
          end
        end

        ## pngじゃなかったらpngにする
        if suffix == 'png'
          img_temp_png = img_temp
        else
          magick_image = Magick::ImageList.new(img_temp.path)
          img_temp_png = Tempfile.create(['sf', '.png'])
          magick_image.write(img_temp_png.path)
        end

        ## 顔検出
        faces = AnimeFace.detect(Magick::ImageList.new(img_temp_png))
        next if faces.size == 0

        ## コラ生成
        collage = Collage.new(@otaku_gen, ChunkyPNG::Image.from_file(img_temp_png), faces)
        new_img = collage.fusion(scale: 2.2)

        output_temp = Tempfile.create(['sf', '.png'])
        new_img.save(output_temp.path)

        res << output_temp.path
      end

      if res.size == 0

        @twitter_rest_api.update("@#{o.user.screen_name} なにもわからん", in_reply_to_status_id: o.id)

      else

        media_ids = res.map do |file|
          Thread.new do
            @twitter_rest_api.upload(File.new(file))
          end
        end.map(&:value)

        @twitter_rest_api.update("@#{o.user.screen_name}", in_reply_to_status_id: o.id, :media_ids => media_ids.join(','))
      end

      @retry_count = 0
    end
  end

  def log(text)
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    puts "[#{timestamp}] #{text}"
  end
end

config = YAML.load_file('./config.yml')
s = SekimiyaFusion.new(config)
s.run
