-- Copyright (c) 2022 Maksim Tuprikov <insality@gmail.com>. This code is licensed under MIT license

--- Druid Rich Input custom component.
-- It's wrapper on Input component with cursor and placeholder text
-- @module RichInput
-- @within Input
-- @alias druid.rich_input

--- The component druid instance
-- @tfield DruidInstance druid @{DruidInstance}

--- On input field text change callback(self, input_text)
-- @tfield Input input @{Input}

--- On input field text change to empty string callback(self, input_text)
-- @tfield node cursor

--- On input field text change to max length string callback(self, input_text)
-- @tfield druid.text placeholder @{Text}

---
local const = require("druid.const")
local component = require("druid.component")
local utf8 = require("druid.system.utf8")
--local render_helper = require ("render.helper")

local RichInput = component.create("druid.rich_input")

local SCHEME = {
	--ROOT = "root",
	BUTTON = "button",
	--PLACEHOLDER = "placeholder_text",
	INPUT = "input_text",
	--CURSOR = "cursor_node",
	--HIGHLIGHT = "highlight_node",
}

local function find_cursor_pos(self, pivot, full_text, touch_delta_x, touch_delta_y, cur_letter_index)
	local left_edge = 0
	local top_edge	= 0
	local text_size_x,  text_size_y =  self.text:get_text_size(full_text)
	
	if pivot == gui.PIVOT_CENTER then
		left_edge	= text_size_x/2 * -1
		top_edge	= text_size_y/2 
	elseif pivot == gui.PIVOT_N then
		left_edge	= text_size_x/2 * -1
		top_edge	= 0
	elseif pivot == gui.PIVOT_NE then
		left_edge	= text_size_x * -1	
		top_edge	= 0
	elseif pivot == gui.PIVOT_E then
		left_edge	= text_size_x * -1

	elseif pivot == gui.PIVOT_SE then
		left_edge	= text_size_x * -1
		
	elseif pivot == gui.PIVOT_S then
		left_edge	= text_size_x/2 * -1
		
	elseif pivot == gui.PIVOT_SW then
		left_edge	= 0
		
	elseif pivot == gui.PIVOT_W then
		left_edge	= 0
		
	elseif pivot == gui.PIVOT_NW then
		left_edge	= 0
		top_edge	= 0
	end

	local letters_count = utf8.len(full_text)
	local cursor_delta_x = 0
	local cursor_delta_y = 0 + touch_delta_y
	local letter_index = 0
	local pos = vmath.vector3(0)

	if cur_letter_index then --если это ввод с клавиатуры, нам не нужно искать индекс, он у нас уже есть.
		cursor_delta_x =  left_edge + self.text:get_text_size(utf8.sub(full_text, 1, cur_letter_index))
		pos.x = (cursor_delta_x )/self.input.text.scale.x --эта мразь умеет скейлиться, так что мы ей это припомним
		pos.y = cursor_delta_y
		letter_index = cur_letter_index
	else -- в противном случае это клик, и индекс надо наи и вернуть
		for i = 0, letters_count do
			cursor_delta_x =  left_edge + self.text:get_text_size(utf8.sub(full_text, 1, i)) 
			if cursor_delta_x > touch_delta_x then
				pos.x = (cursor_delta_x ) /self.input.text.scale.x
				pos.y = cursor_delta_y
				letter_index = i
				break --если перешли за искомую букву, то вываливаемся
			else
				pos.x = (cursor_delta_x ) /self.input.text.scale.x
				pos.y = cursor_delta_y
				letter_index = i
			end
		end	
		
	end
	--print("qq2d", pos, letter_index, self.input.text.scale)
	return pos, letter_index
end


