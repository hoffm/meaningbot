#!/usr/bin/env ruby

require 'rubygems'
require 'chatterbot/dsl'

CONFIG = if File.exists?('meaning_bot.yml')
           YAML.load_file('meaning_bot.yml')
         else
           ENV
         end

#
# this is the script for the twitter bot MeaningBot
# generated on 2014-08-04 14:57:12 -0400
#

consumer_key CONFIG[:consumer_key]
consumer_secret CONFIG[:consumer_secret]
secret CONFIG[:secret]
token CONFIG[:token]

# remove this to send out tweets
debug_mode

# remove this to update the db
no_update
# remove this to get less output when running
verbose

# here's a list of users to ignore
blacklist "abc", "def"

# here's a list of things to exclude from searches
exclude "http", "#", '?', '@'

left_tweets = []
search "\"is the meaning of life\" -http -# -? -@ -\" -what -42" do |tweet|
  left_tweets << tweet
end

right_tweets = []
search "\"the meaning of life is\" -http -# -? -@ -\" -give -42" do |tweet|
  right_tweets << tweet
end

subjects = left_tweets.map do |tweet|
  tweet.text.sub(/is the meaning of life.*/i, '')
end.uniq.sort_by{ |t| t.length }

predicates = right_tweets.map do |tweet|
  tweet.text.sub(/.*the meaning of life is/i, '')
end.uniq.sort_by{ |t| -t.length }

[subjects.count, predicates.count].min.times do |i|
  puts subjects[i] + 'is' + predicates[i]
  puts ""
end

def read_file
  text = []

  File.read("tmp/st_suspect_emails.txt").each_line do |line|
    text << line.chop
  end

  text
end

# replies do |tweet|
#   reply "Yes #USER#, you are very kind to say that!", tweet
# end
