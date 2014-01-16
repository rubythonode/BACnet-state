# Copyright (C) 2013, Alliance for Sustainable Energy
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
########################################################################

class OidDiscoverer 
  include java.lang.Runnable
  def initialize(local_device, filters, svc, databus_sender = false)
    @local_device = local_device
    @filters = filters
    @sched_svc = svc
    @sender = databus_sender
  end

  # schedule fresh lookup of Oids for all known devices 
  # distribute start time randomly over 9 minutes (code runs every 10 minutes)
  def run
    new_devices = KnownDevice.where(:refresh_oids_heartbeat => nil).limit(10).entries
    stale_devices = KnownDevice.where(:refresh_oids_heartbeat.lt => (Time.now - 1.day)).limit(10).entries
    LoggerSingleton.logger.info "#{DateTime.now} kicking oid discovery.  total new device count = #{KnownDevice.where(:refresh_oids_heartbeat => nil).count} and total stale device count = #{KnownDevice.where(:refresh_oids_heartbeat.lt => (Time.now - 1.day)).count}"
    new_devices.each do |kd|
      # if kd.complete?
        delay = rand(60 * 9)
        LoggerSingleton.logger.info "#{DateTime.now} scheduling oid lookup for device #{kd.instance_number} with delay of #{delay}"
        @sched_svc.schedule(DeviceOidLookup.new(kd, @local_device, @filters, @sender), delay, TimeUnit::SECONDS)
      # end
    end
    stale_devices.each do |kd|
      # if kd.complete?
        delay = rand(60 * 9)
        LoggerSingleton.logger.info "#{DateTime.now} scheduling oid lookup for device #{kd.instance_number} with delay of #{delay}"
        @sched_svc.schedule(DeviceOidLookup.new(kd, @local_device, @filters, @sender), delay, TimeUnit::SECONDS)
      # end
    end
  end

end