local function get_cursor_delta_y (self, pivot, full_text, touch_delta_y, cursor_delta_y)
	touch_delta_y = touch_delta_y or 0
	cursor_delta_y = cursor_delta_y or 0
	
	local top_edge	= 0
	local text_size_x,  text_size_y =  self.text:get_text_size(full_text)
	local selected_line = 1
	local total_lines =  math.ceil(self.input.text_height /self.cursor_height ) --всего строк
	
	if pivot == gui.PIVOT_CENTER then
		top_edge	= text_size_y/2 - self.half_cursor_height
		selected_line = total_lines - math.ceil((touch_delta_y + cursor_delta_y  - self.half_cursor_height )/ self.cursor_height )
		
	elseif pivot == gui.PIVOT_N then
		top_edge	= 0 -  self.half_cursor_height
		selected_line =  math.ceil((touch_delta_y)/ self.cursor_height ) * -1 
		
	elseif pivot == gui.PIVOT_NE then
		top_edge	= 0 -  self.half_cursor_height
		selected_line = math.ceil((touch_delta_y)/ self.cursor_height ) * -1 
		
	elseif pivot == gui.PIVOT_E then
		top_edge	= text_size_y/2 - self.half_cursor_height
		selected_line = total_lines - math.ceil((touch_delta_y + cursor_delta_y  - self.half_cursor_height )/ self.cursor_height )

	elseif pivot == gui.PIVOT_SE then
		top_edge	= text_size_y - self.half_cursor_height
		selected_line = total_lines - math.ceil((touch_delta_y )/ self.cursor_height )

	elseif pivot == gui.PIVOT_S then
		top_edge	= text_size_y - self.half_cursor_height
		selected_line = total_lines - math.ceil((touch_delta_y )/ self.cursor_height )

	elseif pivot == gui.PIVOT_SW then
		top_edge	= text_size_y - self.half_cursor_height
		selected_line = total_lines - math.ceil((touch_delta_y )/ self.cursor_height )

	elseif pivot == gui.PIVOT_W then
		top_edge	= text_size_y/2 - self.half_cursor_height
		selected_line = total_lines - math.ceil((touch_delta_y + cursor_delta_y  - self.half_cursor_height )/ self.cursor_height )
		
	elseif pivot == gui.PIVOT_NW then
		top_edge	= 0 -  self.half_cursor_height
		selected_line = math.ceil((touch_delta_y)/ self.cursor_height ) * -1 
		
	end
	
	return top_edge, selected_line
end


local function get_last_string(text)
	local count =1
	local last_string
	for s in (utf8.gmatch( text, "\n" )) do
		count = count + 1		
	end
	last_string = utf8.match(text, ".*\n(.*)") or text
	return count, last_string
end


local function get_all_lines(text)
	if utf8.sub(text, -1)~="\n" then 
		text=text.."\n"
	else
		text=text.." \n"
	end
	return utf8.gmatch(text, "(.-)\n")
end



local function get_closest_cursor_pos(pivot, new_line, local_index, old_line)
	local new_pos = 0
	if pivot == gui.PIVOT_CENTER or pivot == gui.PIVOT_N or pivot == gui.PIVOT_S  then

		if new_line.length >= local_index then
			new_pos = local_index
		else 
			new_pos = new_line.length
		end
		--[[
		local old_half = math.ceil(old_line.length /2)
		local new_half = math.ceil(new_line.length/2)
		
		local gap = old_half - local_index
		if  new_half >= old_half then
			new_pos =  old_half -local_index
		else
			new_pos = new_half
		end
		--]]
		
	elseif pivot == gui.PIVOT_E or pivot == gui.PIVOT_NE or pivot == gui.PIVOT_SE then
		local trail = old_line.length - local_index
		if new_line.length <= trail then
			new_pos = 0
		else
			new_pos = new_line.length - trail
		end
	elseif pivot == gui.PIVOT_W or pivot == gui.PIVOT_SW or pivot == gui.PIVOT_NW then
		if new_line.length >= local_index then
			new_pos = local_index
		else 
			new_pos = new_line.length
		end
	end

	--print ("qq2d", "\nqq2d Старый индекс",local_index, "\nqq2d Длина строки",new_line.length, "\nqq2d Новый индекс", new_pos )
	return new_pos + new_line.prefix
