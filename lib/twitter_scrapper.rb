#!/usr/bin/env ruby
require 'twitter'
require "open-uri"
load 'config/twitter_config.rb'
class TwitterScrapper

  def initialize(user)
    @user = user
    @client = CLIENT
  end

  def user_timeline(options={})
    options ||= {count: 200, include_rts: true}
    @client.user_timeline(@user, options)
  end

  def get_media(options={})
    tweets = get_all_tweets(options)
    tweets.count
    Dir.mkdir("images/#{@user}") unless File.exists? "images/#{@user}"
    tweets.each do |tweet|
      tweet.media.each do |media| 
        download_media(media)
        videos = []
        if media.class == Twitter::Media::Video
          media.video_info.variants.each{|vid| videos << vid if vid.content_type == "video/mp4" }
        end
        videos.each{|vid| download_media(vid)}
      end
    end
  end

  def download_media(media)
    url = if media.class == Twitter::Variant
            media.url
          else
            media.media_url
          end
    File.open("images/#{@user}/#{url.basename}", 'wb') do |fo|
      fo.write open(url.to_s).read
    end
  rescue
    puts url
  end

  def collect_with_max_id(collection=[], max_id=nil, &block)
    response = yield(max_id)
    collection += response
    response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
  end

  def get_all_tweets(params)
    collect_with_max_id do |max_id|
      options = {count: 200, include_rts: true}
      options[:since_id] = params[:since_id] if params.has_key?(:since_id)
      unless max_id.nil?
        options[:max_id] = max_id
        puts max_id
        puts options
      end
      user_timeline options
    end
  end

end

