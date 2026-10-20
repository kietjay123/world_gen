@tool
class_name TileDataRes extends Resource

@export_tool_button("UpdateLookUpTable") var ulut = updateTable

@export var meshNameLookUp : Dictionary = {
	"WWWW" : {
		"names" : [
			"wwww(1)"
		],
		"mirror" : false,
	},
	"LLLL" : {
		"names" : [
			"llll(1)"
		],
		"mirror" : false,
	},
	"MMMM" : {
		"names" : [
			"mmmm(1)"
		],
		"mirror" : false,
	},
	"LLWL" : {
		"names" : [
			"llwl(1)",
			"llwl(2)",
			"llwl(3)"
		],
		"mirror" : false,
	},
	"LLMW" : {
		"names" : [
			"llmw(1)",
		],
		"mirror" : true,
	},
	"LLWW" : {
		"names" : [
			"llww(1)",
			"llww(2)",
			"llww(3)"
		],
		"mirror" : false,
	},
	"LMMW" : {
		"names" : [
			"lmmw(1)",
		],
		"mirror" : true,
	},
	"LMWW" : {
		"names" : [
			"lmww(1)",
		],
		"mirror" : true,
	},
	"LWLW" : {
		"names" : [
			"lwlw(1)",
			"lwlw(2)"
		],
		"mirror" : false,
	},
	"LWWW" : {
		"names" : [
			"lwww(1)",
			"lwww(2)",
			"lwww(3)"
		],
		"mirror" : false,
	},
	"MLLL" : {
		"names" : [
			"mlll(1)",
			"mlll(2)",
			"mlll(3)"
		],
		"mirror" : false,
	},
	"MLML" : {
		"names" : [
			"mlml(1)",
			"mlml(2)"
		],
		"mirror" : false,
	},
	"MMLL" : {
		"names" : [
			"mmll(1)",
			"mmll(2)",
			"mmll(3)",
			"mmll(4)",
			"mmll(5)"
		],
		"mirror" : false,
	},
	"MMLM" : {
		"names" : [
			"mmlm(1)",
			"mmlm(2)"
		],
		"mirror" : false,
	},
	"MMWM" : {
		"names" : [
			"mmwm(1)",
			"mmwm(2)"
		],
		"mirror" : false,
	},
	"MMWW" : {
		"names" : [
			"mmww(1)",
			"mmww(2)"
		],
		"mirror" : false,
	},
	"MWMW" : {
		"names" : [
			"mwmw(1)",
			"mwmw(2)"
		],
		"mirror" : false,
	},
	"MWWW" : {
		"names" : [
			"mwww(1)",
			"mwww(2)"
		],
		"mirror" : false,
	},
	"LLLL/0020" : {
		"names" : [
			"llllr5(1)",
		],
		"mirror" : false,
	},
	"LLLL/1020" : {
		"names" : [
			"llllr92(1)",
			"llllr92(2)",
		],
		"mirror" : false,
	},
	"LLLL/1200" : {
		"names" : [
			"llllr96(1)",
			"llllr96(2)",
		],
		"mirror" : true,
	},
	"LLLL/1220" : {
		"names" : [
			"llllr926(1)",
			"llllr926(2)",
		],
		"mirror" : true,
	},
	"LLWW/1000" : {
		"names" : [
			"llwwr92(1)",
			"llwwr92(2)"
		],
		"mirror" : false,
	},
	"MMMM/0020" : {
		"names" : [
			"mmmmr5(1)",
		],
		"mirror" : false,
	},
	"MMMM/1020" : {
		"names" : [
			"mmmmr92(1)",
			"mmmmr92(2)",
		],
		"mirror" : false,
	},
	"MMMM/1200" : {
		"names" : [
			"mmmmr96(1)",
			"mmmmr96(2)",
		],
		"mirror" : true,
	},
	"MMMM/1220" : {
		"names" : [
			"mmmmr926(1)",
			"mmmmr926(2)",
		],
		"mirror" : true,
	},
	"MMLL/1020" : {
		"names" : [
			"mmllr92(1)",
			"mmllr92(2)"
		],
		"mirror" : false,
	},
	"MMLL/0020" : {
		"names" : [
			"mmllr5(1)",
		],
		"mirror" : false,
	},
	"MMWW/1020" : {
		"names" : [
			"mmwwr92(1)",
		],
		"mirror" : false,
	},
	"LLLL/1202" : {
		"names" : [
			"llllr946(1)",
		],
		"mirror" : false,
	},
	"MMMM/1202" : {
		"names" : [
			"mmmmr946(1)",
		],
		"mirror" : false,
	},
	"LMLW" : {
		"names" : [
			"lmlw(1)",
		],
		"mirror" : false,
	},
	"MLMW" : {
		"names" : [
			"mlmw(1)",
		],
		"mirror" : false,
	},
	"WMWL" : {
		"names" : [
			"wmwl(1)",
		],
		"mirror" : false,
	},
	"LLLL/0000/1010" : {
		"names" : [
			"llllp92(1)",
		],
		"mirror" : false,
	},
	"LLLL/0000/1100" : {
		"names" : [
			"llllp96(1)",
		],
		"mirror" : false,
	},
	"LLLL/0000/1110" : {
		"names" : [
			"llllp962(1)",
		],
		"mirror" : false,
	},
	"LLLL/0000/1111" : {
		"names" : [
			"llllp9624(1)",
		],
		"mirror" : false,
	},
	"LLLL/0000/1000" : {
		"names" : [
			"llllp9(1)",
		],
		"mirror" : false,
	},
	"LLLL/1020/0011" : {
		"names" : [
			"llllp24r96(1)",
		],
		"mirror" : true,
	},
	"LLLL/0020/0101" : {
		"names" : [
			"llllp64r5(1)",
		],
		"mirror" : false,
	},
	"LLLL/1020/0101" : {
		"names" : [
			"llllp64r92(1)",
		],
		"mirror" : false,
	},
	"LLLL/0020/1100" : {
		"names" : [
			"llllp96r5(1)",
		],
		"mirror" : true,
	},
	"LLLL/0020/1101" : {
		"names" : [
			"llllp964r5(1)",
		],
		"mirror" : false,
	},
	"LLLL/0020/0100" : {
		"names" : [
			"llllp6r5(1)",
		],
		"mirror" : true,
	},
	"LLLL/0020/1000" : {
		"names" : [
			"llllp9r5(1)",
		],
		"mirror" : false,
	},
	"MLLL/0000/0010" : {
		"names" : [
			"mlllp2(1)",
		],
		"mirror" : true,
	},
	"MLLL/0000/0110" : {
		"names" : [
			"mlllp62(1)",
		],
		"mirror" : false,
	},
	"LLWL/0000/1000" : {
		"names" : [
			"llwlp9(1)",
		],
		"mirror" : true,
	},
	"LLWL/0000/1001" : {
		"names" : [
			"llwlp94(1)",
		],
		"mirror" : false,
	},
	"MMLL/0000/0010" : {
		"names" : [
			"mmllp2(1)",
		],
		"mirror" : false,
	},
	"LLWW/0000/0010" : {
		"names" : [
			"llwwp9(1)",
		],
		"mirror" : false,
	}
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
		print(i)
		var substr : PackedStringArray = i.split("/")
		var terrain : String = substr[0]
		var river : String = substr[1] if substr.size() > 1 else "0000"
		var path : String = substr[2] if substr.size() > 2 else "0000"
		if i == "LLLL/1020/0101" :
			prints(path, river, terrain)
		var uniqueVariation : Array[String] = []
		uniqueVariation.append(path + river + terrain)
		for j in 3 :
			var temp : String = ""
			terrain = (terrain.right(1) + terrain).substr(0, 4)
			if river != "0000" :
				river = (river.right(1) + river).substr(0, 4)
			if path != "0000" :
				path = (path.right(1) + path).substr(0, 4)
			temp = path + river + terrain
			if !uniqueVariation.has(temp) :
				uniqueVariation.append(temp)
		for jj in uniqueVariation.size() :
			var baseThreeTerrain : String = ""
			for kk in uniqueVariation[jj].right(4) :
				baseThreeTerrain += str(TYPE[kk])
			var baseTen : int = baseThreeToBaseTen(uniqueVariation[jj].left(-4) + baseThreeTerrain)
			print(baseTen)
			final[baseTen] = {"type": i, "rotation" : jj, "mirror" : false}
		
		if meshNameLookUp[i]["mirror"] == true :
			terrain = substr[0]
			river = substr[1] if substr.size() > 1 else "0000"
			path = substr[2] if substr.size() > 2 else "0000"
			terrain = mirrorTerrain(terrain)
			river = mirrorRiver(river)
			# BUG MAYBe
			path = mirrorRiver(path)
			uniqueVariation = []
			uniqueVariation.append(path + river + terrain)
			for j in 3 :
				var temp : String = ""
				terrain = (terrain.right(1) + terrain).substr(0, 4)
				if river != "0000" :
					river = (river.right(1) + river).substr(0, 4)
				if path != "0000" :
					path = (path.right(1) + path).substr(0, 4)
				temp = path + river + terrain
				if !uniqueVariation.has(temp) :
					uniqueVariation.append(temp)
			for jj in uniqueVariation.size() :
				var baseThreeTerrain : String = ""
				for kk in uniqueVariation[jj].right(4) :
					baseThreeTerrain += str(TYPE[kk])
				var baseTen : int = baseThreeToBaseTen(uniqueVariation[jj].left(-4) + baseThreeTerrain)
				print(baseTen)
				final[baseTen] = {"type": i, "rotation" : jj, "mirror" : true}
	lookUptable = final

func mirrorTerrain(input : String) -> String :
	var a = input[1]
	var b = input[3]
	input[1] = input[0]
	input[3] = input[2]
	input[0] = a
	input[2] = b
	return input 

func mirrorRiver(input : String) -> String :
	var a = input[1]
	input[1] = input[3]
	input[3] = a
	return input 
