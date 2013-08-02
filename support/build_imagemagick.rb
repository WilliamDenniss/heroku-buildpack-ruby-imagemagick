#!/usr/bin/env ruby

# Compile Imagemagick and delegates using Heroku's Vulcan build server
#
# Expects the latest source files to be downloaded in the same directory. 
# Get the delegate files from http://www.imagemagick.org/download/delegates/
# Currently, the only delegate that's being specially added is libpng15
#
# TODO - Download automatically.
# TODO - Figure out how to set permissions by default on S3, so files have permissions that 
#        allow access from Heroku instances

require 'fileutils'
require 'aws'

S3_BUCKET = '12spokes'
IMAGEMAGICK_VERSION = '6.7.8-0'
LIBPNG_VERSION = '1.5.11'
ZLIB_VERSION = '1.2.7'
GHOSTSCRIPT_VERSION = '9.05'

s3 = AWS::S3.new( :access_key_id => '',
                  :secret_access_key => '')

# Helper methods
def run(command)
  puts %x{ #{command} 2>&1 }
end

# libpng
libpng_name = "libpng-#{LIBPNG_VERSION}"
puts "Preparing #{libpng_name}"

run "tar xvfz #{libpng_name}.tar.gz"

Dir.chdir libpng_name do
  puts "Building #{libpng_name}"
  run "vulcan build --verbose --name #{libpng_name}"
  puts "Done"
end

s3.buckets[S3_BUCKET].objects["#{libpng_name}.tgz"].write File.read("/tmp/#{libpng_name}.tgz")
FileUtils.rm_rf libpng_name if Dir.exists? libpng_name



# ImageMagick
imagemagick_name = "ImageMagick-#{IMAGEMAGICK_VERSION}"
puts "Preparing #{imagemagick_name}"

run "tar xvfz ImageMagick.tar.gz"

Dir.chdir imagemagick_name do
  puts "Building #{imagemagick_name}"
  run "vulcan build --verbose --name #{imagemagick_name} --deps https://s3.amazonaws.com/12spokes/libpng-1.5.11.tgz"
  puts "Done"
end

s3.buckets[S3_BUCKET].objects["#{imagemagick_name}.tgz"].write File.read("/tmp/#{imagemagick_name}.tgz")

FileUtils.rm_rf imagemagick_name if Dir.exists? imagemagick_name
