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

	def Extract destination
		@rar_file.ExtractFile self, destination
	end
end

class RarFile
	attr_accessor :files, :excluded_files, :original_file_name, :switches, :password

	def ListFiles
		str = `unrar l #{original_file_name}`

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

	def initialize file_name, switches = []
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
		# TODO
	end

	def SetPassword password
		@password = password
	end

	def ExcludeFile file
		@excluded_files.push file
		@excluded_files = @excluded_files.uniq
	end

	def ExcludeFilesFromList file_list
		file_list.each{|file| 
			@excluded_files.push file 
			# todo: remove from @files
		}
		@excluded_files = @excluded_files.uniq
	end

	def Files
		if @files.size == 0
			self.ListFiles
		end
		@files
	end

	def ExtractArchive destination, full_path = false

	end

	def TestArchiveFiles

	end

	def ExtractFile file, destination, full_path = false
		new_file_name = destination.split("/").last
		old_file_name = file.Name.split("/").last

		new_path = destination[0, destination.size - new_file_name.size]

		`unrar e -y #{original_file_name} #{Shellwords.escape(file.Name)} #{new_path}`
		
		if(File.directory? destination)
			puts "#{destination} is a dir."
			return
		end

		`mv #{Shellwords.escape(new_path + old_file_name)} #{Shellwords.escape(new_path + new_file_name)}`

		return new_path + new_file_name
	end

end

class Rar
	def self.OpenFile path
		return RarFile.new path
	end
end