end

local function move_cursor_updown(self, full_text, move_up)	
	local cur_pivot = self.input:get_pivot()
	local prefix_length = 0 --длинна текса до курсора
	local string_num = 1
	local cursor_on_string = 1
	local cursor_local_pos = 0
	local cursor_found = false
	local str_table = {}
	
	for cur_string in get_all_lines(full_text) do
		local letters_count = utf8.len(cur_string)
		--------------------
		--if (self.input.cursor_letter_index < prefix_length + letters_count + string_num) and not cursor_found then --это текущая строка
		if (self.input.cursor_letter_index <= prefix_length + letters_count) and not cursor_found then --это текущая строка
			cursor_local_pos = self.input.cursor_letter_index - prefix_length
			cursor_on_string = string_num
			cursor_found = true
		end
		--------------------
		table.insert(str_table, {length = letters_count, prefix = prefix_length})  ---  -1 это чтоб знак переноса не считать
		
		prefix_length = prefix_length + letters_count +1 --один символ на перенос строки
		string_num = string_num + 1
	end
	--print ("qq2d","cursor_on_string", cursor_on_string, "#str_table", #str_table)
	if move_up then
		if cursor_on_string > 1 then
			self.input.cursor_letter_index =  get_closest_cursor_pos(cur_pivot, str_table[cursor_on_string - 1], cursor_local_pos, str_table[cursor_on_string])
			--print ("qq2d","Со строки",cursor_on_string,  "На индекс",self.input.cursor_letter_index)
		end
	else
		if cursor_on_string < #str_table then
			self.input.cursor_letter_index =  get_closest_cursor_pos(cur_pivot, str_table[cursor_on_string + 1], cursor_local_pos, str_table[cursor_on_string])
			--print ("qq2d","Со строки",cursor_on_string,  "На индекс",self.input.cursor_letter_index)
		end
	end
end


local function set_cursor(self)
	local cur_pivot = self.input:get_pivot()
	local full_text = self.input:get_text()
	local input_scale = gui.get_scale(self.input.click_node)

	if self.touch_pos_x then -- клики мышкой
		--print ("qq2d", "update_cursor_mouse")
		local node_pos = gui.get_screen_position(self.input.text_node)
		--local touch_delta_x = ((self.action_pos_x - node_pos.x) / input_scale.x ) / render_helper.zoom_factor_x 
		--local touch_delta_y = ((self.action_pos_y - node_pos.y) / input_scale.y) / render_helper.zoom_factor_y
		local touch_delta_x = ((self.action_pos_x - node_pos.x) / input_scale.x ) / 1
		local touch_delta_y = ((self.action_pos_y - node_pos.y) / input_scale.y) / 1
		local string_num = 0
		local cursor_delta_y = 0

		if self.input.is_multiline then
			local selected_line			
			cursor_delta_y, selected_line =  get_cursor_delta_y(self, cur_pivot, full_text, touch_delta_y, cursor_delta_y)  -- это координаты курсора для первой строки
			local prefix_length = 0 --длинна текса до курсора
			
			for cur_string in get_all_lines(full_text) do
				if string_num == selected_line then
					--------------------
					local cursor_pos, new_letter_index = find_cursor_pos(self, cur_pivot, cur_string, touch_delta_x, cursor_delta_y - (string_num) * self.cursor_height)
					self.input.cursor_letter_index = new_letter_index + prefix_length
					gui.set_position(self.cursor, cursor_pos)
					--------------------
				else
					prefix_length = prefix_length + utf8.len(cur_string)+1 --один символ на перенос строки
				end
				string_num = string_num + 1
			end	
			
		else
			local cursor_pos
			cursor_pos, self.input.cursor_letter_index = find_cursor_pos(self, cur_pivot, full_text, touch_delta_x, 0)
			gui.set_position(self.cursor, cursor_pos)
		end
		self.touch_pos_x = nil
		
	else ----------ввод с клавиатуры-----------------------------------------------------------------------------------------------
		if self.input.is_multiline then
			local cursor_delta_y = get_cursor_delta_y(self, cur_pivot, full_text)    -- это координаты курсора для первой строки
			local string_num = 0
			local prefix_length = 0 --длинна текса до курсора

			for cur_string in get_all_lines(full_text) do
				local letters_count = utf8.len(cur_string)
				--------------------
				if (self.input.cursor_letter_index <= prefix_length + letters_count  + string_num) and  (self.input.cursor_letter_index >= prefix_length)  then
					local cur_string_pos = self.input.cursor_letter_index - prefix_length--позиция внутри строки
					local cursor_pos = find_cursor_pos(self, cur_pivot, cur_string, 0, cursor_delta_y - (string_num) * self.cursor_height, cur_string_pos)
					gui.set_position(self.cursor, cursor_pos)
					--print ("qq2d", cur_string_pos)
					--break
				end
				--------------------
				prefix_length = prefix_length + letters_count +1 --один символ на перенос строки
				string_num = string_num + 1
			end	
		else
			local cursor_pos = find_cursor_pos(self, cur_pivot, full_text, 0, 0, self.input.cursor_letter_index)
			gui.set_position(self.cursor, cursor_pos)
		end	
	end
end


local function animate_cursor(self)
	
	gui.cancel_animation(self.cursor, gui.PROP_COLOR)
	gui.set_color(self.cursor, vmath.vector4(1))
	gui.animate(self.cursor, gui.PROP_COLOR, vmath.vector4(1,1,1,0), gui.EASING_INSINE, 0.8, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
end


local function update_text(self)
	
	local text_width = self.input.total_width
	local text_height = self.input.text_height
	--gui.set_scale(self.cursor, self.input.text.scale)
	gui.set_size(self.highlight, vmath.vector3(text_width, text_height, 0))
	self.cursor_width, self.cursor_height = self.text:get_text_size("|") 
	self.half_cursor_height = self.cursor_height/2
	
	set_cursor(self)
end


local function clear_text(self, replace_with_symbol)
	
	local spacer = replace_with_symbol or ""
	self.input:set_text(spacer)
	update_text(self)

	if replace_with_symbol then
		gui.set_position(self.cursor, vmath.vector3(self.input.total_width/2, 0, 0))
		self.input.cursor_letter_index = 1
	else
		gui.set_position(self.cursor, vmath.vector3(0, 0, 0))
		self.input.cursor_letter_index = 1
	end
	
	gui.set_enabled(self.highlight, false)
	gui.set_enabled(self.cursor, true)
end


local function on_select(self)
	
	self.input.cursor_letter_index = utf8.len(self.input:get_text()) or 0
	gui.set_enabled(self.cursor, true)
	gui.set_enabled(self.highlight, false)
	gui.set_enabled(self.placeholder, false)
	--gui.set_enabled(self.placeholder.node, false)
	animate_cursor(self)
end


local function on_unselect(self)
	
	gui.set_enabled(self.cursor, false)
	gui.set_enabled(self.highlight, false)
	gui.set_enabled(self.placeholder, true and #self.input:get_text() == 0)
	--gui.set_enabled(self.placeholder.node, true and #self.input:get_text() == 0)
end


local function on_button_click(self)
	
	self.touch_pos_x = self.action_pos_x
	gui.set_enabled(self.highlight, false)
	gui.set_enabled(self.cursor, true)
	self.text:set_to(self.input:get_text())
	set_cursor(self)
end


local function on_button_double_click(self)
	
	if #self.input:get_text() > 0 then
		gui.set_enabled(self.highlight, true)
		gui.set_enabled(self.cursor, false)
	end
end

--- Component init function
-- @tparam RichInput self @{RichInput}
-- @tparam string template The template string name
-- @tparam table nodes Nodes table from gui.clone_tree
function RichInput.init(self, template, nodes)
	if template then self:set_template(template) end
	self:set_nodes(nodes)
	self.druid = self:get_druid()
	self.input = self.druid:new_input(self:get_node(SCHEME.BUTTON), self:get_node(SCHEME.INPUT))
	self.placeholder = gui.new_text_node(vmath.vector3(0), "qweeqweqwe") -- self:get_node(SCHEME.PLACEHOLDER)
	gui.set_parent(self.placeholder, self:get_node(SCHEME.BUTTON))
	gui.set_color(self.placeholder, vmath.vector4(1.0, 1.0, 1.0, 0.5))
	
	--self.placeholder = self.druid:new_text(self:get_node(SCHEME.PLACEHOLDER))
	self.text = self.druid:new_text(self:get_node(SCHEME.INPUT))

	self.cursor_width, self.cursor_height = self.text:get_text_size("|")
	self.cursor = gui.new_box_node(vmath.vector3(0), vmath.vector3(2, self.cursor_height,0))  -- self:get_node(SCHEME.CURSOR)
	gui.set_parent(self.cursor, self:get_node(SCHEME.INPUT))
	
	self.highlight = gui.new_box_node(vmath.vector3(0), vmath.vector3(self.cursor_width, self.cursor_height,0)) -- self:get_node(SCHEME.HIGHLIGHT) 	
	gui.set_parent(self.highlight, self:get_node(SCHEME.INPUT))
	gui.set_enabled(self.highlight, false)
	gui.set_color(self.highlight, vmath.vector4(0.3,0.5,0.7,0.5))
	
	self.input.on_input_text:subscribe(update_text)
	self.input.on_input_select:subscribe(on_select)
	self.input.on_input_unselect:subscribe(on_unselect)
	
	self.input.button.on_click:subscribe(on_button_click, self)
	self.input.button.on_double_click:subscribe(on_button_double_click, self)
	self.input.style.NO_CONSUME_INPUT_WHILE_SELECTED = true
	self.input.style.SKIP_INPUT_KEYS = true
	self.input.style.IS_LONGTAP_ERASE = false

	self.input.cursor_letter_index = 0
	self.action_pos_x = nil
	self.action_pos_y = nil

	
	
	self.half_cursor_height = self.cursor_height/2

	self.pivot = self.input.pivot
	gui.set_pivot(self.highlight, self.pivot)

	if self.input.is_multiline then
		self.input.text.adjust_type = const.TEXT_ADJUST.NO_ADJUST
		self.text.adjust_type = const.TEXT_ADJUST.NO_ADJUST
	end
	
	clear_text(self)
	on_unselect(self)
end


--- Set placeholder text
-- @tparam RichInput self @{RichInput}
-- @tparam string placeholder_text The placeholder text
function RichInput.set_placeholder(self, placeholder_text)
	self.placeholder:set_to(placeholder_text)
	return self
end


function RichInput.on_input(self, action_id, action)
	self.action_pos_x = action.screen_x
	self.action_pos_y = action.screen_y
	
	if gui.is_enabled(self.highlight) then
		if action_id == const.ACTION_BACKSPACE or action_id == const.ACTION_DEL  then
			clear_text(self)
			on_select(self)
		elseif action_id == const.ACTION_TEXT then
			clear_text(self, action.text)
		end
	else
		if action_id == const.ACTION_DEL and  (action.pressed or action.repeated)  then
			local text = self.input:get_text()
			local deleting_symbol = utf8.sub(text, self.input.cursor_letter_index+1,  self.input.cursor_letter_index+1)
			--print ("qq2d", deleting_symbol)
			if deleting_symbol ~= "\n" then  --игорёк удаляе обычную буковку
				local new_text = utf8.sub(text, 1, self.input.cursor_letter_index) .. utf8.sub(text, self.input.cursor_letter_index +2 ) 
				self.input:set_text(new_text)
			else --игорёк пытается удалить символ переноса. 
				--if  utf8.sub(text, self.input.cursor_letter_index+2,  self.input.cursor_letter_index+2) == "\n" then --дадим возможность удалять только двойные переносы строк
					local new_text = utf8.sub(text, 1, self.input.cursor_letter_index) .. utf8.sub(text, self.input.cursor_letter_index +2 ) 
					self.input:set_text(new_text)
				--end
			end
		end
		
		if action_id == const.ACTION_BACKSPACE  then
			if self.input.cursor_letter_index > 0 and gui.is_enabled(self.cursor) and (action.pressed or action.repeated)  then 
				local text = self.input:get_text()
				local deleting_symbol = utf8.sub(text, self.input.cursor_letter_index,  self.input.cursor_letter_index)
				if deleting_symbol ~= "\n" then  --игорёк удаляе обычную буковку
					local new_text = utf8.sub(text, 1, self.input.cursor_letter_index-1) .. utf8.sub(text, self.input.cursor_letter_index +1 ) 
					self.input.cursor_letter_index = self.input.cursor_letter_index -1
					self.input:set_text(new_text)
				else --игорёк пытается удалить символ переноса. 
					local new_text = utf8.sub(text, 1, self.input.cursor_letter_index-2) .. utf8.sub(text, self.input.cursor_letter_index) 
					self.input.cursor_letter_index = self.input.cursor_letter_index -2
					self.input:set_text(new_text)
				end
				--print ("qq2d", deleting_symbol)
			end
			--return true  --закомментил, ибо сранно себя ведёт
		end
		
		if action_id == const.ACTION_LEFT and  (action.pressed or action.repeated)  then
			--print("left")
			if self.input.cursor_letter_index > 0 then
				self.input.cursor_letter_index = self.input.cursor_letter_index -1
			end
		elseif action_id == const.ACTION_RIGHT and  (action.pressed or action.repeated)  then
			--print("right")
			if self.input.cursor_letter_index <  utf8.len(self.input:get_text()) then
				self.input.cursor_letter_index = self.input.cursor_letter_index + 1
			end

		elseif action_id == const.ACTION_UP and  (action.pressed or action.repeated)  then
			move_cursor_updown(self, self.input:get_text(), true)
		elseif action_id == const.ACTION_DOWN and  (action.pressed or action.repeated)  then
			move_cursor_updown(self, self.input:get_text(), false)

		--elseif action_id == const.ACTION_ENTER and action.pressed then	
		--	set_cursor(self)
		end

		if action_id then  --для всех случаев, кроме простого движения мыши
			update_text(self)
		end
		--self.touch_pos_x = nil
		
		if utf8.len(self.input:get_text()) <=0 then
			self.input.cursor_letter_index = 0
		end	
	end

	------------------------------------------------------------------
	if action_id == const.ACTION_CTRL then
		if action.pressed then
			self.ctrl_pressed = true
		elseif action.released then
			self.ctrl_pressed = false
		end
	end
	------------------------------------------------------------------	
	if self.ctrl_pressed and (action_id == const.ACTION_KEY_V and action.released) then
		local text = clipboard.paste()
		local prefix = utf8.sub(self.input:get_text(), 1, self.input.cursor_letter_index)
		local postfix =  utf8.sub(self.input:get_text(),  self.input.cursor_letter_index + 1)
		self.input:set_text(prefix..text..postfix)
		self.input.cursor_letter_index = self.input.cursor_letter_index + utf8.len(text)
		update_text(self)
	end

	
	if gui.is_enabled(self.cursor) then
		return true
	else
		return false
	end
end

return RichInput
