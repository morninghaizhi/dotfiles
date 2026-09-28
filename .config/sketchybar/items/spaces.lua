local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.icon_map")

-- AeroSpace workspaces
-- Keep in sync with the `alt-<key> = 'workspace <name>'` bindings in aerospace.toml
local workspaces = {
	"1", "2", "3", "4", "5", "6", "7", "8", "9",
	"E", "G", "M", "S", "T", "W", "Z",
}

local aerospace = "/opt/homebrew/bin/aerospace"

local colors_spaces = {
	colors.cmap_1,
	colors.cmap_2,
	colors.cmap_3,
	colors.cmap_4,
	colors.cmap_5,
	colors.cmap_6,
	colors.cmap_7,
	colors.cmap_8,
	colors.cmap_9,
	colors.cmap_10,
}

local spaces = {}
local space_names = {}

for i, ws in ipairs(workspaces) do
	local color = colors_spaces[(i - 1) % #colors_spaces + 1]

	local space = sbar.add("item", "space." .. ws, {
		drawing = false,
		icon = {
			font = {
				family = settings.font.numbers,
				size = 14,
			},
			string = ws,
			padding_left = 5,
			padding_right = 0,
			color = color,
			highlight_color = colors.tn_black3,
		},
		label = {
			padding_right = 10,
			padding_left = 3,
			color = color,
			highlight_color = colors.tn_black3,
			font = "sketchybar-app-font-bg:Regular:21.0",
			y_offset = -2,
		},
		padding_right = 4,
		padding_left = 4,
		background = {
			color = colors.transparent,
			height = 22,
			border_width = 0,
			border_color = colors.transparent,
		},
		click_script = aerospace .. " workspace " .. ws,
	})

	spaces[ws] = { item = space, color = color }
	table.insert(space_names, space.name)
end

sbar.add("bracket", space_names, {
	background = {
		color = colors.background,
		border_color = colors.accent3,
		border_width = 2,
	},
})

-- Show only the focused workspace and workspaces that have windows,
-- with the icons of the apps on each workspace
local function render_spaces(focused)
	sbar.exec(aerospace .. " list-windows --all --format '%{workspace}|%{app-name}'", function(windows)
		local apps = {}
		for line in tostring(windows):gmatch("[^\r\n]+") do
			local ws, app = line:match("^(.-)|(.*)$")
			if ws then
				apps[ws] = apps[ws] or {}
				apps[ws][app] = true
			end
		end

		for ws, space in pairs(spaces) do
			local selected = ws == focused
			local icon_line = ""
			for app, _ in pairs(apps[ws] or {}) do
				local lookup = app_icons[app]
				local icon = ((lookup == nil) and app_icons["default"] or lookup)
				icon_line = icon_line .. utf8.char(0x202F) .. icon
			end
			if icon_line == "" then
				icon_line = "—"
			end

			space.item:set({
				drawing = selected or apps[ws] ~= nil,
				icon = { highlight = selected },
				label = { string = icon_line, highlight = selected },
				background = {
					height = 25,
					color = selected and space.color or colors.transparent,
					border_color = selected and space.color or colors.transparent,
					corner_radius = 6,
				},
			})
		end
	end)
end

local function update_spaces(focused)
	if focused and focused ~= "" then
		render_spaces(focused)
	else
		sbar.exec(aerospace .. " list-workspaces --focused", function(result)
			render_spaces((tostring(result):gsub("%s+", "")))
		end)
	end
end

-- Triggered by `exec-on-workspace-change` in aerospace.toml
sbar.add("event", "aerospace_workspace_change")

local space_window_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})

space_window_observer:subscribe(
	{ "aerospace_workspace_change", "front_app_switched", "space_windows_change", "system_woke" },
	function(env)
		update_spaces(env.FOCUSED_WORKSPACE)
	end
)

update_spaces()

sbar.add("item", { width = 6 })

local spaces_indicator = sbar.add("item", {
	background = {
		color = colors.with_alpha(colors.grey, 0.0),
		border_color = colors.with_alpha(colors.bg1, 0.0),
		border_width = 0,
		corner_radius = 6,
		height = 24,
		padding_left = 6,
		padding_right = 6,
	},
	icon = {
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 14.0,
		},
		padding_left = 6,
		padding_right = 9,
		color = colors.accent1,
		string = icons.switch.on,
	},
	label = {
		drawing = "off",
		padding_left = 0,
		padding_right = 0,
	},
})

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
	local currently_on = spaces_indicator:query().icon.value == icons.switch.on
	spaces_indicator:set({
		icon = currently_on and icons.switch.off or icons.switch.on,
	})
end)

spaces_indicator:subscribe("mouse.entered", function(env)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = colors.tn_black1,
				border_color = { alpha = 1.0 },
				padding_left = 6,
				padding_right = 6,
			},
			icon = {
				color = colors.accent1,
				padding_left = 6,
				padding_right = 9,
			},
			label = { drawing = "off" },
			padding_left = 6,
			padding_right = 6,
		})
	end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = { alpha = 0.0 },
				border_color = { alpha = 0.0 },
			},
			icon = { color = colors.accent1 },
			label = { width = 0 },
		})
	end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
	sbar.trigger("swap_menus_and_spaces")
end)

local front_app_icon = sbar.add("item", "front_app_icon", {
	display = "active",
	icon = { drawing = false },
	label = {
		font = "sketchybar-app-font-bg:Regular:21.0",
	},
	updates = true,
	padding_right = 0,
	padding_left = -10,
})

front_app_icon:subscribe("front_app_switched", function(env)
	local icon_name = env.INFO
	local lookup = app_icons[icon_name]
	local icon = ((lookup == nil) and app_icons["default"] or lookup)
	front_app_icon:set({ label = { string = icon, color = colors.accent1 } })
end)

sbar.add("bracket", {
	spaces_indicator.name,
	front_app_icon.name,
}, {
	background = {
		color = colors.tn_black3,
		border_color = colors.accent1,
		border_width = 2,
	},
})
