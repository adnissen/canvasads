#
# This file contains the helper functions for the server logs. Choose the function by the type of event being logged.
#
# @author: gtgettel

require 'builder'
require 'nokogiri'
require 'keen'

#
# Creates a log file under 'helpers/logs/'
#
# @params: filename - full name of log file (use .xml extension) e.g. master_log.xml
# @params: log_type - description of events that the log will hold
# @return: N/A
#
def log_create(filename, log_type)
  path = "helpers/logs/" + filename
  file = File.new(path, "w+")
  xml_file = Builder::XmlMarkup.new(:target => file, :indent => 1)
  xml_file.instruct! :xml, :encoding => "ASCII" # adds xml encoding info
  xml_file.log(Time.now.strftime("%d/%m/%Y %H:%M"), "type" => log_type) # creates first entry with date log opened and log_type
end

#
# Creates a log of an impression in the master_log.xml
#
# @params: request - sinatra request served to route handler
# @params: ad_id - id of add being returned
# @return: N/A
#
def log_Impression(request, impres)
  File.open("helpers/logs/master_log.xml", "a") { |file|
    xml_file = Builder::XmlMarkup.new(:target => file, :indent => 2)
    xml_file.impression { |imp|  # creates XML entry
      imp.time(impres[:time]);
      imp.token(impres[:token]);
	    imp.group(impres[:group]) || nil;
	    imp.host(request.host);
	    imp.ip(impres[:ip]);
	    imp.adID([:ad_id]);
    }
    Keen.publish(:ad_views, impression) if ENV["KEEN_PROJECT_ID"]

		# <impression>
		# => <time>   </time>
		# => <token>  </token>
		# => <group>	</group>
		# => <host>		</host>
		# => <ip>			</ip>
		# => <adID>		</adID>
		#</impression>

  }
end

#
# Creates a log of a request that went unserved in the master_log.xml
#
# @params: request - sinatra request served to route handler
# @return: N/A
#
def log_no_serve(request)
	File.open("helpers/logs/master_log.xml", "a") { |file|
	xml_file = Builder::XmlMarkup.new(:target => file, :indent => 2)
		xml_file.noServe { |ns|  # creates XML entry
			ns.time(Time.now.strftime("%d/%m/%Y %H:%M"));
			ns.token(request['token']);
			ns.host(request.host);
			ns.ip(request.ip);
		}

			# <noServe>
			# => <time>   	</time>
			# => <token>   	</token>
			# => <host>		</host>
			# => <ip>		</ip>
			#</noServe>
	}
end

#
# Counts the number of impressions in log file
#
# @params: logfile - xml file that contains impression log
# @return: counter - number of impressions in file
#
def count_impressions(logfile)
	file = File.open("helpers/logs/" + logfile)
	doc = Nokogiri::XML(file)
	counter = 0
	doc.xpath('/impression').each do |imp| # gets each <impression> tag
		counter++
	end
	return counter
end

#
# Counts the number of noServes in log file
#
# @params: logfile - xml file that contains noServe log
# @return: counter - number of noServes in file
#
def count_no_serve(logfile)
	file = File.open("helpers/logs/" + logfile)
	doc = Nokogiri::XML(file)
	counter = 0
	doc.xpath('/noServe').each do |imp| # gets each <noServe> tag
		counter++
	end
	return counter
end

#
# Counts the number of impressions in log file by nostname
#
# @params: logfile - xml file that contains impression log
# @params: hostname - host name of site that requested ad
# @return: counter - number of impressions in file
#
def count_impressions_by_host(logfile, hostname)
	file = File.open("helpers/logs/" + logfile)
	doc = Nokogiri::XML(file)
	counter = 0
	doc.xpath('/impression').each do |imp| # gets each <impression> tag
		if imp.at_xpath('host') == hostname
		  counter++
		end
	end
	return counter
end

#
# Counts the number of noServes in log file by hostname
#
# @params: logfile - xml file that contains noServe log
# @params: hostname - host name of site that requested ad
# @return: counter - number of noServes in file
#
def count_no_serve_by_host(logfile, hostname)
	file = File.open("helpers/logs/" + logfile)
	doc = Nokogiri::XML(file)
	counter = 0
	doc.xpath('/noServe').each do |ns| # gets each <noServe> tag
		if ns.at_xpath('host') == hostname
			counter++
		end
	end
	return counter
end

#
# Counts the number of impressions in log file by ad ID
#
# @params: logfile - xml file that contains impression log
# @params: ad_ID - ID of requested ad
# @return: counter - number of impressions in file
#
def count_impressions_by_ad_id(logfile, ad_ID)
	file = File.open("helpers/logs/" + logfile)
	doc = Nokogiri::XML(file)
	counter = 0
	doc.xpath('/impression').each do |imp| # gets each <impression> tag
		if imp.at_xpath('adID') == ad_ID
			counter++
		end
	end
	return counter
end
