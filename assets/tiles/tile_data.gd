@tool
class_name TileDataRes extends Resource

@export_tool_button("UpdateLookUpTable", "Callable") var ulut = updateTable

@export var meshNameLookUp : Dictionary = {
	"WWWW" : {
		"names" : [
			"wwww(1)"
		]
	},
	"LLLL" : {
		"names" : [
			"llll(1)"
		]
	},
	"MMMM" : {
		"names" : [
			"mmmm(1)"
		]
	},
	"LLWL" : {
		"names" : [
			"llwl(1)",
			"llwl(2)"
		]
	},
	"LLMW" : {
		"names" : [
			"llwm(1)",
		]
	},
	"LLWW" : {
		"names" : [
			"llww(1)",
			"llww(2)",
			"llww(3)"
		]
	},
	"LMMW" : {
		"names" : [
			"lmmw(1)",
		]
	},
	"LMWW" : {
		"names" : [
			"lmww(1)",
		]
	},
	"LWLW" : {
		"names" : [
			"lwlw(1)",
			"lwlw(2)"
		]
	},
	"LWWW" : {
		"names" : [
			"lwww(1)",
			"Lwww(2)",
			"Lwww(3)"
		]
	},
	"MLLL" : {
		"names" : [
			"mlll(1)",
			"mlll(2)",
			"mlll(3)"
		]
	},
	"MLML" : {
		"names" : [
			"mlml(1)",
			"mlml(2)"
		]
	},
	"MMLL" : {
		"names" : [
			"mmll(1)",
			"mmll(2)",
			"mmll(3)"
		]
	},
	"MMLM" : {
		"names" : [
			"mmlm(1)",
			"mmlm(2)"
		]
	},
	"MMWM" : {
		"names" : [
			"mmwm(1)",
			"mmwm(2)"
		]
	},
	"MMWW" : {
		"names" : [
			"mmww(1)",
			"mmww(2)"
		]
	},
	"MWMW" : {
		"names" : [
			"mwmw(1)",
			"mwmw(2)"
		]
	},
	"MWWW" : {
		"names" : [
			"mwww(1)",
			"mwww(2)"
		]
	},
}

@export var lookUptable : Dictionary[int, Dictionary] = {}

@export var scenePath : String = "res://assets/tiles/scenes/"

func baseThreeToBaseTen(arg : String) -> int :
	var result : int  = 0
	var power : int = 0
	for i in range(arg.length() - 1, -1, -1) :
		result += arg[i].to_int() * (3 ** power)
		power += 1
	return result 

enum TYPE {W, L, M}
func updateTable() -> void :
	var final : Dictionary[int, Dictionary] = {}
	for i : String in meshNameLookUp.keys() :
		var temp := i
		var uniqueVariation : Array[String] = []
		uniqueVariation.append(temp)
		for j in 3 :
			temp = (temp.right(1) + temp).substr(0, 4)
			if !uniqueVariation.has(temp) :
				uniqueVariation.append(temp)
		for jj in uniqueVariation.size() :
			var baseThreeStr : String = ""
			for kk in uniqueVariation[jj] :
				baseThreeStr += str(TYPE[kk])
			var baseTen : int = baseThreeToBaseTen(baseThreeStr)
			final[baseTen] = {"type": i, "rotation" : jj}
	lookUptable = final
