class Board < ActiveRecord::Base
	require 'csv'

	belongs_to :user
	has_many :trays, dependent: :destroy
	has_many :places, dependent: :destroy
	has_many :picks, dependent: :destroy
	accepts_nested_attributes_for :places
	accepts_nested_attributes_for :picks

	validates_presence_of :name

	def self.import_from_text(params)
		@name = params[:name]
		@text = params[:places]

		counter = 0
		line = @text.split(/[\r\n]+/)
		@places_array = []
		for l in line 
			if(counter!=0&&counter!=1)	
				elements = l.split(" ")
				chash = {}
				if(Board.all.empty?)
					nextid = 1
				else
					nextid = Board.maximum(:id).next
				end
				chash[:board_id]=nextid
				chash[:designator]=elements[0]
				if(Footprint.find_by(name: elements[1]).nil?)
					Footprint.create(name: elements[1])
				end
				footprint_id = Footprint.find_by(name: elements[1]).id
				chash[:footprint_id]=footprint_id
				chash[:mid_x]=Board.prettify(elements[2])
				chash[:mid_y]=Board.prettify(elements[3])
				chash[:ref_x]=Board.prettify(elements[4])
				chash[:ref_y]=Board.prettify(elements[5])
				chash[:pad_x]=Board.prettify(elements[6])
				chash[:pad_y]=Board.prettify(elements[7])
				chash[:tb]=elements[8]
				chash[:rotation]=elements[9]
				chash[:comment]=elements[10]
				chash[:unit]="mm"
				@places_array.push(chash)
			end
			counter+=1
		end
		params = {board: {name: @name, places_attributes: @places_array }}
		board = Board.create(params[:board])
		board.save
	end

	def self.prettify(text)
		num = text.gsub("mm","")
		return num
	end

	def self.load_footprint_csv(file)
		CSV.foreach(file.path, headers: true) do |row|
			footprint_attributes = row.to_hash.slice(*updatable_attributes)
			footprint_name = footprint_attributes["name"]
			footprint = Footprint.find_by(name: footprint_name)
			footprint.attributes = footprint_attributes
			footprint.save
		end
	end

	def self.updatable_attributes
		["name","outward_width","outward_depth","unit"]
	end

end