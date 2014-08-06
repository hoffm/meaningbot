#!/usr/bin/env ruby

require 'rubygems'
require 'chatterbot/dsl'

CONFIG = if File.exists?('meaning_bot.yml')
           YAML.load_file('meaning_bot.yml')
         else
           ENV
         end

consumer_key CONFIG[:consumer_key]
consumer_secret CONFIG[:consumer_secret]
secret CONFIG[:secret]
token CONFIG[:token]

# remove this to send out tweets
#debug_mode

# remove this to update the db
no_update
# remove this to get less output when running
verbose

###
# Helpers
###

EXCLUSIONS = %w{? " 42}.map{|e| "-#{e}"}.join(' ')

def search_term(base, modifiers)
  "\"#{base}\" " + EXCLUSIONS + ' ' + modifiers
end

###
# Bot Script
###

if rand(10 == 7) # Only tweet once every 100 minutes

  left_tweets = []
  search search_term('is the meaning of life', '-what') do |tweet|
    left_tweets << tweet
  end

  right_tweets = []
  search search_term('the meaning of life is', '-give') do |tweet|
    right_tweets << tweet
  end

  recent_tweet_text = client.user_timeline(
    :screen_name => 'meaningbot',
    :count => 200,
    :trim_user => true
  ).map(&:text).join

  subject_tweet = left_tweets.map do |tweet|
    {
      :tweet => tweet,
      :text => tweet.text.sub(/is the meaning of life.*/i, '').strip.delete('\""')
    }
  end.shuffle.find do |tweet|
    !(tweet[:text] =~ /http|@|meaning/) &&
    !(recent_tweet_text.index(tweet[:text]))
  end

  predicate_tweet = right_tweets.map do |tweet|
    {
      :tweet => tweet,
      :text => tweet.text.sub(/.*the meaning of life is /i, '').strip.delete('\""')
    }
  end.shuffle.find do |tweet|
    (tweet[:text].length + subject_tweet[:text].length) < 136 &&
      !(tweet[:text] =~ /http|@|meaning/) &&
      !(recent_tweet_text.index(tweet[:text]))
  end

  if subject_tweet[:text] && predicate_tweet[:text]
    aphorism = subject_tweet[:text] + ' is ' + predicate_tweet[:text]
    if tweet(aphorism)
      client.favorite(subject_tweet[:tweet])
      client.favorite(predicate_tweet[:tweet])
      puts "Tweeted: " + aphorism
    else
      puts "Failed to tweet: " + aphorism
    end
  else
    puts "Not enough data."
    puts "LEFT: " + subject_tweet[:text].inspect
    puts "RIGHT: " + predicate_tweet[:text].inspect
  end

end

