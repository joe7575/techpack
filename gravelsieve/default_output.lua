local api = gravelsieve.api


api.register_input("gravelsieve:sieved_gravel", "gravelsieve:sieved_gravel")

api.after_ores_calculated(function (ore_probabilities)
	local ore_rates = api.sum_probabilities(ore_probabilities)
	api.register_input("default:gravel",
		api.merge_probabilities(
			gravelsieve.ore_probabilities,
			api.scale_probabilities_to_fill({
				["default:gravel"] = 1,
				["gravelsieve:sieved_gravel"] = 1
			}, 1-ore_rates)
		)
	)
end)