local city = require("template.data.city")
local citycell = require("template.data.citycell")
local citycell_creature = require("template.data.citycell_creature")
local card = require("template.data.card")
local hero = require("template.data.hero")
local magic = require("template.data.magic")
local skill = require("template.data.skill")
module("template.data.gametemplate")
gameTemplate = {}
gameTemplate["city"] =city.data
gameTemplate["citycell"] =citycell.data
gameTemplate["citycell_creature"] =citycell_creature.data
gameTemplate["card"] =card.data
gameTemplate["hero"] =hero.data
gameTemplate["magic"] =magic.data
gameTemplate["skill"] =skill.data
return gameTemplate
