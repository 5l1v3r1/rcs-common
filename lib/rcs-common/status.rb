#
#  Status of the process and system
#

# from RCS::Common
require 'rcs-common/trace'

# system
require 'sys/filesystem'
require 'sys/cpu'

include Sys

module RCS
module Collector

#TODO: move this class to rcs-common

class Status
  extend RCS::Tracer

  OK = "OK"
  WARN = "WARN"
  ERROR = "ERROR"
  
  def self.my_status
    return @@status || "N/A"
  end

  def self.my_status=(status)
    @@status = status
  end

  # returns the percentage of free space
  def self.disk_free
    # check the filesystem containing the current dir
    path = Dir.pwd
    # windows just want the drive letter, won't work with full path
    path = path.slice(0..2) if RUBY_PLATFORM.downcase.include?("mingw")
    stat = Filesystem.stat(path)
    # get the free and total blocks
    free = stat.blocks_free.to_f
    total = stat.blocks.to_f
    # return the percentage (pessimistic)
    return (free / total * 100).floor
  end

  # returns an indicator of the CPU usage in the last minute
  # not exactly the CPU usage percentage, but very close to it
  def self.cpu_load
    # cpu load in the last minute
    avg = CPU.load_avg
    if avg.is_a? Array then
      # under unix like, there are 3 values (1, 15 and 15 minutes)
      load_last_minute = avg.first
      # default values for systems where the number is not reported (linux)
      num_cpu = 1
      num_cpu = CPU.num_cpu if CPU.num_cpu
      # on multi core systems we have to divide by the number of CPUs
      percentage = (load_last_minute / num_cpu * 100).floor
    else
      # under windows there is only one value that is the percentage
      percentage = avg
    end

    return percentage
  end

  # returns the CPU usage of the current process
  def self.my_cpu_load
    # the first call to it
    @@prev_cpu ||= Process.times
    @@prev_time ||= Time.now

    # calculate the current cpu time
    current_cpu = Process.times

    # diff them and divide by the call interval
    cpu_time = (current_cpu.utime + current_cpu.stime) - (@@prev_cpu.utime + @@prev_cpu.stime)
    time_diff = Time.now - @@prev_time
    # prevent division by zero on low res systems
    time_diff = (time_diff == 0) ? 1 : time_diff
    # calculate the percentage
    cpu_percent = cpu_time / time_diff

    # remember it for the next iteration
    @@previous_times = Process.times
    @@prev_time = Time.now

    return cpu_percent.ceil
  end

end #Status

end #Collector::
end #RCS::
