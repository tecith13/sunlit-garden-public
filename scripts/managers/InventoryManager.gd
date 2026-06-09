extends Node

# 현재 보유 돈.
# 나중에 UI에 표시하고, 상점 구매/판매에 사용.
var money: int = 0

# 현재 인벤토리 아이템.
# carrot_seed: 심을 수 있는 당근 씨앗
# carrot: 수확한 당근
var items: Dictionary = {
	"carrot_seed": 3,
	"carrot": 0
}


func _ready() -> void:
	# 다른 스크립트에서 InventoryManager를 찾을 수 있도록 그룹에 추가.
	add_to_group("inventory_manager")

	printInventory()


func addItem(itemId: String, amount: int) -> void:
	if amount <= 0:
		return

	if items.has(itemId) == false:
		items[itemId] = 0

	items[itemId] += amount

	print("Added item: ", itemId, " +", amount)
	printInventory()


func removeItem(itemId: String, amount: int) -> bool:
	if amount <= 0:
		return false

	if items.has(itemId) == false:
		print("Item not found: ", itemId)
		return false

	if items[itemId] < amount:
		print("Not enough item: ", itemId)
		return false

	items[itemId] -= amount

	print("Removed item: ", itemId, " -", amount)
	printInventory()

	return true


func hasItem(itemId: String, amount: int = 1) -> bool:
	if items.has(itemId) == false:
		return false

	return items[itemId] >= amount


func getItemCount(itemId: String) -> int:
	if items.has(itemId) == false:
		return 0

	return items[itemId]


func addMoney(amount: int) -> void:
	if amount <= 0:
		return

	money += amount

	print("Money +", amount)
	printInventory()


func spendMoney(amount: int) -> bool:
	if amount <= 0:
		return false

	if money < amount:
		print("Not enough money. Need: ", amount, " Current: ", money)
		return false

	money -= amount

	print("Money -", amount)
	printInventory()

	return true


func getMoney() -> int:
	return money


func printInventory() -> void:
	print("Money: ", money, " Inventory: ", items)


func getAllItems() -> Dictionary:
	return items.duplicate(true)


func setAllItems(loadedItems: Dictionary) -> void:
	items.clear()

	for itemId in loadedItems.keys():
		items[String(itemId)] = int(loadedItems[itemId])

	printInventory()


func setMoney(value: int) -> void:
	money = max(value, 0)
	printInventory()
