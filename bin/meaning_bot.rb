#!/usr/bin/env ruby

module MeaningBot
  require 'rubygems'
  require 'chatterbot/dsl'

  module_function


  # remove this to send out tweets
  #debug_mode

  # remove this to update the db
  #no_update

  # remove this to get less output when running
  #verbose

  ###
  # Helpers
  ###

  SUBJECT_SIGNATURE = ' is the meaning of life'
  PREDICATE_SIGNATURE = 'the meaning of life is '
  UNDESIRABLE_CHARS = /http|@|meaning/

  def search_term(base, modifiers)
    "\"#{base}\" " + '-? -42 -Christ' + modifiers
  end

  def one_nth_of_the_time(n)
    rand(n) == 0
  end

  def get_search_tweets(query)
    tweets = []
    search query do |tweet|
      tweets << tweet
    end
    since_id(0)

    tweets
  end

  def subject_tweets
    get_search_tweets search_term(SUBJECT_SIGNATURE, '-what')
  end

  def predicate_tweets
    get_search_tweets search_term(PREDICATE_SIGNATURE, '-give')
  end

  def recently_tweeted_text
    text = client.user_timeline(
      :screen_name => 'meaningbot',
      :count => 200,
      :trim_user => true
    ).map(&:text).join.downcase

    since_id(0)

    text
  end

  def pair_of_tweets
    recents = recently_tweeted_text

    subject_tweet = subject_tweets.map do |tweet|
      {
        :tweet => tweet,
        :snippet => tweet.text.sub(/#{SUBJECT_SIGNATURE}.*/i, '').strip.delete('\""')
      }
    end.shuffle.find do |tweet|
      !(tweet[:snippet] =~ UNDESIRABLE_CHARS) &&
        !(recents.index(tweet[:snippet].downcase))
    end

    predicate_tweet = predicate_tweets.map do |tweet|
      {
        :tweet => tweet,
        :snippet => tweet.text.sub(/.*#{PREDICATE_SIGNATURE}/i, '').strip.delete('\""')
      }
    end.shuffle.find do |tweet|
      (tweet[:snippet].length + subject_tweet[:snippet].length + 4) < 140 &&
        !(tweet[:snippet] =~ UNDESIRABLE_CHARS) &&
        !(recents.index(tweet[:snippet].downcase))
    end

    [subject_tweet, predicate_tweet]
  end


  def run(opts)
    if one_nth_of_the_time(10) || opts[:force]
      subject_tweet, predicate_tweet = pair_of_tweets

      if subject_tweet && predicate_tweet
        aphorism = subject_tweet[:snippet] + ' is ' + predicate_tweet[:snippet]

        puts "*"*10
        if opts[:testing]
          puts "TESTING MODE. NOT TWEETING."
        else
          puts "TWEETING!"
          tweet(aphorism)
          client.favorite(subject_tweet[:tweet])
          client.favorite(predicate_tweet[:tweet])
        end
        puts "SUBJECT FULL TEXT: " + subject_tweet[:tweet].text
        puts "PREDICATE FULL TEXT: " + predicate_tweet[:tweet].text
        puts "TWEET TEXT: " + aphorism
        puts "*"*10
      else
        puts "Not enough material."
      end
    else
      puts "Staying silent this time."
    end
  end

end

CREDS = if File.exists?('bin/meaning_bot.yml')
          YAML.load_file('bin/meaning_bot.yml')
        else
          ENV.symbolize_keys!
        end

consumer_key CREDS[:consumer_key]
consumer_secret CREDS[:consumer_secret]
secret CREDS[:secret]
token CREDS[:token]


MeaningBot.run(:testing => true, :force => true)