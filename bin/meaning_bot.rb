#!/usr/bin/env ruby

module MeaningBot
  require 'rubygems'
  require 'chatterbot/dsl'

  module_function

  ###
  # Helpers
  ###

  MEANING_NOUNS = %w{meaning purpose point}
  SUBJECT_QUERIES = MEANING_NOUNS.map{|n| " is the #{n} of life"}
  PREDICATE_QUERIES = MEANING_NOUNS.map{|n| "the #{n} of life is "}
  SEARCH_EXCLUSIONS = '-? -42 -Christ'
  UNDESIRABLE_STRINGS = /http|@|#{MEANING_NOUNS.join('|')}/

  CREDS = if File.exists?('meaning_bot.yml')
            YAML.load_file('meaning_bot.yml')
          else
            ENV
          end

  consumer_key CREDS['consumer_key']
  consumer_secret CREDS['consumer_secret']
  secret CREDS['secret']
  token CREDS['token']

  def search_term(queries, modifiers)
    [
      queries.map{|q| "\"#{q}\""}.join(' OR '),
      SEARCH_EXCLUSIONS,
      modifiers
    ].join(' ')
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
    get_search_tweets search_term(SUBJECT_QUERIES, '-what')
  end

  def predicate_tweets
    get_search_tweets search_term(PREDICATE_QUERIES, '-give')
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

  def strip_queries_from_tweet(tweet_text, queries, query_type)
    query_matchers = queries.map do |q|
      matcher = ''
      matcher += '.*' if query_type == :predicate
      matcher += q
      matcher += '.*' if query_type == :subject
      matcher
    end

    tweet_text.sub(/#{query_matchers.join('|')}/i, '').strip.delete('\""')
  end

  def pair_of_tweets
    recents = recently_tweeted_text

    subject_tweet = subject_tweets.map do |tweet|
      {
        :tweet => tweet,
        :snippet => strip_queries_from_tweet(tweet.text, SUBJECT_QUERIES, :subject)
      }
    end.shuffle.find do |tweet|
      !(tweet[:snippet] =~ UNDESIRABLE_STRINGS) &&
        !(recents.index(tweet[:snippet].downcase))
    end

    predicate_tweet = predicate_tweets.map do |tweet|
      {
        :tweet => tweet,
        :snippet => strip_queries_from_tweet(tweet.text, PREDICATE_QUERIES, :predicate)
      }
    end.shuffle.find do |tweet|
      (tweet[:snippet].length + subject_tweet[:snippet].length + 4) < 140 &&
        !(tweet[:snippet] =~ UNDESIRABLE_STRINGS) &&
        !(recents.index(tweet[:snippet].downcase))
    end

    [subject_tweet, predicate_tweet]
  end


  def run(opts={})
    frequency = ARGV[0] ?  ARGV[0].to_i : (opts[:frequency] || 6)
    test_mode = (ARGV[1] == 'test') || opts[:testing]

    if one_nth_of_the_time(frequency)
      subject_tweet, predicate_tweet = pair_of_tweets

      if subject_tweet && predicate_tweet
        aphorism = subject_tweet[:snippet] + ' is ' + predicate_tweet[:snippet]

        puts "*"*10
        if test_mode
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


MeaningBot.run