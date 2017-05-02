require 'shellwords'

module RarSwitch
	DISABLE_AV_CHECK = "-av-"
	DISABLE_COMMENTS_SHOW = "-c-"
	FRESHEN_FILES = "-f"
	KEEP_BROKEN_EXTRACTED_FILES = "-kb"
	SEND_ALL_MESSAGES_TO_STDERR = "-ierr"
	DISABLE_ALL_MESSAGES = "-inul"
	OVERWRITE_EXISTING_FILES = "-o+"
	DO_NOT_OVERWRITE_EXISTING_FILES = "-o-"
	DO_NOT_QUERY_PASSWORD = "-p-"
	RECURSIVE_SUBDIRECTORIES = "-r"
	UPDATE_FILES = "-u"
	LIST_ALL_VOLUMES = "-v"
	ASSUME_YES_ON_ALL_QUERIES = "-y"
end

class InnerRarFile
	include Comparable
	attr_accessor :attributes, :size, :date, :time, :name, :rar_file, :password

	def initialize attrs, size, date, time, name, rar_file
		@attributes = attrs
		@size = size
		@date = date
		@name = name
		@rar_file = rar_file
	end

	def Attributes
		@attributes
	end
	def Size
		@size
	end
	def Date
		@date
	end
	def Time
		@time
	end
	def Name
		@name
	end

	def to_s
		"#{@attributes} #{@size} #{@name}"
	end

	def is_dir?
		@attributes.include? "D"
	end

	def <=>(anOther)
		@name <=> anOther.Name
	end

	def Extract destination_path, file_name = ""
		puts "file_name #{file_name}"
		if file_name == ""
			@rar_file.ExtractFile self, destination_path, self.Name.split("/").last
		else
			@rar_file.ExtractFile self, destination_path, file_name
		end
	end
end

class RarFile
	attr_accessor :files, :excluded_files, :original_file_name, :switches, :password

	def ListFiles
		str = self.ExecuteCommand "l", original_file_name
		#`unrar l #{original_file_name}`

		strs = str.split("\n")

		is_file = false
		strs.each{|s|
			if s.start_with? "-----------"
				is_file = !is_file  
				next
			elsif !is_file
				next
			else
				info = s.split(" ")
				file = InnerRarFile.new info[0], info[1], info[2], info[3], info[4, info.size].join(" "), self
				@files.push file
			end
		}
	end

	def initialize file_name, switches = [RarSwitch::ASSUME_YES_ON_ALL_QUERIES]
		@original_file_name = file_name
		@files = []
		@switches = switches
		@password = nil
		@excluded_files = []
	end

	def Switches 
		@switches
	end

	def AddSwitch switch
		@switches.push switch
		@switches = @switched.uniq
	end

	def RemoveSwitch switch
		@switches.delete switch
	end

	def SetPassword password
		@password = password
	end

	def ExcludeFile file
		@excluded_files.push file
		@excluded_files = @excluded_files.uniq

		to_remove = @files.select{|search| search.Name == file.Name } if file.is_a? InnerRarFile
		to_remove = @files.select{|search| search.Name == file } if file.is_a? String
		@files.delete to_remove
	end

	def ExcludeFilesFromList file_list
		file_list.each{|file| 
			@excluded_files.push file 

			to_remove = @files.select{|search| search.Name == file.Name } if file.is_a? InnerRarFile
			to_remove = @files.select{|search| search.Name == file } if file.is_a? String
			@files.delete to_remove
		}
		@excluded_files = @excluded_files.uniq
	end

	def Files
		if @files.size == 0
			self.ListFiles
		end
		@files
	end

	def ExtractArchive destination
		self.ExecuteCommand "e", "#{@original_file_name} #{destination}"
	end

	def TestArchiveFiles

	end

	def ExtractFile file, destination_path, file_name
		new_file_name = file_name
		old_file_name = file.Name.split("/").last

		new_path = destination_path

		self.ExecuteCommand "e", "#{@original_file_name} #{Shellwords.escape(file.Name)} #{new_path}"
		
		`mv #{Shellwords.escape(new_path + old_file_name)} #{Shellwords.escape(new_path + new_file_name)}`

		return new_path + new_file_name
	end

	def ExecuteCommand command, arguments
		command = "unrar #{command} "
		@switches.each {|switch|
			command += "#{switch} "
		}
		command += "#{arguments}"
		puts command
		`#{command}`
	end

end

class Rar
	def self.OpenFile path
		return RarFile.new path
	end
end